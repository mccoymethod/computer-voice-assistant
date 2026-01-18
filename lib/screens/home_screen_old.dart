import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/assistant_provider.dart';
import '../providers/settings_provider.dart';
import '../models/conversation.dart';
import '../services/queue_service.dart';

/// Main screen of the voice assistant
/// 
/// Shows:
/// - Current state visualization
/// - Conversation history
/// - Manual input option
/// - Quick settings access
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
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
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COMPUTER'),
        actions: [
          // Queue indicator
          Consumer<QueueService>(
            builder: (context, queue, _) {
              if (queue.pendingRequests.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  avatar: Icon(
                    queue.isOnline ? Icons.cloud_queue : Icons.cloud_off,
                    size: 18,
                  ),
                  label: Text('${queue.pendingRequests.length}'),
                ),
              );
            },
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status area
          _buildStatusArea(),
          
          // Conversation history
          Expanded(
            child: _buildConversationList(),
          ),
          
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  /// Build the status/visualization area
  Widget _buildStatusArea() {
    return Consumer<AssistantProvider>(
      builder: (context, assistant, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Animated state indicator
              _buildStateIndicator(assistant.state),
              const SizedBox(height: 16),
              // Status message
              Text(
                assistant.statusMessage,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              // Transcribed text (while listening)
              if (assistant.transcribedText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    assistant.transcribedText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Error message
              if (assistant.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    assistant.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build animated state indicator
  Widget _buildStateIndicator(AssistantState state) {
    final color = _getStateColor(state);
    final size = state == AssistantState.idle ? 80.0 : 100.0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = state == AssistantState.idle 
            ? 1.0 
            : 1.0 + (_pulseController.value * 0.1);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
              border: Border.all(color: color, width: 3),
              boxShadow: state != AssistantState.idle
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _getStateIcon(state),
              size: 40,
              color: color,
            ),
          ),
        );
      },
    );
  }

  Color _getStateColor(AssistantState state) {
    switch (state) {
      case AssistantState.idle:
        return Colors.grey;
      case AssistantState.listening:
        return Colors.green;
      case AssistantState.processing:
        return Colors.blue;
      case AssistantState.thinking:
        return Colors.purple;
      case AssistantState.speaking:
        return Colors.orange;
      case AssistantState.error:
        return Colors.red;
    }
  }

  IconData _getStateIcon(AssistantState state) {
    switch (state) {
      case AssistantState.idle:
        return Icons.mic_none;
      case AssistantState.listening:
        return Icons.mic;
      case AssistantState.processing:
        return Icons.hearing;
      case AssistantState.thinking:
        return Icons.psychology;
      case AssistantState.speaking:
        return Icons.volume_up;
      case AssistantState.error:
        return Icons.error_outline;
    }
  }

  /// Build conversation history list
  Widget _buildConversationList() {
    return Consumer<AssistantProvider>(
      builder: (context, assistant, _) {
        final messages = assistant.currentConversation.messages;
        
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Say "Computer" to start a conversation',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _buildMessageBubble(messages[index]);
          },
        );
      },
    );
  }

  /// Build a single message bubble
  Widget _buildMessageBubble(Message message) {
    final isUser = message.role == MessageRole.user;
    final isError = message.role == MessageRole.error;
    final isSystem = message.role == MessageRole.system;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            message.content,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isError
              ? Theme.of(context).colorScheme.errorContainer
              : isUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isError
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : isUser
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            if (message.provider != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message.provider!.shortName,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build text input area (for testing without voice)
  Widget _buildInputArea() {
    return Consumer<AssistantProvider>(
      builder: (context, assistant, _) {
        final isProcessing = assistant.state != AssistantState.idle;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Provider indicator
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    return Tooltip(
                      message: settings.defaultProvider.displayName,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          settings.defaultProvider.shortName[0],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                // Text input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !isProcessing,
                    decoration: InputDecoration(
                      hintText: 'Type a message (or use voice)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (text) => _sendTextMessage(assistant, text),
                  ),
                ),
                const SizedBox(width: 12),
                // Send button
                IconButton.filled(
                  onPressed: isProcessing
                      ? null
                      : () => _sendTextMessage(assistant, _textController.text),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendTextMessage(AssistantProvider assistant, String text) {
    if (text.trim().isEmpty) return;
    assistant.sendTextMessage(text.trim());
    _textController.clear();
  }
}
