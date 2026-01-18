import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/llm_provider.dart';
import '../../services/secure_storage_service.dart';
import '../../theme/tricorder_theme.dart';
import 'api_key_test_screen.dart';

/// API key input screen - enter and validate API key
class ApiKeyInputScreen extends StatefulWidget {
  final LLMProvider provider;

  const ApiKeyInputScreen({
    super.key,
    required this.provider,
  });

  @override
  State<ApiKeyInputScreen> createState() => _ApiKeyInputScreenState();
}

class _ApiKeyInputScreenState extends State<ApiKeyInputScreen> {
  final TextEditingController _controller = TextEditingController();
  final SecureStorageService _secureStorage = SecureStorageService();

  bool _isValid = false;
  bool _showPassword = false;
  String? _validationError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateApiKey(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _isValid = false;
        _validationError = null;
        return;
      }

      _isValid = _secureStorage.validateApiKeyFormat(widget.provider, value);

      if (!_isValid) {
        _validationError = _getFormatError();
      } else {
        _validationError = null;
      }
    });
  }

  String _getFormatError() {
    switch (widget.provider) {
      case LLMProvider.claude:
        return 'Claude keys start with "sk-ant-"';
      case LLMProvider.openai:
        return 'OpenAI keys start with "sk-"';
      case LLMProvider.gemini:
        return 'Gemini keys start with "AIza" (39 chars)';
    }
  }

  String _getProviderInstructions() {
    switch (widget.provider) {
      case LLMProvider.claude:
        return '''1. Go to console.anthropic.com
2. Sign in or create an account
3. Navigate to Settings → API Keys
4. Click "Create Key"
5. Copy the key and paste below''';

      case LLMProvider.openai:
        return '''1. Go to platform.openai.com
2. Sign in or create an account
3. Click your profile → View API keys
4. Click "Create new secret key"
5. Copy the key and paste below''';

      case LLMProvider.gemini:
        return '''1. Go to makersuite.google.com/app/apikey
2. Sign in with Google
3. Click "Create API key"
4. Select or create a project
5. Copy the key and paste below''';
    }
  }

  String _getProviderUrl() {
    switch (widget.provider) {
      case LLMProvider.claude:
        return 'https://console.anthropic.com/settings/keys';
      case LLMProvider.openai:
        return 'https://platform.openai.com/api-keys';
      case LLMProvider.gemini:
        return 'https://makersuite.google.com/app/apikey';
    }
  }

  Future<void> _continue() async {
    if (!_isValid) return;

    // Save the API key
    await _secureStorage.setApiKey(widget.provider, _controller.text.trim());
    await _secureStorage.setActiveProvider(widget.provider);

    if (!mounted) return;

    // Navigate to test screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ApiKeyTestScreen(
          provider: widget.provider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ENTER API KEY'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TricorderTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Provider name
              Text(
                _getProviderName(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: TricorderTheme.spacingM),

              // Instructions panel
              TricorderTheme.panel(
                accentColor: TricorderTheme.accentCyan,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: TricorderTheme.accentCyan,
                          size: 20,
                        ),
                        const SizedBox(width: TricorderTheme.spacingS),
                        Text(
                          'HOW TO GET YOUR API KEY',
                          style: TextStyle(
                            color: TricorderTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),
                    Text(
                      _getProviderInstructions(),
                      style: const TextStyle(
                        color: TricorderTheme.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TricorderTheme.spacingL),

              // Open URL button
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _getProviderUrl()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('URL copied: ${_getProviderUrl()}'),
                      backgroundColor: TricorderTheme.accentCyan,
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('COPY URL'),
              ),

              const SizedBox(height: TricorderTheme.spacingXL),

              // API Key input field
              TricorderTheme.panel(
                accentColor: _isValid
                    ? TricorderTheme.accentMint
                    : _validationError != null
                        ? TricorderTheme.statusError
                        : TricorderTheme.primaryAmber,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API KEY',
                      style: TextStyle(
                        color: TricorderTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),
                    TextField(
                      controller: _controller,
                      onChanged: _validateApiKey,
                      obscureText: !_showPassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(
                        color: TricorderTheme.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Paste your API key here',
                        hintStyle: TextStyle(
                          color: TricorderTheme.textTertiary,
                          fontFamily: 'monospace',
                        ),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: TricorderTheme.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    // Validation feedback
                    if (_controller.text.isNotEmpty) ...[
                      const SizedBox(height: TricorderTheme.spacingM),
                      Row(
                        children: [
                          Icon(
                            _isValid ? Icons.check_circle : Icons.error,
                            size: 16,
                            color: _isValid
                                ? TricorderTheme.accentMint
                                : TricorderTheme.statusError,
                          ),
                          const SizedBox(width: TricorderTheme.spacingS),
                          Expanded(
                            child: Text(
                              _isValid
                                  ? 'Valid format'
                                  : _validationError ?? 'Invalid format',
                              style: TextStyle(
                                color: _isValid
                                    ? TricorderTheme.accentMint
                                    : TricorderTheme.statusError,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: TricorderTheme.spacingL),

              // Privacy note
              TricorderTheme.panel(
                accentColor: TricorderTheme.accentViolet,
                padding: const EdgeInsets.all(TricorderTheme.spacingM),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: TricorderTheme.accentViolet,
                      size: 20,
                    ),
                    const SizedBox(width: TricorderTheme.spacingM),
                    Expanded(
                      child: Text(
                        'Your API key is encrypted and stored locally on your device. We never send it to our servers.',
                        style: TextStyle(
                          color: TricorderTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TricorderTheme.spacingXL),

              // Continue button
              ElevatedButton(
                onPressed: _isValid ? _continue : null,
                child: const Text('TEST CONNECTION'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getProviderName() {
    switch (widget.provider) {
      case LLMProvider.claude:
        return 'Anthropic Claude';
      case LLMProvider.openai:
        return 'OpenAI GPT';
      case LLMProvider.gemini:
        return 'Google Gemini';
    }
  }
}
