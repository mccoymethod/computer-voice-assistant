/// Supported LLM providers
/// 
/// Each provider has different strengths:
/// - Claude: Best for complex reasoning, coding, nuanced conversations
/// - OpenAI: Good all-around, wide model selection
/// - Gemini: Fast responses, generous free tier
enum LLMProvider {
  claude,
  openai,
  gemini,
}

/// Extension methods for LLMProvider enum
extension LLMProviderExtension on LLMProvider {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case LLMProvider.claude:
        return 'Claude (Anthropic)';
      case LLMProvider.openai:
        return 'GPT (OpenAI)';
      case LLMProvider.gemini:
        return 'Gemini (Google)';
    }
  }

  /// Short name for logging
  String get shortName {
    switch (this) {
      case LLMProvider.claude:
        return 'Claude';
      case LLMProvider.openai:
        return 'GPT';
      case LLMProvider.gemini:
        return 'Gemini';
    }
  }

  /// Icon for UI
  String get iconAsset {
    switch (this) {
      case LLMProvider.claude:
        return 'assets/icons/anthropic.png';
      case LLMProvider.openai:
        return 'assets/icons/openai.png';
      case LLMProvider.gemini:
        return 'assets/icons/google.png';
    }
  }

  /// Whether this provider has a free tier
  bool get hasFreeTier {
    switch (this) {
      case LLMProvider.claude:
        return false; // Claude API requires payment
      case LLMProvider.openai:
        return false; // OpenAI API requires payment
      case LLMProvider.gemini:
        return true;  // Gemini has generous free tier
    }
  }

  /// Environment variable key for API key
  String get envKeyName {
    switch (this) {
      case LLMProvider.claude:
        return 'ANTHROPIC_API_KEY';
      case LLMProvider.openai:
        return 'OPENAI_API_KEY';
      case LLMProvider.gemini:
        return 'GOOGLE_AI_API_KEY';
    }
  }
}

/// Configuration for a specific LLM model
class LLMModelConfig {
  final LLMProvider provider;
  final String modelId;
  final String displayName;
  final int maxTokens;
  final double costPer1kInputTokens;  // USD
  final double costPer1kOutputTokens; // USD
  final bool isDefault;

  const LLMModelConfig({
    required this.provider,
    required this.modelId,
    required this.displayName,
    this.maxTokens = 4096,
    this.costPer1kInputTokens = 0.0,
    this.costPer1kOutputTokens = 0.0,
    this.isDefault = false,
  });
}

/// Available model configurations
/// 
/// Prices as of early 2025 - verify current pricing before production use
class LLMModels {
  // Claude models
  static const claudeSonnet = LLMModelConfig(
    provider: LLMProvider.claude,
    modelId: 'claude-sonnet-4-20250514',
    displayName: 'Claude Sonnet 4',
    maxTokens: 8192,
    costPer1kInputTokens: 0.003,
    costPer1kOutputTokens: 0.015,
    isDefault: true,
  );

  static const claudeHaiku = LLMModelConfig(
    provider: LLMProvider.claude,
    modelId: 'claude-haiku-4-20250514',
    displayName: 'Claude Haiku 4',
    maxTokens: 8192,
    costPer1kInputTokens: 0.0008,
    costPer1kOutputTokens: 0.004,
  );

  // OpenAI models
  static const gpt4oMini = LLMModelConfig(
    provider: LLMProvider.openai,
    modelId: 'gpt-4o-mini',
    displayName: 'GPT-4o Mini',
    maxTokens: 4096,
    costPer1kInputTokens: 0.00015,
    costPer1kOutputTokens: 0.0006,
    isDefault: true,
  );

  static const gpt4o = LLMModelConfig(
    provider: LLMProvider.openai,
    modelId: 'gpt-4o',
    displayName: 'GPT-4o',
    maxTokens: 4096,
    costPer1kInputTokens: 0.005,
    costPer1kOutputTokens: 0.015,
  );

  // Gemini models
  static const geminiFlash = LLMModelConfig(
    provider: LLMProvider.gemini,
    modelId: 'gemini-2.0-flash',
    displayName: 'Gemini 2.0 Flash',
    maxTokens: 8192,
    costPer1kInputTokens: 0.0,  // Free tier
    costPer1kOutputTokens: 0.0,
    isDefault: true,
  );

  static const geminiPro = LLMModelConfig(
    provider: LLMProvider.gemini,
    modelId: 'gemini-1.5-pro',
    displayName: 'Gemini 1.5 Pro',
    maxTokens: 8192,
    costPer1kInputTokens: 0.00125,
    costPer1kOutputTokens: 0.005,
  );

  /// Get all models for a provider
  static List<LLMModelConfig> getModelsForProvider(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.claude:
        return [claudeSonnet, claudeHaiku];
      case LLMProvider.openai:
        return [gpt4oMini, gpt4o];
      case LLMProvider.gemini:
        return [geminiFlash, geminiPro];
    }
  }

  /// Get default model for a provider
  static LLMModelConfig getDefaultModel(LLMProvider provider) {
    return getModelsForProvider(provider).firstWhere(
      (m) => m.isDefault,
      orElse: () => getModelsForProvider(provider).first,
    );
  }

  /// Get all available models
  static List<LLMModelConfig> get allModels => [
    claudeSonnet,
    claudeHaiku,
    gpt4oMini,
    gpt4o,
    geminiFlash,
    geminiPro,
  ];
}
