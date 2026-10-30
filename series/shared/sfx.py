"""Shared sound-design toolkit for สี่สิบวันของอาดัม (EP02 onward).

Foley and ambience only, no melodic instruments. Cues are written on the
episode's authored ("old") timeline; with a warp file (build_timing.py) they
move onto the voiceover timeline so effects stay on their picture.

    from sfx import Mix
    m = Mix(total, warp='audio/warp.json')   # warp optional
    m.bed(0, 9, m.wind, .16)
    m.place(2.2, m.drop(), .3)
    m.write('out.wav', vo='audio/vo_placed.wav')
"""
import json, wave
import numpy as np
from scipy.signal import lfilter

SR = 44100


class Mix:
    def __init__(self, total, warp=None, seed=7):
        self.old, self.new = [0, total], [0, total]
        if warp:
            w = json.load(open(warp)); self.old, self.new = zip(*w['anchors']); total = w['total']
        self.total = total
        self.n = int(SR * total)
        self.L = np.zeros(self.n); self.R = np.zeros(self.n)
        self.rng = np.random.default_rng(seed)
        self.silences = []

    # time on the final timeline
    def W(self, sec):
        return float(np.interp(sec, self.old, self.new))

    # ---- placing ----
    def place(self, sec, sig, gain=1.0, pan=0.0):
        i = int(self.W(sec) * SR); j = min(self.n, i + len(sig))
        if j <= i: return
        self.L[i:j] += sig[: j - i] * gain * (1 - max(0, pan))
        self.R[i:j] += sig[: j - i] * gain * (1 + min(0, pan))

    def bed(self, a, b, fn, gain, fade=0.6):
        d = self.W(b) - self.W(a); k = int(d * SR)
        if k <= 0: return
        self.place(a, fn(d)[:k] * self.ar(k, fade, fade), gain)

    def silence(self, a, b):
        self.silences.append((a, b))

    # ---- building blocks ----
    @staticmethod
    def ar(k, a, r):
        e = np.ones(k); ia, ir = min(k, int(a * SR)), min(k, int(r * SR))
        if ia: e[:ia] = np.linspace(0, 1, ia)
        if ir: e[k - ir:] = np.minimum(e[k - ir:], np.linspace(1, 0, ir))
        return e

    @staticmethod
    def lp(x, a): return lfilter([a], [1, a - 1], x)
    def hp(self, x, a): return x - self.lp(x, a)
    def noise(self, sec): return self.rng.standard_normal(int(sec * SR))
    @staticmethod
    def env_exp(sec, tau): return np.exp(-np.arange(int(sec * SR)) / (tau * SR))
    @staticmethod
    def tone(f0, f1, sec, decay):
        k = np.arange(int(sec * SR)) / SR
        return np.sin(2 * np.pi * (f0 * k + (f1 - f0) * k * k / (2 * sec))) * np.exp(-k * decay)
    @staticmethod
    def thud(f, sec, decay):
        k = np.arange(int(sec * SR)) / SR
        return np.sin(2 * np.pi * f * k) * np.exp(-k * decay)
    def whoosh(self, sec, a=.3): return self.hp(self.lp(self.noise(sec), a), .02) * np.hanning(int(sec * SR))
    def click(self, sec=.03): return self.hp(self.noise(sec), .4) * np.hanning(int(sec * SR))

    # beds (return a function of length)
    def wind(self, sec):
        x = self.lp(self.noise(sec), .015); x /= np.abs(x).max() + 1e-9
        t = np.arange(len(x)) / SR
        return x * (.55 + .45 * np.sin(t * .5) * np.sin(t * .23 + 1))
    def room(self, sec):
        x = self.lp(self.noise(sec), .03); return x / (np.abs(x).max() + 1e-9)
    def night(self, sec):
        x = self.lp(self.noise(sec), .01); return x / (np.abs(x).max() + 1e-9)
    def crackle(self, sec):
        k = int(sec * SR); x = self.lp(self.noise(sec), .2) * .15
        for _ in range(int(sec * 6)):
            i = self.rng.integers(0, max(1, k - 400)); x[i:i + 300] += self.hp(self.noise(300 / SR), .5)[:300] * np.exp(-np.arange(300) / 40) * self.rng.uniform(.3, 1)
        return x
    def birds(self, sec):           # sparse morning chirps
        k = int(sec * SR); x = np.zeros(k)
        for _ in range(int(sec * 1.6)):
            i = self.rng.integers(0, max(1, k - 9000)); f = self.rng.uniform(2600, 4200)
            for r in range(self.rng.integers(2, 5)):
                c = self.tone(f, f * self.rng.uniform(1.1, 1.4), .07, 30); j = i + r * 3000
                x[j:j + len(c)] += c[: max(0, min(len(c), k - j))] * self.rng.uniform(.4, 1)
        return x
    def crickets(self, sec):
        t = np.arange(int(sec * SR)) / SR
        return np.sin(2 * np.pi * 4300 * t) * (np.sin(2 * np.pi * 30 * t) > .6) * (np.sin(2 * np.pi * .7 * t) > 0) * .3

    # spot effects
    def drop(self): return self.tone(1500, 600, .3, 20)
    def knock(self):
        k = np.arange(int(.3 * SR)) / SR
        return self.thud(105, .3, 28) + .5 * self.thud(180, .3, 40) + self.lp(self.noise(.3), .25) * np.exp(-k * 70) * .9
    def creak(self, sec=1.4):
        k = np.arange(int(sec * SR)) / SR
        return self.lp(np.sign(np.sin(2 * np.pi * (60 + 30 * np.sin(k * 4.5)) * k)) * np.hanning(len(k)), .06)
    def step(self, soft=True): return self.lp(self.noise(.06), .3 if soft else .5) * self.env_exp(.06, .007)
    def rustle(self, sec=.5): return self.hp(self.lp(self.noise(sec), .3), .05) * np.hanning(int(sec * SR))
    def tick(self): return self.hp(self.noise(.012), .6) * self.env_exp(.012, .0014)
    def heartbeat(self, a, b, start=1.0, floor=.55, gain=.55):
        s, beat = a, start
        while s < b:
            self.place(s, self.thud(55, .25, 18), gain); self.place(s + .18, self.thud(48, .25, 22), gain * .64)
            beat = max(floor, beat * .96); s += beat

    # ---- output ----
    def write(self, path, vo=None, lufs_hint=True):
        mix = np.stack([self.L, self.R], 1)
        for a, b in self.silences:
            mix[int(self.W(a) * SR):int(self.W(b) * SR)] *= 0
        if vo:
            with wave.open(vo) as w:
                v = np.frombuffer(w.readframes(w.getnframes()), np.int16).reshape(-1, w.getnchannels()).astype(float).mean(1) / 32767
            v = np.pad(v, (0, max(0, self.n - len(v))))[: self.n]
            env = self.lp(np.abs(v), .002) * 6
            mix *= (1 - np.clip(env, 0, .6))[:, None]            # duck effects under the voice
            mix += v[:, None] * 2.2
        mix /= max(1e-9, np.abs(mix).max()) / .8
        with wave.open(path, 'wb') as w:
            w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((mix * 32767).astype(np.int16).tobytes())
