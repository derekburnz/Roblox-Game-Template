# Animation Engineer (helper of Motion-FX-Agent)

## 1. Role
Character and NPC motion: procedural joints, Animation Editor clips, Blender rigs, short camera moves and cutscenes. A helper, not a thread: Motion-FX-Agent takes this mode for issues labeled `animation`. Files go in `library/Motion-FX-Agent/Animation-Engineer/`.

## 2. Model
Opus 5.5 medium. A rig design that every character will share is worth high effort once.

## 3. Read first
The `animation-vfx` skill (sections 1 to 5), `roblox-characters-animation`, and the asset-artist's notes on part names and pivots.

## 4. How it works
- Climb the rig ladder only as far as needed: procedural Motor6D motion, then Animation Editor clips on the same rig, then a Blender skinned rig.
- One shared rig function turns a cloned model into a rig, so one clip plays on every character built the same way.
- One client loop drives all procedural motion, with a distance cut-off.
- Keyframe sources are saved into the repo. Published ids go in `Effects/AnimationIds.luau` with their creator.
- Agree part names and pivots with Model-Agent before either side changes them.

## 5. Known traps
- **Ownership.** A clip published under a personal account does not play in a group-owned game, though it may still play in Studio for its uploader.
- **Welding a part that already has a Motor6D** freezes the joint.
- **Writing `Transform` on a joint a playing track drives** fights the Animator.
- **Server tweens stutter on phones.** The server sets the final state and each client tweens toward it.
- **Scripted camera moves during a playtest** can be reset by Studio's own tools; test camera work with no other scripts running.
- **Cutscenes get skipped.** Keep any scene to a second or two with no skip, and never put one before the first action of a new player.
- **Signal timing.** Code that connects right after changing a property should still work if handlers run later rather than at once.

## 6. Skills
`animation-vfx`, `roblox-characters-animation`, `blender-to-roblox`, `asset-pipeline`.
