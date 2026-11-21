# story-clips: a narrated story over real gameplay

`python3 story.py stories/<story>.json [out.mp4]` makes a 1080x1920, 30 fps clip (H.264 video, AAC sound) for TikTok, Reels and Shorts.

What you get, top to bottom: a headline with one accent-coloured word, real gameplay in a rounded card with a soft glow, the story line in a pill under the card (it changes on each beat), a narrator character whose mouth moves with the voice, then a short end card.

The length of each beat comes from the voice, so the cut always fits what is said.

## Story file
Copy `stories/example-story.json`. Each beat sets:
- `line`: the pill text
- `say`: the words to speak, or "" for none
- `clip` and `start`: the gameplay file and how many seconds into it to start
- `hold`: extra seconds after the voice, 0.35 by default
- `min`: the shortest the beat runs, 1.6 s by default
- `hit`: true on the reveal beat, to play the `hit` sound there

`music` and `hit` at the top are optional sound files. Leave them "" for none.

## Settings (environment variables)
Nothing about one game or one PC is written in the script.

| Variable | What |
|---|---|
| `FONT` | path to a `.ttf` font you have the right to use |
| `NARRATOR_DIR` | folder with `Narrator_MouthClosed.png`, `Narrator_MouthOpen.png` and `Narrator_EyesClosed.png`: your own character, same size, transparent background |
| `END_CARD` | your end card picture, 1080x1920: the game icon plus a join line |
| `KOKORO_DIR` | folder with the Kokoro voice model files (default `./kokoro`) |
| `STORY_BG`, `STORY_ACCENT`, `STORY_INK`, `STORY_GLOW` | optional colours as `r,g,b`, to match the game's palette |

## Needs
- `ffmpeg` on PATH.
- Python with `pillow`, `numpy`, `soundfile` and `kokoro-onnx`.
- The Kokoro model files `kokoro-v1.0.onnx` and `voices-v1.0.bin`, from the kokoro-onnx project's model release. Kokoro is a free text-to-speech model that runs on the PC; check its licence terms before commercial use.

## Rules
- **Real footage only.** Every clip is a recording from real play. A test render with stand-in footage checks layout, voice and timing and is never posted.
- **Honest numbers.** A line that states odds uses the real in-game number.
- **Music you may use off Roblox.** Not Creator Store music.
- The owner approves every video before it is queued anywhere.

## Status
This script was carried over from a first game and made neutral. It compiles, but it has not been run end to end since the change, so make one test clip before relying on it.
