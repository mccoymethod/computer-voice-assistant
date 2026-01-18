import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

/// Speech-to-Text service using Sherpa-ONNX streaming ASR
///
/// Converts speech to text in real-time using the Zipformer model.
/// All processing is done on-device for privacy.
class SttService {
  final Logger _logger = Logger();

  OnlineRecognizer? _recognizer;
  OnlineStream? _stream;
  bool _isInitialized = false;

  /// Callback for partial (in-progress) recognition results
  Function(String)? onPartialResult;

  /// Callback for final recognition results
  Function(String)? onFinalResult;

  /// Initialize the STT service with the Zipformer model
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('STT already initialized');
      return;
    }

    try {
      _logger.i('Initializing STT service...');

      // Get model paths
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = '${appDir.path}/models/stt';

      // Copy models from assets if needed
      await _ensureModelsExist(modelDir);

      // Create recognizer configuration
      final config = OnlineRecognizerConfig(
        model: OnlineModelConfig(
          transducer: OnlineTransducerModelConfig(
            encoder: '$modelDir/encoder-epoch-99-avg-1.onnx',
            decoder: '$modelDir/decoder-epoch-99-avg-1.onnx',
            joiner: '$modelDir/joiner-epoch-99-avg-1.onnx',
          ),
          tokens: '$modelDir/tokens.txt',
          numThreads: 1,
          provider: 'cpu',
          debug: false,
          modelType: '',
        ),
        feat: FeatureConfig(
          sampleRate: 16000,
          featureDim: 80,
        ),
        enableEndpoint: true,
        rule1MinTrailingSilence: 2.4,
        rule2MinTrailingSilence: 1.2,
        rule3MinUtteranceLength: 20.0,
      );

      // Create the recognizer
      _recognizer = OnlineRecognizer(config);

      // Create a stream for this recognizer
      _stream = _recognizer!.createStream();

      _isInitialized = true;
      _logger.i('✓ STT service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize STT service: $e');
      rethrow;
    }
  }

  /// Ensure all STT models exist in the file system
  Future<void> _ensureModelsExist(String modelDir) async {
    final directory = Directory(modelDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // List of model files to copy
    final modelFiles = [
      'encoder-epoch-99-avg-1.onnx',
      'decoder-epoch-99-avg-1.onnx',
      'joiner-epoch-99-avg-1.onnx',
      'tokens.txt',
    ];

    for (final filename in modelFiles) {
      final destPath = '$modelDir/$filename';
      final destFile = File(destPath);

      if (!await destFile.exists()) {
        _logger.i('Copying $filename...');
        final data = await rootBundle.load('assets/models/stt/$filename');
        await destFile.writeAsBytes(data.buffer.asUint8List());
      }
    }

    _logger.i('STT models ready at: $modelDir');
  }

  /// Process audio samples for speech recognition
  ///
  /// [samples] - Audio samples as Float32List (16kHz, mono)
  /// This should be called continuously with new audio data
  void processAudio(Float32List samples) {
    if (!_isInitialized || _stream == null) {
      throw Exception('STT not initialized. Call initialize() first.');
    }

    try {
      // Accept audio samples
      _stream!.acceptWaveform(
        sampleRate: 16000,
        samples: samples,
      );

      // Decode the stream
      if (_recognizer != null) {
        _recognizer!.decode(_stream!);
      }

      // Get recognition results
      final result = _recognizer!.getResult(_stream!);

      if (result.text.isNotEmpty) {
        // Check if this is a final result (endpoint detected)
        if (_recognizer!.isEndpoint(_stream!)) {
          _logger.d('Final result: ${result.text}');
          onFinalResult?.call(result.text);

          // Reset the stream for next utterance
          _recognizer!.reset(_stream!);
        } else {
          // Partial result (still recognizing)
          _logger.d('Partial result: ${result.text}');
          onPartialResult?.call(result.text);
        }
      }
    } catch (e) {
      _logger.e('Error processing audio: $e');
    }
  }

  /// Signal that input has finished (end of speech)
  void inputFinished() {
    if (_stream != null && _recognizer != null) {
      _stream!.inputFinished();

      // Decode remaining audio
      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
      }

      // Get final result
      final result = _recognizer!.getResult(_stream!);
      if (result.text.isNotEmpty) {
        _logger.i('Final result: ${result.text}');
        onFinalResult?.call(result.text);
      }
    }
  }

  /// Get the current recognition result
  String getCurrentResult() {
    if (!_isInitialized || _recognizer == null || _stream == null) {
      return '';
    }

    final result = _recognizer!.getResult(_stream!);
    return result.text;
  }

  /// Reset the recognizer for a new utterance
  void reset() {
    if (_recognizer != null && _stream != null) {
      _recognizer!.reset(_stream!);
      _logger.d('STT stream reset');
    }
  }

  /// Clean up resources
  void dispose() {
    if (_stream != null) {
      _stream!.free();
      _stream = null;
    }
    if (_recognizer != null) {
      _recognizer!.free();
      _recognizer = null;
    }
    _isInitialized = false;
    _logger.i('STT service disposed');
  }

  /// Check if STT is initialized
  bool get isInitialized => _isInitialized;
}
