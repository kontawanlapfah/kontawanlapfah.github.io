"""EP07 sound design, cued to index.html. Foley and ambience only.
Usage: python3 sound.py out.wav [audio/vo_placed.wav audio/warp.json]
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from sfx import Mix, SR

m = Mix(104.3, warp=sys.argv[3] if len(sys.argv) > 3 else None)

def crowd(sec):
    t = np.arange(int(sec * SR)) / SR
    x = sum(m.lp(m.noise(sec), .06) * (.4 + .6 * abs(np.sin(t * f))) for f in (1.1, 1.9, 2.7, 3.3))
    return m.hp(x, .01) / (abs(x).max() + 1e-9)
def river(sec):                      # running water: band noise with a slow wobble
    t = np.arange(int(sec * SR)) / SR
    x = m.hp(m.lp(m.noise(sec), .25), .05) * (.7 + .3 * np.sin(t * 1.7))
    return x / (abs(x).max() + 1e-9)
def roar(sec):                       # a big fire: low rumble plus crackle
    x = m.lp(m.noise(sec), .02) * 1.5 + m.crackle(sec) * .6
    return x / (abs(x).max() + 1e-9)

# hook: river on one side, fire on the other
m.bed(0, 9.8, river, .10); m.bed(0, 9.8, roar, .12)
m.place(5.5, m.whoosh(.9, .05), .3); m.place(5.6, m.thud(48, 1.2, 4), .3)      # title
# the whisper: night, boots, a torch hum
m.bed(9.6, 23.7, m.night, .05)
for i in range(8):
    m.place(10.2 + i * .9, m.step(False), .06)
m.place(13.4, m.rustle(.5), .08)
# the square: river, fire, crowd; heat; the crowd at the announcement
m.bed(23.5, 37.2, river, .07); m.bed(23.5, 37.2, roar, .12); m.bed(23.5, 37.2, crowd, .08)
m.bed(32.5, 37.2, crowd, .10)
# slow motion run: muffled, low
m.bed(37, 41.2, lambda s: m.lp(crowd(s), .2), .12); m.bed(37, 41.2, river, .08)
for i in range(6):
    m.place(37.2 + i * .65, m.thud(70, .25, 10), .12)
# memory: quiet room
m.bed(41, 44.7, m.room, .05)
# the swap
m.bed(44.5, 51.7, river, .06); m.bed(44.5, 51.7, roar, .06)
m.place(45.0, m.whoosh(1.0, .05), .12); m.place(47.6, m.whoosh(1.0, .05), .12)
# carrying Hawa toward the fire
m.bed(51.5, 56.2, roar, .14); m.place(51.7, m.rustle(.6), .1)
# recitation: the fire held low, a heartbeat that slows
m.bed(56, 69.7, roar, .06); m.heartbeat(56.2, 69.4, start=1.0, floor=.6, gain=.3)
for k in (60.6, 62.0, 63.4):
    m.place(k, m.thud(220, .25, 18), .08)
# into the flames, then everything cut at the white
m.bed(69.5, 75.9, roar, .22, .8)
m.silence(76, 87)
# closing
m.bed(87.3, 104.3, m.room, .03, 1.5)
m.place(99.95, m.thud(260, .15, 30), .14); m.place(100.5, m.thud(380, .1, 40), .07)

m.write(sys.argv[1], vo=sys.argv[2] if len(sys.argv) > 2 else None)
