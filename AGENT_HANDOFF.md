# Agent Handoff Summary: "Computer" Voice Assistant Project

## Date: January 17, 2026

---

## Project Goal

Build a custom Android voice assistant app in Flutter that:
1. Responds to the wake word **"Computer"** (Star Trek inspired, not "Hey Siri" or "Hey Google")
2. Uses **locally-hosted Whisper** for speech-to-text (privacy, no cloud STT)
3. Sends transcribed text to **LLM APIs** (Claude, GPT, Gemini - user's choice)
4. Uses **local TTS** (Piper via Sherpa-ONNX) to speak responses
5. Supports **offline queuing** - requests made without internet are saved and sent when connectivity returns

---

## User Profile

- **Experience Level**: Junior Flutter/Dart developer
- **Target Platform**: Android only (for now)
- **Device Target**: Mid-range phones, 2+ years old should work
- **Budget**: Free where possible, but has paid Claude subscription
- **Preferences**: Verbose explanations, accuracy over speed, blunt feedback

---

## Key Technical Decisions Made

| Component | Choice | Rationale |
|-----------|--------|-----------|
| **Framework** | Flutter/Dart | User's preference and growing skill |
| **Wake Word** | openWakeWord + custom "Computer" model | Open source, trainable in ~1 hour via Colab |
| **Speech-to-Text** | Sherpa-ONNX with Whisper small.en | Local/private, good accuracy/speed balance for mobile |
| **Text-to-Speech** | Sherpa-ONNX with Piper voices | Local, fast, decent quality |
| **LLM Integration** | Abstracted service supporting Claude/OpenAI/Gemini | User wants to swap between providers |
| **Offline Support** | SQLite queue with auto-retry | User specifically requested this feature |
| **State Management** | Provider package | Simple, appropriate for junior dev |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLUTTER APP                                 │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐                                          │
│  │ Wake Word Engine │  ◄── openWakeWord/Sherpa-ONNX KWS        │
│  │ "Computer"       │      (local, always listening when open) │
│  └────────┬─────────┘                                          │
│           │ Wake word detected                                  │
│           ▼                                                     │
│  ┌──────────────────┐                                          │
│  │   Audio Capture  │  ◄── record package + VAD                │
│  │   + VAD          │                                          │
│  └────────┬─────────┘                                          │
│           ▼                                                     │
│  ┌──────────────────┐                                          │
│  │  Whisper STT     │  ◄── Sherpa-ONNX (local)                 │
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
│  │   Piper TTS      │  ◄── Sherpa-ONNX (local)                 │
│  └────────┬─────────┘                                          │
│           ▼                                                     │
│  ┌──────────────────┐                                          │
│  │   Audio Output   │                                          │
│  └──────────────────┘                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## What Has Been Implemented

A complete Flutter project scaffold was created with these working components:

### ✅ Fully Implemented
1. **LLM Services** (`lib/services/llm/`)
   - `llm_service.dart` - Abstract interface and response models
   - `claude_service.dart` - Anthropic Claude API (Messages API)
   - `openai_service.dart` - OpenAI Chat Completions API
   - `gemini_service.dart` - Google Gemini API
   - All include error handling, token tracking, latency measurement

2. **Offline Queue** (`lib/services/queue_service.dart`)
   - SQLite-based persistent queue
   - Auto-processes when connectivity returns
   - Retry logic (3 attempts before marking failed)
   - User can view/cancel pending requests

3. **Models** (`lib/models/`)
   - `llm_provider.dart` - Provider enum, model configs with pricing
   - `conversation.dart` - Message and Conversation models with serialization
   - `queued_request.dart` - Offline queue request model

4. **State Management** (`lib/providers/`)
   - `settings_provider.dart` - Hive-based persistent settings
   - `assistant_provider.dart` - Main coordinator (state machine for assistant states)

5. **UI** (`lib/screens/`)
   - `home_screen.dart` - Main screen with conversation display, text input, state visualization
   - `settings_screen.dart` - Full settings UI (theme, provider, API keys, voice settings)
   - `conversation_screen.dart` - Placeholder for history

6. **Configuration**
   - `pubspec.yaml` - All dependencies declared
   - `.env.example` - Template for API keys
   - `.gitignore` - Proper exclusions
   - `README.md` - Setup instructions
   - `TODO.md` - Detailed implementation guide for remaining work

### 🔲 NOT Yet Implemented (Voice Components)

These require native Sherpa-ONNX integration:

1. **Wake Word Service** - Needs Sherpa-ONNX keyword spotting + custom trained model
2. **STT Service** - Needs Sherpa-ONNX Whisper integration
3. **TTS Service** - Needs Sherpa-ONNX Piper integration
4. **Audio Service** - Microphone capture and audio playback coordination
5. **Model Manager** - Download large models on first run (not bundled)

---

## Project File Structure

```
computer_assistant/
├── .env.example              # API key template
├── .gitignore
├── README.md                 # Setup guide
├── TODO.md                   # Implementation guide for voice components
├── pubspec.yaml              # Dependencies
├── assets/
│   └── models/
│       └── README.md         # Model download instructions
└── lib/
    ├── main.dart             # Entry point
    ├── app.dart              # App widget, theming, routing
    ├── models/
    │   ├── conversation.dart
    │   ├── llm_provider.dart
    │   └── queued_request.dart
    ├── providers/
    │   ├── assistant_provider.dart
    │   └── settings_provider.dart
    ├── screens/
    │   ├── home_screen.dart
    │   ├── settings_screen.dart
    │   └── conversation_screen.dart
    └── services/
        ├── queue_service.dart
        └── llm/
            ├── llm_service.dart
            ├── claude_service.dart
            ├── openai_service.dart
            └── gemini_service.dart
```

---

## Key Dependencies (from pubspec.yaml)

```yaml
# Core voice (not yet integrated)
sherpa_onnx: ^1.10.40
sherpa_onnx_android: ^1.10.40

# Audio
record: ^5.1.0
just_audio: ^0.9.39
audio_session: ^0.1.21

# State & Storage
provider: ^6.1.2
sqflite: ^2.3.3+1
hive: ^2.2.3
hive_flutter: ^1.1.0

# Networking
http: ^1.2.2
dio: ^5.4.3+1
connectivity_plus: ^6.0.3

# Config
flutter_dotenv: ^5.1.0
permission_handler: ^11.3.1
```

---

## Models Needed (Must Download Separately)

| Model | Size | Purpose | Download From |
|-------|------|---------|---------------|
| whisper-small.en | ~500MB | Speech-to-text | Sherpa-ONNX releases |
| whisper-tiny.en | ~150MB | STT (faster, less accurate) | Sherpa-ONNX releases |
| en_US-amy-medium | ~100MB | TTS voice | Piper releases |
| computer.onnx | ~5MB | Wake word | Train with openWakeWord |

---

## Important Resources

### Sherpa-ONNX (STT, TTS, KWS)
- Main repo: https://github.com/k2-fsa/sherpa-onnx
- Flutter examples: https://github.com/k2-fsa/sherpa-onnx/tree/master/flutter-examples
- Flutter package: https://pub.dev/packages/sherpa_onnx
- Model downloads: https://github.com/k2-fsa/sherpa-onnx/releases

### openWakeWord (Custom Wake Word Training)
- Repo: https://github.com/dscripka/openWakeWord
- Training Colab: https://colab.research.google.com/github/dscripka/openWakeWord/blob/main/notebooks/automatic_model_training.ipynb
- Android port exists: https://github.com/hasanatlodhi/OpenwakewordforAndroid

### Piper TTS
- Voice samples: https://rhasspy.github.io/piper-samples/
- Releases: https://github.com/rhasspy/piper/releases

---

## Recommended Next Steps

1. **Test current implementation** - Run app, configure API key, test text-based LLM chat
2. **Implement TTS first** - Follow Sherpa-ONNX Flutter TTS examples, integrate with Piper
3. **Implement STT** - Follow Sherpa-ONNX Flutter ASR examples, integrate Whisper
4. **Train wake word** - Use openWakeWord Colab to train "Computer" model (~1 hour)
5. **Implement wake word detection** - Integrate trained model with Sherpa-ONNX KWS
6. **Add model download manager** - Handle first-run model downloads gracefully
7. **Polish** - Error handling, loading states, latency optimization

---

## Constraints & Notes

- App only needs to work **while open** (no background wake word detection needed)
- Voice components run **on-device only** - privacy requirement
- LLM calls require internet, but offline queue handles temporary disconnection
- User wants ability to **swap LLM providers** based on task (Claude for complex, Gemini free tier for simple)
- Target latency: **<5 seconds** from wake word to spoken response

---

## Questions the User May Have

They understand the architecture but may need help with:
- Actual Sherpa-ONNX Flutter integration code
- Training the custom wake word
- Debugging audio issues on Android
- Optimizing model loading time
- Memory management with large models

---

*This summary was generated from a conversation on January 17, 2026. The project scaffold has been provided as a downloadable zip file.*
