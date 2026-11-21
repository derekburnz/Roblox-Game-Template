# Assets

Source files for art and sound live under `assets/<game-slug>/`:

- `blender/` Blender sources or generator scripts, `exports/` FBX and reports, `rbx/` model files Rojo syncs into `ReplicatedStorage.Assets`.
- `anim/` animation sources, `vfx/` effect textures.
- `audio/` upload-ready sound files and the license log.
- `ui/` HTML or SVG mockups.

Create each folder when its first file arrives. See the `asset-pipeline`, `animation-vfx` and `audio-pipeline` skills. Keep rendered videos and large binaries out of Git where you can.
