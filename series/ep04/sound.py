"""EP04 sound design, cued to index.html. Foley and ambience only.
Usage: python3 sound.py out.wav [audio/vo_placed.wav audio/warp.json]
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from sfx import Mix, SR

m = Mix(100.3, warp=sys.argv[3] if len(sys.argv) > 3 else None)

def rain(sec):
    return m.hp(m.lp(m.noise(sec), .35), .05) * .6
def bleat(sec=.7, f=420):
    k = np.arange(int(sec * SR)) / SR
    vib = f * (1 + .06 * np.sin(2 * np.pi * 7 * k))
    x = np.sign(np.sin(2 * np.pi * np.cumsum(vib) / SR)) * np.hanning(len(k))
    return m.lp(x, .08)

# 1. split: rain on the left (panned), dry wind on the right
m.bed(0, 9.8, lambda s: rain(s), .10)
m.bed(0, 9.8, m.wind, .10)
m.place(5.5, m.whoosh(.9, .05), .3); m.place(5.6, m.thud(48, 1.2, 4), .3)   # title
# 2. rain over two houses only
m.bed(9.6, 18.2, m.wind, .05); m.bed(10.5, 18.2, rain, .08, 1.0)
# 3. goats, then an empty dry pen
m.bed(18, 23.5, m.birds, .04)
for s, f in ((18.8, 420), (20.6, 380), (22.2, 450)):
    m.place(s, bleat(.6, f), .05)
m.bed(23.5, 28.2, m.wind, .12)
# 4. the watch racing through the month-long day
s = 28.0
while s < 35.2:
    m.place(s, m.tick(), .14, pan=.3); s += .06
# 5. the cloth: wringing, two drops, a near-empty bottle
m.bed(35, 42.2, m.room, .05)
m.place(35.4, m.rustle(2.4), .14)
for i in range(2):
    m.place(36.9 + i * .9, m.tone(1500, 700, .25, 22), .18)
m.place(39.0, m.hp(m.lp(m.noise(.6), .2), .03) * np.hanning(int(.6 * SR)), .08)   # water sloshing low
# 6. doubt: low room, heartbeat
m.bed(42, 47.2, m.room, .05)
m.heartbeat(42.3, 47, start=.9, floor=.8, gain=.35)
# 7. memory of the shaykh: softer room
m.bed(47, 53.2, m.room, .04)
# 8. prayer: quiet, cloth as he sits for the tashahhud
m.bed(53, 58.2, m.room, .05)
m.place(55.6, m.rustle(.7), .12)
# 9-10. Harith at the door: lamp, night air, the box rattling in his hands
m.bed(58, 83, m.night, .07); m.bed(58, 83, m.crackle, .12)
m.place(58.1, m.creak(1.2), .08)
s = 58.6
while s < 83:
    m.place(s, m.click(.015), .05, pan=.3); s += .11 + .05 * np.sin(s * 7)
m.silence(83, 83.6)                                       # cut to black

# closing
m.bed(83.4, 100.3, m.room, .03, 1.5)
m.place(95.95, m.thud(260, .15, 30), .14); m.place(96.5, m.thud(380, .1, 40), .07)

m.write(sys.argv[1], vo=sys.argv[2] if len(sys.argv) > 2 else None)
