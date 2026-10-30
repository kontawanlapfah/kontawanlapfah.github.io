"""EP01 sound design, synthesized so every render matches the picture.

Foley and ambience only (no melodic instruments), cued to the timeline in
index.html. Mixed low so a voiceover can sit on top.
Usage: python3 sound.py out.wav [voiceover.wav]
"""
import sys, wave
import numpy as np

SR, TOTAL = 44100, 107.5
rng = np.random.default_rng(7)
n = int(SR * TOTAL)
L = np.zeros(n); R = np.zeros(n)

def place(sec, sig, gain=1.0, pan=0.0):
    i = int(sec * SR); j = min(n, i + len(sig))
    L[i:j] += sig[: j - i] * gain * (1 - max(0, pan))
    R[i:j] += sig[: j - i] * gain * (1 + min(0, pan))

def ar(k, a, r):
    """attack/release envelope of k samples"""
    e = np.ones(k); ia, ir = int(a * SR), int(r * SR)
    if ia: e[:ia] = np.linspace(0, 1, ia)
    if ir: e[k - ir:] = np.minimum(e[k - ir:], np.linspace(1, 0, ir))
    return e

def lp(x, a):
    """one-pole low-pass, vectorised via cumulative filter"""
    from scipy.signal import lfilter
    return lfilter([a], [1, a - 1], x)

def hp(x, a):
    return x - lp(x, a)

def noise(sec):
    return rng.standard_normal(int(sec * SR))

def span(a, b):
    return int(a * SR), int(b * SR)

def bed(a, b, sig_fn, gain, fade=0.6):
    k = int((b - a) * SR); place(a, sig_fn(b - a)[:k] * ar(k, fade, fade), gain)

# --- ambience beds per location ---------------------------------------------
def wind(sec):          # dry desert wind, slow gusts
    x = lp(noise(sec), .015); x /= np.abs(x).max()
    tt = np.arange(len(x)) / SR
    return x * (.55 + .45 * np.sin(tt * .5) * np.sin(tt * .23 + 1))
def room(sec):          # quiet room tone
    x = lp(noise(sec), .03); return x / np.abs(x).max()
def crackle(sec):       # candle: sparse tiny ticks over a soft hiss
    k = int(sec * SR); x = lp(noise(sec), .2) * .15
    for _ in range(int(sec * 6)):
        i = rng.integers(0, k - 400); x[i:i + 300] += hp(noise(300 / SR), .5)[:300] * np.exp(-np.arange(300) / 40) * rng.uniform(.3, 1)
    return x
def murmur(sec):        # muffled crowd from a phone speaker
    tt = np.arange(int(sec * SR)) / SR
    x = sum(lp(noise(sec), .08) * (.5 + .5 * np.sin(tt * rng.uniform(2, 6) + rng.uniform(0, 6))) for _ in range(6))
    x = hp(lp(x, .12), .02); return x / np.abs(x).max()
def night(sec):         # night outside the open door
    x = lp(noise(sec), .01); return x / np.abs(x).max()

bed(0, 9, wind, .16, 1.0)                 # A dry city
bed(9, 17, room, .05); bed(9, 17, crackle, .25)
bed(17, 29, room, .04); bed(17.4, 29, murmur, .07)
bed(29, 41.5, room, .04)
bed(41.5, 49, room, .05); bed(41.5, 49, crackle, .18)
bed(49, 53, room, .05); bed(49, 53, crackle, .25)
bed(53, 54.6, room, .05, .3)              # near-silence before the knocks
bed(58, 79, night, .10, .8); bed(58, 79, wind, .06, .8)
bed(91.5, 107.5, room, .03, 1.5)

# --- spot effects cued to the picture ----------------------------------------
def tone(f0, f1, sec, decay):
    k = np.arange(int(sec * SR)) / SR
    return np.sin(2 * np.pi * (f0 * k + (f1 - f0) * k * k / (2 * sec))) * np.exp(-k * decay)
def thud(f, sec, decay):
    k = np.arange(int(sec * SR)) / SR
    return np.sin(2 * np.pi * f * k) * np.exp(-k * decay)
def whoosh(sec, a=.3):
    k = int(sec * SR); return hp(lp(noise(sec), a), .02) * np.hanning(k)

