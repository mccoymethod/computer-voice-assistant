import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../models/conversation.dart';
import '../../models/llm_provider.dart';
import 'llm_service.dart';

/// Google Gemini API implementation
/// 
/// Implements the Generative Language API: https://ai.google.dev/api/rest
class GeminiService extends LLMService with LLMHttpMixin {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  
  final Logger _logger = Logger();
  final String? _apiKey;

  GeminiService({String? apiKey}) 
      : _apiKey = apiKey ?? dotenv.env['GOOGLE_AI_API_KEY'];

  @override
  LLMProvider get provider => LLMProvider.gemini;

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
      // Build the URL with model and API key
      final url = '$_baseUrl/${modelConfig.modelId}:generateContent?key=$_apiKey';
      
      // Convert messages to Gemini format
      final geminiContents = _convertMessages(messages);
      
      // Build request body
      final body = {
        'contents': geminiContents,
        if (systemPrompt != null)
          'systemInstruction': {
            'parts': [{'text': systemPrompt}]
          },
        'generationConfig': {
          'maxOutputTokens': modelConfig.maxTokens,
        },
      };

      _logger.d('Sending request to Gemini: ${modelConfig.modelId}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      stopwatch.stop();

      if (response.statusCode != 200) {
        throw parseHttpError(response.statusCode, response.body, provider);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Check for errors in response
      if (json.containsKey('error')) {
        final error = json['error'] as Map<String, dynamic>;
        throw LLMException(
          message: error['message'] as String? ?? 'Unknown error',
          statusCode: error['code'] as int?,
          provider: provider,
        );
      }

      // Extract response content
      final candidates = json['candidates'] as List;
      if (candidates.isEmpty) {
        throw LLMException(
          message: 'No response generated',
          provider: provider,
        );
      }

      final content = candidates.first['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List;
      final text = parts
          .where((p) => p['text'] != null)
          .map((p) => p['text'] as String)
          .join('\n');

      // Extract usage (Gemini provides this in usageMetadata)
      final usageMetadata = json['usageMetadata'] as Map<String, dynamic>?;
      final inputTokens = usageMetadata?['promptTokenCount'] as int? ?? 0;
      final outputTokens = usageMetadata?['candidatesTokenCount'] as int? ?? 0;
      
      return LLMResponse(
        content: text,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
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
      // List models to validate key
      final response = await http.get(
        Uri.parse('$_baseUrl?key=$_apiKey'),
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('API key validation failed: $e');
      return false;
    }
  }

  /// Convert our Message format to Gemini's format
  List<Map<String, dynamic>> _convertMessages(List<Message> messages) {
    return messages
        .where((m) => m.role == MessageRole.user || m.role == MessageRole.assistant)
        .map((m) => {
          'role': m.role == MessageRole.user ? 'user' : 'model',
          'parts': [
            {'text': m.content}
          ],
        })
        .toList();
  }
}
