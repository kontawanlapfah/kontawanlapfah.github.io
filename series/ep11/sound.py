"""EP11 sound design, cued to index.html. Foley and ambience only.
Usage: python3 sound.py out.wav [audio/vo_placed.wav audio/warp.json]
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from sfx import Mix, SR

m = Mix(97.3, warp=sys.argv[3] if len(sys.argv) > 3 else None)

def crowd(sec):
    t = np.arange(int(sec * SR)) / SR
    x = sum(m.lp(m.noise(sec), .06) * (.4 + .6 * abs(np.sin(t * f))) for f in (1.1, 1.9, 2.7, 3.3))
    return m.hp(x, .01) / (abs(x).max() + 1e-9)
def murmur(sec):
    x = m.lp(m.noise(sec), .02); return x / (abs(x).max() + 1e-9)
def bubbles(sec):
    k = int(sec * SR); x = np.zeros(k)
    for _ in range(int(sec * 6)):
        i = m.rng.integers(0, max(1, k - 6000)); c = m.tone(m.rng.uniform(700, 1600), m.rng.uniform(1600, 2600), .05, 40)
        x[i:i + len(c)] += c * m.rng.uniform(.3, 1)
    return x

# hook: wind and dust through an empty gate
m.bed(0, 9.8, m.wind, .10)
m.place(5.5, m.whoosh(.9, .05), .3); m.place(5.6, m.thud(48, 1.2, 4), .3)      # title
# the wall: a murmuring city below, then a voice calling (the narration carries the words)
m.bed(9.6, 22.2, murmur, .06); m.bed(9.6, 22.2, m.wind, .05)
m.bed(13, 22.2, crowd, .05)
# the symbol: salt dropped into water, dissolving; very quiet
m.place(22.4, m.drop(), .14); m.bed(22.6, 30, bubbles, .05); m.bed(22, 33.2, m.room, .04)
# the square: a hush, then the crowd rises (takbir is in the narration; the crowd swells under it)
m.silence(33, 34.4); m.bed(34.6, 41.2, crowd, .16)
m.place(37.9, m.rustle(.8), .1)
# Harith crying, Adam beside him
m.bed(41, 45.7, murmur, .04)
# the watch: ordinary ticking
m.bed(45.5, 54.2, m.wind, .03)
for k in range(17):
    m.place(45.7 + k * .5, m.tick(), .12)
# Hawa's question, the smile
m.bed(54, 62.2, m.room, .04)
# evening at the camp: everyone on their feet, quiet
m.bed(62, 80, m.wind, .06); m.bed(62, 80, murmur, .03); m.bed(62, 80, m.crickets, .02)
m.place(62.3, m.rustle(1.0), .1)
m.silence(80, 80.4)
# closing
m.bed(80.3, 97.3, m.room, .03, 1.5)
m.place(92.95, m.thud(260, .15, 30), .14); m.place(93.5, m.thud(380, .1, 40), .07)

m.write(sys.argv[1], vo=sys.argv[2] if len(sys.argv) > 2 else None)