# B: small footsteps as Hawa walks to her mother (9.3-12.3s)
for i in range(8):
    place(9.5 + i * .385, lp(noise(.06), .3) * np.exp(-np.arange(int(.06 * SR)) / 300), .18, pan=.3 - i * .06)

# A: the single water drop and its splash on dry ground (drop lands 2.2s)
place(2.2, tone(1500, 600, .3, 20), .30)
place(2.22, hp(noise(.08), .3) * np.exp(-np.arange(int(.08 * SR)) / 300), .10)
# title card: low air hit
place(5.4, whoosh(.9, .05), .35); place(5.5, thud(48, 1.2, 4), .35)
# C: thumb taps play, clips fly out
place(17.3, hp(noise(.03), .4) * np.hanning(int(.03 * SR)), .25)
for i in range(10):
    place(25.2 + i * .18, whoosh(.35, .25), .07, pan=(-.6 if i % 2 else .6))
# D: voice message play tap, then signal drops bar by bar
place(32.9, hp(noise(.03), .4) * np.hanning(int(.03 * SR)), .25)
for i, s in enumerate((38.95, 39.3, 39.65, 40.0)):
    place(s, tone(900 - i * 120, 700 - i * 120, .1, 30), .07)
# E: page turn, then the watch ticks on every second the hand moves
place(41.6, hp(lp(noise(.5), .3), .05) * np.hanning(int(.5 * SR)), .25)
for s in range(42, 49):
    place(s, hp(noise(.012), .6) * np.exp(-np.arange(int(.012 * SR)) / 60), .22, pan=.5)
for i in range(3):                         # three verses light up
    place(45.8 + i * .35, hp(noise(.25), .4) * np.exp(-np.arange(int(.25 * SR)) / 2000), .05)
# F: three slow knocks on wood, felt through the door
for s in (55, 56.2, 57.4):
    k = np.arange(int(.3 * SR)) / SR
    knock = thud(105, .3, 28) + .5 * thud(180, .3, 40) + lp(noise(.3), .25) * np.exp(-k * 70) * .9
    place(s, knock, .65)
# G: latch, creaking hinge, drips, steam hiss
place(57.95, hp(noise(.05), .3) * np.exp(-np.arange(int(.05 * SR)) / 200), .25)
k = np.arange(int(1.4 * SR)) / SR
creak = np.sign(np.sin(2 * np.pi * (60 + 30 * np.sin(k * 4.5)) * k)) * np.hanning(len(k))
place(58.05, lp(creak, .06), .10)
for i in range(44):                        # drips land in rhythm with the visual loop
    place(59 + i * .47 + rng.random() * .15, tone(2200, 1400, .08, 55), .05, pan=rng.uniform(-.3, .3))
bed(59, 79, lambda s: hp(noise(s), .3), .012)
# whisper line lands closer: room drops away at 74s
# H: heartbeat speeds up under the dilemma, then the cut to black is silent
beat, s = 1.0, 79.2
while s < 90.8:
    place(s, thud(55, .25, 18), .55); place(s + .18, thud(48, .25, 22), .35)
    beat = max(.55, beat * .96); s += beat
place(79, whoosh(1.0, .04), .25)

# page logo pop-up: one soft pop as it appears
place(103.15, thud(260, .15, 30), .14); place(103.15, hp(noise(.08), .5) * np.exp(-np.arange(int(.08 * SR)) / 200), .035)
place(103.7, thud(380, .1, 40), .07)

# --- mix ---------------------------------------------------------------------
mix = np.stack([L, R], 1)
mix[span(91, 91.5)[0]:span(91, 91.5)[1]] *= 0                       # hard silence on the cut
if len(sys.argv) > 2:                                                # optional voiceover on top, ducked bed
    with wave.open(sys.argv[2]) as w:
        vo = np.frombuffer(w.readframes(w.getnframes()), np.int16).reshape(-1, w.getnchannels()).astype(float) / 32767
        if w.getframerate() != SR: raise SystemExit('voiceover must be 44.1 kHz wav')
    vo = vo.mean(1)[:n]; env = lp(np.abs(vo), .002) * 6
    mix *= (1 - np.clip(env, 0, .5))[:, None] if len(env) == n else 1
    mix[: len(vo)] += vo[:, None] * .9
mix /= max(1e-9, np.abs(mix).max()) / .8
with wave.open(sys.argv[1], 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((mix * 32767).astype(np.int16).tobytes())
