"""EP02 sound design, cued to index.html. Foley and ambience only.
Usage: python3 sound.py out.wav [audio/vo_placed.wav audio/warp.json]
"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from sfx import Mix

m = Mix(124.3, warp=sys.argv[3] if len(sys.argv) > 3 else None)

# 1. bread in the dark; Hawa wakes to the smell
m.bed(0, 9.6, m.room, .05)
m.place(3.45, m.rustle(.6), .12)                          # she stirs
m.place(5.5, m.whoosh(.9, .05), .3); m.place(5.6, m.thud(48, 1.2, 4), .3)   # title

# 2-4. the doorway: night outside, lamp inside
m.bed(9.6, 52.3, m.night, .08); m.bed(9.6, 52.3, m.crackle, .14); m.bed(9.6, 44, m.wind, .05)
m.place(30.9, m.thud(140, .2, 25), .25)                   # bread set on the threshold
m.place(36.6, m.creak(4.6), .12)                          # the door swings slowly
m.place(41.2, m.click(.05), .3)                           # it stops short of the latch
for i in range(8):                                        # footsteps leaving in the dark
    m.place(41.7 + i * .3, m.step(False), .12 * (1 - i / 9), pan=.2 + i * .08)
for i in range(6):                                        # Hawa's small steps behind him
    m.place(44.7 + i * .33, m.step(), .14, pan=-.4 + i * .06)
m.place(48.6, m.rustle(.7), .2)                           # he kneels and holds her

# 5. morning at the mosque
m.bed(52, 56.8, m.birds, .10); m.bed(52, 56.8, m.wind, .05)
m.bed(56.5, 69.2, m.room, .06); m.bed(56.5, 69.2, m.birds, .03)
m.place(69.3, m.rustle(.5), .18)                          # the shaykh takes his hand
m.bed(69, 78.7, m.room, .05)

# 7. night, five verses
m.bed(78.5, 81.7, m.crickets, .03); m.bed(78.5, 81.7, m.crackle, .14)
for i in range(5):
    m.place(79.2 + i * .2, m.hp(m.noise(.25), .4) * m.env_exp(.25, .05), .04)

# 8. dawn: birds, a page, the watch ticking
m.bed(81.5, 90, m.birds, .08); m.bed(81.5, 107, m.room, .04)
for s in range(82, 90):
    m.place(s, m.tick(), .18, pan=.4)
# 9. time-lapse: ticks race, then only single ticks over the frozen sun
for (a, b) in ((90, 93.5), (96, 98)):
    s = a
    while s < b:
        m.place(s, m.tick(), .16, pan=.3); s += .045
for s in range(94, 96):
    m.place(s, m.tick(), .25, pan=.3)
for s in range(98, 107):
    m.place(s, m.tick(), .32, pan=.3)
m.place(98.2, m.whoosh(1.2, .03), .12)
m.silence(107, 107.6)                                     # cut to black

# closing
m.bed(107.4, 124.3, m.room, .03, 1.5)
m.place(119.95, m.thud(260, .15, 30), .14); m.place(120.5, m.thud(380, .1, 40), .07)

m.write(sys.argv[1], vo=sys.argv[2] if len(sys.argv) > 2 else None)
