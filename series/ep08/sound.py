"""EP08 sound design, cued to index.html. Foley and ambience only.
Usage: python3 sound.py out.wav [audio/vo_placed.wav audio/warp.json]
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from sfx import Mix, SR

m = Mix(105.8, warp=sys.argv[3] if len(sys.argv) > 3 else None)

def under(sec):                      # underwater: low muffled noise
    x = m.lp(m.noise(sec), .01); return x / (abs(x).max() + 1e-9)
def bubbles(sec):
    k = int(sec * SR); x = np.zeros(k)
    for _ in range(int(sec * 9)):
        i = m.rng.integers(0, max(1, k - 6000)); c = m.tone(m.rng.uniform(500, 1400), m.rng.uniform(1500, 2600), .06, 40)
        x[i:i + len(c)] += c * m.rng.uniform(.3, 1)
    return x
def far_crowd(sec):
    x = m.lp(m.noise(sec), .03); return x / (abs(x).max() + 1e-9)

# hook: drops falling in the dark
m.bed(0, 9.8, m.room, .03)
for i in range(16):
    m.place(.9 + i * .55 + (i % 3) * .07, m.drop(), .12)
m.place(5.5, m.whoosh(.9, .05), .3); m.place(5.6, m.thud(48, 1.2, 4), .3)      # title
# through the fire: water wraps around them
m.bed(9.6, 18.2, under, .14); m.bed(9.6, 18.2, bubbles, .10)
# the alley: dripping, the square's noise far off
m.bed(18, 27.2, far_crowd, .05)
for i in range(14):
    m.place(18.3 + i * .42, m.drop(), .08)
m.place(24.3, m.rustle(.7), .1)                                               # sujud
# escape at night: footsteps, crickets
m.bed(27, 35.7, m.crickets, .05); m.bed(27, 35.7, m.wind, .05)
for i in range(22):
    m.place(27.2 + i * .24, m.step(), .07)
# the barn: small fire
m.bed(35.5, 41.2, m.crackle, .14); m.bed(35.5, 41.2, m.room, .04)
# flashback: a quiet paper hush; light at the gates
m.bed(41, 64.2, m.wind, .04)
for k in (42, 42.5, 43, 43.5):
    m.place(k, m.tone(900, 1300, .6, 6), .04)
m.place(52.5, m.whoosh(.6, .1), .14); m.place(52.9, m.thud(70, .5, 8), .1)      # struck down (no violence shown)
m.place(55.2, m.whoosh(.8, .05), .08)                                            # raised
m.place(61.2, m.whoosh(.6, .1), .14); m.place(61.3, m.tone(600, 900, 1.2, 3), .06)   # the second time fails
# back in the barn, before sleep
m.bed(64, 80.7, m.crackle, .10); m.bed(69, 80.7, m.crickets, .03)
# the mountains at night
m.bed(80.5, 88.5, m.wind, .10)
# closing
m.bed(88.8, 105.8, m.room, .03, 1.5)
m.place(101.45, m.thud(260, .15, 30), .14); m.place(102.0, m.thud(380, .1, 40), .07)

m.write(sys.argv[1], vo=sys.argv[2] if len(sys.argv) > 2 else None)
