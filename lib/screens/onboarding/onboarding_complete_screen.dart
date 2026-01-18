import 'package:flutter/material.dart';

import '../../theme/tricorder_theme.dart';

/// Onboarding complete screen - final step before using the app
class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TricorderTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success animation/icon
              Icon(
                Icons.check_circle_outline,
                size: 120,
                color: TricorderTheme.accentMint,
              ),

              const SizedBox(height: TricorderTheme.spacingXL),

              Text(
                'ALL SET!',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: TricorderTheme.accentMint,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: TricorderTheme.spacingM),

              Text(
                'Your voice assistant is ready to use',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: TricorderTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: TricorderTheme.spacingXL * 2),

              // Quick tips
              TricorderTheme.panel(
                accentColor: TricorderTheme.accentCyan,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUICK TIPS',
                      style: TextStyle(
                        color: TricorderTheme.textSecondary,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),
                    _buildTip(
                      number: '1',
                      text: 'Press the button to activate voice mode',
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),
                    _buildTip(
                      number: '2',
                      text: 'Say "Computer" to start listening',
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),
                    _buildTip(
                      number: '3',
                      text: 'Switch providers anytime in Settings',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TricorderTheme.spacingXL),

              // Start button
              ElevatedButton(
                onPressed: () {
                  // Navigate to home screen and clear navigation stack
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: TricorderTheme.spacingL,
                  ),
                ),
                child: const Text('START USING COMPUTER'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip({required String number, required String text}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: TricorderTheme.primaryAmber,
            borderRadius: BorderRadius.circular(TricorderTheme.radiusSmall),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: TricorderTheme.backgroundDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: TricorderTheme.spacingM),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: TricorderTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
