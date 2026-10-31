"""EP06 sound design, cued to index.html. Foley and ambience only.
Usage: python3 sound.py out.wav [audio/vo_placed.wav audio/warp.json]
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from sfx import Mix, SR

m = Mix(102.3, warp=sys.argv[3] if len(sys.argv) > 3 else None)

def crowd(sec):
    t = np.arange(int(sec * SR)) / SR
    x = sum(m.lp(m.noise(sec), .06) * (.4 + .6 * abs(np.sin(t * f))) for f in (1.1, 1.9, 2.7, 3.3))
    return m.hp(x, .01) / (abs(x).max() + 1e-9)

# hook: rooftop wind, the far crowd, cloth pulled in a small hand
m.bed(0, 9.8, m.wind, .08); m.bed(0, 9.8, crowd, .05)
m.place(1.0, m.rustle(.6), .12)
m.place(5.5, m.whoosh(.9, .05), .3); m.place(5.6, m.thud(48, 1.2, 4), .3)      # title
# the face: the crowd falls away, a heartbeat; the letters arrive with soft ticks
m.bed(9.6, 29.2, crowd, .04); m.heartbeat(10.2, 28.8, start=.9, floor=.7, gain=.3)
for k in (25.6, 26.5, 27.4):
    m.place(k, m.thud(220, .25, 18), .10)
# ك ف ر: a low swell, then quiet
m.place(29.1, m.thud(60, 1.6, 3), .25)
# the crowd below cheers on
m.bed(32.5, 36.7, crowd, .18)
# Hawa on the ladder: creaks and small steps
m.bed(36.5, 49.7, crowd, .06); m.bed(36.5, 49.7, m.wind, .05)
m.place(37.0, m.creak(1.0), .10)
for i in range(5):
    m.place(37.3 + i * .45, m.step(), .12)
# the hug: cloth, the crowd still far off
m.bed(49.5, 59.7, crowd, .07); m.place(49.8, m.rustle(.8), .12)
# the half-smile and the turn: footsteps of the procession move on
m.bed(59.5, 63.7, crowd, .10)
for i in range(10):
    m.place(61.7 + i * .2, m.step(False), .07 * (1 - i / 12))
# night: crickets, pounding on doors
m.bed(63.5, 85, m.night, .05); m.bed(63.5, 85, m.crickets, .04)
for k in (64.1, 64.5, 64.9, 66.4, 66.8, 67.2):
    m.place(k, m.knock(), .45)
m.place(69.6, m.creak(1.4), .14)                                            # the shutter
m.heartbeat(70.2, 84.6, start=1.0, floor=.8, gain=.35)
m.place(73.0, m.rustle(.4), .06)                                            # the list in Harith's hand
m.silence(85, 85.4)
# closing
m.bed(85.3, 102.3, m.room, .03, 1.5)
m.place(97.95, m.thud(260, .15, 30), .14); m.place(98.5, m.thud(380, .1, 40), .07)

m.write(sys.argv[1], vo=sys.argv[2] if len(sys.argv) > 2 else None)
