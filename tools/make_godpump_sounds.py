"""GOD PUMP placeholder sounds (#37), synthesized so the game has a voice until real recordings arrive.

    python3 tools/make_godpump_sounds.py

Writes into assets/audio/placeholder/: applause (the regulars), cash (a register ding), horn (a car
complaining), choir (the heavenly "AAAH" of the intro), truck (the fuel truck arriving, air brakes).
Pure Python, no dependencies.
"""
import math, os, random, struct, wave

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "placeholder")
random.seed(1985)


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = min(1.0, 0.95 / peak)
    with wave.open(os.path.join(OUT, name), "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale * 32000)) for s in samples))


def lowpass(samples, k):
    out, y = [], 0.0
    for s in samples:
        y += k * (s - y)
        out.append(y)
    return out


def applause(dur=2.2):
    """Many short hand claps (bursts of noise) thinning out."""
    n = int(RATE * dur)
    out = [0.0] * n
    for c in range(260):
        start = int(random.random() ** 1.6 * (n - 4000))
        length = random.randint(700, 1600)
        vol = random.uniform(0.2, 0.6)
        for i in range(length):
            out[start + i] += vol * random.uniform(-1, 1) * math.exp(-i / (length * 0.25))
    hp = []
    prev = 0.0
    for s in out:  # a crude high-pass: claps are bright
        hp.append(s - prev * 0.6)
        prev = s
    return [s * min(1.0, (n - i) / (RATE * 0.6)) for i, s in enumerate(hp)]


def cash(dur=0.9):
    """The register: a two-tone bell and a rattle of coins."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        bell = math.sin(2 * math.pi * 1568 * t) * math.exp(-5 * t) + 0.7 * math.sin(2 * math.pi * 2093 * max(0, t - 0.09)) * math.exp(-5 * max(0, t - 0.09)) * (t > 0.09)
        rattle = random.uniform(-1, 1) * 0.25 * math.exp(-14 * t) if t < 0.3 else 0
        out.append(0.6 * bell + rattle)
    return out


def horn(dur=0.6):
    """An old car horn: two detuned buzzy tones."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        e = min(1, t / 0.02) * min(1, (dur - t) / 0.05)
        v = sum((1 if math.sin(2 * math.pi * f * t) > 0 else -1) * 0.5 for f in (392, 466))
        out.append(e * v * 0.4)
    return lowpass(out, 0.18)


def choir(dur=3.4):
    """The heavens: a held major chord sung on 'AAH' (harmonics weighted toward the vowel's formants),
    with a slow swell and a little vibrato."""
    n = int(RATE * dur)
    chord = [220.0, 277.18, 329.63, 440.0, 554.37]
    formants = [(730, 90), (1090, 110), (2440, 160)]

    def weight(f):
        return sum(math.exp(-((f - c) / bw) ** 2 / 2) for c, bw in formants) + 0.15

    voices = []
    for base in chord:
        for detune in (-0.004, 0.0, 0.005):
            f0 = base * (1 + detune)
            harmonics = [(h, weight(f0 * h) / h ** 0.3) for h in range(1, 14)]
            voices.append((f0, harmonics, random.random() * 6))
    out = []
    for i in range(n):
        t = i / RATE
        swell = min(1, t / 0.9) * min(1, (dur - t) / 0.8)
        v = 0.0
        for f0, harmonics, ph in voices:
            vib = 1 + 0.006 * math.sin(2 * math.pi * 5.2 * t + ph)
            for h, w in harmonics:
                v += w * math.sin(2 * math.pi * f0 * vib * h * t + ph * h)
        out.append(swell * v)
    return out


def truck(dur=2.6):
    """The fuel truck: a diesel rumble rolling in, then the hiss of the air brakes."""
    n = int(RATE * dur)
    noise = [random.uniform(-1, 1) for _ in range(n)]
    rumble = lowpass(noise, 0.02)
    out = []
    for i in range(n):
        t = i / RATE
        engine = 0.6 * math.sin(2 * math.pi * 48 * t) * (0.6 + 0.4 * math.sin(2 * math.pi * 7 * t))
        fade_in = min(1, t / 0.8)
        brake = 0.0
        if t > 1.9:
            brake = random.uniform(-1, 1) * 0.5 * math.exp(-(t - 1.9) * 4)
        out.append(fade_in * (engine + rumble[i] * 3.0) * (1.0 if t < 1.9 else 0.5) + brake)
    return out


if __name__ == "__main__":
    write("applause.wav", applause())
    write("cash.wav", cash())
    write("horn.wav", horn())
    write("choir.wav", choir())
    write("truck.wav", truck())
    print("wrote applause, cash, horn, choir, truck")
