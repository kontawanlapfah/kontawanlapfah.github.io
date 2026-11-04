"""EP09 sound design, cued to index.html. Foley and ambience only.
Usage: python3 sound.py out.wav [audio/vo_placed.wav audio/warp.json]
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from sfx import Mix, SR

m = Mix(101.8, warp=sys.argv[3] if len(sys.argv) > 3 else None)

def murmur(sec):                     # many people far off, quiet
    x = m.lp(m.noise(sec), .02); return x / (abs(x).max() + 1e-9)
def sob(sec):                        # muffled breaths, uneven
    t = np.arange(int(sec * SR)) / SR
    x = m.lp(m.noise(sec), .05) * np.clip(np.sin(t * 2 * np.pi * .9) ** 8 + .15 * np.sin(t * 7) ** 2, 0, 1)
    return x / (abs(x).max() + 1e-9)

# hook: mountain wind, Harith's muffled crying
m.bed(0, 9.8, m.wind, .10); m.bed(.5, 9.8, sob, .08)
m.place(5.5, m.whoosh(.9, .05), .3); m.place(5.6, m.thud(48, 1.2, 4), .3)      # title
# the foot of the mountain; footsteps on gravel
m.bed(9.6, 19.7, m.wind, .08)
for i in range(8):
    m.place(10 + i * .45, m.step(False), .06)
# the confession, close
m.bed(19.5, 32.7, m.wind, .05); m.bed(19.5, 28, sob, .04)
m.place(28.2, m.rustle(.5), .08)                                              # head bowed
# memory
m.bed(32.5, 38.2, m.room, .05)
# the water bottle
m.place(38.6, m.rustle(.4), .08); m.place(40.0, m.tone(900, 700, .3, 12), .05); m.place(40.3, m.drop(), .06)
# the camp: many people, small fires
m.bed(41.5, 47.7, murmur, .07); m.bed(41.5, 47.7, m.crackle, .08)
# ordinary days: birds at each sunrise, crickets at night; the watch ticks
m.bed(47.5, 54.2, m.wind, .05)
for k in range(13):
    m.place(47.7 + k * .5, m.tick(), .10)
m.place(47.8, m.birds(1.6), .05); m.place(51.0, m.birds(1.6), .05)
# the lesson by the fire
m.bed(54, 62.2, m.crackle, .10); m.bed(54, 62.2, m.crickets, .04)
# before dawn: stillness, then everyone stands
m.bed(62, 84.5, m.wind, .05); m.bed(62, 72.2, m.crickets, .03)
for i in range(9):
    m.place(72.4 + i * .38, m.rustle(.4), .05)
m.silence(84.5, 84.9)
# closing
m.bed(84.8, 101.8, m.room, .03, 1.5)
m.place(97.45, m.thud(260, .15, 30), .14); m.place(98.0, m.thud(380, .1, 40), .07)

m.write(sys.argv[1], vo=sys.argv[2] if len(sys.argv) > 2 else None)
