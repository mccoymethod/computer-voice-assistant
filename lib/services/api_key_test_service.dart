import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../models/llm_provider.dart';

/// Service for testing API keys with minimal API calls
class ApiKeyTestService {
  final Logger _logger = Logger();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Test an API key with a minimal request
  Future<ApiKeyTestResult> testApiKey(
    LLMProvider provider,
    String apiKey,
  ) async {
    _logger.i('Testing API key for ${provider.name}');

    try {
      switch (provider) {
        case LLMProvider.claude:
          return await _testClaudeKey(apiKey);
        case LLMProvider.openai:
          return await _testOpenAIKey(apiKey);
        case LLMProvider.gemini:
          return await _testGeminiKey(apiKey);
      }
    } catch (e) {
      _logger.e('API key test failed: $e');
      return ApiKeyTestResult.failure(
        errorMessage: 'Network error: ${e.toString()}',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  Future<ApiKeyTestResult> _testClaudeKey(String apiKey) async {
    try {
      final response = await _dio.post(
        'https://api.anthropic.com/v1/messages',
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        ),
        data: {
          'model': 'claude-3-haiku-20240307', // Cheapest model
          'max_tokens': 1, // Minimal tokens
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
        },
      );

      if (response.statusCode == 200) {
        return ApiKeyTestResult.success();
      } else {
        return ApiKeyTestResult.failure(
          errorMessage: 'Unexpected response: ${response.statusCode}',
          errorCode: 'HTTP_${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, LLMProvider.claude);
    }
  }

  Future<ApiKeyTestResult> _testOpenAIKey(String apiKey) async {
    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-3.5-turbo', // Cheapest model
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
          'max_tokens': 1, // Minimal tokens
        },
      );

      if (response.statusCode == 200) {
        return ApiKeyTestResult.success();
      } else {
        return ApiKeyTestResult.failure(
          errorMessage: 'Unexpected response: ${response.statusCode}',
          errorCode: 'HTTP_${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, LLMProvider.openai);
    }
  }

  Future<ApiKeyTestResult> _testGeminiKey(String apiKey) async {
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
        queryParameters: {'key': apiKey},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          'contents': [
            {
              'parts': [
                {'text': 'Hi'}
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 1, // Minimal tokens
          },
        },
      );

      if (response.statusCode == 200) {
        return ApiKeyTestResult.success();
      } else {
        return ApiKeyTestResult.failure(
          errorMessage: 'Unexpected response: ${response.statusCode}',
          errorCode: 'HTTP_${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, LLMProvider.gemini);
    }
  }

  ApiKeyTestResult _handleDioError(DioException e, LLMProvider provider) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    _logger.e('DioException: $statusCode - $responseData');

    // Handle common error codes
    if (statusCode == 401) {
      return ApiKeyTestResult.failure(
        errorMessage: 'Invalid API key. Please check your key and try again.',
        errorCode: 'INVALID_KEY',
      );
    } else if (statusCode == 403) {
      return ApiKeyTestResult.failure(
        errorMessage:
            'Access forbidden. Your API key may not have the required permissions.',
        errorCode: 'FORBIDDEN',
      );
    } else if (statusCode == 429) {
      return ApiKeyTestResult.failure(
        errorMessage:
            'Rate limit exceeded. Please wait a moment and try again.',
        errorCode: 'RATE_LIMIT',
      );
    } else if (statusCode == 500 || statusCode == 503) {
      return ApiKeyTestResult.failure(
        errorMessage:
            '${provider.name} servers are experiencing issues. Please try again later.',
        errorCode: 'SERVER_ERROR',
      );
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return ApiKeyTestResult.failure(
        errorMessage:
            'Connection timeout. Please check your internet connection.',
        errorCode: 'TIMEOUT',
      );
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return ApiKeyTestResult.failure(
        errorMessage: 'Server response timeout. Please try again.',
        errorCode: 'TIMEOUT',
      );
    } else {
      return ApiKeyTestResult.failure(
        errorMessage: responseData?.toString() ?? 'Unknown error occurred',
        errorCode: 'UNKNOWN',
      );
    }
  }
}

/// Result of an API key test
class ApiKeyTestResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  final DateTime testedAt;

  ApiKeyTestResult._({
    required this.success,
    this.errorMessage,
    this.errorCode,
    DateTime? testedAt,
  }) : testedAt = testedAt ?? DateTime.now();

  factory ApiKeyTestResult.success() {
    return ApiKeyTestResult._(success: true);
  }

  factory ApiKeyTestResult.failure({
    required String errorMessage,
    required String errorCode,
  }) {
    return ApiKeyTestResult._(
      success: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }

  bool get isInvalidKey => errorCode == 'INVALID_KEY';
  bool get isRateLimit => errorCode == 'RATE_LIMIT';
  bool get isNetworkError =>
      errorCode == 'NETWORK_ERROR' || errorCode == 'TIMEOUT';
  bool get isServerError => errorCode == 'SERVER_ERROR';
}
