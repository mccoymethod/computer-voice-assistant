import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

import '../models/queued_request.dart';

/// Service for managing offline request queue
/// 
/// When the device loses connectivity:
/// 1. New requests are stored in SQLite
/// 2. When connectivity returns, requests are processed in order
/// 3. Failed requests are retried up to 3 times
/// 4. Users can view and cancel pending requests
class QueueService extends ChangeNotifier {
  static const String _tableName = 'queued_requests';
  
  final Logger _logger = Logger();
  Database? _database;
  StreamSubscription? _connectivitySubscription;
  bool _isProcessing = false;

  /// Current pending requests (cached for UI)
  List<QueuedRequest> _pendingRequests = [];
  List<QueuedRequest> get pendingRequests => List.unmodifiable(_pendingRequests);

  /// Whether currently connected to internet
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Callback for when a queued request is successfully processed
  /// The UI should use this to add the response to the conversation
  Function(QueuedRequest request, String response)? onRequestProcessed;

  /// Initialize the database and start connectivity monitoring
  Future<void> initialize() async {
    await _initDatabase();
    await _loadPendingRequests();
    _startConnectivityMonitoring();
  }

  /// Initialize SQLite database
  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'request_queue.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            user_message TEXT NOT NULL,
            conversation_id TEXT NOT NULL,
            provider TEXT NOT NULL,
            model_id TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            processed_at INTEGER,
            retry_count INTEGER DEFAULT 0,
            error_message TEXT,
            response TEXT
          )
        ''');
        
        // Index for efficient queries
        await db.execute('''
          CREATE INDEX idx_status ON $_tableName(status)
        ''');
      },
    );

    _logger.i('Queue database initialized');
  }

  /// Load pending requests from database
  Future<void> _loadPendingRequests() async {
    if (_database == null) return;

    final rows = await _database!.query(
      _tableName,
      where: 'status IN (?, ?)',
      whereArgs: [
        QueuedRequestStatus.pending.name,
        QueuedRequestStatus.processing.name,
      ],
      orderBy: 'created_at ASC',
    );

    _pendingRequests = rows.map((r) => QueuedRequest.fromSqlRow(r)).toList();
    notifyListeners();
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (result) async {
        final wasOnline = _isOnline;
        _isOnline = result.any((r) => r != ConnectivityResult.none);
        
        _logger.i('Connectivity changed: $_isOnline');
        
        // If we just came online, process the queue
        if (_isOnline && !wasOnline) {
          await processQueue();
        }
        
        notifyListeners();
      },
    );

    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      _isOnline = result.any((r) => r != ConnectivityResult.none);
      notifyListeners();
    });
  }

  /// Add a request to the queue
  /// 
  /// Called when a request fails due to no connectivity
  Future<QueuedRequest> enqueue(QueuedRequest request) async {
    if (_database == null) {
      throw StateError('Queue service not initialized');
    }

    await _database!.insert(_tableName, request.toSqlValues());
    
    _pendingRequests.add(request);
    notifyListeners();

    _logger.i('Request queued: ${request.id}');
    
    return request;
  }

  /// Update a request in the queue
  Future<void> _updateRequest(QueuedRequest request) async {
    if (_database == null) return;

    await _database!.update(
      _tableName,
      request.toSqlValues(),
      where: 'id = ?',
      whereArgs: [request.id],
    );

    // Update cached list
    final index = _pendingRequests.indexWhere((r) => r.id == request.id);
    if (index >= 0) {
      if (request.isTerminal) {
        _pendingRequests.removeAt(index);
      } else {
        _pendingRequests[index] = request;
      }
    }
    
    notifyListeners();
  }

  /// Cancel a pending request
  Future<void> cancelRequest(String requestId) async {
    final request = _pendingRequests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => throw ArgumentError('Request not found'),
    );

    await _updateRequest(request.markCancelled());
    _logger.i('Request cancelled: $requestId');
  }

  /// Process all pending requests
  /// 
  /// Called automatically when connectivity is restored
  Future<void> processQueue() async {
    if (_isProcessing || !_isOnline || _pendingRequests.isEmpty) return;

    _isProcessing = true;
    _logger.i('Processing queue: ${_pendingRequests.length} requests');

    try {
      // Process in order
      for (final request in List.from(_pendingRequests)) {
        if (!_isOnline) break; // Stop if we lose connectivity

        await _processRequest(request);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single request
  Future<void> _processRequest(QueuedRequest request) async {
    // Mark as processing
    final processing = request.markProcessing();
    await _updateRequest(processing);

    try {
      // The actual LLM call will be made by the caller via callback
      // This service just manages the queue state
      
      // For now, we'll emit an event that the provider can listen to
      // The provider will make the actual API call and report back
      
      _logger.i('Processing request: ${request.id}');
      
      // Emit event for processing
      // Note: In a real implementation, you might use a Stream or callback
      // For simplicity, we'll let the AssistantProvider handle this
      
    } catch (e) {
      _logger.e('Failed to process request: $e');
      await _updateRequest(request.markFailed(e.toString()));
    }
  }

  /// Mark a request as completed
  Future<void> markCompleted(String requestId, String response) async {
    final request = _pendingRequests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => throw ArgumentError('Request not found: $requestId'),
    );

    final completed = request.markCompleted(response);
    await _updateRequest(completed);

    // Notify listeners that response is ready
    onRequestProcessed?.call(completed, response);
    
    _logger.i('Request completed: $requestId');
  }

  /// Mark a request as failed
  Future<void> markFailed(String requestId, String error) async {
    final request = _pendingRequests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => throw ArgumentError('Request not found: $requestId'),
    );

    await _updateRequest(request.markFailed(error));
    _logger.w('Request failed: $requestId - $error');
  }

  /// Get request history (completed and failed)
  Future<List<QueuedRequest>> getHistory({int limit = 50}) async {
    if (_database == null) return [];

    final rows = await _database!.query(
      _tableName,
      where: 'status IN (?, ?, ?)',
      whereArgs: [
        QueuedRequestStatus.completed.name,
        QueuedRequestStatus.failed.name,
        QueuedRequestStatus.cancelled.name,
      ],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return rows.map((r) => QueuedRequest.fromSqlRow(r)).toList();
  }

  /// Clear completed/failed requests older than given duration
  Future<int> clearOldHistory(Duration age) async {
    if (_database == null) return 0;

    final cutoff = DateTime.now().subtract(age).millisecondsSinceEpoch;

    return await _database!.delete(
      _tableName,
      where: 'status IN (?, ?, ?) AND created_at < ?',
      whereArgs: [
        QueuedRequestStatus.completed.name,
        QueuedRequestStatus.failed.name,
        QueuedRequestStatus.cancelled.name,
        cutoff,
      ],
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _database?.close();
    super.dispose();
  }
}
