"""Align an ElevenLabs voiceover to an episode's captions (EP02 onward).

No speech recogniser is available offline for Thai, so the voice's pauses are
matched to the captions by text length: speech runs between pauses are grouped
into consecutive units so each unit's spoken length is closest to its share of
the text (dynamic programming).

Units, in spoken order: every CAPS line in index.html, then the extra spoken
lines listed in timing.json ("extra": [[old_seconds, text], ...]) such as the
CTA and the closing line.

Usage (from the episode folder): python3 ../shared/align.py vo.wav > audio/alignment.json
"""
import json, re, subprocess, sys

wav = sys.argv[1]
html = open('index.html', encoding='utf-8').read()
cfg = json.load(open('timing.json', encoding='utf-8'))

caps = re.findall(r"^\s*\[([\d.]+), ([\d.]+), '[a-z]*', '(.*)'\],?$", html, re.M)
units = [(float(a), re.sub(r'<[^>]+>', '', t)) for a, b, t in caps] + [tuple(x) for x in cfg['extra']]


def weight(text):
    # spoken length ~ Thai base characters (combining vowels/tone marks skipped) + a pause per ellipsis
    base = sum(1 for c in text if not (c == 'ั' or 'ิ' <= c <= 'ฺ' or '็' <= c <= '๎')
               and c.strip() and c not in '“”"?…')
    return base + 6 * text.count('…') + (40 if 'ﷺ' in text else 0)      # ﷺ is spoken in full


W = [weight(t) for _, t in units]
out = subprocess.run(['ffmpeg', '-hide_banner', '-i', wav, '-af', 'silencedetect=noise=-35dB:d=0.12', '-f', 'null', '-'],
                     capture_output=True, text=True).stderr
starts = [float(x) for x in re.findall(r'silence_start: ([\d.]+)', out)]
ends = [float(x) for x in re.findall(r'silence_end: ([\d.]+)', out)]
h, m, s = re.search(r'Duration: (\d+):(\d+):([\d.]+)', out).groups()
dur = int(h) * 3600 + int(m) * 60 + float(s)
segs, cur = [], 0.0
for a, b in sorted(zip(starts, ends)):
    if a - cur > 0.05: segs.append((cur, a))
    cur = b
if dur - cur > 0.05: segs.append((cur, dur))

N, M = len(units), len(segs)
assert M >= N, f'only {M} speech runs for {N} lines'
rate = sum(b - a for a, b in segs) / sum(W)
INF = float('inf')
cost = [[INF] * (M + 1) for _ in range(N + 1)]; back = [[0] * (M + 1) for _ in range(N + 1)]
cost[0][0] = 0
for i in range(1, N + 1):
    for j in range(i, M + 1):
        for k in range(i - 1, j):
            if cost[i - 1][k] == INF: continue
            spoken = sum(b - a for a, b in segs[k:j]); want = rate * W[i - 1]
            c = cost[i - 1][k] + ((spoken - want) / max(1.0, want)) ** 2
            if c < cost[i][j]: cost[i][j], back[i][j] = c, k
res, j = [], M
for i in range(N, 0, -1):
    k = back[i][j]; res.append((segs[k][0], segs[j - 1][1])); j = k
res.reverse()
data = [{'old': o, 'text': t, 'start': round(a, 3), 'end': round(b, 3)} for (o, t), (a, b) in zip(units, res)]
json.dump(data, sys.stdout, ensure_ascii=False, indent=1)
for i, d in enumerate(data):
    print(f"{i:2d} {d['start']:7.2f}-{d['end']:7.2f} ({d['end'] - d['start']:4.1f}s)  {d['text'][:55]}", file=sys.stderr)
