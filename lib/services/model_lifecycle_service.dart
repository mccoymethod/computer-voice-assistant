import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'memory_service.dart';

/// Model size configurations
enum ModelSize {
  tiny, // ~150MB Whisper, fastest
  small, // ~500MB Whisper, balanced (default)
  medium, // ~1.5GB Whisper, most accurate
}

extension ModelSizeExtension on ModelSize {
  String get displayName {
    switch (this) {
      case ModelSize.tiny:
        return 'Tiny (Fast, Less Accurate)';
      case ModelSize.small:
        return 'Small (Balanced)';
      case ModelSize.medium:
        return 'Medium (Accurate, Slow)';
    }
  }

  /// Estimated RAM usage in MB
  int get estimatedRAM {
    switch (this) {
      case ModelSize.tiny:
        return 200;
      case ModelSize.small:
        return 600;
      case ModelSize.medium:
        return 1500;
    }
  }

  /// Recommended for device types
  String get recommendation {
    switch (this) {
      case ModelSize.tiny:
        return 'Recommended for older devices (2+ years old)';
      case ModelSize.small:
        return 'Recommended for most devices';
      case ModelSize.medium:
        return 'Recommended for flagship devices only';
    }
  }
}

/// Manages lifecycle of ML models (loading/unloading)
///
/// Handles:
/// - Loading models on demand
/// - Unloading models when not in use (if setting enabled)
/// - Memory tracking for loaded models
/// - Preventing OOM by checking memory before loading
class ModelLifecycleService extends ChangeNotifier {
  final MemoryService _memoryService;
  final Logger _logger = Logger();

  // Model state tracking
  bool _isWakeWordLoaded = false;
  bool _isSTTLoaded = false;
  bool _isTTSLoaded = false;

  bool get isWakeWordLoaded => _isWakeWordLoaded;
  bool get isSTTLoaded => _isSTTLoaded;
  bool get isTTSLoaded => _isTTSLoaded;
  bool get anyModelLoaded => _isWakeWordLoaded || _isSTTLoaded || _isTTSLoaded;

  ModelLifecycleService({required MemoryService memoryService})
      : _memoryService = memoryService;

  // ============================================
  // Wake Word Model
  // ============================================

  /// Load wake word detection model (~20MB)
  Future<void> loadWakeWordModel() async {
    if (_isWakeWordLoaded) {
      _logger.d('Wake word model already loaded');
      return;
    }

    await _memoryService.updateMemoryUsage();

    if (!_memoryService.hasEnoughMemoryForModel(20)) {
      throw ModelLoadException(
        'Not enough memory to load wake word model. '
        'Current: ${_memoryService.currentMemoryMB}MB',
      );
    }

    _logger.i('Loading wake word model...');
    _memoryService.logMemoryState('before wake word load');

    // TODO: Actual Sherpa-ONNX wake word model loading
    // await _sherpaOnnx.loadKeywordSpotter(...);

    _isWakeWordLoaded = true;
    await _memoryService.updateMemoryUsage();
    _memoryService.logMemoryState('after wake word load');

    _logger.i('Wake word model loaded successfully');
    notifyListeners();
  }

  /// Unload wake word model to free memory
  Future<void> unloadWakeWordModel() async {
    if (!_isWakeWordLoaded) return;

    _logger.i('Unloading wake word model...');
    _memoryService.logMemoryState('before wake word unload');

    // TODO: Actual model unloading
    // await _sherpaOnnx.releaseKeywordSpotter();

    _isWakeWordLoaded = false;
    await _memoryService.updateMemoryUsage();
    _memoryService.logMemoryState('after wake word unload');

    _logger.i('Wake word model unloaded');
    notifyListeners();
  }

  // ============================================
  // STT Model
  // ============================================

  /// Load speech-to-text model (size depends on ModelSize setting)
  Future<void> loadSTTModel(ModelSize size) async {
    if (_isSTTLoaded) {
      _logger.d('STT model already loaded');
      return;
    }

    await _memoryService.updateMemoryUsage();

    if (!_memoryService.hasEnoughMemoryForModel(size.estimatedRAM)) {
      throw ModelLoadException(
        'Not enough memory to load ${size.displayName} STT model. '
        'Current: ${_memoryService.currentMemoryMB}MB, '
        'Needed: ~${size.estimatedRAM}MB',
      );
    }

    _logger.i('Loading STT model (${size.displayName})...');
    _memoryService.logMemoryState('before STT load');

    // TODO: Actual Sherpa-ONNX Whisper model loading
    // await _sherpaOnnx.loadASR(modelSize: size);

    _isSTTLoaded = true;
    await _memoryService.updateMemoryUsage();
    _memoryService.logMemoryState('after STT load');

    _logger.i('STT model loaded successfully');
    notifyListeners();
  }

  /// Unload STT model to free memory
  Future<void> unloadSTTModel() async {
    if (!_isSTTLoaded) return;

    _logger.i('Unloading STT model...');
    _memoryService.logMemoryState('before STT unload');

    // TODO: Actual model unloading
    // await _sherpaOnnx.releaseASR();

    _isSTTLoaded = false;
    await _memoryService.updateMemoryUsage();
    _memoryService.logMemoryState('after STT unload');

    _logger.i('STT model unloaded');
    notifyListeners();
  }

  // ============================================
  // TTS Model
  // ============================================

  /// Load text-to-speech model (~150MB)
  Future<void> loadTTSModel() async {
    if (_isTTSLoaded) {
      _logger.d('TTS model already loaded');
      return;
    }

    await _memoryService.updateMemoryUsage();

    if (!_memoryService.hasEnoughMemoryForModel(150)) {
      throw ModelLoadException(
        'Not enough memory to load TTS model. '
        'Current: ${_memoryService.currentMemoryMB}MB',
      );
    }

    _logger.i('Loading TTS model...');
    _memoryService.logMemoryState('before TTS load');

    // TODO: Actual Sherpa-ONNX Piper TTS model loading
    // await _sherpaOnnx.loadTTS(...);

    _isTTSLoaded = true;
    await _memoryService.updateMemoryUsage();
    _memoryService.logMemoryState('after TTS load');

    _logger.i('TTS model loaded successfully');
    notifyListeners();
  }

  /// Unload TTS model to free memory
  Future<void> unloadTTSModel() async {
    if (!_isTTSLoaded) return;

    _logger.i('Unloading TTS model...');
    _memoryService.logMemoryState('before TTS unload');

    // TODO: Actual model unloading
    // await _sherpaOnnx.releaseTTS();

    _isTTSLoaded = false;
    await _memoryService.updateMemoryUsage();
    _memoryService.logMemoryState('after TTS unload');

    _logger.i('TTS model unloaded');
    notifyListeners();
  }

  // ============================================
  // Batch Operations
  // ============================================

  /// Unload all models to free maximum memory
  Future<void> unloadAllModels() async {
    _logger.i('Unloading all models...');

    await Future.wait([
      unloadWakeWordModel(),
      unloadSTTModel(),
      unloadTTSModel(),
    ]);

    _logger.i('All models unloaded');
  }

  /// Get total estimated memory usage of loaded models
  int getLoadedModelsMemoryMB() {
    int total = 0;
    if (_isWakeWordLoaded) total += 20;
    if (_isSTTLoaded) total += 600; // Assumes small model
    if (_isTTSLoaded) total += 150;
    return total;
  }
}

/// Exception thrown when model loading fails
class ModelLoadException implements Exception {
  final String message;

  ModelLoadException(this.message);

  @override
  String toString() => 'ModelLoadException: $message';
}
