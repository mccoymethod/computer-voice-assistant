import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

import '../models/conversation.dart';
import '../models/llm_provider.dart';

/// Service for archiving and retrieving past conversations
///
/// Stores conversations in SQLite for:
/// - Conversation history viewing
/// - Full-text search across all conversations
/// - Usage statistics and analytics
class ConversationArchiveService {
  static const String _dbName = 'conversation_archive.db';
  static const int _dbVersion = 1;

  final Logger _logger = Logger();
  Database? _db;

  // ============================================
  // Initialization
  // ============================================

  Future<void> initialize() async {
    final String dbPath = join(await getDatabasesPath(), _dbName);

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );

    _logger.i('Conversation archive database initialized');
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Conversations table
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        message_count INTEGER DEFAULT 0,
        total_input_tokens INTEGER DEFAULT 0,
        total_output_tokens INTEGER DEFAULT 0
      )
    ''');

    // Messages table (for full-text search)
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        provider TEXT,
        model_id TEXT,
        input_tokens INTEGER,
        output_tokens INTEGER,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');

    // Create FTS5 table for full-text search
    await db.execute('''
      CREATE VIRTUAL TABLE messages_fts USING fts5(
        message_id UNINDEXED,
        conversation_id UNINDEXED,
        content,
        tokenize = 'porter unicode61'
      )
    ''');

    // Create indexes for performance
    await db.execute('''
      CREATE INDEX idx_conversations_created 
      ON conversations(created_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_conversation 
      ON messages(conversation_id, timestamp)
    ''');

    _logger.i('Conversation archive database created');
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
    _logger.i('Upgrading database from v$oldVersion to v$newVersion');
  }

  // ============================================
  // Archive Operations
  // ============================================

  /// Archive a conversation
  Future<void> archiveConversation(Conversation conversation) async {
    if (_db == null) {
      throw Exception('Database not initialized');
    }

    if (conversation.messages.isEmpty) {
      _logger.d('Skipping empty conversation');
      return;
    }

    await _db!.transaction((txn) async {
      // Insert conversation
      await txn.insert(
        'conversations',
        {
          'id': conversation.id,
          'title': conversation.autoTitle,
          'created_at': conversation.createdAt.millisecondsSinceEpoch,
          'updated_at': conversation.updatedAt.millisecondsSinceEpoch,
          'message_count': conversation.messages.length,
          'total_input_tokens': conversation.totalInputTokens,
          'total_output_tokens': conversation.totalOutputTokens,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert all messages
      for (final message in conversation.messages) {
        await txn.insert(
          'messages',
          {
            'id': message.id,
            'conversation_id': conversation.id,
            'role': message.role.name,
            'content': message.content,
            'timestamp': message.timestamp.millisecondsSinceEpoch,
            'provider': message.provider?.name,
            'model_id': message.modelId,
            'input_tokens': message.inputTokens,
            'output_tokens': message.outputTokens,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Add to FTS index for search
        await txn.insert(
          'messages_fts',
          {
            'message_id': message.id,
            'conversation_id': conversation.id,
            'content': message.content,
          },
        );
      }
    });

    _logger.i(
        'Archived conversation ${conversation.id} with ${conversation.messages.length} messages');
  }

  // ============================================
  // Retrieval Operations
  // ============================================

  /// Get all conversations (most recent first)
  Future<List<ConversationSummary>> getAllConversations({
    int? limit,
    int? offset,
  }) async {
    if (_db == null) return [];

    final List<Map<String, dynamic>> results = await _db!.query(
      'conversations',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((row) => ConversationSummary.fromMap(row)).toList();
  }

  /// Get a single conversation with all messages
  Future<Conversation?> getConversation(String conversationId) async {
    if (_db == null) return null;

    // Get conversation metadata
    final List<Map<String, dynamic>> convResults = await _db!.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );

    if (convResults.isEmpty) return null;

    // Get all messages
    final List<Map<String, dynamic>> msgResults = await _db!.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );

    final List<Message> messages = msgResults.map((row) {
      return Message(
        id: row['id'] as String,
        role: MessageRole.values.firstWhere(
          (r) => r.name == row['role'],
          orElse: () => MessageRole.user,
        ),
        content: row['content'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
        provider: row['provider'] != null
            ? LLMProvider.values.firstWhere(
                (p) => p.name == row['provider'],
                orElse: () => LLMProvider.claude,
              )
            : null,
        modelId: row['model_id'] as String?,
        inputTokens: row['input_tokens'] as int?,
        outputTokens: row['output_tokens'] as int?,
      );
    }).toList();

    final Map<String, dynamic> conv = convResults.first;
    return Conversation(
      id: conv['id'] as String,
      title: conv['title'] as String,
      messages: messages,
      createdAt: DateTime.fromMillisecondsSinceEpoch(conv['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(conv['updated_at'] as int),
    );
  }

  // ============================================
  // Search Operations
  // ============================================

  /// Search conversations by content (full-text search)
  Future<List<SearchResult>> searchConversations(String query) async {
    if (_db == null || query.trim().isEmpty) return [];

    final List<Map<String, dynamic>> results = await _db!.rawQuery('''
      SELECT 
        m.id as message_id,
        m.conversation_id,
        m.content,
        m.timestamp,
        c.title as conversation_title,
        c.created_at as conversation_created_at
      FROM messages_fts fts
      JOIN messages m ON fts.message_id = m.id
      JOIN conversations c ON m.conversation_id = c.id
      WHERE messages_fts MATCH ?
      ORDER BY rank
      LIMIT 50
    ''', [query]);

    return results.map((row) => SearchResult.fromMap(row)).toList();
  }

  // ============================================
  // Statistics
  // ============================================

  /// Get total number of archived conversations
  Future<int> getTotalConversationCount() async {
    if (_db == null) return 0;

    final result = await _db!.rawQuery(
      'SELECT COUNT(*) as count FROM conversations',
    );
    return result.first['count'] as int;
  }

  /// Get total token usage across all conversations
  Future<TokenUsageStats> getTokenUsageStats() async {
    if (_db == null) {
      return TokenUsageStats(totalInput: 0, totalOutput: 0);
    }

    final result = await _db!.rawQuery('''
      SELECT 
        SUM(total_input_tokens) as input,
        SUM(total_output_tokens) as output
      FROM conversations
    ''');

    final row = result.first;
    return TokenUsageStats(
      totalInput: (row['input'] as int?) ?? 0,
      totalOutput: (row['output'] as int?) ?? 0,
    );
  }

  // ============================================
  // Cleanup
  // ============================================

  /// Delete a single conversation
  Future<void> deleteConversation(String conversationId) async {
    if (_db == null) return;

    await _db!.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    _logger.i('Deleted conversation $conversationId');
  }

  /// Delete conversations older than specified days
  Future<int> deleteOldConversations(int daysOld) async {
    if (_db == null) return 0;

    final DateTime cutoff = DateTime.now().subtract(Duration(days: daysOld));
    final int cutoffMs = cutoff.millisecondsSinceEpoch;

    final int count = await _db!.delete(
      'conversations',
      where: 'created_at < ?',
      whereArgs: [cutoffMs],
    );

    _logger.i('Deleted $count conversations older than $daysOld days');
    return count;
  }

  /// Delete all conversations (use with caution!)
  Future<void> deleteAllConversations() async {
    if (_db == null) return;

    await _db!.delete('conversations');
    _logger.w('Deleted ALL conversations');
  }

  // ============================================
  // Cleanup
  // ============================================

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

// ============================================
// Helper Classes
// ============================================

/// Summary of a conversation (for list display)
class ConversationSummary {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final int totalInputTokens;
  final int totalOutputTokens;

  ConversationSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.totalInputTokens,
    required this.totalOutputTokens,
  });

  factory ConversationSummary.fromMap(Map<String, dynamic> map) {
    return ConversationSummary(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      messageCount: map['message_count'] as int,
      totalInputTokens: map['total_input_tokens'] as int,
      totalOutputTokens: map['total_output_tokens'] as int,
    );
  }
}

/// Search result with context
class SearchResult {
  final String messageId;
  final String conversationId;
  final String content;
  final DateTime messageTimestamp;
  final String conversationTitle;
  final DateTime conversationCreatedAt;

  SearchResult({
    required this.messageId,
    required this.conversationId,
    required this.content,
    required this.messageTimestamp,
    required this.conversationTitle,
    required this.conversationCreatedAt,
  });

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      messageId: map['message_id'] as String,
      conversationId: map['conversation_id'] as String,
      content: map['content'] as String,
      messageTimestamp:
          DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      conversationTitle: map['conversation_title'] as String,
      conversationCreatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['conversation_created_at'] as int),
    );
  }
}

/// Token usage statistics
class TokenUsageStats {
  final int totalInput;
  final int totalOutput;

  TokenUsageStats({required this.totalInput, required this.totalOutput});

  int get total => totalInput + totalOutput;
}
