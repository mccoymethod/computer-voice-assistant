import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../models/llm_provider.dart';

/// Secure storage service for API keys and sensitive data
///
/// Uses platform-specific secure storage:
/// - Android: EncryptedSharedPreferences with AES encryption
/// - iOS: Keychain
///
/// All API keys are stored encrypted and never exposed in plain text.
class SecureStorageService {
  static const String _apiKeyPrefix = 'api_key_';
  static const String _lastTestedPrefix = 'last_tested_';
  static const String _activeProviderKey = 'active_provider';

  final FlutterSecureStorage _storage;
  final Logger _logger = Logger();

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  // ============================================
  // API Key Storage
  // ============================================

  /// Store API key for a provider
  Future<void> setApiKey(LLMProvider provider, String apiKey) async {
    try {
      await _storage.write(
        key: '$_apiKeyPrefix${provider.name}',
        value: apiKey,
      );
      _logger.i('API key stored for ${provider.name}');
    } catch (e) {
      _logger.e('Failed to store API key for ${provider.name}: $e');
      rethrow;
    }
  }

  /// Retrieve API key for a provider
  Future<String?> getApiKey(LLMProvider provider) async {
    try {
      return await _storage.read(key: '$_apiKeyPrefix${provider.name}');
    } catch (e) {
      _logger.e('Failed to read API key for ${provider.name}: $e');
      return null;
    }
  }

  /// Delete API key for a provider
  Future<void> deleteApiKey(LLMProvider provider) async {
    try {
      await _storage.delete(key: '$_apiKeyPrefix${provider.name}');
      await _storage.delete(key: '$_lastTestedPrefix${provider.name}');
      _logger.i('API key deleted for ${provider.name}');
    } catch (e) {
      _logger.e('Failed to delete API key for ${provider.name}: $e');
      rethrow;
    }
  }

  /// Check if API key exists for a provider
  Future<bool> hasApiKey(LLMProvider provider) async {
    final key = await getApiKey(provider);
    return key != null && key.isNotEmpty;
  }

  /// Get all providers with stored API keys
  Future<List<LLMProvider>> getConfiguredProviders() async {
    final List<LLMProvider> configured = [];

    for (final provider in LLMProvider.values) {
      if (await hasApiKey(provider)) {
        configured.add(provider);
      }
    }

    return configured;
  }

  // ============================================
  // API Key Testing Metadata
  // ============================================

  /// Store timestamp of last successful API key test
  Future<void> setLastTested(LLMProvider provider, DateTime timestamp) async {
    try {
      await _storage.write(
        key: '$_lastTestedPrefix${provider.name}',
        value: timestamp.toIso8601String(),
      );
    } catch (e) {
      _logger.e('Failed to store last tested for ${provider.name}: $e');
    }
  }

  /// Get timestamp of last successful API key test
  Future<DateTime?> getLastTested(LLMProvider provider) async {
    try {
      final value = await _storage.read(
        key: '$_lastTestedPrefix${provider.name}',
      );

      if (value != null) {
        return DateTime.parse(value);
      }
    } catch (e) {
      _logger.e('Failed to read last tested for ${provider.name}: $e');
    }

    return null;
  }

  // ============================================
  // Active Provider
  // ============================================

  /// Store the currently active provider
  Future<void> setActiveProvider(LLMProvider provider) async {
    try {
      await _storage.write(
        key: _activeProviderKey,
        value: provider.name,
      );
    } catch (e) {
      _logger.e('Failed to store active provider: $e');
    }
  }

  /// Get the currently active provider
  Future<LLMProvider?> getActiveProvider() async {
    try {
      final value = await _storage.read(key: _activeProviderKey);

      if (value != null) {
        return LLMProvider.values.firstWhere(
          (p) => p.name == value,
          orElse: () => LLMProvider.claude,
        );
      }
    } catch (e) {
      _logger.e('Failed to read active provider: $e');
    }

    return null;
  }

  // ============================================
  // Validation Helpers
  // ============================================

  /// Validate API key format for a provider
  bool validateApiKeyFormat(LLMProvider provider, String apiKey) {
    if (apiKey.trim().isEmpty) return false;

    switch (provider) {
      case LLMProvider.claude:
        // Claude keys: sk-ant-api03-... (API keys) or sk-ant-sid01-... (session IDs)
        return apiKey.startsWith('sk-ant-');

      case LLMProvider.openai:
        // OpenAI keys: sk-...
        return apiKey.startsWith('sk-') && apiKey.length > 20;

      case LLMProvider.gemini:
        // Gemini keys: AIza... (39 characters)
        return apiKey.startsWith('AIza') && apiKey.length == 39;
    }
  }

  /// Auto-detect provider from API key format
  LLMProvider? detectProviderFromKey(String apiKey) {
    if (apiKey.startsWith('sk-ant-')) {
      return LLMProvider.claude;
    } else if (apiKey.startsWith('sk-')) {
      return LLMProvider.openai;
    } else if (apiKey.startsWith('AIza') && apiKey.length == 39) {
      return LLMProvider.gemini;
    }

    return null;
  }

  // ============================================
  // Cleanup
  // ============================================

  /// Delete all stored API keys (use with caution!)
  Future<void> deleteAllApiKeys() async {
    try {
      for (final provider in LLMProvider.values) {
        await deleteApiKey(provider);
      }

      await _storage.delete(key: _activeProviderKey);
      _logger.w('All API keys deleted');
    } catch (e) {
      _logger.e('Failed to delete all API keys: $e');
      rethrow;
    }
  }

  /// Get storage statistics (for debug/settings screen)
  Future<Map<String, dynamic>> getStorageStats() async {
    final configured = await getConfiguredProviders();
    final active = await getActiveProvider();

    final Map<String, DateTime?> lastTested = {};
    for (final provider in configured) {
      lastTested[provider.name] = await getLastTested(provider);
    }

    return {
      'configured_providers': configured.map((p) => p.name).toList(),
      'active_provider': active?.name,
      'last_tested': lastTested,
    };
  }
}
