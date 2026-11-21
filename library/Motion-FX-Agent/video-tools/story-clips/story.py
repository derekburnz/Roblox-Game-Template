#!/usr/bin/env python3
"""Story clip cut: a narrated story over real gameplay. 1080x1920, 30 fps, H.264 + AAC.

Usage:  python3 story.py STORY.json [OUT.mp4]

The layout, top to bottom on a dark background:
  headline   a white part plus one accent-coloured word (top 18%)
  card       real gameplay in a rounded card with a soft glow
  pill       the current story line, changing with each beat
  narrator   your narrator character; the mouth opens on the voice's loudness and the eyes blink
  end card   your end card picture (game icon plus a join line) for the last `end_seconds`

STORY.json (paths relative to the json file; see stories/example-story.json):
  headline      ["Plain part", "accent word"]
  music         optional, a track you may use off Roblox; it sits under the voice
  hit           optional, a short sound played at the beat marked "hit": true
  beats         each { "line": pill text, "say": words for the voice (or ""), "clip": gameplay file,
                       "start": seconds into the clip, "hold": extra seconds after the voice (default 0.35),
                       "min": shortest the beat runs (default 1.6), "hit": true on the reveal }
  voice         default "af_bella", speed default 0.95 (Kokoro, kokoro-onnx; model files in KOKORO_DIR)
  end_seconds   default 2

Settings come from the environment, so nothing about one game or one PC is written in this file:
  FONT          path to a .ttf font file (required)
  NARRATOR_DIR  folder with Narrator_MouthClosed.png, Narrator_MouthOpen.png and Narrator_EyesClosed.png,
                all the same size with a transparent background (required)
  END_CARD      path to the end card picture, 1080x1920 (required)
  KOKORO_DIR    folder with kokoro-v1.0.onnx and voices-v1.0.bin (default: ./kokoro)
  STORY_BG, STORY_ACCENT, STORY_INK, STORY_GLOW   optional colours as "r,g,b"

Real footage only: every clip is a recording from real play.
"""

import json
import math
import os
import shutil
import subprocess
import sys
import tempfile

import numpy as np
import soundfile as sf
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))


def need(name):
    value = os.environ.get(name)
    if not value:
        sys.exit("Set the %s environment variable (see the top of this file)." % name)
    return value


def colour(name, default):
    raw = os.environ.get(name)
    if not raw:
        return default
    parts = tuple(int(p) for p in raw.split(","))
    if len(parts) != 3:
        sys.exit("%s must be r,g,b" % name)
    return parts


FONT = need("FONT")
NARRATOR = need("NARRATOR_DIR")
END_CARD = need("END_CARD")
KOKORO_DIR = os.environ.get("KOKORO_DIR", os.path.join(os.getcwd(), "kokoro"))

W, H, FPS, SR = 1080, 1920, 30, 24000
BG = colour("STORY_BG", (26, 18, 13))  # the page: dark and never busy
ACCENT = colour("STORY_ACCENT", (242, 193, 78))  # the accent word, pill rim and card rim
INK = colour("STORY_INK", (74, 46, 30))  # text outline and pill text
GLOW = colour("STORY_GLOW", (242, 170, 80))  # the soft glow behind the card
CARD = (40, 360, 1040, 1160)  # x1 y1 x2 y2: 1000x800
CARD_RADIUS = 44
PILL_Y = 1200
NARR_BOX = (1330, 1905)  # the narrator's top and bottom on screen


def font(size):
    return ImageFont.truetype(FONT, size)


def fit(text, size, width):
    while size > 30 and font(size).getlength(text) > width:
        size -= 2
    return font(size)


def background(path):
    """The dark page, the same every frame."""
    Image.new("RGB", (W, H), BG).save(path)


