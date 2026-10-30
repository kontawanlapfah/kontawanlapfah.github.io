"""Align the ElevenLabs voiceover to the on-screen captions.

No speech recogniser is available offline for Thai, so this matches the
voice's pauses to the captions by text length: speech runs between pauses
are grouped into consecutive caption units so each unit's spoken length is
as close as possible to its share of the text (dynamic programming).

Usage: python3 align.py vo.wav > audio/alignment.json
"""
import json, re, subprocess, sys

wav = sys.argv[1]
html = open('index.html', encoding='utf-8').read()

# units, in spoken order: every caption, then the CTA, then the closing line
caps = re.findall(r"^\s*\[([\d.]+), ([\d.]+), '[a-z]*', '(.*)'\],?$", html, re.M)
units = [(float(a), re.sub(r'<[^>]+>', '', t)) for a, b, t in caps]
units.append((91.3, 'ถ้าเป็นคุณ คุณจะรับขนมปังก้อนนั้นไหม? คอมเมนต์บอกกันด้วย และอย่าลืมกดติดตามและแชร์เรื่องนี้ เพื่อไม่ให้พลาดตอนต่อไป'))
units.append((103.0, 'ก่อนตะวันลับฟ้า… กดติดตามและแชร์ต่อ'))

def weight(text):
    # spoken length ~ Thai base characters (skip combining vowels/tone marks) + pause for ellipses
    base = sum(1 for c in text if not ('ั' == c or 'ิ' <= c <= 'ฺ' or '็' <= c <= '๎') and c.strip() and c not in '“”"?…')
    return base + 6 * text.count('…')

W = [weight(t) for _, t in units]

out = subprocess.run(['ffmpeg', '-hide_banner', '-i', wav, '-af', 'silencedetect=noise=-35dB:d=0.12', '-f', 'null', '-'],
                     capture_output=True, text=True).stderr
starts = [float(x) for x in re.findall(r'silence_start: ([\d.]+)', out)]
ends = [float(x) for x in re.findall(r'silence_end: ([\d.]+)', out)]
dur = float(re.search(r'Duration: (\d+):(\d+):([\d.]+)', out).groups()[2]) + 60 * int(re.search(r'Duration: (\d+):(\d+)', out).groups()[1])
# speech segments between silences
edges = sorted(zip(starts, ends))
segs, cur = [], 0.0
for s, e in edges:
    if s - cur > 0.05: segs.append((cur, s))
    cur = e
if dur - cur > 0.05: segs.append((cur, dur))

N, M = len(units), len(segs)
speech = sum(b - a for a, b in segs)
rate = speech / sum(W)  # seconds per weight unit
INF = float('inf')
# cost[i][j]: best cost placing first i units on first j segments
cost = [[INF] * (M + 1) for _ in range(N + 1)]; back = [[0] * (M + 1) for _ in range(N + 1)]
cost[0][0] = 0
for i in range(1, N + 1):
    for j in range(1, M + 1):
        for k in range(i - 1, j):           # unit i takes segments k..j-1
            if cost[i - 1][k] == INF: continue
            spoken = sum(b - a for a, b in segs[k:j])
            c = cost[i - 1][k] + ((spoken - rate * W[i - 1]) / max(1.0, rate * W[i - 1])) ** 2
            if c < cost[i][j]: cost[i][j], back[i][j] = c, k
res, j = [], M
for i in range(N, 0, -1):
    k = back[i][j]; res.append((segs[k][0], segs[j - 1][1])); j = k
res.reverse()
data = [{'old': o, 'text': t, 'start': round(a, 3), 'end': round(b, 3)} for (o, t), (a, b) in zip(units, res)]
json.dump(data, sys.stdout, ensure_ascii=False, indent=1)
for d in data:
    print(f"{d['start']:7.2f}-{d['end']:7.2f} ({d['end'] - d['start']:4.1f}s)  {d['text'][:60]}", file=sys.stderr)
