"""EP12 sound design, cued to index.html. Foley and ambience only.
Usage: python3 sound.py out.wav [audio/vo_placed.wav audio/warp.json]
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from sfx import Mix, SR

m = Mix(100.3, warp=sys.argv[3] if len(sys.argv) > 3 else None)

def murmur(sec):
    x = m.lp(m.noise(sec), .02); return x / (abs(x).max() + 1e-9)
def sobs(sec):
    t = np.arange(int(sec * SR)) / SR
    x = m.lp(m.noise(sec), .05) * np.clip(np.sin(t * 2 * np.pi * .7) ** 8 + .1, 0, 1)
    return x / (abs(x).max() + 1e-9)

# hook: stillness, cloth, a held breath
m.bed(0, 9.8, m.wind, .04); m.place(.8, m.rustle(.5), .08)
m.place(5.5, m.whoosh(.9, .05), .3); m.place(5.6, m.thud(48, 1.2, 4), .3)      # title
# the camp: everyone still; soft steps passing along the row; sobbing around
m.bed(9.6, 27.7, m.wind, .04); m.bed(9.6, 27.7, murmur, .02)
for i in range(10):
    m.place(18.2 + i * .65, m.step(), .05)
m.bed(23.5, 27.7, sobs, .05)
for k in range(4):
    m.place(24.9 + k * .8, m.drop(), .05)
# before dawn: night, the camp stirring; a low rumble far off at the name
m.bed(27.5, 38.7, m.night, .05); m.bed(27.5, 38.7, m.crickets, .03)
m.place(28.2, m.rustle(1.0), .08); m.place(35.8, m.thud(40, 2.5, 2), .18)
# the climb at dawn: many steps, wind, birds
m.bed(38.5, 54.2, m.wind, .06); m.bed(38.5, 54.2, m.birds, .03)
for i in range(30):
    m.place(38.7 + i * .5, m.step(False), .05)
# the voice message memory
m.bed(54, 58.2, m.room, .05); m.place(54.2, m.tick(), .1)
# what protected them: quiet room tone
m.bed(58, 70.2, m.room, .04)
# the end: the whisper, then the wide mountain wind
m.bed(70, 82, m.wind, .06)
m.silence(82, 82.4)
# closing
m.bed(82.3, 100.3, m.room, .03, 1.5)
m.place(95.95, m.thud(260, .15, 30), .14); m.place(96.5, m.thud(380, .1, 40), .07)

m.write(sys.argv[1], vo=sys.argv[2] if len(sys.argv) > 2 else None)
