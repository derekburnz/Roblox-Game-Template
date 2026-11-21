"""Re-voice a finished story without re-rendering: same sentence timings, a new Kokoro voice.

python3 revoice.py <workspace> <slug> [--voice am_eric] [--speed 1.3] [--replace "old words=new words"]

Each sentence is synthesized again, then time-fitted to its old slot in audio/sentences.json, so frames,
sound cues and captions stay in sync. --replace swaps a phrase in the script on the way (for example when
a trend's opening line changes); it may be given more than once. Keep the word count the same, because
words.json keeps its old timings and only the matching words are renamed.

The old audio is backed up once to audio/old_voice/. Afterwards re-mix and re-caption, then run assemble.sh.

Needs ffmpeg on PATH and Python with numpy, soundfile and kokoro-onnx. Model files go in KOKORO_DIR
(default: ./kokoro).
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

if len(sys.argv) < 3:
    sys.exit(__doc__)
ws, slug = sys.argv[1], sys.argv[2]
args = sys.argv[3:]


def opt(name, default):
    return args[args.index(name) + 1] if name in args else default


voice = opt("--voice", os.environ.get("KOKORO_VOICE", "am_eric"))
speed = float(opt("--speed", 1.3))
swaps = []
for i, a in enumerate(args):
    if a == "--replace":
        old, _, new = args[i + 1].partition("=")
        if not old or not new:
            sys.exit('--replace needs "old words=new words"')
        swaps.append((old, new))


def swap(text):
    for old, new in swaps:
        text = text.replace(old, new)
    return text


KD = os.environ.get("KOKORO_DIR", os.path.join(os.getcwd(), "kokoro"))
ad = os.path.join(ws, "videos", slug, "audio")
bk = os.path.join(ad, "old_voice")
if not os.path.exists(bk):
    os.makedirs(bk)
    for f in ("voice.wav", "voice.m4a", "words.json", "sentences.json", "mix.m4a"):
        if os.path.exists(os.path.join(ad, f)):
            shutil.copy2(os.path.join(ad, f), bk)
sj = json.load(open(os.path.join(bk, "sentences.json")))
words = json.load(open(os.path.join(bk, "words.json")))
old_audio, SR = sf.read(os.path.join(bk, "voice.wav"))
total = len(old_audio)
k = Kokoro(os.path.join(KD, "kokoro-v1.0.onnx"), os.path.join(KD, "voices-v1.0.bin"))
tmp = tempfile.mkdtemp()


def trim(x, sr):
    a = np.abs(x)
    thr = max(a.max() * 0.02, 1e-4)
    idx = np.where(a > thr)[0]
    if not len(idx):
        return x
    pad = int(0.015 * sr)
    return x[max(0, idx[0] - pad): idx[-1] + pad]


def ff(*a):
    subprocess.run(["ffmpeg", "-v", "error", "-y", *a], check=True)


def lufs(p):
    """Integrated loudness of a file, read from ffmpeg's ebur128 report."""
    r = subprocess.run(["ffmpeg", "-hide_banner", "-i", p, "-af", "ebur128", "-f", "null", "-"],
                       capture_output=True, text=True).stderr
    m = re.findall(r"I:\s+(-?[\d.]+) LUFS", r)
    return float(m[-1]) if m else -16.0


try:
    out = np.zeros(total + SR, np.float32)
    facs = []
    for i, s in enumerate(sj):
        a, sr = k.create(swap(s["text"]), voice=voice, speed=speed, lang="en-us")
        a = trim(np.asarray(a, dtype=np.float32), sr)
        slot = s["end"] - s["start"]
        nxt = sj[i + 1]["start"] if i + 1 < len(sj) else total / SR + 0.5
        d = len(a) / sr
        room_s = nxt - s["start"] - 0.04
        f = max(0.85, d / slot)  # never slow a line by more than 15% (it just ends early)
        if f > 1.3:
            f = max(1.3, d / room_s)  # a long line may use the pause after it before it is sped up more
        f = min(f, 1.7)
        a_in, a_out = os.path.join(tmp, "in.wav"), os.path.join(tmp, "out.wav")
        sf.write(a_in, a, sr)
        ff("-i", a_in, "-af", f"atempo={f:.4f}", "-ar", str(SR), "-ac", "1", a_out)
        b, _ = sf.read(a_out)
        b = b.astype(np.float32)
        room = int((nxt - s["start"] - 0.03) * SR)
        if len(b) > room:
            b = b[:room]
            print("  cut", i)
        st = int(s["start"] * SR)
        out[st:st + len(b)] += b
        facs.append(round(f, 2))
    out = out[:total + int(0.25 * SR)]
    full, pol = os.path.join(tmp, "full.wav"), os.path.join(tmp, "pol.wav")
    sf.write(full, out, SR)
    # A light polish, then match the old track's loudness so the mix needs no other change.
    tgt = lufs(os.path.join(bk, "voice.wav"))
    ff("-i", full, "-af", "highpass=f=80,equalizer=f=4000:t=q:w=1:g=3,acompressor=threshold=-20dB:ratio=3:attack=10:release=200",
       "-ar", str(SR), "-ac", "1", pol)
    g = tgt - lufs(pol)
    ff("-i", pol, "-af", f"volume={g:.2f}dB,alimiter=limit=0.95", "-ar", str(SR), "-ac", "1", os.path.join(ad, "voice.wav"))
    ff("-i", os.path.join(ad, "voice.wav"), "-c:a", "aac", "-b:a", "192k", os.path.join(ad, "voice.m4a"))
finally:
    shutil.rmtree(tmp, ignore_errors=True)

# Rename swapped words in the caption data. Timings stay as they were.
for old, new in swaps:
    ow, nw = old.split(), new.split()
    if len(ow) != len(nw):
        print(f'  note: "{old}" and "{new}" differ in word count; fix words.json by hand')
        continue
    for i in range(len(words) - len(ow) + 1):
        if [re.sub(r"\W", "", w["word"]).lower() for w in words[i:i + len(ow)]] == [re.sub(r"\W", "", x).lower() for x in ow]:
            for j, x in enumerate(nw):
                tail = re.search(r"\W*$", words[i + j]["word"]).group(0)
                words[i + j]["word"] = x + tail
json.dump(words, open(os.path.join(ad, "words.json"), "w"), indent=0)
for s in sj:
    s["text"] = swap(s["text"])
json.dump(sj, open(os.path.join(ad, "sentences.json"), "w"), indent=1)
print(f"{slug}: {voice}, {len(sj)} sentences, fit factors {facs}, loudness {tgt:.1f} LUFS (gain {g:+.1f} dB), "
      f"first words {[w['word'] for w in words[:3]]}")
