import 'package:flutter/material.dart';

import '../../models/llm_provider.dart';
import '../../services/api_key_test_service.dart';
import '../../services/secure_storage_service.dart';
import '../../theme/tricorder_theme.dart';
import 'onboarding_complete_screen.dart';

/// API key test screen - test the API key connection
class ApiKeyTestScreen extends StatefulWidget {
  final LLMProvider provider;

  const ApiKeyTestScreen({
    super.key,
    required this.provider,
  });

  @override
  State<ApiKeyTestScreen> createState() => _ApiKeyTestScreenState();
}

class _ApiKeyTestScreenState extends State<ApiKeyTestScreen> {
  final ApiKeyTestService _testService = ApiKeyTestService();
  final SecureStorageService _secureStorage = SecureStorageService();

  bool _testing = false;
  ApiKeyTestResult? _result;

  @override
  void initState() {
    super.initState();
    // Auto-start test on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testConnection();
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _result = null;
    });

    // Get the API key
    final apiKey = await _secureStorage.getApiKey(widget.provider);

    if (apiKey == null) {
      setState(() {
        _testing = false;
        _result = ApiKeyTestResult.failure(
          errorMessage: 'API key not found',
          errorCode: 'NOT_FOUND',
        );
      });
      return;
    }

    // Test the API key
    final result = await _testService.testApiKey(widget.provider, apiKey);

    setState(() {
      _testing = false;
      _result = result;
    });

    // Save test timestamp if successful
    if (result.success) {
      await _secureStorage.setLastTested(widget.provider, result.testedAt);

      // Auto-navigate to complete screen after delay
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const OnboardingCompleteScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TEST CONNECTION'),
        automaticallyImplyLeading: !_testing,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TricorderTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status indicator
              if (_testing) ...[
                _buildTestingState(),
              ] else if (_result != null) ...[
                if (_result!.success)
                  _buildSuccessState()
                else
                  _buildErrorState(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestingState() {
    return Column(
      children: [
        // Animated spinner
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              TricorderTheme.primaryAmber,
            ),
          ),
        ),

        const SizedBox(height: TricorderTheme.spacingXL),

        Text(
          'TESTING CONNECTION',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: TricorderTheme.primaryAmber,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: TricorderTheme.spacingM),

        Text(
          'Verifying your API key with ${_getProviderName()}...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TricorderTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        // Success icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TricorderTheme.accentMint.withOpacity(0.2),
            border: Border.all(
              color: TricorderTheme.accentMint,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.check,
            size: 60,
            color: TricorderTheme.accentMint,
          ),
        ),

        const SizedBox(height: TricorderTheme.spacingXL),

        Text(
          'CONNECTION SUCCESSFUL',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: TricorderTheme.accentMint,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: TricorderTheme.spacingM),

        Text(
          'Your API key is valid and working!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TricorderTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        // Error icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TricorderTheme.statusError.withOpacity(0.2),
            border: Border.all(
              color: TricorderTheme.statusError,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.error_outline,
            size: 60,
            color: TricorderTheme.statusError,
          ),
        ),

        const SizedBox(height: TricorderTheme.spacingXL),

        Text(
          'CONNECTION FAILED',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: TricorderTheme.statusError,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: TricorderTheme.spacingM),

        // Error message
        TricorderTheme.panel(
          accentColor: TricorderTheme.statusError,
          child: Text(
            _result?.errorMessage ?? 'Unknown error occurred',
            style: const TextStyle(
              color: TricorderTheme.textPrimary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: TricorderTheme.spacingXL),

        // Retry button
        ElevatedButton(
          onPressed: _testConnection,
          child: const Text('RETRY'),
        ),

        const SizedBox(height: TricorderTheme.spacingM),

        // Go back button
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('GO BACK'),
        ),
      ],
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
