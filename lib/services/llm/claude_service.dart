import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../models/conversation.dart';
import '../../models/llm_provider.dart';
import 'llm_service.dart';

/// Claude (Anthropic) API implementation
/// 
/// Implements the Messages API: https://docs.anthropic.com/claude/reference/messages_post
class ClaudeService extends LLMService with LLMHttpMixin {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiVersion = '2023-06-01';
  
  final Logger _logger = Logger();
  final String? _apiKey;

  ClaudeService({String? apiKey}) 
      : _apiKey = apiKey ?? dotenv.env['ANTHROPIC_API_KEY'];

  @override
  LLMProvider get provider => LLMProvider.claude;

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
      // Convert messages to Claude format
      final claudeMessages = _convertMessages(messages);
      
      // Build request body
      final body = {
        'model': modelConfig.modelId,
        'max_tokens': modelConfig.maxTokens,
        'messages': claudeMessages,
        if (systemPrompt != null) 'system': systemPrompt,
      };

      _logger.d('Sending request to Claude: ${modelConfig.modelId}');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode(body),
      );

      stopwatch.stop();

      if (response.statusCode != 200) {
        throw parseHttpError(response.statusCode, response.body, provider);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Extract response content
      final content = json['content'] as List;
      final textContent = content
          .where((c) => c['type'] == 'text')
          .map((c) => c['text'] as String)
          .join('\n');

      // Extract usage
      final usage = json['usage'] as Map<String, dynamic>;
      
      return LLMResponse(
        content: textContent,
        inputTokens: usage['input_tokens'] as int,
        outputTokens: usage['output_tokens'] as int,
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
      // Send a minimal request to validate the key
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-20250514',
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
        }),
      );

      // 200 = valid, 401 = invalid key
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('API key validation failed: $e');
      return false;
    }
  }

  /// Convert our Message format to Claude's format
  List<Map<String, dynamic>> _convertMessages(List<Message> messages) {
    return messages
        .where((m) => m.role == MessageRole.user || m.role == MessageRole.assistant)
        .map((m) => {
          'role': m.role == MessageRole.user ? 'user' : 'assistant',
          'content': m.content,
        })
        .toList();
  }
}
