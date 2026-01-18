# Models Directory

This directory contains ML models for:
- Wake word detection (keyword spotting)
- Speech-to-text (Whisper)
- Text-to-speech (Piper)

## Directory Structure

```
models/
├── kws/           # Keyword Spotting (Wake Word)
│   └── computer.onnx    # Custom "Computer" wake word model
├── whisper/       # Speech-to-Text
│   ├── encoder.onnx
│   ├── decoder.onnx
│   └── tokens.txt
└── piper/         # Text-to-Speech
    ├── model.onnx
    ├── tokens.txt
    └── espeak-ng-data/
```

## Downloading Models

Models are NOT included in the repository (too large).

### Wake Word Model
Train your own using openWakeWord:
https://github.com/dscripka/openWakeWord

### Whisper Models
Download from Sherpa-ONNX releases:
https://github.com/k2-fsa/sherpa-onnx/releases

Recommended: `sherpa-onnx-whisper-small.en`

### Piper TTS Models
Download from Piper releases:
https://github.com/rhasspy/piper/releases

Recommended: `en_US-amy-medium`
