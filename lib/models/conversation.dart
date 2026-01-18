import 'package:uuid/uuid.dart';
import 'llm_provider.dart';

/// Represents a single message in a conversation
class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final LLMProvider? provider; // Which LLM responded (for assistant messages)
  final String? modelId;       // Which specific model was used
  final int? inputTokens;      // Token usage for cost tracking
  final int? outputTokens;

  Message({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.provider,
    this.modelId,
    this.inputTokens,
    this.outputTokens,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  /// Create a user message
  factory Message.user(String content) {
    return Message(
      role: MessageRole.user,
      content: content,
    );
  }

  /// Create an assistant message
  factory Message.assistant(
    String content, {
    required LLMProvider provider,
    required String modelId,
    int? inputTokens,
    int? outputTokens,
  }) {
    return Message(
      role: MessageRole.assistant,
      content: content,
      provider: provider,
      modelId: modelId,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );
  }

  /// Create a system message (used for context/instructions)
  factory Message.system(String content) {
    return Message(
      role: MessageRole.system,
      content: content,
    );
  }

  /// Create an error message
  factory Message.error(String content) {
    return Message(
      role: MessageRole.error,
      content: content,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'provider': provider?.name,
      'modelId': modelId,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
    };
  }

  /// Create from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      role: MessageRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      provider: json['provider'] != null
          ? LLMProvider.values.firstWhere(
              (p) => p.name == json['provider'],
              orElse: () => LLMProvider.claude,
            )
          : null,
      modelId: json['modelId'] as String?,
      inputTokens: json['inputTokens'] as int?,
      outputTokens: json['outputTokens'] as int?,
    );
  }

  /// Copy with modifications
  Message copyWith({
    String? content,
    int? inputTokens,
    int? outputTokens,
  }) {
    return Message(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      provider: provider,
      modelId: modelId,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
    );
  }
}

/// Role of a message sender
enum MessageRole {
  user,
  assistant,
  system,
  error,
}

/// Extension methods for MessageRole
extension MessageRoleExtension on MessageRole {
  /// Whether this role is from the AI
  bool get isAssistant => this == MessageRole.assistant;
  
  /// Whether this role is from the user
  bool get isUser => this == MessageRole.user;
  
  /// Whether this is an error message
  bool get isError => this == MessageRole.error;
}

/// Represents a complete conversation
class Conversation {
  final String id;
  final String title;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       title = title ?? 'New Conversation',
       messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Add a message to the conversation
  Conversation addMessage(Message message) {
    return Conversation(
      id: id,
      title: title,
      messages: [...messages, message],
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a title from the first user message
  String get autoTitle {
    final firstUserMessage = messages.firstWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => Message.user('New Conversation'),
    );
    final content = firstUserMessage.content;
    if (content.length <= 50) return content;
    return '${content.substring(0, 47)}...';
  }

  /// Get the last message
  Message? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Get total token usage
  int get totalInputTokens => messages
      .where((m) => m.inputTokens != null)
      .fold(0, (sum, m) => sum + m.inputTokens!);

  int get totalOutputTokens => messages
      .where((m) => m.outputTokens != null)
      .fold(0, (sum, m) => sum + m.outputTokens!);

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
