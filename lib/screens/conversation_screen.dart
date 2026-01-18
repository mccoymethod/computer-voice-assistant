import 'package:flutter/material.dart';

/// Screen for viewing conversation history
/// 
/// TODO: Implement conversation persistence and history browsing
class ConversationScreen extends StatelessWidget {
  const ConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation History'),
      ),
      body: const Center(
        child: Text('Conversation history coming soon'),
      ),
    );
  }
}
