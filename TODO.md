# Implementation TODO & Next Steps

This document outlines what remains to be implemented and provides guidance for completing the voice assistant.

## Current Status

### ✅ Completed
- [x] Project structure and architecture
- [x] LLM service abstraction and implementations (Claude, OpenAI, Gemini)
- [x] Offline queue system with SQLite
- [x] Settings provider with persistence
- [x] Main assistant state management
- [x] Basic UI (home screen, settings screen)
- [x] Conversation model and message handling

### 🔲 TODO: Voice Components

These require integration with Sherpa-ONNX native libraries:

## 1. Wake Word Detection Service

**File to create:** `lib/services/wake_word_service.dart`

```dart
// Pseudocode - needs Sherpa-ONNX keyword spotting integration
import 'package:sherpa_onnx/sherpa_onnx.dart';

class WakeWordService {
  // Load the custom "Computer" keyword model
  // Listen continuously when app is open
  // Emit events when wake word detected
  
  Stream<void> get onWakeWordDetected;
  
  Future<void> startListening();
  Future<void> stopListening();
  void setSensitivity(double value);
}
```

**Resources:**
- Sherpa-ONNX KWS examples: https://github.com/k2-fsa/sherpa-onnx/tree/master/flutter-examples/keyword-spotter
- Train custom wake word with openWakeWord: https://github.com/dscripka/openWakeWord

**Steps:**
1. Train a "Computer" wake word model using openWakeWord
2. Export to ONNX format
3. Place in assets/models/kws/
4. Use Sherpa-ONNX Flutter API to load and run the model
5. Set up audio stream from microphone
6. Process audio frames through the model
7. Emit events when confidence threshold exceeded

---

## 2. Speech-to-Text Service

**File to create:** `lib/services/stt_service.dart`

```dart
// Pseudocode - needs Sherpa-ONNX ASR integration
import 'package:sherpa_onnx/sherpa_onnx.dart';

class STTService {
  // Initialize with Whisper model
  // Stream audio to the model
  // Return transcribed text
  
  Future<void> initialize(String modelSize);
  Stream<String> startTranscription(); // Partial results
  Future<String> stopAndFinalize();    // Final result
  void dispose();
}
```

**Resources:**
- Sherpa-ONNX Flutter ASR examples: https://github.com/k2-fsa/sherpa-onnx/tree/master/flutter-examples/streaming_asr
- Whisper models: https://github.com/k2-fsa/sherpa-onnx/releases (search for "whisper")

**Steps:**
1. Download Whisper model files (encoder.onnx, decoder.onnx, tokens.txt)
2. Place in assets/models/whisper/
3. Initialize Sherpa-ONNX recognizer with Whisper config
4. Use `record` package to capture audio at 16kHz
5. Feed audio chunks to the recognizer
6. Use VAD (Voice Activity Detection) to know when user stopped speaking
7. Return final transcription

**Model recommendations:**
- `sherpa-onnx-whisper-tiny.en` - Fast, less accurate (~150MB)
- `sherpa-onnx-whisper-small.en` - Balanced (~500MB) **RECOMMENDED**
- `sherpa-onnx-whisper-medium.en` - Accurate, slow (~1.5GB)

---

## 3. Text-to-Speech Service

**File to create:** `lib/services/tts_service.dart`

```dart
// Pseudocode - needs Sherpa-ONNX TTS integration
import 'package:sherpa_onnx/sherpa_onnx.dart';
import 'package:just_audio/just_audio.dart';

class TTSService {
  // Initialize with Piper voice model
  // Convert text to audio
  // Play audio
  
  Future<void> initialize(String voiceModel);
  Future<void> speak(String text);
  void stop();
  void setRate(double rate);
  void dispose();
}
```

**Resources:**
- Sherpa-ONNX Flutter TTS examples: https://github.com/k2-fsa/sherpa-onnx/tree/master/flutter-examples/tts
- Piper voice samples: https://rhasspy.github.io/piper-samples/