def headline(path, plain, accent):
    im = Image.new("RGBA", (W, 330), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    text = plain + " " + accent if plain else accent
    f = fit(text, 112, W - 120)
    lw = f.getlength(plain + " ") if plain else 0
    x = (W - f.getlength(text)) / 2
    y = 120
    d.text((x, y), plain, font=f, fill="white", stroke_width=6, stroke_fill=INK)
    # the accent word leans a little, like an italic: drawn alone, then sheared
    word = Image.new("RGBA", (int(f.getlength(accent)) + 60, 200), (0, 0, 0, 0))
    ImageDraw.Draw(word).text((20, 20), accent, font=f, fill=ACCENT, stroke_width=6, stroke_fill=INK)
    word = word.transform(word.size, Image.AFFINE, (1, 0.18, -20, 0, 1, 0), Image.BICUBIC)
    im.alpha_composite(word, (int(x + lw) - 20, y - 20))
    im.save(path)


def card_mask(path):
    w, h = CARD[2] - CARD[0], CARD[3] - CARD[1]
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), CARD_RADIUS, fill=255)
    m.save(path)


def card_glow(path):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    pad = 10
    d.rounded_rectangle(
        (CARD[0] - pad, CARD[1] - pad, CARD[2] + pad, CARD[3] + pad), CARD_RADIUS + pad, fill=GLOW + (190,)
    )
    im = im.filter(ImageFilter.GaussianBlur(26))
    # a thin gold rim on top of the blur
    ImageDraw.Draw(im).rounded_rectangle(
        (CARD[0] - 4, CARD[1] - 4, CARD[2] + 4, CARD[3] + 4), CARD_RADIUS + 4, outline=ACCENT + (255,), width=4
    )
    im.save(path)


