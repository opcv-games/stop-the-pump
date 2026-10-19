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


def tone(freqs, dur, vol=0.5, wave_fn=math.sin, release=0.7):
    n = int(RATE * dur)
    return [vol * env(i, n, release=release) * sum(wave_fn(2 * math.pi * f * i / RATE) for f in freqs) / len(freqs) for i in range(n)]


def square(x):
    return 1.0 if math.sin(x) >= 0 else -1.0


def seq(*parts):
    out = []
    for p in parts:
        out += p
    return out


random.seed(7)
# Motor hum, exactly 1 s so it loops cleanly (all partials are whole Hz).
write("pour_loop.wav", [0.25 * (math.sin(2 * math.pi * 90 * i / RATE) + 0.5 * math.sin(2 * math.pi * 180 * i / RATE)
                               + 0.3 * square(2 * math.pi * 45 * i / RATE)) / 1.8 + 0.03 * random.uniform(-1, 1)
                        for i in range(RATE)])
write("tick.wav", [0.6 * env(i, 900, attack=0.0005, release=0.9) * random.uniform(-1, 1) for i in range(900)])
write("ok.wav", tone([392.0], 0.18, 0.4, release=0.5))
write("miss.wav", tone([110.0, 116.0], 0.4, 0.35, wave_fn=square, release=0.3))


# Gas Bar Blues (playtest 8): a 12-bar blues in A uses three dominant-7th chords.
# Perfect adds the "blue note" (the flat third) on top, an octave up.
def note(n):  # MIDI note number to Hz
    return 440.0 * 2 ** ((n - 69) / 12)


def keys(freqs, dur=0.8, vol=0.45):
    """Soft electric-piano-ish tone: sine + a little 2nd harmonic, quick attack, slow decay."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        e = min(1, t / 0.004) * math.exp(-2.8 * t)
        v = sum(math.sin(2 * math.pi * f * t) + 0.35 * math.sin(4 * math.pi * f * t) for f in freqs)
        out.append(vol * e * v / (len(freqs) * 1.35))
    return out


# root, 3rd, 5th, flat 7th (voiced around middle C), and the blue note (flat 3rd of the key's chord root)
CHORDS = {"A7": ([45, 57, 61, 64, 67], 72), "D7": ([50, 57, 60, 62, 66], 77), "E7": ([52, 56, 59, 62, 64], 79)}
for name, (notes, blue) in CHORDS.items():
    write("chord_%s.wav" % name, keys([note(m) for m in notes]))
    write("chord_%s_perfect.wav" % name, keys([note(m) for m in notes] + [note(blue)], vol=0.5))

# The chain breaks: a detuned cluster that sags in pitch, like a tape slowing down.
n = int(RATE * 0.9)
out = []
phase = [0.0, 0.0, 0.0, 0.0]
base = [note(60), note(61), note(66), note(67)]
for i in range(n):
    t = i / RATE
    sag = 1.0 - 0.35 * (t / 0.9) ** 1.5
    e = min(1, t / 0.01) * math.exp(-2.5 * t)
    v = 0.0
    for k, f in enumerate(base):
        phase[k] += 2 * math.pi * f * sag / RATE
        v += square(phase[k]) * 0.5 + math.sin(phase[k]) * 0.5
    out.append(0.35 * e * v / 4)
write("chord_break.wav", out)
print("ok")
