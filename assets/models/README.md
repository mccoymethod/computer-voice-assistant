# Voice Models for Computer Assistant

This directory contains AI models for on-device voice processing using Sherpa-ONNX.

## Directory Structure

```
models/
├── vad/           # Voice Activity Detection
│   └── silero_vad.onnx
├── stt/           # Speech-to-Text (Streaming Zipformer)
│   ├── encoder-epoch-99-avg-1.onnx
│   ├── decoder-epoch-99-avg-1.onnx
│   ├── joiner-epoch-99-avg-1.onnx
│   └── tokens.txt
├── tts/           # Text-to-Speech (Piper)
│   ├── en_US-amy-medium.onnx
│   ├── tokens.txt
│   └── espeak-ng-data/
└── kws/           # Keyword Spotting (Wake Word)
    ├── encoder-epoch-12-avg-2-chunk-16-left-64.onnx
    ├── decoder-epoch-12-avg-2-chunk-16-left-64.onnx
    ├── joiner-epoch-12-avg-2-chunk-16-left-64.onnx
    ├── tokens.txt
    └── keywords.txt (contains: "computer")
```

## Quick Download Script

Save this as `download_models.sh` in this directory and run it:

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "===== Downloading Sherpa-ONNX Models ====="

# 1. VAD Model (~2MB)
echo "[1/4] Downloading VAD model..."
cd vad/
curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx
cd ..

# 2. STT Model (~20MB)
echo "[2/4] Downloading STT model..."
cd stt/
curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17.tar.bz2
tar -xjf sherpa-onnx-streaming-zipformer-en-20M-2023-02-17.tar.bz2
mv sherpa-onnx-streaming-zipformer-en-20M-2023-02-17/* .
rm -rf sherpa-onnx-streaming-zipformer-en-20M-2023-02-17 *.tar.bz2
cd ..

# 3. TTS Model (~10MB)
echo "[3/4] Downloading TTS model..."
cd tts/
curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-amy-medium.tar.bz2
tar -xjf vits-piper-en_US-amy-medium.tar.bz2
mv vits-piper-en_US-amy-medium/* .
rm -rf vits-piper-en_US-amy-medium *.tar.bz2
cd ..

# 4. KWS Model (~3MB)
echo "[4/4] Downloading KWS model..."
cd kws/
curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/kws-models/sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01.tar.bz2
tar -xjf sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01.tar.bz2
mv sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01/* .
echo "computer" > keywords.txt
rm -rf sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01 *.tar.bz2
cd ..

echo ""
echo "===== All models downloaded successfully! ====="
echo "Total size: ~35MB"
```

Run with:
```bash
chmod +x download_models.sh
./download_models.sh
```

## Manual Download Instructions

### 1. VAD (Voice Activity Detection) - 2MB
```bash
cd vad/
curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx
```

### 2. STT (Speech-to-Text) - 20MB
```bash
cd stt/
curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17.tar.bz2
tar -xjf sherpa-onnx-streaming-zipformer-en-20M-2023-02-17.tar.bz2
mv sherpa-onnx-streaming-zipformer-en-20M-2023-02-17/* .
rm -rf sherpa-onnx-streaming-zipformer-en-20M-2023-02-17 *.tar.bz2
```

### 3. TTS (Text-to-Speech) - 10MB
```bash
cd tts/
curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-amy-medium.tar.bz2
tar -xjf vits-piper-en_US-amy-medium.tar.bz2
mv vits-piper-en_US-amy-medium/* .
rm -rf vits-piper-en_US-amy-medium *.tar.bz2
```

### 4. KWS (Keyword Spotting) - 3MB
```bash
cd kws/
curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/kws-models/sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01.tar.bz2
tar -xjf sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01.tar.bz2
mv sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01/* .
echo "computer" > keywords.txt
rm -rf sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01 *.tar.bz2
```

## Model Details

| Model | Purpose | Size | Language |
|-------|---------|------|----------|
| Silero VAD | Detect speech vs silence | 2MB | Language-agnostic |
| Zipformer-20M | Real-time speech recognition | 20MB | English |
| Piper Amy | Natural voice synthesis | 10MB | English (US) |
| Zipformer KWS | Wake word "Computer" | 3MB | English |

**Total**: ~35MB

## Notes
- ✅ All models run 100% offline
- ✅ Optimized for mid-range Android phones
- ✅ No internet connection needed after download
- ✅ Privacy-preserving (all processing on-device)
- ✅ Low latency (<100ms for wake word detection)