def pill(path, text):
    """The chat-style pill under the card."""
    f = fit(text, 58, W - 200)
    tw = f.getlength(text)
    bw, bh = int(tw + 96), 104
    im = Image.new("RGBA", (W, bh + 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    x = (W - bw) // 2
    d.rounded_rectangle((x, 8, x + bw, 8 + bh), bh // 2, fill=(255, 249, 242, 245), outline=ACCENT + (255,), width=4)
    d.text((W / 2, 8 + bh / 2), text, font=f, fill=INK, anchor="mm")
    im.save(path)


def narrator_frames(folder):
    """The three frames cropped to the narrator and scaled into the bottom box, all the same size so they line up."""
    names = {"closed": "MouthClosed", "open": "MouthOpen", "blink": "EyesClosed"}
    ims = {k: Image.open(os.path.join(NARRATOR, "Narrator_%s.png" % v)).convert("RGBA") for k, v in names.items()}
    box = ims["closed"].getbbox()
    for im in ims.values():
        b = im.getbbox()
        box = (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    tall = NARR_BOX[1] - NARR_BOX[0]
    out = {}
    for k, im in ims.items():
        c = im.crop(box)
        s = tall / c.height
        c = c.resize((round(c.width * s), tall), Image.LANCZOS)
        p = os.path.join(folder, "narr_%s.png" % k)
        c.save(p)
        out[k] = p
    return out, out_size(out["closed"])


def out_size(p):
    return Image.open(p).size


def speak(kokoro, text, voice, speed):
    if not text.strip():
        return np.zeros(0, dtype=np.float32)
    samples, sr = kokoro.create(text, voice=voice, speed=speed, lang="en-us")
    assert sr == SR
    return samples.astype(np.float32)


def mouth_track(voice, total_frames):
    """Per frame: open while the voice is loud, with a little hold so it does not flicker; blink every ~3.5 s."""
    hop = SR // FPS
    loud = np.zeros(total_frames)
    for i in range(total_frames):
        seg = voice[i * hop : (i + 1) * hop]
        if len(seg):
            loud[i] = math.sqrt(float(np.mean(seg * seg)))
    peak = max(float(np.percentile(loud, 95)), 1e-4)
    state = []
    held = 0
    for i in range(total_frames):
        if loud[i] > peak * 0.28:
            # open and shut on the syllables: alternate within long loud runs
            held += 1
            state.append("open" if (held // 3) % 2 == 0 else "closed")
        else:
            held = 0
            state.append("closed")
    blink_every = int(3.4 * FPS)
    for start in range(int(1.2 * FPS), total_frames, blink_every):
        for j in range(start, min(start + 4, total_frames)):
            if state[j] == "closed":
                state[j] = "blink"
    return state


def run(cmd):
    subprocess.run(cmd, check=True)


def main():
    story_path = os.path.abspath(sys.argv[1])
    base = os.path.dirname(story_path)
    story = json.load(open(story_path))
    out = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else os.path.splitext(story_path)[0] + ".mp4"
    rel = lambda p: p if os.path.isabs(p) else os.path.join(base, p)
    work = tempfile.mkdtemp()
    try:
        from kokoro_onnx import Kokoro

        kokoro = Kokoro(os.path.join(KOKORO_DIR, "kokoro-v1.0.onnx"), os.path.join(KOKORO_DIR, "voices-v1.0.bin"))
        voice_name = story.get("voice", "af_bella")
        speed = float(story.get("speed", 0.95))
        end_s = float(story.get("end_seconds", 2))

        # 1. the voice, beat by beat, and each beat's length
        parts, times = [], []
        t = 0.0
        for beat in story["beats"]:
            said = speak(kokoro, beat.get("say", ""), voice_name, speed)
            length = max(len(said) / SR + float(beat.get("hold", 0.35)), float(beat.get("min", 1.6)))
            pad = np.zeros(int(round(length * SR)) - len(said), dtype=np.float32)
            parts.append(np.concatenate([said, pad]))
            times.append((t, t + length))
            t += length
        story_s = t
        total = story_s + end_s
        voice = np.concatenate(parts + [np.zeros(int(round(end_s * SR)), dtype=np.float32)])
        sf.write(os.path.join(work, "voice.wav"), voice, SR)

        # 2. the still layers
        background(os.path.join(work, "bg.png"))
        hl = story["headline"]
        headline(os.path.join(work, "headline.png"), hl[0], hl[1])
        card_mask(os.path.join(work, "mask.png"))
        card_glow(os.path.join(work, "glow.png"))
        for i, beat in enumerate(story["beats"]):
            pill(os.path.join(work, "pill%d.png" % i), beat["line"])
        frames, (nw, nh) = narrator_frames(work)

        # 3. the gameplay, one piece per beat, cropped to the card
        cw, ch = CARD[2] - CARD[0], CARD[3] - CARD[1]
        lst = os.path.join(work, "clips.txt")
        with open(lst, "w") as f:
            for i, beat in enumerate(story["beats"]):
                a, b = times[i]
                piece = os.path.join(work, "clip%d.mp4" % i)
                run([
                    "ffmpeg", "-loglevel", "error", "-y", "-ss", str(beat.get("start", 0)), "-t", "%.3f" % (b - a),
                    "-i", rel(beat["clip"]), "-an", "-vf",
                    "scale=%d:%d:force_original_aspect_ratio=increase,crop=%d:%d,fps=%d,format=yuv420p,tpad=stop_mode=clone:stop_duration=5"
                    % (cw, ch, cw, ch, FPS),
                    "-t", "%.3f" % (b - a), "-c:v", "libx264", "-preset", "fast", "-crf", "16", piece,
                ])
                f.write("file '%s'\n" % piece)
        run(["ffmpeg", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy",
             os.path.join(work, "game.mp4")])

        # 4. the narrator's face, as a run of still frames
        nframes = int(round(story_s * FPS))
        state = mouth_track(voice[: int(story_s * SR)], nframes)
        nl = os.path.join(work, "narr.txt")
        with open(nl, "w") as f:
            i = 0
            while i < nframes:
                j = i
                while j < nframes and state[j] == state[i]:
                    j += 1
                f.write("file '%s'\nduration %.4f\n" % (frames[state[i]], (j - i) / FPS))
                i = j
            f.write("file '%s'\n" % frames[state[-1]])

        # 5. put it together
        inputs = [
            "-loop", "1", "-t", "%.3f" % story_s, "-i", os.path.join(work, "bg.png"),  # 0
            "-i", os.path.join(work, "game.mp4"),  # 1
            "-loop", "1", "-i", os.path.join(work, "mask.png"),  # 2
            "-loop", "1", "-i", os.path.join(work, "glow.png"),  # 3
            "-loop", "1", "-i", os.path.join(work, "headline.png"),  # 4
            "-f", "concat", "-safe", "0", "-i", nl,  # 5
        ]
        n = 6
        for i in range(len(story["beats"])):
            inputs += ["-loop", "1", "-i", os.path.join(work, "pill%d.png" % i)]
        fc = [
            "[0:v]fps=%d,format=rgba[bg]" % FPS,
            "[1:v]format=rgba[g]",
            "[2:v]format=gray[m]",
            "[g][m]alphamerge[card]",
            "[bg][3:v]overlay=0:0:shortest=1[a0]",
            "[a0][card]overlay=%d:%d:shortest=1[a1]" % (CARD[0], CARD[1]),
            "[a1][4:v]overlay=0:0:shortest=1[a2]",
            "[5:v]fps=%d,format=rgba[nar]" % FPS,
            "[a2][nar]overlay=(W-w)/2:%d:shortest=1[a3]" % NARR_BOX[0],
        ]
        last = "a3"
        for i in range(len(story["beats"])):
            a, b = times[i]
            # the pill pops in a little after its beat starts, so the eye reads the change
            fc.append(
                "[%s][%d:v]overlay=0:%d:enable='between(t,%.3f,%.3f)':shortest=1[p%d]"
                % (last, n + i, PILL_Y, a + 0.05, b, i)
            )
            last = "p%d" % i
        fc.append("[%s]format=yuv420p[v]" % last)
        run(["ffmpeg", "-loglevel", "error", "-y", *inputs, "-filter_complex", ";".join(fc), "-map", "[v]",
             "-t", "%.3f" % story_s, "-c:v", "libx264", "-preset", "medium", "-crf", "18", os.path.join(work, "story.mp4")])
        run(["ffmpeg", "-loglevel", "error", "-y", "-loop", "1", "-t", "%.3f" % end_s, "-i", END_CARD, "-vf",
             "scale=%d:%d,fps=%d,format=yuv420p,fade=t=in:st=0:d=0.25" % (W, H, FPS), "-c:v", "libx264", "-preset",
             "medium", "-crf", "18", os.path.join(work, "end.mp4")])
        with open(os.path.join(work, "all.txt"), "w") as f:
            f.write("file '%s'\nfile '%s'\n" % (os.path.join(work, "story.mp4"), os.path.join(work, "end.mp4")))
        run(["ffmpeg", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", os.path.join(work, "all.txt"),
             "-c", "copy", os.path.join(work, "video.mp4")])

        # 6. the sound: voice on top, music under it, the hit on the reveal
        ain = ["-i", os.path.join(work, "voice.wav")]
        mix = ["[0:a]volume=1.0[vo]"]
        labels = ["[vo]"]
        k = 1
        if story.get("music"):
            ain += ["-stream_loop", "-1", "-i", rel(story["music"])]
            mix.append("[%d:a]atrim=0:%.3f,volume=0.22,afade=t=out:st=%.3f:d=1.2[mu]" % (k, total, total - 1.2))
            labels.append("[mu]")
            k += 1
        hits = [times[i][0] for i, b in enumerate(story["beats"]) if b.get("hit")]
        if story.get("hit") and hits:
            ain += ["-i", rel(story["hit"])]
            ms = int(hits[0] * 1000)
            mix.append("[%d:a]adelay=%d|%d,volume=0.9[hi]" % (k, ms, ms))
            labels.append("[hi]")
            k += 1
        mix.append("%samix=inputs=%d:duration=first:normalize=0,alimiter=limit=0.95[a]" % ("".join(labels), len(labels)))
        run(["ffmpeg", "-loglevel", "error", "-y", "-i", os.path.join(work, "video.mp4"), *ain, "-filter_complex",
             ";".join(shift(mix, 1)), "-map", "0:v", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", "-b:a", "160k",
             "-ar", "48000", "-movflags", "+faststart", "-t", "%.3f" % total, out])
        print("%s  %.1f s  beats at %s" % (out, total, ", ".join("%.1f" % a for a, _ in times)))
    finally:
        shutil.rmtree(work, ignore_errors=True)


def shift(parts, by):
    """The audio inputs follow the video, so their stream numbers move up by `by`."""
    import re

    return [re.sub(r"\[(\d+):a\]", lambda m: "[%d:a]" % (int(m.group(1)) + by), p) for p in parts]


if __name__ == "__main__":
    main()
