# story-kit: the animated story video

The story format: a short narrated story about one player, in the style of a current trend, with every scene built from the game's own art, word-by-word captions and an end card. The rules for the format are in `../playbooks/short-video-format.md`. This folder holds the three tools that are the same for every game.

| File | What it does |
|---|---|
| `src/kokoro_voice.py` | Voices a script with Kokoro (a free text-to-speech model that runs locally) and writes word timings for captions |
| `src/revoice.py` | Changes the voice of a finished story without re-rendering, keeping every timing |
| `tools/assemble.sh` | Joins the rendered story, an optional gameplay tail and the end card, and ducks music under the voice |

## What is not here
The part that draws the scenes is game specific: a script per story that builds sets and characters from the game's own model generators in Blender, renders the frames, mixes sound cues and burns in the captions. A first game's version of that was tied to its own characters, so it was left out. Build it for the new game once there are models to film, with Model-Agent (sets and poses) and Motion-FX-Agent (animation and camera). Until then, `library/Motion-FX-Agent/video-tools/story-clips/` makes the same story format over real gameplay recordings.

## The folder layout the tools expect
```
<workspace>/videos/<slug>/
  script.txt              the narration, one sentence or more per line
  audio/voice.wav         written by kokoro_voice.py
  audio/words.json        word timings, for word-by-word captions
  audio/sentences.json    sentence timings in seconds and frames, for timing shots to the voice
  audio/mix.m4a           voice plus sound cues, made by your render step
  out/final.mp4           the rendered, captioned story, made by your render step
```

## A run, start to end
1. Write `script.txt` by the script rules in the playbook. Open with the current trend's line.
2. `python3 src/kokoro_voice.py <workspace> <slug>` to voice it. Options: `--voice`, `--speed`, `--wpm`.
3. Time the shots to `sentences.json`, render the frames, mix the sound and burn in captions (your game's render step).
4. `tools/assemble.sh --main .../out/final.mp4 --voice .../audio/mix.m4a --endcard endcard.png --out story.mp4 --music track.ogg`
5. Check the whole video on a phone, then give it to the owner. Nothing is posted without their say.

To change the voice later: `python3 src/revoice.py <workspace> <slug> --voice <name>`, re-mix, then assemble again. `--replace "old words=new words"` swaps a phrase, for example when the trend's opening line changes.

## The end card
One picture, 1080x1920: the game icon plus a join line. Nothing else. No gameplay clip after the story by default, so the viewer goes to the game page to see more. Model-Agent makes it once and it is reused on every video.

## Needs
- `ffmpeg` and `ffprobe` on PATH.
- Python with `numpy`, `soundfile` and `kokoro-onnx`, and the Kokoro model files in `KOKORO_DIR`.
- Installing anything on the owner's PC needs the owner's say. Free tools are fine; a paid voice needs their OK and a plan that allows commercial use.

## Tips
- Pick one voice and keep it for every line and every video.
- A long background render can be killed by a time limit. Render in chunks that can resume.
- After changing a shot, preview every shot you touched before the final render.
- Keep finals only in the library, under 95 MB each.

## Status
The three tools were carried over from a first game and made neutral: paths, the voice and the opening line are now arguments. The Python files compile; none of the three has been run end to end since the change. Make one short test video before relying on them.
