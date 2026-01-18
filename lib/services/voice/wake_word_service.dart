import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

/// Wake Word Detection service for "Computer"
///
/// Continuously monitors audio for the wake word "Computer".
/// Uses Sherpa-ONNX keyword spotting for on-device detection.
class WakeWordService {
  final Logger _logger = Logger();

  KeywordSpotter? _spotter;
  OnlineStream? _stream;
  bool _isInitialized = false;

  /// Callback when wake word is detected
  Function(String)? onWakeWordDetected;

  /// Initialize the wake word service
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('Wake word service already initialized');
      return;
    }

    try {
      _logger.i('Initializing wake word service...');

      // Get model paths
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = '${appDir.path}/models/kws';

      // Copy models from assets if needed
      await _ensureModelsExist(modelDir);

      // Create keyword spotter configuration
      final config = KeywordSpotterConfig(
        feat: FeatureConfig(
          sampleRate: 16000,
          featureDim: 80,
        ),
        model: OnlineModelConfig(
          transducer: OnlineTransducerModelConfig(
            encoder: '$modelDir/encoder-epoch-12-avg-2-chunk-16-left-64.onnx',
            decoder: '$modelDir/decoder-epoch-12-avg-2-chunk-16-left-64.onnx',
            joiner: '$modelDir/joiner-epoch-12-avg-2-chunk-16-left-64.onnx',
          ),
          tokens: '$modelDir/tokens.txt',
          numThreads: 1,
          provider: 'cpu',
          debug: false,
          modelType: '',
        ),
        keywordsFile: '$modelDir/keywords.txt',
        maxActivePaths: 4,
        numTrailingBlanks: 1,
        keywordsScore: 1.0,
        keywordsThreshold: 0.25,
      );

      // Create the keyword spotter
      _spotter = KeywordSpotter(config);

      // Create a stream
      _stream = _spotter!.createStream();

      _isInitialized = true;
      _logger.i('✓ Wake word service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize wake word service: $e');
      _logger.w(
          'KWS models may not be downloaded yet. Check assets/models/README.md');
      // Don't rethrow - allow app to continue without wake word
    }
  }

  /// Ensure all wake word models exist in the file system
  Future<void> _ensureModelsExist(String modelDir) async {
    final directory = Directory(modelDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Check if models exist (they should be downloaded by the script)
    final encoderFile =
        File('$modelDir/encoder-epoch-12-avg-2-chunk-16-left-64.onnx');
    if (!await encoderFile.exists()) {
      _logger.w('KWS models not found. Please run download_models.sh');
      throw Exception('KWS models not found');
    }

    // Ensure keywords.txt contains "computer"
    final keywordsFile = File('$modelDir/keywords.txt');
    if (!await keywordsFile.exists()) {
      await keywordsFile.writeAsString('computer\n');
      _logger.i('Created keywords.txt with "computer"');
    }

    _logger.i('Wake word models ready at: $modelDir');
  }

  /// Process audio samples for wake word detection
  ///
  /// [samples] - Audio samples as Float32List (16kHz, mono)
  /// Returns true if wake word is detected
  bool processAudio(Float32List samples) {
    if (!_isInitialized || _spotter == null || _stream == null) {
      return false;
    }

    try {
      // Accept audio samples
      _stream!.acceptWaveform(
        sampleRate: 16000,
        samples: samples,
      );

      // Decode the stream
      if (_spotter!.isReady(_stream!)) {
        _spotter!.decode(_stream!);
      }

      // Check for keyword detection
      final result = _spotter!.getResult(_stream!);

      if (result.keyword.isNotEmpty) {
        _logger.i('✓ Wake word detected: ${result.keyword}');
        onWakeWordDetected?.call(result.keyword);
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Error processing audio for wake word: $e');
      return false;
    }
  }

  /// Reset the wake word detector
  void reset() {
    if (_spotter != null && _stream != null) {
      // Create a new stream
      _stream?.free();
      _stream = _spotter!.createStream();
      _logger.d('Wake word service reset');
    }
  }

  /// Clean up resources
  void dispose() {
    if (_stream != null) {
      _stream!.free();
      _stream = null;
    }
    if (_spotter != null) {
      _spotter!.free();
      _spotter = null;
    }
    _isInitialized = false;
    _logger.i('Wake word service disposed');
  }

  /// Check if wake word service is initialized
  bool get isInitialized => _isInitialized;
}
