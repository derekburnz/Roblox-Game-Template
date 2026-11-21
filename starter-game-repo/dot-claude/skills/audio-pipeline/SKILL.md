---
name: audio-pipeline
description: How sound effects, music and ambience go from an idea to the game: Roblox audio basics, sourcing and licenses, file prep and the audio gate, naming, uploads and permissions, SoundGroups and client playback, mixing for phones. Use for any sound, music, ambience or volume task.
---

# Audio pipeline (cue to file to Roblox asset to game)

The "what" lives in `docs/audio/<game-slug>/sound-list.md` (every cue, the music brief, the listening list). This skill is the "how". For engine API details read the third-party `roblox-audio` skill; for Creator Store search, license checks and credits read `find-resources`.

## 1. Roblox audio in two minutes
- **Asset id.** Every sound on Roblox is an uploaded asset with a number, played as `rbxassetid://<number>`. Audio files never ship inside the place: the repo keeps the source files and the ids.
- **Sound.** The object that plays one asset. Properties we use: `SoundId`, `Volume` (default 0.5), `PlaybackSpeed` (1 is normal; a small random change per play stops repeats sounding robotic), `Looped`, `TimePosition`.
- **2D or 3D.** A Sound inside a Part or Attachment is positional: it pans and fades with distance between `RollOffMinDistance` and `RollOffMaxDistance` (studs). A Sound in `SoundService` plays flat in both ears; music, UI and ambience beds go there.
- **SoundGroup** is a mixer channel. Each Sound points at one; the group's `Volume` scales all of them. Settings toggles mute groups, never single sounds.
- **Client or server.** A Sound started by a client script is heard only by that player. One started by the server replicates to everyone and ignores each player's settings. Play every sound on the client.
- **Loading.** A Sound downloads before it can play, so the first play of a cold sound can be late. Preload only the few that must be instant (`ContentProvider:PreloadAsync`); preloading everything slows joins.
- **Two audio engines.** Classic `Sound` and the newer Audio API (`AudioPlayer`, `Wire`, `AudioDeviceOutput`). Classic Sound plus SoundGroups is enough for most games. Keep all audio behind `src/client/Audio/` so a later move changes one folder. Never mix the two engines in one feature.

## 2. Where things live
| What | Path | Owner |
|---|---|---|
| Cue list, music brief, listening list | `docs/audio/<game-slug>/sound-list.md` | sound-designer |
| Upload-ready files | `assets/<game-slug>/audio/{music,ambience,sfx,ui}/<GamePrefix>_<Bus>_<Name>.ogg` | sound-designer |
| Sources and license log | `assets/<game-slug>/audio/README.md` | sound-designer |
| Gate report | `assets/<game-slug>/audio/gates.md` (written by the script, never by hand) | sound-designer |
| Cue table, player, hook contract | `games/<game-slug>/src/client/Audio/{Cues.luau,init.luau,README.md}` | sound-designer, reviewed by luau-reviewer |
| CC-BY credits | `CREDITS.md` at the repo root, through find-resources `credit.sh` | sound-designer |

Creator Store audio used as it is has no file in the repo; its log row and the id in `Cues.luau` are enough. Project files, raw recordings and stems stay out of Git; the log says where they are.

## 3. Names
- File name, uploaded asset name and Sound instance name are the same: `<GamePrefix>_<Bus>_<Name>[_<Variant>]`, Bus one of `Music`, `Amb`, `Sfx`, `Ui`. Examples: `<GamePrefix>_Music_DayA`, `<GamePrefix>_Sfx_Collect`, `<GamePrefix>_Ui_Click`.
- Cue ids in code are short camelCase: `collect`, `uiClick`. A cue can hold variants (one cue picks one of five files).
- Moments, the game events that fire cues, use PascalCase names shared with the vfx-animator. One moment can fire several cues and several effects.

## 4. Sourcing and licenses
In this order:
1. **Roblox Creator Store audio.** A large library from Roblox's audio partners, free in experiences, with no upload needed. Search with the Studio asset search or `find-resources/scripts/search.sh --type sound` (or `music`). Licensed music is for use inside Roblox only: never in a trailer, devlog clip or any video off the platform. Take the audio id; never insert a Model only because it contains a sound.
2. **Our own.** Record it (a phone in a quiet room is enough) or synthesize it (UI blips, chimes, ticks) with a script in the repo or an sfxr-style tool. Fully original, with no license questions.
3. **CC0.** Free packs and libraries filtered to CC0. Log the page link anyway.
4. **CC-BY.** Allowed with a credit in `CREDITS.md` and on the in-game credits screen; record the version.
5. **Paid royalty-free**: only with a license that allows commercial use in a game; log where the license or receipt lives.

