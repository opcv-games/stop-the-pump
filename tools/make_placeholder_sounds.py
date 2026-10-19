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
    """Soft electric-piano-ish tone: sine + a little 2nd harmonic, quick attack, slow decay."""
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

# --- Melody: the player's stops, on top of the band (#12) ----------------------
# Gas Bar Blues is a 12-bar blues in A: three dominant-7th chords, A7, D7, E7.
# Super Perfect: 3 notes strummed (root, 3rd, flat 7th). Perfect: root + 5th. Good: root.
# Miss: two notes that clash with the chord. OK plays nothing.
MELODY_ROOTS = {"A7": 69, "D7": 62, "E7": 64}


def strum(midis, gap=0.025, dur=0.9, vol=0.5):
    n = int(RATE * (dur + gap * len(midis)))
    out = [0.0] * n
    for k, m in enumerate(midis):
        part = keys([note(m)], dur, vol)
        off = int(RATE * gap * k)
        for i, v in enumerate(part):
            out[off + i] += v / math.sqrt(len(midis))
    return out


for name, root in MELODY_ROOTS.items():
    write("note_%s_good.wav" % name, strum([root]))
    write("note_%s_perfect.wav" % name, strum([root, root + 7]))
    write("note_%s_super.wav" % name, strum([root, root + 4, root + 10]))
    bad = []
    for i in range(int(RATE * 0.5)):
        t = i / RATE
        e = min(1, t / 0.005) * math.exp(-5 * t)
        bad.append(0.3 * e * (square(2 * math.pi * note(root + 1) * t) + square(2 * math.pi * note(root + 6) * t)) / 2)
    write("note_%s_bad.wav" % name, bad)

# --- Backing band: one 12-bar chorus in A at 90 BPM, shuffle feel, loops seamlessly ----
BPM = 90
BEAT = 60.0 / BPM
BAR = BEAT * 4
TWELVE_BAR = ["A7", "A7", "A7", "A7", "D7", "D7", "A7", "A7", "E7", "D7", "A7", "E7"]
BASS_ROOTS = {"A7": 45, "D7": 50, "E7": 52}
BOOGIE = [0, 4, 7, 9, 10, 9, 7, 4]  # classic walking boogie bass, one note per swung eighth
mix = [0.0] * int(RATE * BAR * 12)


def add(at, samples):
    off = int(at * RATE)
    for i, v in enumerate(samples):
        if off + i < len(mix):
            mix[off + i] += v


def bass(midi, dur):
    f = note(midi)
    return [0.5 * min(1, (i / RATE) / 0.005) * math.exp(-4 * i / RATE)
            * (math.sin(2 * math.pi * f * i / RATE) + 0.5 * math.sin(4 * math.pi * f * i / RATE)
               + 0.25 * math.sin(6 * math.pi * f * i / RATE)) / 1.75 for i in range(int(RATE * dur))]


def noise(dur, vol, decay):
    return [vol * math.exp(-decay * i / RATE) * random.uniform(-1, 1) for i in range(int(RATE * dur))]


def kick():
    out, ph = [], 0.0
    for i in range(int(RATE * 0.15)):
        t = i / RATE
        ph += 2 * math.pi * (50 + 70 * math.exp(-30 * t)) / RATE
        out.append(0.55 * math.exp(-18 * t) * math.sin(ph))
    return out


for b, chord in enumerate(TWELVE_BAR):
    for beat in range(4):
        on = b * BAR + beat * BEAT
        off = on + BEAT * 2 / 3  # swung eighth
        add(on, bass(BASS_ROOTS[chord] + BOOGIE[beat * 2], BEAT * 2 / 3))
        add(off, bass(BASS_ROOTS[chord] + BOOGIE[beat * 2 + 1], BEAT / 3))
        add(off, noise(0.04, 0.07, 90))
        add(on, noise(0.03, 0.05, 120))
        add(on, kick() if beat in (0, 2) else noise(0.12, 0.14, 30))
peak = max(abs(v) for v in mix)
write("backing_12bar.wav", [v * 0.6 / peak for v in mix])
print("ok")
