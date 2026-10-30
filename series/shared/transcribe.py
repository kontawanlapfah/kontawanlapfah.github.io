"""Transcribe a voiceover run by run (between pauses) with Whisper via sherpa-onnx.

Gives align.py real Thai text for every stretch of speech, so lines are matched
by what was said, not by length. Model: sherpa-onnx-whisper-turbo (GitHub release
k2-fsa/sherpa-onnx, tag asr-models); pass its folder as the second argument.

Usage: python3 transcribe.py vo.wav MODEL_DIR > audio/transcript.json
"""
import json, re, subprocess, sys, wave
import numpy as np
import sherpa_onnx

wav, model = sys.argv[1], sys.argv[2]
rec = sherpa_onnx.OfflineRecognizer.from_whisper(
    encoder=f'{model}/turbo-encoder.int8.onnx', decoder=f'{model}/turbo-decoder.int8.onnx',
    tokens=f'{model}/turbo-tokens.txt', language='th', task='transcribe', num_threads=4)

with wave.open(wav) as w:
    sr = w.getframerate(); x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768
out = subprocess.run(['ffmpeg', '-hide_banner', '-i', wav, '-af', 'silencedetect=noise=-35dB:d=0.12', '-f', 'null', '-'],
                     capture_output=True, text=True).stderr
starts = [float(v) for v in re.findall(r'silence_start: ([\d.]+)', out)]
ends = [float(v) for v in re.findall(r'silence_end: ([\d.]+)', out)]
dur = len(x) / sr
segs, cur = [], 0.0
for a, b in sorted(zip(starts, ends)):
    if a - cur > 0.05: segs.append((cur, a))
    cur = b
if dur - cur > 0.05: segs.append((cur, dur))

res = []
for a, b in segs:
    clip = x[int(max(0, a - .05) * sr): int(min(dur, b + .05) * sr)]
    if sr != 16000:
        clip = np.interp(np.arange(0, len(clip), sr / 16000), np.arange(len(clip)), clip).astype(np.float32)
    clip = np.concatenate([clip, np.zeros(32000, np.float32)])      # trailing silence: without it Whisper stops early
    s = rec.create_stream(); s.accept_waveform(16000, clip); rec.decode_stream(s)
    res.append({'start': round(a, 3), 'end': round(b, 3), 'text': s.result.text.strip()})
    print(f'{a:7.2f}-{b:7.2f}  {res[-1]["text"]}', file=sys.stderr)
json.dump(res, sys.stdout, ensure_ascii=False, indent=1)
