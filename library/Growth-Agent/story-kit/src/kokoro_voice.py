"""Voice a story script with Kokoro, a free text-to-speech model that runs locally, and write word timings.

python3 kokoro_voice.py <workspace> <slug> [--voice af_bella] [--speed 1.1] [--wpm 255]

Reads   <workspace>/videos/<slug>/script.txt  (one line or more of narration; lines starting with # are skipped)
Writes  <workspace>/videos/<slug>/audio/voice.wav (48 kHz mono), voice.m4a, words.json, sentences.json

Each sentence is synthesized alone, its silences trimmed, with 0.20 s between sentences. Word times inside
a sentence are spread by syllable weight, so no speech aligner is needed. words.json drives word-by-word
captions; sentences.json gives each sentence's start and end in seconds and frames (30 fps).

Needs ffmpeg on PATH and Python with numpy, soundfile and kokoro-onnx. The model files kokoro-v1.0.onnx
and voices-v1.0.bin go in KOKORO_DIR (default: ./kokoro).
"""
import json
import os
import re
import subprocess
import sys

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

if len(sys.argv) < 3:
    sys.exit(__doc__)
ws, slug = sys.argv[1], sys.argv[2]
args = sys.argv[3:]


def opt(name, default):
    return args[args.index(name) + 1] if name in args else default


voice = opt("--voice", os.environ.get("KOKORO_VOICE", "af_bella"))
speed = float(opt("--speed", 1.1))
wpm = float(opt("--wpm", 255))
KD = os.environ.get("KOKORO_DIR", os.path.join(os.getcwd(), "kokoro"))
vd = os.path.join(ws, "videos", slug)
ad = os.path.join(vd, "audio")
os.makedirs(ad, exist_ok=True)

lines = [l.strip() for l in open(os.path.join(vd, "script.txt"), encoding="utf-8") if l.strip() and not l.startswith("#")]
sents = []
for l in lines:
    sents += [s for s in re.split(r"(?<=[.!?])\s+", l) if s]
k = Kokoro(os.path.join(KD, "kokoro-v1.0.onnx"), os.path.join(KD, "voices-v1.0.bin"))
SR = 48000
FPS = 30


def trim(x, sr):
    """Cut the silence off both ends, keeping 20 ms of room."""
    a = np.abs(x)
    thr = max(a.max() * 0.02, 1e-4)
    idx = np.where(a > thr)[0]
    if not len(idx):
        return x
    pad = int(0.02 * sr)
    return x[max(0, idx[0] - pad): idx[-1] + pad]


def syl(w):
    """A rough syllable count, used only to share a sentence's time between its words."""
    w = re.sub(r"[^a-z]", "", w.lower())
    return max(1, len(re.findall(r"[aeiouy]+", w)) - (1 if w.endswith("e") and len(w) > 3 else 0)) + 0.4


chunks, words, sj, t = [], [], [], 0.0
wi = 0
for si, s in enumerate(sents):
    a, sr = k.create(s, voice=voice, speed=speed, lang="en-us")
    a = trim(np.asarray(a, dtype=np.float32), sr)
    n = int(len(a) * SR / sr)
    a = np.interp(np.linspace(0, len(a) - 1, n), np.arange(len(a)), a).astype(np.float32)
    dur = len(a) / SR
    ws_ = s.split()
    wts = np.array([syl(w) for w in ws_])
    edges = np.concatenate([[0], np.cumsum(wts) / wts.sum()]) * dur
    first = wi
    for j, w in enumerate(ws_):
        words.append({"word": w, "start": round(t + edges[j], 3), "end": round(t + edges[j + 1], 3)})
        wi += 1
    sj.append({"text": s, "start": round(t, 3), "end": round(t + dur, 3), "words": [first, wi - 1]})
    chunks.append(a)
    t += dur
    gap = 0.20 if si < len(sents) - 1 else 0.0
    chunks.append(np.zeros(int(gap * SR), np.float32))
    t += gap
v = np.concatenate(chunks)

# Speed the whole track up or down to hit the target words per minute, within sane limits.
cur = len(words) / (t / 60)
f = max(0.9, min(1.35, wpm / cur))
raw = os.path.join(ad, "raw48.wav")
sf.write(raw, v, SR)
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", raw, "-af", f"atempo={f:.4f}", "-ar", "48000", "-ac", "1",
                os.path.join(ad, "voice.wav")], check=True)
for w in words:
    w["start"] = round(w["start"] / f, 3)
    w["end"] = round(w["end"] / f, 3)
for s in sj:
    s["start"] = round(s["start"] / f, 3)
    s["end"] = round(s["end"] / f, 3)
    s["startFrame"] = int(s["start"] * FPS)
    s["endFrame"] = int(s["end"] * FPS)
json.dump(words, open(os.path.join(ad, "words.json"), "w"), indent=0)
json.dump(sj, open(os.path.join(ad, "sentences.json"), "w"), indent=1)
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", os.path.join(ad, "voice.wav"), "-c:a", "aac", "-b:a", "192k",
                os.path.join(ad, "voice.m4a")], check=True)
print(f"{voice}: {len(words)} words, {t / f:.2f} s, {len(words) / (t / f / 60):.0f} wpm (tempo x{f:.3f}); "
      f"words before 15 s: {sum(1 for w in words if w['start'] < 15)}")
