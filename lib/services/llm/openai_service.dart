import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../models/conversation.dart';
import '../../models/llm_provider.dart';
import 'llm_service.dart';

/// OpenAI API implementation
/// 
/// Implements the Chat Completions API: https://platform.openai.com/docs/api-reference/chat
class OpenAIService extends LLMService with LLMHttpMixin {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  final Logger _logger = Logger();
  final String? _apiKey;

  OpenAIService({String? apiKey}) 
      : _apiKey = apiKey ?? dotenv.env['OPENAI_API_KEY'];

  @override
  LLMProvider get provider => LLMProvider.openai;

  @override
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  Future<LLMResponse> sendMessage({
    required List<Message> messages,
    required LLMModelConfig modelConfig,
    String? systemPrompt,
  }) async {
    if (!isConfigured) {
      throw LLMException.unauthorized(provider);
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Convert messages to OpenAI format
      final openaiMessages = _convertMessages(messages, systemPrompt);
      
      // Build request body
      final body = {
        'model': modelConfig.modelId,
        'max_tokens': modelConfig.maxTokens,
        'messages': openaiMessages,
      };

      _logger.d('Sending request to OpenAI: ${modelConfig.modelId}');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(body),
      );

      stopwatch.stop();

      if (response.statusCode != 200) {
        throw parseHttpError(response.statusCode, response.body, provider);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Extract response content
      final choices = json['choices'] as List;
      final content = choices.first['message']['content'] as String;

      // Extract usage
      final usage = json['usage'] as Map<String, dynamic>;
      
      return LLMResponse(
        content: content,
        inputTokens: usage['prompt_tokens'] as int,
        outputTokens: usage['completion_tokens'] as int,
        modelId: modelConfig.modelId,
        provider: provider,
        latency: stopwatch.elapsed,
      );

    } on http.ClientException catch (e) {
      throw LLMException(
        message: 'Network error: ${e.message}',
        isRetryable: true,
        provider: provider,
      );
    } catch (e) {
      if (e is LLMException) rethrow;
      throw LLMException(
        message: 'Unexpected error: $e',
        isRetryable: false,
        provider: provider,
      );
    }
  }

  @override
  Future<bool> validateApiKey() async {
    if (!isConfigured) return false;

    try {
      // List models endpoint is cheaper than a completion
      final response = await http.get(
        Uri.parse('https://api.openai.com/v1/models'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('API key validation failed: $e');
      return false;
    }
  }

  /// Convert our Message format to OpenAI's format
  List<Map<String, dynamic>> _convertMessages(
    List<Message> messages, 
    String? systemPrompt,
  ) {
    final result = <Map<String, dynamic>>[];
    
    // Add system prompt if provided
    if (systemPrompt != null) {
      result.add({
        'role': 'system',
        'content': systemPrompt,
      });
    }

    // Add conversation messages
    for (final m in messages) {
      if (m.role == MessageRole.user || m.role == MessageRole.assistant) {
        result.add({
          'role': m.role == MessageRole.user ? 'user' : 'assistant',
          'content': m.content,
        });
      }
    }

    return result;
  }
}
