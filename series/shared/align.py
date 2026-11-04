"""Align an ElevenLabs voiceover to an episode's captions (EP02 onward).

Uses audio/transcript.json from transcribe.py (Whisper, run by run between
pauses). Each run's recognised words are matched against the captions, so lines
are placed by what was actually said. Runs are assigned to lines in order; a
line nobody spoke (e.g. a closing line left out of the recording) comes back
with "missing": true.

Units, in spoken order: every CAPS line in index.html, then the "extra" spoken
lines in timing.json (CTA, closing line).

Usage (from the episode folder): python3 ../shared/align.py [vo.wav] > audio/alignment.json
"""
import json, re, sys
from difflib import SequenceMatcher

import wave
import numpy as np
ENV = None                                                   # 10 ms loudness envelope of the voice, if given
if len(sys.argv) > 1:
    with wave.open(sys.argv[1]) as w:
        sr = w.getframerate(); x = np.abs(np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(float))
    hop = sr // 100; ENV = np.convolve(x[: len(x) // hop * hop].reshape(-1, hop).mean(1), np.ones(14) / 14, 'same')   # ~140 ms: favours real gaps over syllable dips
html = open('index.html', encoding='utf-8').read()
cfg = json.load(open('timing.json', encoding='utf-8'))
runs = json.load(open('audio/transcript.json', encoding='utf-8'))

caps = re.findall(r"^\s*\[([\d.]+), ([\d.]+), '[a-z]*', '(.*)'\],?$", html, re.M)
units = [(float(a), re.sub(r'<[^>]+>', '', t)) for a, b, t in caps] + [tuple(x) for x in cfg['extra']]

NUM = {'1': 'หนึ่ง', '2': 'สอง', '3': 'สาม', '4': 'สี่', '5': 'ห้า', '6': 'หก', '7': 'เจ็ด', '8': 'แปด', '9': 'เก้า', '10': 'สิบ'}


def norm(s):
    s = re.sub(r'\d+', lambda m: NUM.get(m.group(), m.group()), s)
    s = s.replace('ﷺ', 'ศ็อลลัลลอฮุอะลัยฮิวะซัลลัม')
    return re.sub(r'[^฀-๿]', '', s)        # Thai letters only: drops spaces, punctuation, Latin


U = [norm(t) for _, t in units]
R = [norm(r['text']) for r in runs]


def partial(sub, text):
    """best similarity of sub against any window of text (0..1)"""
    if not sub: return 0.0
    n, best = len(sub), 0.0
    for i in range(0, max(1, len(text) - n + 1)):
        best = max(best, SequenceMatcher(None, sub, text[i:i + n]).ratio())
        if best > .97: break
    return best


def head(sub, text):
    """how well sub matches the beginning of text"""
    return SequenceMatcher(None, sub, text[:max(len(sub) + 4, 1)]).ratio() if sub else 0.0


N, M = len(U), len(R)
P = [[partial(R[j], U[i]) for j in range(M)] for i in range(N)]
Hd = [[head(R[j], U[i]) for j in range(M)] for i in range(N)]
NEG = -1e9
f = [[NEG] * (M + 1) for _ in range(N + 1)]; bk = [[0] * (M + 1) for _ in range(N + 1)]
f[0][0] = 0
for i in range(1, N + 1):
    for j in range(0, M + 1):
        best, arg = NEG, j
        if f[i - 1][j] > NEG: best, arg = f[i - 1][j] - .5, j             # line not spoken
        acc, psum = 0.0, 0.0
        for k in range(j - 1, -1, -1):                                     # line i takes runs k..j-1
            acc += (P[i - 1][k] - .6) * min(1.0, len(R[k]) / 6)        # short runs count less
            psum += P[i - 1][k]
            if f[i - 1][k] == NEG or psum / (j - k) < .45: continue       # runs must really be this line
            sc = f[i - 1][k] + acc + 2.0 * max(0.0, Hd[i - 1][k] - .45)   # only a real match of the line's opening counts
            if sc > best: best, arg = sc, k
        f[i][j], bk[i][j] = best, arg
spans, j = [], M
for i in range(N, 0, -1):
    k = bk[i][j]; spans.append((k, j)); j = k
spans.reverse()

data, prev_end = [], 0.0
for (old, text), (k, j) in zip(units, spans):
    if j > k:
        d = {'old': old, 'text': text, 'start': runs[k]['start'], 'end': runs[j - 1]['end'],
             'heard': ' | '.join(r['text'] for r in runs[k:j])}
        prev_end = d['end']
    else:
        d = {'old': old, 'text': text, 'start': prev_end + .01, 'end': prev_end + .01, 'missing': True, 'heard': ''}
    data.append(d)
# hand corrections for runs Whisper garbled: timing.json "fix": {"line index": start_seconds}
for idx, st in cfg.get('fix', {}).items():
    i = int(idx); data[i]['start'] = st; data[i].pop('missing', None); data[i]['fixed'] = True
    data[i - 1]['end'] = max(r['end'] for r in runs if r['end'] <= st + 1e-6)
    if data[i]['end'] < st: data[i]['end'] = min(r['end'] for r in runs if r['end'] > st)
# a run can hold the end of one line and the opening of the next: split it where the next line's words begin
for i in range(len(data) - 1):
    a_, b_ = data[i], data[i + 1]
    if a_.get('missing') or b_.get('missing'): continue
    k = spans[i][1] - 1; txt = R[k]; nxt = U[i + 1][:10]
    if len(txt) < 8 or len(nxt) < 5: continue
    best, pos = 0.0, -1
    for p in range(3, len(txt) - 3):
        r = SequenceMatcher(None, nxt[:min(len(nxt), len(txt) - p)], txt[p:p + len(nxt)]).ratio()
        if r > best: best, pos = r, p
    if best > .75:
        cut = runs[k]['start'] + (runs[k]['end'] - runs[k]['start']) * pos / len(txt)
        if ENV is not None:                                  # snap to the quietest 60 ms within ±0.6 s: the gap between words
            lo, hi = max(runs[k]['start'] + .2, cut - .6), min(runs[k]['end'] - .2, cut + .6)
            ts = np.arange(lo, hi, .01)
            if len(ts): cut = float(ts[np.argmin([ENV[int(t * 100)] for t in ts])])
        a_['end'] = round(cut, 3); b_['start'] = round(cut, 3); b_['split'] = True
json.dump(data, sys.stdout, ensure_ascii=False, indent=1)
for i, d in enumerate(data):
    flag = '  <-- NOT IN RECORDING' if d.get('missing') else ''
    print(f"{i:2d} {d['start']:7.2f}-{d['end']:7.2f}  {d['text'][:34]:34s} | heard: {d['heard'][:40]}{flag}", file=sys.stderr)
