import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

import '../models/llm_provider.dart';

/// Manages user preferences and settings
///
/// Settings are persisted using Hive for fast access.
class SettingsProvider extends ChangeNotifier {
  static const String _boxName = 'settings';

  final Logger _logger = Logger();
  Box? _box;
  bool _isInitialized = false;

  // ============================================
  // Settings with defaults
  // ============================================

  /// Theme mode
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  /// Default LLM provider
  LLMProvider _defaultProvider = LLMProvider.claude;
  LLMProvider get defaultProvider => _defaultProvider;

  /// Default model for each provider
  final Map<LLMProvider, String> _defaultModels = {
    LLMProvider.claude: LLMModels.claudeSonnet.modelId,
    LLMProvider.openai: LLMModels.gpt4oMini.modelId,
    LLMProvider.gemini: LLMModels.geminiFlash.modelId,
  };
  String getDefaultModel(LLMProvider provider) =>
      _defaultModels[provider] ?? LLMModels.getDefaultModel(provider).modelId;

  /// Wake word sensitivity (0.0 - 1.0)
  double _wakeWordSensitivity = 0.5;
  double get wakeWordSensitivity => _wakeWordSensitivity;

  /// STT model size (tiny, small, medium)
  String _sttModelSize = 'small';
  String get sttModelSize => _sttModelSize;

  /// TTS voice name
  String _ttsVoice = 'en_US-amy-medium';
  String get ttsVoice => _ttsVoice;

  /// TTS speaking rate (0.5 - 2.0)
  double _ttsSpeakingRate = 1.0;
  double get ttsSpeakingRate => _ttsSpeakingRate;

  /// Whether to show conversation history
  bool _showHistory = true;
  bool get showHistory => _showHistory;

  /// Auto-play TTS responses
  bool _autoPlayTts = true;
  bool get autoPlayTts => _autoPlayTts;

  /// Keep models loaded in memory (vs unload when not in use)
  bool _keepModelsLoaded = false;
  bool get keepModelsLoaded => _keepModelsLoaded;

  /// STT listening timeout in seconds
  int _sttTimeoutSeconds = 30;
  int get sttTimeoutSeconds => _sttTimeoutSeconds;

  /// API Keys (stored securely - in production, use flutter_secure_storage)
  final Map<LLMProvider, String?> _apiKeys = {};
  String? getApiKey(LLMProvider provider) => _apiKeys[provider];
  bool hasApiKey(LLMProvider provider) =>
      _apiKeys[provider] != null && _apiKeys[provider]!.isNotEmpty;

  // ============================================
  // Initialization
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _box = await Hive.openBox(_boxName);
      _loadSettings();
      _isInitialized = true;
      _logger.i('Settings loaded');
    } catch (e) {
      _logger.e('Failed to initialize settings: $e');
    }
  }

  void _loadSettings() {
    if (_box == null) return;

    // Theme
    final themeName = _box!.get('themeMode', defaultValue: 'dark');
    _themeMode = ThemeMode.values.firstWhere(
      (t) => t.name == themeName,
      orElse: () => ThemeMode.dark,
    );

    // LLM settings
    final providerName = _box!.get('defaultProvider', defaultValue: 'claude');
    _defaultProvider = LLMProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => LLMProvider.claude,
    );

    // Load default models for each provider
    for (final provider in LLMProvider.values) {
      final key = 'defaultModel_${provider.name}';
      final modelId = _box!.get(key);
      if (modelId != null) {
        _defaultModels[provider] = modelId;
      }
    }

    // Voice settings
    _wakeWordSensitivity = _box!.get('wakeWordSensitivity', defaultValue: 0.5);
    _sttModelSize = _box!.get('sttModelSize', defaultValue: 'small');
    _ttsVoice = _box!.get('ttsVoice', defaultValue: 'en_US-amy-medium');
    _ttsSpeakingRate = _box!.get('ttsSpeakingRate', defaultValue: 1.0);

    // UI settings
    _showHistory = _box!.get('showHistory', defaultValue: true);
    _autoPlayTts = _box!.get('autoPlayTts', defaultValue: true);

    // Model management settings
    _keepModelsLoaded = _box!.get('keepModelsLoaded', defaultValue: false);
    _sttTimeoutSeconds = _box!.get('sttTimeoutSeconds', defaultValue: 30);

    // API Keys
    for (final provider in LLMProvider.values) {
      final key = 'apiKey_${provider.name}';
      _apiKeys[provider] = _box!.get(key);
    }
  }

  // ============================================
  // Setters (with persistence)
  // ============================================

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _box?.put('themeMode', mode.name);
    notifyListeners();
  }

  Future<void> setDefaultProvider(LLMProvider provider) async {
    _defaultProvider = provider;
    await _box?.put('defaultProvider', provider.name);
    notifyListeners();
  }

  Future<void> setDefaultModel(LLMProvider provider, String modelId) async {
    _defaultModels[provider] = modelId;
    await _box?.put('defaultModel_${provider.name}', modelId);
    notifyListeners();
  }

  Future<void> setWakeWordSensitivity(double sensitivity) async {
    _wakeWordSensitivity = sensitivity.clamp(0.0, 1.0);
    await _box?.put('wakeWordSensitivity', _wakeWordSensitivity);
    notifyListeners();
  }

  Future<void> setSttModelSize(String size) async {
    _sttModelSize = size;
    await _box?.put('sttModelSize', size);
    notifyListeners();
  }

  Future<void> setTtsVoice(String voice) async {
    _ttsVoice = voice;
    await _box?.put('ttsVoice', voice);
    notifyListeners();
  }

  Future<void> setTtsSpeakingRate(double rate) async {
    _ttsSpeakingRate = rate.clamp(0.5, 2.0);
    await _box?.put('ttsSpeakingRate', _ttsSpeakingRate);
    notifyListeners();
  }

  Future<void> setShowHistory(bool show) async {
    _showHistory = show;
    await _box?.put('showHistory', show);
    notifyListeners();
  }

  Future<void> setAutoPlayTts(bool autoPlay) async {
    _autoPlayTts = autoPlay;
    await _box?.put('autoPlayTts', autoPlay);
    notifyListeners();
  }

  Future<void> setKeepModelsLoaded(bool keep) async {
    _keepModelsLoaded = keep;
    await _box?.put('keepModelsLoaded', keep);
    notifyListeners();
  }

  Future<void> setSttTimeoutSeconds(int seconds) async {
    _sttTimeoutSeconds = seconds.clamp(10, 60);
    await _box?.put('sttTimeoutSeconds', _sttTimeoutSeconds);
    notifyListeners();
  }

  Future<void> setApiKey(LLMProvider provider, String? apiKey) async {
    _apiKeys[provider] = apiKey;
    await _box?.put('apiKey_${provider.name}', apiKey);
    notifyListeners();
  }

  // ============================================
  // Utility methods
  // ============================================

  /// Get configuration for the currently selected model
  LLMModelConfig getCurrentModelConfig() {
    final modelId = getDefaultModel(_defaultProvider);
    return LLMModels.allModels.firstWhere(
      (m) => m.modelId == modelId,
      orElse: () => LLMModels.getDefaultModel(_defaultProvider),
    );
  }

  /// Check if any LLM is configured
  bool get hasAnyApiKey => LLMProvider.values.any((p) => hasApiKey(p));

  /// Get list of configured providers
  List<LLMProvider> get configuredProviders =>
      LLMProvider.values.where((p) => hasApiKey(p)).toList();

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _box?.clear();
    _loadSettings(); // This will load defaults
    notifyListeners();
  }

  @override
  void dispose() {
    _box?.close();
    super.dispose();
  }
}
