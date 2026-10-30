"""Check picture/voice sync: for every caption, transcribe the voice that plays
while that caption is on screen and compare it with the caption's text.

Usage (from the episode folder): python3 ../shared/verify_sync.py MODEL_DIR
Reads index.html, audio/warp.json, audio/vo_placed.wav. Prints one row per caption
with a similarity score; rows under 0.6 are marked CHECK.
"""
import json, re, sys, wave
from difflib import SequenceMatcher
import numpy as np
import sherpa_onnx

model = sys.argv[1]
rec = sherpa_onnx.OfflineRecognizer.from_whisper(
    encoder=f'{model}/turbo-encoder.int8.onnx', decoder=f'{model}/turbo-decoder.int8.onnx',
    tokens=f'{model}/turbo-tokens.txt', language='th', task='transcribe', num_threads=4)
html = open('index.html', encoding='utf-8').read()
caps = [(float(a), float(b), re.sub(r'<[^>]+>', '', t)) for a, b, t in
        re.findall(r"^\s*\[([\d.]+), ([\d.]+), '[a-z]*', '(.*)'\],?$", html, re.M)]
w = json.load(open('audio/warp.json')); old, new = zip(*w['anchors'])
W = lambda t: float(np.interp(t, old, new))
with wave.open('audio/vo_placed.wav') as f:
    sr = f.getframerate(); x = np.frombuffer(f.readframes(f.getnframes()), np.int16).astype(np.float32) / 32768
NUM = {'1': 'หนึ่ง', '2': 'สอง', '3': 'สาม', '5': 'ห้า', '9': 'เก้า', '10': 'สิบ'}
norm = lambda s: re.sub(r'[^฀-๿]', '', re.sub(r'\d+', lambda m: NUM.get(m.group(), m.group()), s.replace('ﷺ', 'ศ็อลลัลลอฮุอะลัยฮิวะซัลลัม')))
bad = 0
for i, (a, b, text) in enumerate(caps):
    s, e = W(a), W(b)
    clip = x[int(s * sr): int(e * sr)]
    clip = np.interp(np.arange(0, len(clip), sr / 16000), np.arange(len(clip)), clip).astype(np.float32)
    st = rec.create_stream(); st.accept_waveform(16000, np.concatenate([clip, np.zeros(32000, np.float32)])); rec.decode_stream(st)
    heard = st.result.text.strip()
    score = SequenceMatcher(None, norm(text), norm(heard)).ratio()
    bad += score < .6
    print(f"{i:2d} {s:6.2f}-{e:6.2f} {score:4.2f} {'CHECK' if score < .6 else '  ok '}  {text[:30]:30s} | {heard[:40]}")
print(f'{len(caps) - bad}/{len(caps)} captions match the voice under them')
