import 'package:uuid/uuid.dart';
import 'llm_provider.dart';

/// Status of a queued request
enum QueuedRequestStatus {
  pending,    // Waiting for network
  processing, // Currently being sent
  completed,  // Successfully processed
  failed,     // Failed after retries
  cancelled,  // Cancelled by user
}

/// A request that was queued while offline
/// 
/// When the device loses connectivity, requests are stored locally
/// and processed when connectivity returns.
class QueuedRequest {
  final String id;
  final String userMessage;
  final String conversationId;
  final LLMProvider provider;
  final String modelId;
  final QueuedRequestStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final int retryCount;
  final String? errorMessage;
  final String? response; // Stored after successful processing

  QueuedRequest({
    String? id,
    required this.userMessage,
    required this.conversationId,
    required this.provider,
    required this.modelId,
    this.status = QueuedRequestStatus.pending,
    DateTime? createdAt,
    this.processedAt,
    this.retryCount = 0,
    this.errorMessage,
    this.response,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// Maximum retry attempts before marking as failed
  static const int maxRetries = 3;

  /// Whether this request can be retried
  bool get canRetry => 
      status == QueuedRequestStatus.pending && 
      retryCount < maxRetries;

  /// Whether this request is terminal (won't be processed further)
  bool get isTerminal =>
      status == QueuedRequestStatus.completed ||
      status == QueuedRequestStatus.failed ||
      status == QueuedRequestStatus.cancelled;

  /// Create a copy with updated status
  QueuedRequest copyWith({
    QueuedRequestStatus? status,
    DateTime? processedAt,
    int? retryCount,
    String? errorMessage,
    String? response,
  }) {
    return QueuedRequest(
      id: id,
      userMessage: userMessage,
      conversationId: conversationId,
      provider: provider,
      modelId: modelId,
      status: status ?? this.status,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      response: response ?? this.response,
    );
  }

  /// Mark as processing
  QueuedRequest markProcessing() {
    return copyWith(status: QueuedRequestStatus.processing);
  }

  /// Mark as completed with response
  QueuedRequest markCompleted(String responseText) {
    return copyWith(
      status: QueuedRequestStatus.completed,
      processedAt: DateTime.now(),
      response: responseText,
    );
  }

  /// Mark as failed with error
  QueuedRequest markFailed(String error) {
    final newRetryCount = retryCount + 1;
    return copyWith(
      status: newRetryCount >= maxRetries 
          ? QueuedRequestStatus.failed 
          : QueuedRequestStatus.pending,
      retryCount: newRetryCount,
      errorMessage: error,
    );
  }

  /// Mark as cancelled
  QueuedRequest markCancelled() {
    return copyWith(
      status: QueuedRequestStatus.cancelled,
      processedAt: DateTime.now(),
    );
  }

  /// Convert to JSON for SQLite storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userMessage': userMessage,
      'conversationId': conversationId,
      'provider': provider.name,
      'modelId': modelId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'retryCount': retryCount,
      'errorMessage': errorMessage,
      'response': response,
    };
  }

  /// Create from JSON
  factory QueuedRequest.fromJson(Map<String, dynamic> json) {
    return QueuedRequest(
      id: json['id'] as String,
      userMessage: json['userMessage'] as String,
      conversationId: json['conversationId'] as String,
      provider: LLMProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => LLMProvider.claude,
      ),
      modelId: json['modelId'] as String,
      status: QueuedRequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => QueuedRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      retryCount: json['retryCount'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      response: json['response'] as String?,
    );
  }

  /// Convert to SQL insert values
  Map<String, dynamic> toSqlValues() {
    return {
      'id': id,
      'user_message': userMessage,
      'conversation_id': conversationId,
      'provider': provider.name,
      'model_id': modelId,
      'status': status.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'processed_at': processedAt?.millisecondsSinceEpoch,
      'retry_count': retryCount,
      'error_message': errorMessage,
      'response': response,
    };
  }

  /// Create from SQL row
  factory QueuedRequest.fromSqlRow(Map<String, dynamic> row) {
    return QueuedRequest(
      id: row['id'] as String,
      userMessage: row['user_message'] as String,
      conversationId: row['conversation_id'] as String,
      provider: LLMProvider.values.firstWhere(
        (p) => p.name == row['provider'],
        orElse: () => LLMProvider.claude,
      ),
      modelId: row['model_id'] as String,
      status: QueuedRequestStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => QueuedRequestStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      processedAt: row['processed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['processed_at'] as int)
          : null,
      retryCount: row['retry_count'] as int? ?? 0,
      errorMessage: row['error_message'] as String?,
      response: row['response'] as String?,
    );
  }
}
