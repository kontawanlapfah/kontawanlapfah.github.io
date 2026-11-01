"""EP10 sound design, cued to index.html. Foley and ambience only.
Usage: python3 sound.py out.wav [audio/vo_placed.wav audio/warp.json]
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from sfx import Mix, SR

m = Mix(101.3, warp=sys.argv[3] if len(sys.argv) > 3 else None)

def murmur(sec):
    x = m.lp(m.noise(sec), .02); return x / (abs(x).max() + 1e-9)
def crowd(sec):
    t = np.arange(int(sec * SR)) / SR
    x = sum(m.lp(m.noise(sec), .06) * (.4 + .6 * abs(np.sin(t * f))) for f in (1.1, 1.9, 2.7, 3.3))
    return m.hp(x, .01) / (abs(x).max() + 1e-9)

# hook: a vast, still courtyard at dawn; cloth, a breath
m.bed(0, 9.8, m.wind, .04); m.bed(0, 9.8, murmur, .03)
m.place(5.5, m.whoosh(.9, .05), .3); m.place(5.6, m.thud(48, 1.2, 4), .3)      # title
# the mountain before sunrise; running feet on gravel, panting breath
m.bed(9.6, 21.2, m.wind, .06); m.bed(9.6, 21.2, m.crickets, .03)
for i in range(14):
    m.place(13.1 + i * .23, m.step(False), .10)
# the minaret at dawn: birds, stillness
m.bed(21, 33.2, m.birds, .05); m.bed(21, 33.2, m.wind, .03)
# down the mountain: many footsteps
m.bed(33, 38.2, murmur, .06)
for i in range(16):
    m.place(33.2 + i * .3, m.step(), .07)
# the courtyard: a great crowd, hushed
m.bed(38, 51.2, murmur, .06)
# takbir: the crowd falls silent; cloth as hands rise
m.place(51.3, m.rustle(.8), .10); m.silence(51.8, 55)
# after the prayer, near
m.bed(55, 69.2, murmur, .04); m.place(55.4, m.rustle(.4), .08); m.place(64.3, m.rustle(.7), .10)
# the gate: shouting crowd, running feet, dust
m.bed(69, 84, crowd, .14); m.bed(69, 84, m.wind, .06)
for i in range(30):
    m.place(69.2 + i * .45, m.step(False), .06)
m.silence(84, 84.4)
# closing
m.bed(84.3, 101.3, m.room, .03, 1.5)
m.place(96.95, m.thud(260, .15, 30), .14); m.place(97.5, m.thud(380, .1, 40), .07)

m.write(sys.argv[1], vo=sys.argv[2] if len(sys.argv) > 2 else None)
