import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

/// Voice Activity Detection service using Silero VAD
///
/// Detects speech vs silence in audio streams.
/// Uses Sherpa-ONNX's Silero VAD model for on-device processing.
class VadService {
  final Logger _logger = Logger();

  VoiceActivityDetector? _vad;
  bool _isInitialized = false;

  /// Initialize the VAD service with the Silero VAD model
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('VAD already initialized');
      return;
    }

    try {
      _logger.i('Initializing VAD service...');

      // Get the path to the VAD model
      final appDir = await getApplicationDocumentsDirectory();
      final modelPath = '${appDir.path}/models/vad/silero_vad.onnx';

      // Copy model from assets if needed
      await _ensureModelExists(modelPath);

      // Create VAD configuration
      final config = VadModelConfig(
        sileroVad: SileroVadModelConfig(
          model: modelPath,
          threshold: 0.5, // Speech detection threshold (0-1)
          minSilenceDuration: 0.5, // Min silence to end speech (seconds)
          minSpeechDuration: 0.25, // Min speech duration (seconds)
          windowSize: 512, // Analysis window size
          maxSpeechDuration: 10.0, // Max continuous speech (seconds)
        ),
        sampleRate: 16000, // 16kHz audio
        numThreads: 1, // Single thread for mobile
        provider: 'cpu', // CPU inference
        debug: false,
      );

      // Create the VAD detector with 30 seconds buffer
      _vad = VoiceActivityDetector(
        config: config,
        bufferSizeInSeconds: 30.0,
      );
      _isInitialized = true;

      _logger.i('✓ VAD service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize VAD service: $e');
      rethrow;
    }
  }

  /// Ensure the VAD model exists in the file system
  Future<void> _ensureModelExists(String modelPath) async {
    final file = await rootBundle.load('assets/models/vad/silero_vad.onnx');
    final bytes = file.buffer.asUint8List();

    // Write to file system
    final File modelFile = File(modelPath);
    await modelFile.create(recursive: true);
    await modelFile.writeAsBytes(bytes);

    _logger.i('VAD model copied to: $modelPath');
  }

  /// Process audio samples and detect speech
  ///
  /// [samples] - Audio samples as Float32List (16kHz, mono)
  /// Returns true if speech is detected in the audio
  bool detectSpeech(Float32List samples) {
    if (!_isInitialized || _vad == null) {
      throw Exception('VAD not initialized. Call initialize() first.');
    }

    try {
      // Accept samples into the VAD
      _vad!.acceptWaveform(samples);

      // Check if speech is detected
      final isSpeech = _vad!.isDetected();

      return isSpeech;
    } catch (e) {
      _logger.e('Error detecting speech: $e');
      return false;
    }
  }

  /// Check if speech segment is available
  bool get hasSegment {
    if (!_isInitialized || _vad == null) {
      return false;
    }
    return !_vad!.isEmpty();
  }

  /// Check if speech is currently detected
  bool get isDetected {
    if (!_isInitialized || _vad == null) {
      return false;
    }
    return _vad!.isDetected();
  }

  /// Get the next speech segment
  SpeechSegment? getSegment() {
    if (!_isInitialized || _vad == null || _vad!.isEmpty()) {
      return null;
    }
    final segment = _vad!.front();
    _vad!.pop();
    return segment;
  }

  /// Reset the VAD state
  void reset() {
    if (_vad != null) {
      _vad!.reset();
      _logger.d('VAD state reset');
    }
  }

  /// Flush any remaining audio
  void flush() {
    if (_vad != null) {
      _vad!.flush();
      _logger.d('VAD flushed');
    }
  }

  /// Clean up resources
  void dispose() {
    if (_vad != null) {
      _vad!.free();
      _vad = null;
    }
    _isInitialized = false;
    _logger.i('VAD service disposed');
  }

  /// Check if VAD is initialized
  bool get isInitialized => _isInitialized;
}
