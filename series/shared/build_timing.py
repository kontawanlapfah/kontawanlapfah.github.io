"""Fit an episode's animation to its voiceover (EP02 onward).

Reads audio/alignment.json (align.py) and timing.json, writes:
  audio/warp.json, audio/warp.js  anchors [old_seconds, new_seconds]: the page and
                                  sound.py both play the authored timeline through them
  audio/vo_placed.wav             the voice cut at the "breaks" and placed on the new
                                  timeline, leaving room for beats that have no voice

timing.json:
  "breaks":  [[unit, gap_seconds], ...]   a silent gap after that unit's line
  "anchors": [[old, "start"|"end", unit, offset], ...]  extra picture beats tied to the voice
Every caption start is also anchored to its line (LEAD seconds early).

Usage (from the episode folder): python3 ../shared/build_timing.py vo.wav
"""
import json, sys, wave
import numpy as np

SR, LEAD = 44100, 0.15
units = json.load(open('audio/alignment.json', encoding='utf-8'))
cfg = json.load(open('timing.json', encoding='utf-8'))
S = [u['start'] for u in units]; E = [u['end'] for u in units]
ncaps = len(units) - len(cfg['extra'])

# cut the voice in the middle of the pause after each break unit
cuts = sorted((((E[u] + S[u + 1]) / 2 if u + 1 < len(units) else E[u]), u, g) for u, g in cfg['breaks'])
chunks, t, a = [], 0.0, 0.0
for cut, u, gap in cuts:
    chunks.append((a, cut, t)); t += (cut - a) + gap; a = cut
chunks.append((a, None, t))


def new(vo):
    for a, b, n in chunks:
        if b is None or vo < b: return vo - a + n


anchors = {0.0: 0.0}
for i in range(1, ncaps):
    anchors[units[i]['old']] = new(S[i]) - LEAD
for old, which, u, off in cfg['anchors']:
    anchors[old] = new(S[u] if which == 'start' else E[u]) + off
anchors = sorted(anchors.items())
for (o1, n1), (o2, n2) in zip(anchors, anchors[1:]):
    assert n2 > n1, f'anchors out of order: {o1}->{n1:.2f} then {o2}->{n2:.2f}'
total = round(anchors[-1][1], 3)
json.dump({'anchors': anchors, 'total': total}, open('audio/warp.json', 'w'), indent=1)
open('audio/warp.js', 'w').write('window.WARP = ' + json.dumps({'anchors': anchors, 'total': total}) + ';\n')

with wave.open(sys.argv[1]) as w:
    assert w.getframerate() == SR and w.getnchannels() == 1, 'convert first: ffmpeg -i vo.mp3 -ar 44100 -ac 1 vo.wav'
    vo = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(float) / 32767
out = np.zeros(int((total + .5) * SR))
f = int(.03 * SR)
for a, b, n in chunks:
    seg = vo[int(a * SR): int(b * SR) if b else len(vo)].copy()
    seg[:f] *= np.linspace(0, 1, f); seg[-f:] *= np.linspace(1, 0, f)
    i = int(n * SR); out[i:i + len(seg)] += seg[: len(out) - i]
with wave.open('audio/vo_placed.wav', 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((np.clip(out, -1, 1) * 32767).astype(np.int16).tobytes())
for o, n in anchors: print(f'{o:7.2f} -> {n:7.2f}')
print('total', total)
