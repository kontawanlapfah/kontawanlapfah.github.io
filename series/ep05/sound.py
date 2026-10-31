"""EP05 sound design, cued to index.html. Foley and ambience only.
Usage: python3 sound.py out.wav [audio/vo_placed.wav audio/warp.json]
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from sfx import Mix, SR

m = Mix(94.8, warp=sys.argv[3] if len(sys.argv) > 3 else None)

def shimmer(sec):                  # glittering treasure: sparse high ticks
    k = int(sec * SR); x = np.zeros(k)
    for _ in range(int(sec * 40)):
        i = m.rng.integers(0, max(1, k - 2000)); c = m.tone(m.rng.uniform(4000, 7000), 3000, .04, 80)
        x[i:i + len(c)] += c * m.rng.uniform(.2, 1)
    return x
def crowd(sec):
    t = np.arange(int(sec * SR)) / SR
    x = sum(m.lp(m.noise(sec), .06) * (.4 + .6 * abs(np.sin(t * f))) for f in (1.1, 1.9, 2.7, 3.3))
    return m.hp(x, .01) / (abs(x).max() + 1e-9)
def rumble(sec):
    x = m.lp(m.noise(sec), .004); return x / (abs(x).max() + 1e-9)

# 1. dust over the ruin, glitter rising
m.bed(0, 9.8, m.wind, .10); m.bed(.6, 9.8, shimmer, .05, 1)
m.place(5.5, m.whoosh(.9, .05), .3); m.place(5.6, m.thud(48, 1.2, 4), .3)   # title
# 2-3. the box set down, Harith's arm withdrawing, then quiet at the door
m.bed(9.6, 24.2, m.room, .05); m.bed(9.6, 24.2, m.crackle, .10)
m.place(13.9, m.thud(160, .2, 25), .2)
m.place(15.6, m.rustle(2.8), .08)
# 4. a spoon against a cup, a soft breath
m.bed(24, 28.7, m.room, .05)
m.place(24.4, m.tone(2600, 2500, .5, 9), .05)
# 5. the city shakes: deep rumble and the roar of a far crowd
m.bed(28.5, 32.7, rumble, .25, .4); m.bed(28.8, 32.7, crowd, .10, .8)
# 6. from the roof: the procession, a river of footsteps and voices
m.bed(32.5, 41.2, crowd, .14); m.bed(32.5, 41.2, m.wind, .05)
# 7. he speaks, the crowd hushes; the treasure tears up out of the ground
m.bed(41, 47.5, crowd, .06)
m.place(47.5, rumble(1.2) * np.hanning(int(1.2 * SR)), .3)
m.bed(47.6, 56.7, shimmer, .10, 1)
# 8. the crowd screams with excitement
m.bed(52.5, 56.7, crowd, .20, .3)
# 9. cold hands: the noise falls away, a heartbeat
m.bed(56.5, 62.2, crowd, .04); m.heartbeat(56.8, 62, start=.9, floor=.75, gain=.35)
# 10. into the alley: footsteps close below, then they stop
m.bed(62, 66.7, crowd, .10)
for i in range(14):
    m.place(62.1 + i * .28, m.step(False), .10 * (1 - i / 16))
m.bed(66.5, 77.5, m.wind, .06)
m.silence(77.5, 78.1)                                     # cut to black before any face

# closing
m.bed(77.9, 94.8, m.room, .03, 1.5)
m.place(90.45, m.thud(260, .15, 30), .14); m.place(91.0, m.thud(380, .1, 40), .07)

m.write(sys.argv[1], vo=sys.argv[2] if len(sys.argv) > 2 else None)
