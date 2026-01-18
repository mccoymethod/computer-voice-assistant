import 'package:flutter/material.dart';

import '../../theme/tricorder_theme.dart';
import 'provider_selection_screen.dart';

/// Welcome screen - first step of onboarding
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              // App icon/logo
              Icon(
                Icons.mic_none_outlined,
                size: 120,
                color: TricorderTheme.primaryAmber,
              ),

              const SizedBox(height: TricorderTheme.spacingXL),

              // Welcome title
              Text(
                'COMPUTER',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: TricorderTheme.primaryAmber,
                      letterSpacing: 4.0,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: TricorderTheme.spacingM),

              // Subtitle
              Text(
                'Voice Assistant',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: TricorderTheme.textSecondary,
                      letterSpacing: 2.0,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: TricorderTheme.spacingXL * 2),

              // Description
              TricorderTheme.panel(
                accentColor: TricorderTheme.accentCyan,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FEATURES',
                      style: TextStyle(
                        color: TricorderTheme.textSecondary,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),
                    _buildFeature(
                      icon: Icons.hearing_outlined,
                      title: 'Wake Word Detection',
                      description: 'Say "Computer" to activate',
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),
                    _buildFeature(
                      icon: Icons.mic,
                      title: 'Speech-to-Text',
                      description: 'Locally processed voice input',
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),
                    _buildFeature(
                      icon: Icons.psychology_outlined,
                      title: 'AI Assistant',
                      description: 'Claude, OpenAI, or Gemini',
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),
                    _buildFeature(
                      icon: Icons.volume_up,
                      title: 'Text-to-Speech',
                      description: 'Natural voice responses',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TricorderTheme.spacingXL),

              // Get Started button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProviderSelectionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: TricorderTheme.spacingL,
                  ),
                ),
                child: const Text('GET STARTED'),
              ),

              const SizedBox(height: TricorderTheme.spacingM),

              // Privacy note
              Text(
                'Your API keys are encrypted and stored locally.\nWe never send your data to our servers.',
                style: TextStyle(
                  color: TricorderTheme.textTertiary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: TricorderTheme.primaryAmber,
          size: 24,
        ),
        const SizedBox(width: TricorderTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: TricorderTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: TricorderTheme.spacingXS),
              Text(
                description,
                style: const TextStyle(
                  color: TricorderTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
