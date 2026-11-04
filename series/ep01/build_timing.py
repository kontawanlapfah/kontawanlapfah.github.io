"""Fit the animation to the voiceover.

Reads audio/alignment.json (from align.py) and writes:
  audio/warp.json   [[old_seconds, new_seconds], ...] anchors: the animation was
                    authored on the "old" timeline; the final cut plays on "new".
  audio/vo_placed.wav  the voiceover cut into chunks and placed on the new timeline,
                    leaving room for the title card, the three knocks, the cut to
                    black and the disclaimer.
Usage: python3 build_timing.py vo.wav
"""
import json, sys, wave
import numpy as np

SR = 44100
LEAD = 0.15                      # captions appear just before the words
units = json.load(open('audio/alignment.json', encoding='utf-8'))
S = [u['start'] for u in units]; E = [u['end'] for u in units]
mid = lambda a, b: (a + b) / 2

# chunk cut points in the voice file (middle of the pause between units)
cut_hook = mid(E[0], S[1])        # after the hook
cut_knock = mid(E[12], S[13])     # after "...สามครั้ง ช้า ๆ"
cut_black = mid(E[20], S[21])     # after the last cliffhanger line
cut_outro = mid(E[21], S[22])     # between the CTA and the closing line
TITLE, KNOCKS, BLACK, DISC = 3.6, 3.4, 0.7, 6.5

chunks = []                       # (vo_from, vo_to, new_start)
t = 0.0
for a, b, gap in ((0, cut_hook, TITLE), (cut_hook, cut_knock, KNOCKS), (cut_knock, cut_black, BLACK),
                  (cut_black, cut_outro, DISC), (cut_outro, None, 0)):
    chunks.append((a, b, t))
    if b is not None: t += (b - a) + gap
off = lambda vo: next(n - a for a, b, n in chunks if b is None or vo < b)   # vo time -> new time shift
new = lambda vo: vo + off(vo)

caps_old = [u['old'] for u in units]
anchors = [(0.0, 0.0)]
for i, u in enumerate(units[:21]):                       # captions
    anchors.append((u['old'], new(u['start']) - LEAD if i else 0.0))
    if i == 0: anchors.append((5.5, new(E[0]) + .3))      # hook caption -> title card
anchors.append((9.0, new(S[1]) - LEAD))
# knocks land in the gap after "สามครั้ง ช้า ๆ"; the door opens as the next line starts
k0 = new(E[12]) + 0.45
anchors += [(55.0, k0), (57.4, k0 + 2.4)]
anchors.append((58.0, new(S[13]) - .4))
anchors.append((91.0, new(E[20]) + .35))                                    # cut to black
anchors.append((91.3, new(S[21]) - .25))                                   # CTA card
anchors.append((96.5, new(E[21]) + .45))                                   # disclaimer
anchors.append((103.0, new(S[22]) - .5))                                    # logo pop-up
end_new = new(E[22]) + 1.2
anchors.append((107.5, end_new))
anchors = sorted({o: n for o, n in anchors}.items())
for (o1, n1), (o2, n2) in zip(anchors, anchors[1:]):
    assert n2 > n1, (o1, n1, o2, n2)
json.dump({'anchors': anchors, 'total': round(end_new, 3)}, open('audio/warp.json', 'w'), indent=1)
open('audio/warp.js', 'w').write('window.WARP = ' + json.dumps({'anchors': anchors, 'total': round(end_new, 3)}) + ';\n')

# place the voice chunks
with wave.open(sys.argv[1]) as w:
    assert w.getframerate() == SR and w.getnchannels() == 1
    vo = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(float) / 32767
out = np.zeros(int((end_new + .5) * SR))
for a, b, n in chunks:
    seg = vo[int(a * SR): int(b * SR) if b else len(vo)]
    fade = np.ones(len(seg)); f = int(.03 * SR); fade[:f] = np.linspace(0, 1, f); fade[-f:] = np.linspace(1, 0, f)
    i = int(n * SR); out[i:i + len(seg)] += seg * fade
with wave.open('audio/vo_placed.wav', 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((np.clip(out, -1, 1) * 32767).astype(np.int16).tobytes())
for o, n in anchors: print(f'{o:7.2f} -> {n:7.2f}')
print('total', round(end_new, 2))
