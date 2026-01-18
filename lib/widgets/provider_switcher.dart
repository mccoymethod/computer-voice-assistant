import 'package:flutter/material.dart';

import '../models/llm_provider.dart';
import '../services/secure_storage_service.dart';
import '../theme/tricorder_theme.dart';

/// Widget for switching between configured LLM providers
class ProviderSwitcher extends StatefulWidget {
  final LLMProvider? currentProvider;
  final Function(LLMProvider)? onProviderChanged;

  const ProviderSwitcher({
    super.key,
    this.currentProvider,
    this.onProviderChanged,
  });

  @override
  State<ProviderSwitcher> createState() => _ProviderSwitcherState();
}

class _ProviderSwitcherState extends State<ProviderSwitcher> {
  final SecureStorageService _secureStorage = SecureStorageService();

  List<LLMProvider> _configuredProviders = [];
  LLMProvider? _activeProvider;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _loading = true);

    final configured = await _secureStorage.getConfiguredProviders();
    final active =
        widget.currentProvider ?? await _secureStorage.getActiveProvider();

    setState(() {
      _configuredProviders = configured;
      _activeProvider = active;
      _loading = false;
    });
  }

  Future<void> _switchProvider(LLMProvider provider) async {
    await _secureStorage.setActiveProvider(provider);

    setState(() {
      _activeProvider = provider;
    });

    widget.onProviderChanged?.call(provider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${_getProviderName(provider)}'),
          backgroundColor: TricorderTheme.accentMint,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_configuredProviders.isEmpty) {
      return TricorderTheme.panel(
        accentColor: TricorderTheme.statusIdle,
        padding: const EdgeInsets.all(TricorderTheme.spacingM),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: TricorderTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: TricorderTheme.spacingM),
            const Expanded(
              child: Text(
                'No providers configured',
                style: TextStyle(
                  color: TricorderTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/settings');
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      );
    }

    if (_configuredProviders.length == 1) {
      // Only one provider - show as status
      return TricorderTheme.panel(
        accentColor: TricorderTheme.accentMint,
        padding: const EdgeInsets.all(TricorderTheme.spacingM),
        child: Row(
          children: [
            _getProviderIcon(_configuredProviders.first),
            const SizedBox(width: TricorderTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getProviderName(_configuredProviders.first),
                    style: const TextStyle(
                      color: TricorderTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Active',
                    style: TextStyle(
                      color: TricorderTheme.accentMint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/settings');
              },
              child: const Text('ADD MORE'),
            ),
          ],
        ),
      );
    }

    // Multiple providers - show switcher
    return TricorderTheme.panel(
      accentColor: TricorderTheme.primaryAmber,
      padding: const EdgeInsets.all(TricorderTheme.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: TricorderTheme.spacingS,
              bottom: TricorderTheme.spacingS,
            ),
            child: Text(
              'AI PROVIDER',
              style: TextStyle(
                color: TricorderTheme.textSecondary,
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              ..._configuredProviders.map((provider) {
                final isActive = provider == _activeProvider;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _switchProvider(provider),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: TricorderTheme.spacingXS,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: TricorderTheme.spacingS,
                        vertical: TricorderTheme.spacingM,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? TricorderTheme.primaryAmber.withOpacity(0.2)
                            : Colors.transparent,
                        border: Border.all(
                          color: isActive
                              ? TricorderTheme.primaryAmber
                              : TricorderTheme.borderColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(
                          TricorderTheme.radiusSmall,
                        ),
                      ),
                      child: Column(
                        children: [
                          _getProviderIcon(provider, isActive: isActive),
                          const SizedBox(height: TricorderTheme.spacingXS),
                          Text(
                            _getProviderShortName(provider),
                            style: TextStyle(
                              color: isActive
                                  ? TricorderTheme.primaryAmber
                                  : TricorderTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isActive) ...[
                            const SizedBox(height: TricorderTheme.spacingXS),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: TricorderTheme.primaryAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getProviderIcon(LLMProvider provider, {bool isActive = false}) {
    final IconData icon;
    final Color color;

    switch (provider) {
      case LLMProvider.claude:
        icon = Icons.psychology_outlined;
        color = isActive
            ? TricorderTheme.primaryAmber
            : TricorderTheme.textSecondary;
        break;
      case LLMProvider.openai:
        icon = Icons.smart_toy_outlined;
        color = isActive
            ? TricorderTheme.primaryAmber
            : TricorderTheme.textSecondary;
        break;
      case LLMProvider.gemini:
        icon = Icons.auto_awesome_outlined;
        color = isActive
            ? TricorderTheme.primaryAmber
            : TricorderTheme.textSecondary;
        break;
    }

    return Icon(icon, color: color, size: 24);
  }

  String _getProviderName(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.claude:
        return 'Anthropic Claude';
      case LLMProvider.openai:
        return 'OpenAI GPT';
      case LLMProvider.gemini:
        return 'Google Gemini';
    }
  }

  String _getProviderShortName(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.claude:
        return 'CLAUDE';
      case LLMProvider.openai:
        return 'GPT';
      case LLMProvider.gemini:
        return 'GEMINI';
    }
  }
}
