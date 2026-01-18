import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../models/conversation.dart';
import '../models/llm_provider.dart';
import '../models/queued_request.dart';
import '../services/llm/llm_service.dart';
import '../services/llm/claude_service.dart';
import '../services/llm/openai_service.dart';
import '../services/llm/gemini_service.dart';
import '../services/queue_service.dart';
import '../services/memory_service.dart';
import '../services/model_lifecycle_service.dart';
import '../services/conversation_archive_service.dart';
import 'settings_provider.dart';

/// Current state of the voice assistant
enum AssistantState {
  idle, // Waiting for push-to-talk
  wakeWordActive, // Wake word listening active (after push-to-talk)
  listening, // Wake word detected, listening for command
  processing, // Converting speech to text
  thinking, // Waiting for LLM response
  speaking, // Speaking the response
  error, // An error occurred
}

/// Main state management for the voice assistant
///
/// Coordinates:
/// - Wake word detection
/// - Speech-to-text
/// - LLM API calls
/// - Text-to-speech
/// - Offline queue
/// - Conversation history
class AssistantProvider extends ChangeNotifier {
  final SettingsProvider _settingsProvider;
  final QueueService _queueService;
  final MemoryService _memoryService;
  final ModelLifecycleService _modelLifecycleService;
  final ConversationArchiveService _archiveService;
  final Logger _logger = Logger();

  // LLM Services
  late final Map<LLMProvider, LLMService> _llmServices;

  // Current state
  AssistantState _state = AssistantState.idle;
  AssistantState get state => _state;

  // Current conversation
  Conversation _currentConversation = Conversation();
  Conversation get currentConversation => _currentConversation;

  // Error message (when state is error)
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Status message for UI
  String _statusMessage = 'Press button to start';
  String get statusMessage => _statusMessage;

  // Currently transcribed text (shown during processing)
  String _transcribedText = '';
  String get transcribedText => _transcribedText;

  // Whether TTS is playing
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  // STT timeout timer
  Timer? _sttTimeoutTimer;

  // Whether wake word is actively listening
  bool _isWakeWordListening = false;
  bool get isWakeWordListening => _isWakeWordListening;

  AssistantProvider({
    required SettingsProvider settingsProvider,
    required QueueService queueService,
    required MemoryService memoryService,
    required ModelLifecycleService modelLifecycleService,
    required ConversationArchiveService archiveService,
  })  : _settingsProvider = settingsProvider,
        _queueService = queueService,
        _memoryService = memoryService,
        _modelLifecycleService = modelLifecycleService,
        _archiveService = archiveService {
    _initializeLLMServices();
    _setupQueueCallbacks();
  }

  /// Initialize LLM services for each provider
  void _initializeLLMServices() {
    _llmServices = {
      LLMProvider.claude: ClaudeService(
        apiKey: _settingsProvider.getApiKey(LLMProvider.claude),
      ),
      LLMProvider.openai: OpenAIService(
        apiKey: _settingsProvider.getApiKey(LLMProvider.openai),
      ),
      LLMProvider.gemini: GeminiService(
        apiKey: _settingsProvider.getApiKey(LLMProvider.gemini),
      ),
    };
  }

  /// Setup callbacks for queue service
  void _setupQueueCallbacks() {
    _queueService.onRequestProcessed = (request, response) {
      // Add the response to the conversation
      _addAssistantResponse(
        response,
        provider: request.provider,
        modelId: request.modelId,
      );
    };
  }

  /// Get the LLM service for current or specified provider
  LLMService _getLLMService([LLMProvider? provider]) {
    final p = provider ?? _settingsProvider.defaultProvider;
    return _llmServices[p]!;
  }

  // ============================================
  // State Management
  // ============================================

  void _setState(AssistantState newState, {String? status, String? error}) {
    _state = newState;
    if (status != null) _statusMessage = status;
    if (error != null) _errorMessage = error;
    notifyListeners();
  }

  // ============================================
  // Push-to-Talk & Wake Word Handling
  // ============================================

  /// Push-to-talk button pressed
  /// Archives current conversation (if any) and starts wake word listening
  Future<void> onPushToTalk() async {
    _logger.i('Push-to-talk pressed');

    // Archive current conversation if it has messages
    if (_currentConversation.messages.isNotEmpty) {
      await _archiveCurrentConversation();
    }

    // Start fresh conversation
    _currentConversation = Conversation();
    _transcribedText = '';
    _errorMessage = null;

    // Load wake word model
    try {
      await _memoryService.updateMemoryUsage();
      _memoryService.logMemoryState('before wake word load');

      await _modelLifecycleService.loadWakeWordModel();

      _isWakeWordListening = true;
      _setState(
        AssistantState.wakeWordActive,
        status: 'Say "Computer" to begin',
      );

      _logger.i('Wake word listening started');
    } catch (e) {
      _handleError('Failed to start wake word detection: $e');
    }

    notifyListeners();
  }

