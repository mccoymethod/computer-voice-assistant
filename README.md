# Computer Voice Assistant for Android

A Star Trek-inspired voice assistant that responds to "Computer" wake word, uses local speech-to-text (Whisper via Sherpa-ONNX), connects to various LLM APIs (Claude, GPT, Gemini), and speaks responses using local TTS.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLUTTER APP                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐                                          │
│  │ Wake Word Engine │  ◄── Sherpa-ONNX Keyword Spotting        │
│  │ "Computer"       │      (local, low power)                  │
│  └────────┬─────────┘                                          │
│           │ Wake word detected                                  │
│           ▼                                                     │
│  ┌──────────────────┐                                          │
│  │   Audio Capture  │  ◄── record package + VAD                │
│  │   + VAD          │      (Voice Activity Detection)          │
│  └────────┬─────────┘                                          │
│           │                                                     │
│           ▼                                                     │
│  ┌──────────────────┐                                          │
│  │  Whisper STT     │  ◄── Sherpa-ONNX (local, ~1-3 sec)       │
│  │  (Local)         │                                          │
│  └────────┬─────────┘                                          │
│           │ Transcribed text                                    │
│           ▼                                                     │
│  ┌──────────────────┐      ┌─────────────────────────────┐     │
│  │  LLM Service     │ ───► │ Claude / GPT / Gemini API   │     │
│  │  (Abstracted)    │ ◄─── │ (with offline queue)        │     │
│  └────────┬─────────┘      └─────────────────────────────┘     │
│           │ Response text                                       │
│           ▼                                                     │
│  ┌──────────────────┐                                          │
│  │   TTS Engine     │  ◄── Sherpa-ONNX Piper TTS (local)       │
│  └────────┬─────────┘                                          │
│           │                                                     │
│           ▼                                                     │
│  ┌──────────────────┐                                          │
│  │   Audio Output   │                                          │
│  └──────────────────┘                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
computer_assistant/
├── android/                      # Android-specific config
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # App widget & routing
│   │
│   ├── config/
│   │   ├── app_config.dart       # App-wide configuration
│   │   └── llm_config.dart       # LLM API configurations
│   │
│   ├── models/
│   │   ├── conversation.dart     # Conversation/message models
│   │   ├── llm_provider.dart     # LLM provider enum & config
│   │   └── queued_request.dart   # Offline queue model
│   │
│   ├── services/
│   │   ├── wake_word_service.dart    # Wake word detection
│   │   ├── stt_service.dart          # Speech-to-text (Whisper)
│   │   ├── tts_service.dart          # Text-to-speech (Piper)
│   │   ├── llm/
│   │   │   ├── llm_service.dart      # Abstract LLM interface
│   │   │   ├── claude_service.dart   # Claude API implementation
│   │   │   ├── openai_service.dart   # OpenAI API implementation
│   │   │   └── gemini_service.dart   # Gemini API implementation
│   │   ├── queue_service.dart        # Offline request queue
│   │   └── audio_service.dart        # Audio capture/playback
│   │
│   ├── providers/
│   │   ├── assistant_provider.dart   # Main state management
│   │   └── settings_provider.dart    # User settings
│   │
│   ├── screens/
│   │   ├── home_screen.dart          # Main assistant screen
│   │   ├── settings_screen.dart      # Settings UI
│   │   └── conversation_screen.dart  # Chat history view
│   │
│   ├── widgets/
│   │   ├── listening_indicator.dart  # Visual feedback
│   │   ├── waveform_visualizer.dart  # Audio visualization
│   │   └── status_card.dart          # Status display
│   │
│   └── utils/
│       ├── logger.dart               # Logging utility
│       └── connectivity.dart         # Network status
│
├── assets/
│   └── models/                   # ML models (downloaded on first run)
│       ├── whisper/              # STT model
│       ├── piper/                # TTS model
│       └── kws/                  # Keyword spotting model
│
├── pubspec.yaml
└── README.md
```

## Setup Instructions

### Prerequisites

1. Flutter SDK 3.16+ installed
2. Android Studio with Android SDK
3. A physical Android device (emulator won't work well for audio)
4. API keys for at least one LLM provider

### Step 1: Create the Flutter Project

```bash
flutter create computer_assistant
cd computer_assistant
```

### Step 2: Replace pubspec.yaml

Copy the `pubspec.yaml` from this project scaffold.

### Step 3: Download Models

Models are large and should NOT be bundled with the app. Instead, download them on first launch. Recommended models for mid-range phones:

**Speech-to-Text (Whisper):**
- Model: `sherpa-onnx-whisper-small.en` (~500MB) 
- Alternative for slower phones: `sherpa-onnx-whisper-tiny.en` (~150MB)
- Download from: https://github.com/k2-fsa/sherpa-onnx/releases

**Text-to-Speech (Piper):**
- Model: `en_US-amy-medium` (~100MB) - Good quality female voice
- Alternative: `en_US-lessac-medium` (~100MB) - Clear male voice
- Download from: https://github.com/rhasspy/piper/releases

**Keyword Spotting:**
- You'll need to train a custom "Computer" model using openWakeWord
- See: https://github.com/dscripka/openWakeWord

### Step 4: Configure API Keys

Create a `.env` file (DO NOT commit to git):

```
ANTHROPIC_API_KEY=sk-ant-xxxxx
OPENAI_API_KEY=sk-xxxxx
GOOGLE_AI_API_KEY=xxxxx
```

### Step 5: Android Configuration

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

### Step 6: Build and Run

```bash
flutter pub get
flutter run
```

## Model Selection Guide for Mid-Range Phones

| Component | Model | Size | RAM Usage | Speed |
|-----------|-------|------|-----------|-------|
| STT | whisper-small.en | ~500MB | ~600MB | ~2-3s |
| STT (lite) | whisper-tiny.en | ~150MB | ~200MB | ~1s |
| TTS | piper amy-medium | ~100MB | ~150MB | <0.5s |
| KWS | openWakeWord custom | ~5MB | ~20MB | real-time |

**Total on-device storage:** ~600-800MB
**Runtime RAM:** ~800MB-1GB

## Offline Queue System

When the device loses internet connectivity, requests are automatically queued to a local SQLite database. When connectivity returns, queued requests are processed in order. You can:

- View pending requests in the UI
- Cancel pending requests
- See request history

## LLM Provider Switching

The app supports multiple LLM providers. You can switch between them:

1. **Claude (Anthropic)** - Your paid option, best for complex tasks
2. **GPT-4o-mini (OpenAI)** - Good balance of cost/performance
3. **Gemini Flash (Google)** - Free tier available, fast responses

Configure default provider and per-task routing in Settings.

## Training Custom Wake Word

To train "Computer" as your wake word:

1. Go to https://github.com/dscripka/openWakeWord
2. Use their Google Colab notebook
3. Enter "Computer" as your target phrase
4. Generate synthetic training data
5. Train for ~1 hour
6. Export the .onnx model
7. Place in `assets/models/kws/computer.onnx`

## Troubleshooting

### "Model not found" error
Models must be downloaded separately. Run the app once to trigger the download dialog, or manually download from the links above.

### Poor wake word detection
Adjust the sensitivity threshold in Settings. Lower = more sensitive (more false positives), Higher = less sensitive (may miss wake words).

### Slow transcription
Switch to whisper-tiny.en model in Settings. Accuracy is slightly lower but speed is much better.

### Audio playback issues
Ensure no other apps are using audio. Try restarting the app.

## License

MIT License - Use freely for personal projects.

## Credits

- Sherpa-ONNX by k2-fsa
- OpenAI Whisper
- Piper TTS by rhasspy
- openWakeWord by dscripka