Never: audio ripped from games, films, TV or songs (Roblox moderates uploads, and a copyright strike lands on the owner's account); non-commercial (NC) licenses, because the game earns Robux; "free for YouTube" music; sounds lifted from other Roblox games; AI-generated music without a plan whose terms grant commercial rights (log the plan and date); voices imitating a real person; sound-alikes of famous themes. Never invent an asset id or a license: use only what a search or the asset's page shows.

## 5. File prep and budgets
Roblox upload limits: `.mp3`, `.ogg`, `.wav` or `.flac`, under 20 MB, under 7 minutes, at most 48 kHz, mono or stereo. Deliver `.ogg` at 44.1 or 48 kHz.

| Kind (folder) | Channels | Length | Loudness | Peak ceiling | Other |
|---|---|---|---|---|---|
| `ui` | mono | 0.02 to 1.5 s | by ear against a reference click | -1 dBTP | at most 10 ms of silence before the sound |
| `sfx` | mono (3D needs mono to pan) | 0.05 to 4 s | by ear against a reference effect | -1 dBTP | at most 20 ms of silence before the sound |
| `ambience` | stereo | 20 to 120 s, seamless loop | about -26 LUFS | -3 dBTP | no fade at either end |
| `music` | stereo | 30 to 240 s, seamless loop | about -18 LUFS | -1 dBTP | loop starts and ends on the beat |
| `music`, named `Jingle*` or `Sting*` (gate kind `stinger`) | stereo | 0.5 to 6 s, no loop | by ear | -1 dBTP | at most 20 ms of silence before the sound |
| `sheets` (gate kind `sheet`): short sounds joined with silence, each cue playing its own region | mono for 3D parts | 0.5 to 120 s | each part by its own kind | -1 dBTP | saves upload quota |

LUFS is perceived loudness over the whole file; dBTP is the loudest instant. Master files close to these so the SoundGroup volumes do the mixing, not per-file fixes.

**The audio gate** measures all of this, because the agent cannot hear:
```sh
python .claude/skills/audio-pipeline/scripts/audio_gate.py assets/<game-slug>/audio
```
It needs `ffmpeg` and `ffprobe` on PATH. FAIL means a Roblox limit, the name, mono or the peak is wrong. WARN means listen: length outside the budget, loudness off target or a loop seam that may click. PASS only means measured clean; a person still listens.

## 6. Upload and permissions
- **Owner.** Upload under the same account or group that owns the experience. Uploaded audio is private: only its owner can use it until it is shared with the experience on the asset's permissions page. When a group owns the game, upload under the group (the `ROBLOX_GROUP_KEY` secret through a workflow, or the group's Creator Hub page). Ask the owner before a batch.
- **Keys.** An Open Cloud key is read from the environment or a GitHub secret, never pasted in chat or written in a file.
- **Quota.** Roblox limits audio uploads per month, and the limit is low on an unverified account. Batch uploads, and do not burn quota on drafts: get the owner's pick first. A sound sheet (several short sounds in one file) stretches the quota.
- **Moderation.** Every upload is reviewed. Upload only files that have a log row with a clean license.
- **After upload.** Put the id in `Cues.luau` and the log row in the same commit.

## 7. Wiring in the game
```
SoundService
  Music     SoundGroup  0.5   muted when the music setting is off
  Ambience  SoundGroup  0.6   muted when the sound setting is off
  Sfx       SoundGroup  0.8   muted when the sound setting is off
  Ui        SoundGroup  0.7   muted when the sound setting is off
```
`src/client/Audio/init.luau` builds the groups at startup and exposes a small API: start, apply settings, play a cue (2D, or at a Part, Attachment or position), loop a cue (returns a stop function) and bind to the moment signals. Rules with no Roblox services live in a pure module so they can be unit tested. A cue entry in `Cues.luau`:
```luau
collect = {
	ids = {}, -- "rbxassetid://..." strings; empty means silent, never an error
	group = "Sfx",
	volume = 0.8,
	pitch = { 0.96, 1.04 }, -- random PlaybackSpeed per play
	minGap = 0.1, -- seconds; drops spam
	voices = 2, -- pooled Sounds; the oldest restarts when all are busy
	preload = true,
},
```
Rules:
- Subscribe to moments; never fire remotes, change state or read the server from audio code.
- Pool Sounds per cue (`voices`); never create one Sound per event. Destroy 3D Sounds with their part.
- Music: one bed at a time. Crossfade over about 2 s on a change. Stingers duck Music for their length, then restore. Music starts only after the player's settings are read, so a player who muted it never hears a note.
- The server never plays sounds.
- Preload only cues marked `preload` (about ten).
- A missing or failed sound must never break gameplay: wrap loads, log once, stay silent.

## 8. Taste rules for a young audience
Nothing harsh, scary or startling. Keep music from repeating one short loop for a whole session: alternate two tracks. Reward sounds stay short and soft; a loud ding on every small event gets muted by the player. Write the game's own music brief (mood, tempo, instruments) in the sound list.

## 9. Mixing for phones
- Most players listen on phone speakers: little below 150 Hz survives, so put the information a sound carries between 1 and 4 kHz and keep bass decorative.
- When it gets busy, the order of importance is: the result of the player's action, UI feedback, rewards, character voices, ambience, music.
- Keep about 16 or fewer Sounds playing at once on a client; pooling and `minGap` handle most of it.

## 10. Listening and testing
- Studio: press Play and walk the listening list at the end of the sound list. An Output line about a sound that failed to load means a wrong id or a missing permission (section 6).
- Before calling a mix done, one pass on a real phone speaker.
- QA's playtest report gets an audio line: missing sound, too loud or quiet, repeats too often, heard by the wrong player, still playing after a toggle.

## 11. Handoff note
Per cue: cue id, moment, file, asset id, source and license, gate verdict, where to listen (exact Studio steps). Then open questions for the owner.