  /// Stop wake word listening
  Future<void> stopWakeWordListening() async {
    if (!_isWakeWordListening) return;

    _logger.i('Stopping wake word listening');
    _isWakeWordListening = false;

    // Unload wake word model if setting is enabled
    if (!_settingsProvider.keepModelsLoaded) {
      await _modelLifecycleService.unloadWakeWordModel();
    }

    _setState(AssistantState.idle, status: 'Press button to start');
    notifyListeners();
  }

  /// Called when wake word is detected
  Future<void> onWakeWordDetected() async {
    _logger.i('Wake word detected');
    _errorMessage = null;

    // Load STT model
    try {
      await _memoryService.updateMemoryUsage();

      final ModelSize modelSize = _getModelSizeFromSettings();
      await _modelLifecycleService.loadSTTModel(modelSize);

      _setState(AssistantState.listening, status: 'Listening...');

      // Start STT timeout timer
      _startSTTTimeout();

      // TODO: Start actual STT service here
    } catch (e) {
      _handleError('Failed to start listening: $e');
    }
  }

  /// Start the STT timeout timer
  void _startSTTTimeout() {
    _sttTimeoutTimer?.cancel();

    final int timeoutSeconds = _settingsProvider.sttTimeoutSeconds;
    _sttTimeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
      _logger.w('STT timeout after $timeoutSeconds seconds');
      _handleSTTTimeout();
    });
  }

  /// Cancel STT timeout timer
  void _cancelSTTTimeout() {
    _sttTimeoutTimer?.cancel();
    _sttTimeoutTimer = null;
  }

  /// Handle STT timeout (no speech detected for N seconds)
  Future<void> _handleSTTTimeout() async {
    _logger.i('No speech detected, returning to wake word listening');

    // Unload STT model
    if (!_settingsProvider.keepModelsLoaded) {
      await _modelLifecycleService.unloadSTTModel();
    }

    _setState(
      AssistantState.wakeWordActive,
      status: 'Say "Computer" to begin',
    );
  }

  /// Get ModelSize enum from settings string
  ModelSize _getModelSizeFromSettings() {
    switch (_settingsProvider.sttModelSize) {
      case 'tiny':
        return ModelSize.tiny;
      case 'medium':
        return ModelSize.medium;
      case 'small':
      default:
        return ModelSize.small;
    }
  }

  // ============================================
  // Speech-to-Text Handling
  // ============================================

  /// Called when speech-to-text returns a result
  void onSpeechResult(String text) {
    _transcribedText = text;
    notifyListeners();
  }

  /// Called when speech-to-text is complete
  Future<void> onSpeechComplete(String finalText) async {
    _logger.i('Speech complete: $finalText');
    _cancelSTTTimeout();
    _transcribedText = finalText;

    // Unload STT model if setting enabled
    if (!_settingsProvider.keepModelsLoaded) {
      await _modelLifecycleService.unloadSTTModel();
    }

    if (finalText.trim().isEmpty) {
      _setState(
        AssistantState.wakeWordActive,
        status: 'Say "Computer" to begin',
      );
      return;
    }

    // Add user message to conversation
    _currentConversation = _currentConversation.addMessage(
      Message.user(finalText),
    );
    notifyListeners();

    // Send to LLM
    await _sendToLLM(finalText);
  }

  // ============================================
  // LLM Communication
  // ============================================

  /// Send message to the current LLM provider
  Future<void> _sendToLLM(String userMessage) async {
    _setState(AssistantState.thinking, status: 'Thinking...');

    final provider = _settingsProvider.defaultProvider;
    final modelConfig = _settingsProvider.getCurrentModelConfig();
    final service = _getLLMService(provider);

    // Check if service is configured
    if (!service.isConfigured) {
      _handleError('${provider.displayName} API key not configured');
      return;
    }

    // Check connectivity
    if (!_queueService.isOnline) {
      await _queueRequest(userMessage, provider, modelConfig.modelId);
      return;
    }

    try {
      final response = await service.sendMessage(
        messages: _currentConversation.messages,
        modelConfig: modelConfig,
        systemPrompt: LLMService.defaultSystemPrompt,
      );

      _addAssistantResponse(
        response.content,
        provider: provider,
        modelId: modelConfig.modelId,
        inputTokens: response.inputTokens,
        outputTokens: response.outputTokens,
      );

      // Start TTS
      await _speakResponse(response.content);
    } on LLMException catch (e) {
      if (e.isRetryable && !_queueService.isOnline) {
        await _queueRequest(userMessage, provider, modelConfig.modelId);
      } else {
        _handleError(e.message);
      }
    } catch (e) {
      _handleError('Unexpected error: $e');
    }
  }

  /// Add assistant response to conversation
  void _addAssistantResponse(
    String content, {
    required LLMProvider provider,
    required String modelId,
    int? inputTokens,
    int? outputTokens,
  }) {
    _currentConversation = _currentConversation.addMessage(
      Message.assistant(
        content,
        provider: provider,
        modelId: modelId,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      ),
    );
    notifyListeners();
  }

  /// Queue a request for later (offline)
  Future<void> _queueRequest(
    String userMessage,
    LLMProvider provider,
    String modelId,
  ) async {
    final request = QueuedRequest(
      userMessage: userMessage,
      conversationId: _currentConversation.id,
      provider: provider,
      modelId: modelId,
    );

    await _queueService.enqueue(request);

    _currentConversation = _currentConversation.addMessage(
      Message.system('Request queued - will send when online'),
    );

    _setState(
      AssistantState.idle,
      status:
          'Request queued (${_queueService.pendingRequests.length} pending)',
    );
  }

  // ============================================
  // Text-to-Speech
  // ============================================

  /// Speak the response using TTS
  Future<void> _speakResponse(String text) async {
    if (!_settingsProvider.autoPlayTts) {
      _setState(
        AssistantState.wakeWordActive,
        status: 'Say "Computer" to begin',
      );
      return;
    }

    try {
      // Load TTS model
      await _modelLifecycleService.loadTTSModel();

      _setState(AssistantState.speaking, status: 'Speaking...');
      _isSpeaking = true;
      notifyListeners();

      // TODO: Integrate with actual TTS service
      // For now, simulate speaking
      await Future.delayed(Duration(milliseconds: text.length * 50));

      _isSpeaking = false;

      // Unload TTS model if setting enabled
      if (!_settingsProvider.keepModelsLoaded) {
        await _modelLifecycleService.unloadTTSModel();
      }

      _setState(
        AssistantState.wakeWordActive,
        status: 'Say "Computer" to begin',
      );
    } catch (e) {
      _handleError('TTS error: $e');
    }
  }

  /// Stop TTS playback
  Future<void> stopSpeaking() async {
    _isSpeaking = false;

    // Unload TTS if needed
    if (!_settingsProvider.keepModelsLoaded) {
      await _modelLifecycleService.unloadTTSModel();
    }

    _setState(
      AssistantState.wakeWordActive,
      status: 'Say "Computer" to begin',
    );
  }

  // ============================================
  // Error Handling
  // ============================================

  void _handleError(String message) {
    _logger.e('Error: $message');

    _currentConversation = _currentConversation.addMessage(
      Message.error(message),
    );

    _setState(AssistantState.error, status: 'Error occurred', error: message);

    // Auto-recover after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (_state == AssistantState.error) {
        if (_isWakeWordListening) {
          _setState(
            AssistantState.wakeWordActive,
            status: 'Say "Computer" to begin',
          );
        } else {
          _setState(AssistantState.idle, status: 'Press button to start');
        }
      }
    });
  }

  // ============================================
  // Conversation Archiving
  // ============================================

  /// Archive current conversation to database
  Future<void> _archiveCurrentConversation() async {
    if (_currentConversation.messages.isEmpty) {
      _logger.d('Skipping empty conversation archive');
      return;
    }

    try {
      await _archiveService.archiveConversation(_currentConversation);
      _logger.i(
        'Archived conversation with ${_currentConversation.messages.length} messages',
      );
    } catch (e) {
      _logger.e('Failed to archive conversation: $e');
      // Don't show error to user - archiving is background operation
    }
  }

  /// Archive and close current session (called on app close or manual close)
  Future<void> closeSession() async {
    _logger.i('Closing session');

    // Cancel any active timers
    _cancelSTTTimeout();

    // Stop wake word listening
    if (_isWakeWordListening) {
      await stopWakeWordListening();
    }

    // Archive conversation
    await _archiveCurrentConversation();

    // Unload all models
    await _modelLifecycleService.unloadAllModels();

    // Reset state
    _currentConversation = Conversation();
    _transcribedText = '';
    _errorMessage = null;
    _setState(AssistantState.idle, status: 'Press button to start');
  }

  // ============================================
  // Conversation Management
  // ============================================

  /// Start a new conversation (archives current one)
  Future<void> newConversation() async {
    await _archiveCurrentConversation();
    _currentConversation = Conversation();
    _transcribedText = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Manually send a text message (for testing without voice)
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    _currentConversation = _currentConversation.addMessage(
      Message.user(text),
    );
    notifyListeners();
    await _sendToLLM(text);
  }

  // ============================================
  // Provider Switching
  // ============================================

  /// Switch to a different LLM provider
  Future<void> switchProvider(LLMProvider provider) async {
    await _settingsProvider.setDefaultProvider(provider);
    notifyListeners();
  }

  /// Validate API key for a provider
  Future<bool> validateProvider(LLMProvider provider) async {
    final service = _getLLMService(provider);
    return await service.validateApiKey();
  }

  // ============================================
  // Cleanup
  // ============================================

  @override
  void dispose() {
    _cancelSTTTimeout();
    _sttTimeoutTimer?.cancel();
    super.dispose();
  }
}
