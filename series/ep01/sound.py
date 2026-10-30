"""Preview soundtrack for EP01, synthesized so every render matches the picture.
Placeholder only: replace with voiceover, music and real foley for the final cut.
Usage: python3 sound.py out.wav
"""
import sys, wave
import numpy as np

SR, TOTAL = 44100, 103.0
rng = np.random.default_rng(7)
n = int(SR * TOTAL)
t = np.arange(n) / SR
out = np.zeros(n)

def at(sec, sig, gain=1.0):
    i = int(sec * SR)
    j = min(n, i + len(sig))
    out[i:j] += sig[: j - i] * gain

def env(length, a, r):
    k = int(length * SR); e = np.ones(k)
    ia, ir = int(a * SR), int(r * SR)
    e[:ia] = np.linspace(0, 1, ia); e[k - ir:] = np.linspace(1, 0, ir)
    return e

def lowpass(x, alpha):
    y = np.empty_like(x); acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc); y[i] = acc
    return y

# dry wind bed under the story (0-91s), breathing slowly
wind = lowpass(rng.standard_normal(int(91 * SR)), 0.02)
wind *= (0.6 + 0.4 * np.sin(np.arange(len(wind)) / SR * 0.35)) * env(91, 2, 1.5)
at(0, wind / np.abs(wind).max(), 0.10)

# low drone that tightens towards the cliffhanger
for f, g in ((55, .05), (82.4, .03)):
    d = np.sin(2 * np.pi * f * t[: int(91 * SR)]) * env(91, 4, .05)
    at(0, d, g)

# single water drop at 2.2s
k = np.arange(int(.35 * SR)) / SR
drop = np.sin(2 * np.pi * (1400 - 2600 * k) * k) * np.exp(-k * 22)
at(2.2, drop, .35)

# clips spreading (25.2s): soft whooshes
for i in range(10):
    w = lowpass(rng.standard_normal(int(.3 * SR)), .2) * np.hanning(int(.3 * SR))
    at(25.2 + i * .18, w, .08)

# signal lost: three falling blips
for i, s in enumerate((39.65, 39.3, 38.95)):
    k = np.arange(int(.12 * SR)) / SR
    at(s, np.sin(2 * np.pi * (880 - i * 180) * k) * np.exp(-k * 25), .12)

# three slow knocks on wood
for s in (55, 56.2, 57.4):
    k = np.arange(int(.25 * SR)) / SR
    knock = (np.sin(2 * np.pi * 110 * k) + .6 * np.sin(2 * np.pi * 190 * k)) * np.exp(-k * 30)
    knock += lowpass(rng.standard_normal(len(k)), .3) * np.exp(-k * 60) * .8
    at(s, knock, .55)

# door creak 58.0-59.4
k = np.arange(int(1.4 * SR)) / SR
creak = np.sign(np.sin(2 * np.pi * (70 + 40 * np.sin(k * 5)) * k)) * np.hanning(len(k))
at(58, lowpass(creak, .08), .10)

# water drips from Harith (58-79)
for i in range(40):
    s = 59 + i * .5 + rng.random() * .3
    k = np.arange(int(.12 * SR)) / SR
    at(s, np.sin(2 * np.pi * (1800 + rng.random() * 600) * k) * np.exp(-k * 50), .04)

# tension swell into the cut to black at 91s
k = np.arange(int(12 * SR)) / SR
swell = (np.sin(2 * np.pi * 110 * k) + np.sin(2 * np.pi * 116.5 * k)) * (k / 12) ** 2
at(79, swell, .10)

# soft pad under the CTA and disclaimer
k = np.arange(int(11.5 * SR)) / SR
pad = sum(np.sin(2 * np.pi * f * k) for f in (220, 277.2, 329.6)) * env(11.5, 1.5, 2)
at(91.5, pad, .025)

out /= max(1e-9, np.abs(out).max()) / 0.8
pcm = (np.repeat(out[:, None], 2, axis=1) * 32767).astype(np.int16)
with wave.open(sys.argv[1], 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
