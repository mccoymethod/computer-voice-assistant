import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

/// Text-to-Speech service using Sherpa-ONNX with Piper TTS
///
/// Converts text to natural-sounding speech using the Piper model.
/// All processing is done on-device for privacy.
class TtsService {
  final Logger _logger = Logger();

  OfflineTts? _tts;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  /// Initialize the TTS service with the Piper model
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('TTS already initialized');
      return;
    }

    try {
      _logger.i('Initializing TTS service...');

      // Get model paths
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = '${appDir.path}/models/tts';

      // Copy models from assets if needed
      await _ensureModelsExist(modelDir);

      // Create TTS configuration
      final config = OfflineTtsConfig(
        model: OfflineTtsModelConfig(
          vits: OfflineTtsVitsModelConfig(
            model: '$modelDir/en_US-amy-medium.onnx',
            lexicon: '',
            tokens: '$modelDir/tokens.txt',
            dataDir: '$modelDir/espeak-ng-data',
            noiseScale: 0.667,
            noiseScaleW: 0.8,
            lengthScale: 1.0,
          ),
          numThreads: 1,
          provider: 'cpu',
          debug: false,
        ),
        ruleFsts: '',
      );

      // Create the TTS engine
      _tts = OfflineTts(config);

      _isInitialized = true;
      _logger.i('✓ TTS service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize TTS service: $e');
      _logger.w(
          'TTS models may not be downloaded yet. Check assets/models/README.md');
      // Don't rethrow - allow app to continue without TTS
    }
  }

  /// Ensure all TTS models exist in the file system
  Future<void> _ensureModelsExist(String modelDir) async {
    final directory = Directory(modelDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Check if model exists
    final modelFile = File('$modelDir/en_US-amy-medium.onnx');
    if (!await modelFile.exists()) {
      _logger.w('TTS model not found. Please download manually.');
      _logger.w('See assets/models/README.md for instructions');
      throw Exception('TTS model not found');
    }

    _logger.i('TTS models ready at: $modelDir');
  }

  /// Convert text to speech and play it
  ///
  /// [text] - The text to speak
  /// [speakerId] - Voice ID (default: 0)
  /// [speed] - Speech speed (default: 1.0, range: 0.5-2.0)
  Future<void> speak(
    String text, {
    int speakerId = 0,
    double speed = 1.0,
  }) async {
    if (!_isInitialized || _tts == null) {
      _logger.w('TTS not initialized, skipping speech');
      return;
    }

    if (text.isEmpty) {
      _logger.w('Empty text, nothing to speak');
      return;
    }

    try {
      _logger.i('Speaking: $text');

      // Generate audio
      final audio = _tts!.generate(
        text: text,
        sid: speakerId,
        speed: speed,
      );

      if (audio.samples.isEmpty) {
        _logger.w('No audio generated');
        return;
      }

      // Save audio to temporary file
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/tts_output.wav';

      await _saveAsWav(
        audioPath,
        audio.samples,
        audio.sampleRate,
      );

      // Play the audio
      await _audioPlayer.setFilePath(audioPath);
      await _audioPlayer.play();

      // Wait for playback to finish
      await _audioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );

      _logger.i('✓ Speech completed');
    } catch (e) {
      _logger.e('Error during TTS: $e');
    }
  }

  /// Save audio samples as WAV file
  Future<void> _saveAsWav(
    String path,
    Float32List samples,
    int sampleRate,
  ) async {
    final file = File(path);

    // Convert Float32 to Int16
    final int16Samples = Int16List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      int16Samples[i] = (samples[i] * 32767).round().clamp(-32768, 32767);
    }

    // Create WAV header
    final numChannels = 1;
    final bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = int16Samples.length * 2;
    final fileSize = 36 + dataSize;

    final buffer = BytesBuilder();

    // RIFF header
    buffer.add('RIFF'.codeUnits);
    buffer.add(_intToBytes(fileSize, 4));
    buffer.add('WAVE'.codeUnits);

    // fmt chunk
    buffer.add('fmt '.codeUnits);
    buffer.add(_intToBytes(16, 4)); // fmt chunk size
    buffer.add(_intToBytes(1, 2)); // PCM format
    buffer.add(_intToBytes(numChannels, 2));
    buffer.add(_intToBytes(sampleRate, 4));
    buffer.add(_intToBytes(byteRate, 4));
    buffer.add(_intToBytes(blockAlign, 2));
    buffer.add(_intToBytes(bitsPerSample, 2));

    // data chunk
    buffer.add('data'.codeUnits);
    buffer.add(_intToBytes(dataSize, 4));

    // Audio data
    for (final sample in int16Samples) {
      buffer.add(_intToBytes(sample, 2));
    }

    await file.writeAsBytes(buffer.toBytes());
  }

  /// Convert integer to little-endian bytes
  List<int> _intToBytes(int value, int numBytes) {
    final bytes = <int>[];
    for (int i = 0; i < numBytes; i++) {
      bytes.add((value >> (i * 8)) & 0xFF);
    }
    return bytes;
  }

  /// Stop current speech
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  /// Check if currently speaking
  bool get isSpeaking => _audioPlayer.playing;

  /// Clean up resources
  void dispose() {
    _audioPlayer.dispose();
    if (_tts != null) {
      _tts!.free();
      _tts = null;
    }
    _isInitialized = false;
    _logger.i('TTS service disposed');
  }

  /// Check if TTS is initialized
  bool get isInitialized => _isInitialized;
}
