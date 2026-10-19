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
write("perfect.wav", seq(tone([1318.5], 0.09, 0.5), tone([1975.5, 1318.5], 0.45, 0.5)))
write("good.wav", tone([1046.5], 0.3, 0.45))
write("ok.wav", tone([392.0], 0.18, 0.4, release=0.5))
write("miss.wav", tone([110.0, 116.0], 0.4, 0.35, wave_fn=square, release=0.3))


# Chord progression for good stops (playtest 7): C - G - Am - F. Perfect adds a bright top note.
def note(n):  # MIDI note number to Hz
    return 440.0 * 2 ** ((n - 69) / 12)


def keys(freqs, dur=0.7, vol=0.45):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        e = min(1, t / 0.004) * math.exp(-3.2 * t)
        v = sum(math.sin(2 * math.pi * f * t) + 0.35 * math.sin(4 * math.pi * f * t) for f in freqs)
        out.append(vol * e * v / (len(freqs) * 1.35))
    return out


CHORDS = {"C": [60, 64, 67], "G": [55, 59, 62], "Am": [57, 60, 64], "F": [53, 57, 60]}
for name, notes in CHORDS.items():
    write("chord_%s.wav" % name, keys([note(m) for m in notes]))
    write("chord_%s_perfect.wav" % name, keys([note(m) for m in notes] + [note(notes[0] + 24), note(notes[2] + 12)], vol=0.5))

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
