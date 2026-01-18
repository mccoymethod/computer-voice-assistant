import 'package:flutter/material.dart';

import '../../models/llm_provider.dart';
import '../../theme/tricorder_theme.dart';
import 'api_key_input_screen.dart';

/// Provider selection screen - choose which LLM to use
class ProviderSelectionScreen extends StatefulWidget {
  const ProviderSelectionScreen({super.key});

  @override
  State<ProviderSelectionScreen> createState() =>
      _ProviderSelectionScreenState();
}

class _ProviderSelectionScreenState extends State<ProviderSelectionScreen> {
  LLMProvider? _selectedProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SELECT PROVIDER'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TricorderTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Choose your AI provider',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: TricorderTheme.spacingM),

              Text(
                'You\'ll need an API key from one of these providers. Don\'t worry, we\'ll help you get one!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TricorderTheme.textSecondary,
                    ),
              ),

              const SizedBox(height: TricorderTheme.spacingXL),

              // Provider cards
              Expanded(
                child: ListView(
                  children: [
                    _buildProviderCard(
                      provider: LLMProvider.claude,
                      title: 'Anthropic Claude',
                      description:
                          'Most capable model. Great for complex tasks and reasoning.',
                      pricing: '\$15/million tokens',
                      recommended: true,
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),
                    _buildProviderCard(
                      provider: LLMProvider.openai,
                      title: 'OpenAI GPT',
                      description:
                          'Popular and versatile. Good balance of speed and quality.',
                      pricing: '\$10/million tokens',
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),
                    _buildProviderCard(
                      provider: LLMProvider.gemini,
                      title: 'Google Gemini',
                      description:
                          'Free tier available. Good for getting started.',
                      pricing: 'Free tier + paid options',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TricorderTheme.spacingL),

              // Continue button
              ElevatedButton(
                onPressed: _selectedProvider == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ApiKeyInputScreen(
                              provider: _selectedProvider!,
                            ),
                          ),
                        );
                      },
                child: const Text('CONTINUE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard({
    required LLMProvider provider,
    required String title,
    required String description,
    required String pricing,
    bool recommended = false,
  }) {
    final bool isSelected = _selectedProvider == provider;

    return GestureDetector(
      onTap: () => setState(() => _selectedProvider = provider),
      child: TricorderTheme.panel(
        accentColor: isSelected
            ? TricorderTheme.primaryAmber
            : TricorderTheme.borderColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? TricorderTheme.primaryAmber
                          : TricorderTheme.borderColor,
                      width: 2,
                    ),
                    color: isSelected
                        ? TricorderTheme.primaryAmber
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: TricorderTheme.backgroundDark,
                        )
                      : null,
                ),

                const SizedBox(width: TricorderTheme.spacingM),

                // Title
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? TricorderTheme.primaryAmber
                          : TricorderTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Recommended badge
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TricorderTheme.spacingS,
                      vertical: TricorderTheme.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: TricorderTheme.accentMint.withOpacity(0.2),
                      border: Border.all(
                        color: TricorderTheme.accentMint,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(
                        TricorderTheme.radiusSmall,
                      ),
                    ),
                    child: const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        color: TricorderTheme.accentMint,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: TricorderTheme.spacingM),

            // Description
            Text(
              description,
              style: const TextStyle(
                color: TricorderTheme.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: TricorderTheme.spacingS),

            // Pricing
            Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  size: 16,
                  color: TricorderTheme.textTertiary,
                ),
                const SizedBox(width: TricorderTheme.spacingXS),
                Text(
                  pricing,
                  style: const TextStyle(
                    color: TricorderTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
