import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service for monitoring and managing app memory usage
///
/// Tracks RAM usage and provides warnings when memory is getting low.
/// Helps decide when to unload models to prevent OOM crashes.
class MemoryService extends ChangeNotifier {
  final Logger _logger = Logger();

  // Memory thresholds (in MB)
  static const int warningThreshold = 512; // Warn at 512MB
  static const int criticalThreshold = 768; // Critical at 768MB

  int _currentMemoryMB = 0;
  int _peakMemoryMB = 0;
  bool _isLowMemory = false;
  bool _isCriticalMemory = false;

  int get currentMemoryMB => _currentMemoryMB;
  int get peakMemoryMB => _peakMemoryMB;
  bool get isLowMemory => _isLowMemory;
  bool get isCriticalMemory => _isCriticalMemory;

  /// Get current app memory usage in MB
  Future<void> updateMemoryUsage() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Get current RSS (Resident Set Size) memory
        final ProcessResult result =
            await Process.run('cat', ['/proc/self/status']);
        final String output = result.stdout.toString();

        // Parse VmRSS (actual physical RAM used)
        final RegExp rssRegex = RegExp(r'VmRSS:\s+(\d+)\s+kB');
        final Match? match = rssRegex.firstMatch(output);

        if (match != null) {
          final int memoryKB = int.parse(match.group(1)!);
          _currentMemoryMB = (memoryKB / 1024).round();

          if (_currentMemoryMB > _peakMemoryMB) {
            _peakMemoryMB = _currentMemoryMB;
          }

          // Update memory status
          _isLowMemory = _currentMemoryMB >= warningThreshold;
          _isCriticalMemory = _currentMemoryMB >= criticalThreshold;

          if (_isCriticalMemory) {
            _logger.w(
                'CRITICAL memory usage: ${_currentMemoryMB}MB (peak: ${_peakMemoryMB}MB)');
          } else if (_isLowMemory) {
            _logger.w(
                'LOW memory warning: ${_currentMemoryMB}MB (peak: ${_peakMemoryMB}MB)');
          }

          notifyListeners();
        }
      }
    } catch (e) {
      _logger.e('Failed to read memory usage: $e');
    }
  }

  /// Get memory status as human-readable string
  String getMemoryStatus() {
    if (_isCriticalMemory) {
      return 'Critical: ${_currentMemoryMB}MB';
    } else if (_isLowMemory) {
      return 'Low: ${_currentMemoryMB}MB';
    } else {
      return 'Normal: ${_currentMemoryMB}MB';
    }
  }

  /// Check if there's enough memory to load a model
  bool hasEnoughMemoryForModel(int modelSizeMB) {
    final int projectedUsage = _currentMemoryMB + modelSizeMB;
    return projectedUsage < criticalThreshold;
  }

  /// Log current memory state
  void logMemoryState(String context) {
    _logger.d(
        'Memory ($context): ${_currentMemoryMB}MB (peak: ${_peakMemoryMB}MB)');
  }

  /// Reset peak memory counter
  void resetPeak() {
    _peakMemoryMB = _currentMemoryMB;
    notifyListeners();
  }
}
