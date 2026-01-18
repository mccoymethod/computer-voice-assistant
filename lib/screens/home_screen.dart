import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/assistant_provider.dart';
import '../providers/settings_provider.dart';
import '../services/memory_service.dart';
import '../services/model_lifecycle_service.dart';
import '../theme/tricorder_theme.dart';
import '../widgets/provider_switcher.dart';

/// Main tricorder-style home screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COMPUTER'),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          // History button
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () => Navigator.pushNamed(context, '/conversation'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Provider switcher at top
            const Padding(
              padding: EdgeInsets.fromLTRB(
                TricorderTheme.spacingM,
                TricorderTheme.spacingS,
                TricorderTheme.spacingM,
                0,
              ),
              child: ProviderSwitcher(),
            ),

            // Status panels
            _buildStatusPanels(),

            // Main conversation area
            Expanded(
              child: _buildConversationArea(),
            ),

            // Push-to-talk button at bottom
            _buildPushToTalkButton(),

            const SizedBox(height: TricorderTheme.spacingL),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Status Panels
  // ============================================

  Widget _buildStatusPanels() {
    return Consumer3<AssistantProvider, MemoryService, ModelLifecycleService>(
      builder: (context, assistant, memory, models, _) {
        return Container(
          margin: const EdgeInsets.all(TricorderTheme.spacingM),
          child: Column(
            children: [
              // Main status display
              TricorderTheme.panel(
                accentColor: _getStateColor(assistant.state),
                child: Column(
                  children: [
                    // Status indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusIndicator(assistant.state),
                      ],
                    ),
                    const SizedBox(height: TricorderTheme.spacingM),

                    // Status message
                    Text(
                      assistant.statusMessage.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: TricorderTheme.textPrimary,
                            letterSpacing: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    // Error message (if any)
                    if (assistant.errorMessage != null) ...[
                      const SizedBox(height: TricorderTheme.spacingS),
                      Text(
                        assistant.errorMessage!,
                        style: const TextStyle(
                          color: TricorderTheme.statusError,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: TricorderTheme.spacingM),

              // System info panels
              Row(
                children: [
                  // Memory panel
                  Expanded(
                    child: TricorderTheme.panel(
                      accentColor: TricorderTheme.accentCyan,
                      padding: const EdgeInsets.all(TricorderTheme.spacingS),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MEMORY',
                            style: TextStyle(
                              color: TricorderTheme.textSecondary,
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: TricorderTheme.spacingXS),
                          Text(
                            '${memory.currentMemoryMB}MB',
                            style: TextStyle(
                              color: memory.isCriticalMemory
                                  ? TricorderTheme.statusError
                                  : memory.isLowMemory
                                      ? TricorderTheme.primaryAmber
                                      : TricorderTheme.accentMint,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: TricorderTheme.spacingM),

                  // Models panel
                  Expanded(
                    child: TricorderTheme.panel(
                      accentColor: TricorderTheme.accentViolet,
                      padding: const EdgeInsets.all(TricorderTheme.spacingS),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MODELS',
                            style: TextStyle(
                              color: TricorderTheme.textSecondary,
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: TricorderTheme.spacingXS),
                          Text(
                            models.anyModelLoaded ? 'LOADED' : 'STANDBY',
                            style: TextStyle(
                              color: models.anyModelLoaded
                                  ? TricorderTheme.accentMint
                                  : TricorderTheme.statusIdle,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(AssistantState state) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final bool shouldPulse = state == AssistantState.listening ||
            state == AssistantState.thinking ||
            state == AssistantState.speaking;

        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStateColor(state).withOpacity(0.1),
            border: Border.all(
              color: _getStateColor(state),
              width: shouldPulse ? 2 + (_pulseController.value * 2) : 2,
            ),
          ),
          child: Center(
            child: Icon(
              _getStateIcon(state),
              size: 48,
              color: _getStateColor(state),
            ),
          ),
        );
      },
    );
  }

  Color _getStateColor(AssistantState state) {
    switch (state) {
      case AssistantState.idle:
        return TricorderTheme.statusIdle;
      case AssistantState.wakeWordActive:
        return TricorderTheme.statusActive;
      case AssistantState.listening:
        return TricorderTheme.statusListening;
      case AssistantState.processing:
        return TricorderTheme.accentViolet;
      case AssistantState.thinking:
        return TricorderTheme.statusThinking;
      case AssistantState.speaking:
        return TricorderTheme.statusSpeaking;
      case AssistantState.error:
        return TricorderTheme.statusError;
    }
  }

  IconData _getStateIcon(AssistantState state) {
    switch (state) {
      case AssistantState.idle:
        return Icons.power_settings_new;
      case AssistantState.wakeWordActive:
        return Icons.hearing_outlined;
      case AssistantState.listening:
        return Icons.mic;
      case AssistantState.processing:
        return Icons.sync;
      case AssistantState.thinking:
        return Icons.psychology_outlined;
      case AssistantState.speaking:
        return Icons.volume_up;
      case AssistantState.error:
        return Icons.error_outline;
    }
  }

  // ============================================
  // Conversation Area
  // ============================================

  Widget _buildConversationArea() {
    return Consumer<AssistantProvider>(
      builder: (context, assistant, _) {
        if (assistant.currentConversation.messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: TricorderTheme.spacingM,
          ),
          itemCount: assistant.currentConversation.messages.length,
          itemBuilder: (context, index) {
            final message = assistant.currentConversation.messages[index];
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none_outlined,
            size: 64,
            color: TricorderTheme.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: TricorderTheme.spacingL),
          Text(
            'PRESS BUTTON TO ACTIVATE',
            style: TextStyle(
              color: TricorderTheme.textTertiary.withOpacity(0.7),
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(message) {
    final bool isUser = message.role.name == 'user';
    final bool isError = message.role.name == 'error';

    return Container(
      margin: const EdgeInsets.only(bottom: TricorderTheme.spacingM),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const Icon(
              Icons.smart_toy_outlined,
              color: TricorderTheme.primaryAmber,
              size: 20,
            ),
            const SizedBox(width: TricorderTheme.spacingS),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(TricorderTheme.spacingM),
              decoration: BoxDecoration(
                color: isError
                    ? TricorderTheme.statusError.withOpacity(0.1)
                    : isUser
                        ? TricorderTheme.accentCyan.withOpacity(0.1)
                        : TricorderTheme.backgroundCard,
                border: Border.all(
                  color: isError
                      ? TricorderTheme.statusError
                      : isUser
                          ? TricorderTheme.accentCyan
                          : TricorderTheme.primaryAmber,
                  width: 1,
                ),
                borderRadius:
                    BorderRadius.circular(TricorderTheme.radiusMedium),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isError
                      ? TricorderTheme.statusError
                      : TricorderTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: TricorderTheme.spacingS),
            const Icon(
              Icons.person_outline,
              color: TricorderTheme.accentCyan,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================
  // Push-to-Talk Button
  // ============================================

  Widget _buildPushToTalkButton() {
    return Consumer<AssistantProvider>(
      builder: (context, assistant, _) {
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: TricorderTheme.spacingL,
          ),
          child: Column(
            children: [
              // Main push-to-talk button
              GestureDetector(
                onTap: () => assistant.onPushToTalk(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: assistant.isWakeWordListening
                        ? TricorderTheme.statusActive
                        : TricorderTheme.primaryAmber,
                    boxShadow: assistant.isWakeWordListening
                        ? [
                            BoxShadow(
                              color:
                                  TricorderTheme.statusActive.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    assistant.isWakeWordListening
                        ? Icons.hearing
                        : Icons.power_settings_new,
                    size: 56,
                    color: TricorderTheme.backgroundDark,
                  ),
                ),
              ),

              const SizedBox(height: TricorderTheme.spacingM),

              // Button label
              Text(
                assistant.isWakeWordListening ? 'ACTIVE' : 'ACTIVATE',
                style: const TextStyle(
                  color: TricorderTheme.primaryAmber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