**Steps:**
1. Download Piper voice model files (model.onnx, tokens.txt, espeak-ng-data/)
2. Place in assets/models/piper/
3. Initialize Sherpa-ONNX TTS with voice config
4. Convert text to audio samples using the model
5. Use `just_audio` to play the generated audio
6. Support interruption (stop mid-speech)

**Voice recommendations:**
- `en_US-amy-medium` - Clear female voice
- `en_US-lessac-medium` - Clear male voice
- `en_GB-alan-medium` - British male voice

---

## 4. Audio Service Integration

**File to create:** `lib/services/audio_service.dart`

```dart
class AudioService {
  // Coordinates audio capture and playback
  // Manages audio session to prevent conflicts
  // Handles permissions
  
  Future<void> initialize();
  Future<bool> requestMicrophonePermission();
  Stream<List<int>> get audioStream; // For wake word and STT
  Future<void> playAudio(List<int> samples); // For TTS output
}
```

---

## 5. Model Download Manager

**File to create:** `lib/services/model_manager.dart`

Models are large (100MB-1GB) and should be downloaded on first run, not bundled:

```dart
class ModelManager {
  // Download models from GitHub releases
  // Show progress UI
  // Verify checksums
  // Store in app documents directory
  
  Future<bool> areModelsDownloaded();
  Stream<double> downloadModels(); // Progress 0.0 - 1.0
  String getModelPath(String modelName);
}
```

---

## Integration Points

### In AssistantProvider

Add these service dependencies:

```dart
class AssistantProvider extends ChangeNotifier {
  final WakeWordService _wakeWordService;
  final STTService _sttService;
  final TTSService _ttsService;
  
  // Initialize services
  Future<void> initialize() async {
    await _wakeWordService.startListening();
    
    _wakeWordService.onWakeWordDetected.listen((_) {
      onWakeWordDetected();
      _startListening();
    });
  }
  
  Future<void> _startListening() async {
    _setState(AssistantState.listening);
    
    // Start STT
    _sttService.startTranscription().listen((partial) {
      onSpeechResult(partial);
    });
  }
  
  Future<void> _speakResponse(String text) async {
    _setState(AssistantState.speaking);
    await _ttsService.speak(text);
    _setState(AssistantState.idle);
  }
}
```

---

## Testing Without Voice

The current implementation supports text input for testing the LLM integration:

1. Run the app
2. Configure an API key in Settings
3. Type a message in the text field
4. Press send

This lets you verify LLM communication works before implementing voice.

---

## Recommended Development Order

1. **Text-based testing** (current) - Verify LLM APIs work
2. **TTS first** - Implement speech output (easier than input)
3. **STT next** - Implement speech recognition
4. **Wake word last** - Implement always-listening activation
5. **Polish** - Add model downloading, error handling, UI refinements

---

## Helpful Resources

### Sherpa-ONNX Flutter
- Main repo: https://github.com/k2-fsa/sherpa-onnx
- Flutter examples: https://github.com/k2-fsa/sherpa-onnx/tree/master/flutter-examples
- pub.dev: https://pub.dev/packages/sherpa_onnx

### OpenWakeWord
- Main repo: https://github.com/dscripka/openWakeWord
- Training notebook: https://colab.research.google.com/github/dscripka/openWakeWord/blob/main/notebooks/automatic_model_training.ipynb

### Audio in Flutter
- record package: https://pub.dev/packages/record
- just_audio: https://pub.dev/packages/just_audio
- audio_session: https://pub.dev/packages/audio_session

---

## Potential Challenges

1. **Memory usage** - Large models may cause OOM on older devices. Monitor memory and consider model size options.

2. **Audio routing** - Android audio can be tricky. Use `audio_session` to manage focus.

3. **Background listening** - Android kills background services. The app must be in foreground for wake word detection.

4. **Model loading time** - First load can take several seconds. Show loading UI.

5. **Latency** - End-to-end delay (wake word → response spoken) should ideally be <5 seconds. Profile and optimize.
