#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "===== Downloading Sherpa-ONNX Models ====="
echo ""

# 1. VAD Model (~2MB)
echo "[1/4] Downloading VAD model (Silero VAD ~2MB)..."
cd vad/
if [ ! -f "silero_vad.onnx" ]; then
    curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx
    echo "✓ VAD model downloaded"
else
    echo "✓ VAD model already exists"
fi
cd ..

# 2. STT Model (~20MB)
echo ""
echo "[2/4] Downloading STT model (Zipformer-20M ~20MB)..."
cd stt/
if [ ! -f "encoder-epoch-99-avg-1.onnx" ]; then
    curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17.tar.bz2
    tar -xjf sherpa-onnx-streaming-zipformer-en-20M-2023-02-17.tar.bz2
    mv sherpa-onnx-streaming-zipformer-en-20M-2023-02-17/* .
    rm -rf sherpa-onnx-streaming-zipformer-en-20M-2023-02-17 *.tar.bz2
    echo "✓ STT model downloaded"
else
    echo "✓ STT model already exists"
fi
cd ..

# 3. TTS Model (~10MB)
echo ""
echo "[3/4] Downloading TTS model (Piper Amy ~10MB)..."
cd tts/
if [ ! -f "en_US-amy-medium.onnx" ]; then
    curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-amy-medium.tar.bz2
    tar -xjf vits-piper-en_US-amy-medium.tar.bz2
    mv vits-piper-en_US-amy-medium/* .
    rm -rf vits-piper-en_US-amy-medium *.tar.bz2
    echo "✓ TTS model downloaded"
else
    echo "✓ TTS model already exists"
fi
cd ..

# 4. KWS Model (~3MB)
echo ""
echo "[4/4] Downloading KWS model (Wake word ~3MB)..."
cd kws/
if [ ! -f "encoder-epoch-12-avg-2-chunk-16-left-64.onnx" ]; then
    curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/kws-models/sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01.tar.bz2
    tar -xjf sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01.tar.bz2
    mv sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01/* .
    echo "computer" > keywords.txt
    rm -rf sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01 *.tar.bz2
    echo "✓ KWS model downloaded"
else
    echo "✓ KWS model already exists"
fi
cd ..

echo ""
echo "===== ✓ All models downloaded successfully! ====="
echo ""
echo "Model Summary:"
echo "  - VAD:  Voice Activity Detection (~2MB)"
echo "  - STT:  Speech-to-Text (~20MB)"
echo "  - TTS:  Text-to-Speech (~10MB)"
echo "  - KWS:  Wake Word Detection (~3MB)"
echo "  Total: ~35MB"
echo ""
echo "All voice processing will run 100% offline on your device!"
