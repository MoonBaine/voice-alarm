"""Generuje domyslne dzwieki budzika (WAV) - bez zewnetrznych zaleznosci."""
import math, struct, wave, os

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")

def tone(freq, dur, vol=0.5, harmonics=((1, 1.0),)):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        env = min(1.0, i / (SR * 0.005), (n - i) / (SR * 0.02))
        s = sum(a * math.sin(2 * math.pi * freq * h * t) for h, a in harmonics)
        out.append(vol * env * s / sum(a for _, a in harmonics))
    return out

def silence(dur):
    return [0.0] * int(SR * dur)

def save(name, samples):
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))

# 1. Klasyczny budzik: seria szybkich beepow
beep = tone(2000, 0.08, 0.6, ((1, 1.0), (2, 0.3)))
classic = []
for _ in range(3):
    for _ in range(4):
        classic += beep + silence(0.07)
    classic += silence(0.35)
save("classic_beep.wav", classic)

# 2. Polifoniczna melodia (akordy, styl starych telefonow)
N = {"C5": 523.25, "E5": 659.25, "G5": 783.99, "C6": 1046.5, "D5": 587.33, "F5": 698.46, "A5": 880.0, "B5": 987.77}
def chord(notes, dur):
    parts = [tone(N[n], dur, 0.5, ((1, 1.0), (2, 0.2))) for n in notes]
    return [sum(v) / len(parts) * 1.4 for v in zip(*parts)]
melody = []
for notes, d in [(("C5", "E5"), .18), (("E5", "G5"), .18), (("G5", "C6"), .18), (("E5", "G5"), .18),
                 (("D5", "F5"), .18), (("F5", "A5"), .18), (("A5", "B5"), .18), (("F5", "A5"), .18),
                 (("C5", "E5", "G5"), .5)]:
    melody += chord(notes, d) + silence(0.03)
melody += silence(0.4)
save("polyphonic_melody.wav", melody)

# 3. Syrena narastajaca
siren = []
for cycle in range(4):
    for i in range(int(SR * 0.6)):
        f = 600 + 600 * (i / (SR * 0.6))
        siren.append(0.5 * math.sin(2 * math.pi * f * (i / SR)))
    for i in range(int(SR * 0.6)):
        f = 1200 - 600 * (i / (SR * 0.6))
        siren.append(0.5 * math.sin(2 * math.pi * f * (i / SR)))
save("rising_siren.wav", siren)
print("OK")
