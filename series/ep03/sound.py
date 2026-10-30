"""EP03 sound design, cued to index.html. Foley and ambience only.
Usage: python3 sound.py out.wav [audio/vo_placed.wav audio/warp.json]
"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from sfx import Mix

m = Mix(106.3, warp=sys.argv[3] if len(sys.argv) > 3 else None)

# 1. the watch, ticking loud and clear (document: "เสียงเข็มเดินดังชัด")
m.bed(0, 9.8, m.room, .04)
for s in range(0, 10):
    m.place(s, m.tick(), .45, pan=.2)
m.place(5.5, m.whoosh(.9, .05), .3); m.place(5.6, m.thud(48, 1.2, 4), .3)   # title

# 2. crowd at the mosque under the glare
def crowd(sec):
    x = sum(m.lp(m.noise(sec), .06) * (.4 + .6 * abs(__import__('numpy').sin(__import__('numpy').arange(int(sec * 44100)) / 44100 * f))) for f in (1.3, 2.1, 2.9, 3.7))
    return m.hp(x, .01) / (abs(x).max() + 1e-9)
m.bed(9.6, 20.8, crowd, .12); m.bed(9.6, 20.8, m.wind, .05)
for i in range(10):                                       # running feet
    m.place(12.7 + i * .22, m.step(False), .14, pan=-.2)
# 3. the shaykh raises his hand: the crowd falls quiet
m.bed(20.6, 21.6, crowd, .08, .2)
m.bed(21.4, 34.2, m.room, .05); m.place(20.9, m.rustle(.6), .16)
# watch again
for s in range(34, 37):
    m.place(s + .05, m.tick(), .4, pan=.2)
# 4. charcoal scratching the plaster, one stroke per prayer
for i in range(5):
    m.place(41.3 + i * .9, m.hp(m.noise(.6), .25) * m.ar(int(.6 * 44100), .05, .2), .07)
m.bed(37, 46.7, m.room, .05)
# 5. a knock, the door, a neighbour asking the time
m.place(46.3, m.knock(), .4); m.place(46.9, m.knock(), .35)
m.bed(46.5, 55.7, m.room, .05); m.bed(46.5, 55.7, m.wind, .04)
# 6-7. verses, then the empty plate
for i in range(7):
    m.place(56.3 + i * .2, m.hp(m.noise(.25), .4) * m.env_exp(.25, .05), .035)
m.bed(55.5, 63.7, m.room, .05)
m.place(61.0, m.thud(220, .12, 35), .08)                  # crumbs on the plate
# 8. fever: quiet room, Salma's hand
m.bed(63.5, 72.7, m.room, .05)
m.place(64.0, m.rustle(.8), .14)
# 9. at the window: distant rain on a few roofs, then silence on the cut
def rain(sec):
    return m.hp(m.lp(m.noise(sec), .35), .05) * .6
m.bed(72.5, 89, m.wind, .05)
m.bed(77.2, 89, rain, .09, 1.5)
m.place(78.0, m.thud(40, 2.0, 1.5), .12)                  # far thunder
m.silence(89, 89.6)

# closing
m.bed(89.4, 106.3, m.room, .03, 1.5)
m.place(101.95, m.thud(260, .15, 30), .14); m.place(102.5, m.thud(380, .1, 40), .07)

m.write(sys.argv[1], vo=sys.argv[2] if len(sys.argv) > 2 else None)
