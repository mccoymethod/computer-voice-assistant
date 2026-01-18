import '../models/conversation.dart';
import '../models/llm_provider.dart';

/// Response from an LLM API call
class LLMResponse {
  final String content;
  final int inputTokens;
  final int outputTokens;
  final String modelId;
  final LLMProvider provider;
  final Duration latency;

  const LLMResponse({
    required this.content,
    required this.inputTokens,
    required this.outputTokens,
    required this.modelId,
    required this.provider,
    required this.latency,
  });

  /// Estimated cost in USD
  double estimateCost(LLMModelConfig config) {
    return (inputTokens / 1000 * config.costPer1kInputTokens) +
           (outputTokens / 1000 * config.costPer1kOutputTokens);
  }
}

/// Exception thrown by LLM services
class LLMException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRetryable;
  final LLMProvider provider;

  const LLMException({
    required this.message,
    this.statusCode,
    this.isRetryable = false,
    required this.provider,
  });

  @override
  String toString() => 'LLMException(${provider.shortName}): $message';

  /// Common error types
  factory LLMException.networkError(LLMProvider provider) => LLMException(
    message: 'Network error - please check your connection',
    isRetryable: true,
    provider: provider,
  );

  factory LLMException.unauthorized(LLMProvider provider) => LLMException(
    message: 'Invalid API key - please check your ${provider.displayName} API key',
    statusCode: 401,
    isRetryable: false,
    provider: provider,
  );

  factory LLMException.rateLimited(LLMProvider provider) => LLMException(
    message: 'Rate limited - please wait a moment',
    statusCode: 429,
    isRetryable: true,
    provider: provider,
  );

  factory LLMException.serverError(LLMProvider provider, int statusCode) => LLMException(
    message: 'Server error ($statusCode) - please try again',
    statusCode: statusCode,
    isRetryable: true,
    provider: provider,
  );
}

/// Abstract interface for LLM services
/// 
/// Each LLM provider (Claude, OpenAI, Gemini) implements this interface.
/// This allows easy swapping between providers and consistent error handling.
abstract class LLMService {
  /// The provider this service implements
  LLMProvider get provider;

  /// Whether the service is properly configured (has API key)
  bool get isConfigured;

  /// Send a message and get a response
  /// 
  /// [messages] - The conversation history
  /// [modelConfig] - Which model to use
  /// [systemPrompt] - Optional system prompt to guide behavior
  Future<LLMResponse> sendMessage({
    required List<Message> messages,
    required LLMModelConfig modelConfig,
    String? systemPrompt,
  });

  /// Validate the API key by making a minimal request
  Future<bool> validateApiKey();

  /// Default system prompt for voice assistant context
  static const String defaultSystemPrompt = '''
You are a helpful voice assistant called "Computer", inspired by the Star Trek ship's computer. 

Key behaviors:
- Keep responses concise and conversational - they will be spoken aloud
- Avoid markdown formatting, bullet points, or numbered lists unless specifically asked
- Use natural speech patterns
- Be helpful, accurate, and friendly
- If you don't know something, say so clearly
- For complex topics, offer to explain in more detail if the user wants

Remember: Your responses will be converted to speech, so write as you would speak.
''';
}

/// Utility mixin for common HTTP handling
mixin LLMHttpMixin {
  /// Parse common HTTP errors
  LLMException parseHttpError(int statusCode, String body, LLMProvider provider) {
    switch (statusCode) {
      case 401:
        return LLMException.unauthorized(provider);
      case 429:
        return LLMException.rateLimited(provider);
      case >= 500 && < 600:
        return LLMException.serverError(provider, statusCode);
      default:
        return LLMException(
          message: 'Request failed: $body',
          statusCode: statusCode,
          isRetryable: statusCode >= 500,
          provider: provider,
        );
    }
  }
}
