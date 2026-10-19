"""Generates placeholder greybox sounds into assets/audio/placeholder/. Replace in Phase 4."""
import math, os, random, struct, wave

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "placeholder")


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32000)) for s in samples))


def env(i, n, attack=0.005, release=0.5):
    t = i / RATE; dur = n / RATE
    a = min(1, t / attack) if attack else 1
    r = max(0, 1 - max(0, t - (dur - dur * release)) / (dur * release)) if release else 1
    return a * r


def square(x):
    return 1.0 if math.sin(x) >= 0 else -1.0


def note(n):  # MIDI note number to Hz
    return 440.0 * 2 ** ((n - 69) / 12)


def keys(freqs, dur=0.8, vol=0.45):
    """Soft bell-ish tone: sine + a little 2nd harmonic, quick attack, slow decay."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        e = min(1, t / 0.004) * math.exp(-2.8 * t)
        v = sum(math.sin(2 * math.pi * f * t) + 0.35 * math.sin(4 * math.pi * f * t) for f in freqs)
        out.append(vol * e * v / (len(freqs) * 1.35))
    return out


random.seed(7)

# --- Pump -----------------------------------------------------------------
# Motor hum, exactly 1 s so it loops cleanly (all partials are whole Hz).
write("pour_loop.wav", [0.25 * (math.sin(2 * math.pi * 90 * i / RATE) + 0.5 * math.sin(2 * math.pi * 180 * i / RATE)
                               + 0.3 * square(2 * math.pi * 45 * i / RATE)) / 1.8 + 0.03 * random.uniform(-1, 1)
                        for i in range(RATE)])
write("tick.wav", [0.6 * env(i, 900, attack=0.0005, release=0.9) * random.uniform(-1, 1) for i in range(900)])

# --- Tier sound effects (#16): plain SFX, not tied to the music ----------------
def chime(midis, gap=0.06, dur=0.5, vol=0.45):
    n = int(RATE * (dur + gap * len(midis)))
    out = [0.0] * n
    for k, m in enumerate(midis):
        part = keys([note(m)], dur, vol)
        off = int(RATE * gap * k)
        for i, v in enumerate(part):
            out[off + i] += v / math.sqrt(len(midis))
    return out


write("sfx_super_perfect.wav", chime([84, 88, 91, 96], gap=0.05))  # bright rising "ka-ching" run
write("sfx_perfect.wav", chime([84, 91]))
write("sfx_good.wav", chime([79]))
write("sfx_ok.wav", [0.4 * min(1, (i / RATE) / 0.003) * math.exp(-22 * i / RATE) * math.sin(2 * math.pi * 180 * i / RATE)
                     for i in range(int(RATE * 0.2))])  # dull thunk
write("sfx_miss.wav", [0.3 * min(1, (i / RATE) / 0.005) * math.exp(-5 * i / RATE)
                       * (square(2 * math.pi * 98 * i / RATE) + square(2 * math.pi * 104 * i / RATE)) / 2
                       for i in range(int(RATE * 0.45))])  # buzzer
out, ph = [], 0.0
for i in range(int(RATE * 0.6)):  # combo break: a sagging "wah-wah"
    t = i / RATE
    ph += 2 * math.pi * (330 * (1 - 0.45 * t / 0.6)) / RATE
    out.append(0.35 * min(1, t / 0.01) * math.exp(-3 * t) * (0.6 * square(ph) + 0.4 * math.sin(ph)))
write("sfx_combo_break.wav", out)
print("ok")
