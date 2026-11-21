---
name: animation-vfx
description: How characters, props and moments move and sparkle: picking procedural motion, a Motor6D rig with the Animation Editor or a Blender skinned rig, AnimationController and Animator playback, publishing animations and who must own them, client-side tweens, ParticleEmitters, Beams, Highlights, and the low-end and mobile budgets. Use for any animation, tween, particle, glow or "make it feel good" task.
---

# Animation and VFX

Everything here is cosmetic. It runs on each player's device, never decides gameplay, and must look the same on a cheap phone as on a PC, only with fewer particles. Read with `asset-pipeline` (pivots, naming) and `docs/art/style-guide.md` (colours, lighting, poses). Third-party references: `roblox-characters-animation` (Animator, tracks, priorities, tweens), `roblox-dev-skill/references/performance-optimization.md` (MicroProfiler, shadows), `roblox-mobile-playtest` (phone pass), `blender-to-roblox/references/export-rules.md` (rig export rules).

## 1. Roblox concepts in one line each
- **Rig**: a model whose parts are joined by joints the engine can bend. Two kinds: parts joined by **Motor6D** joints, or one mesh with **Bones** inside it (a skinned mesh, made in Blender).
- **Motor6D**: a joint between `Part0` (the parent part) and `Part1` (the child). The child sits at `Part0.CFrame * C0 * Transform * C1:Inverse()`. Animations write `Transform`; it is not replicated, so writing it from a LocalScript moves the part only on that player's screen.
- **Animation**: an instance holding `AnimationId = "rbxassetid://<number>"`, the id of an animation asset published to Roblox.
- **Animator**: the object that plays animations on a rig. It lives under a `Humanoid` (player characters) or under an **AnimationController** (anything else). `animator:LoadAnimation(animation)` returns an **AnimationTrack** you `Play`, `Stop`, `AdjustSpeed` and `AdjustWeight`. `Humanoid:LoadAnimation` and `AnimationController:LoadAnimation` are deprecated.
- **KeyframeSequence**: the editable source of an animation, saved by the Animation Editor. Only the published asset plays in a live game.
- **TweenService**: moves a property from A to B over time with an easing curve. Good for UI, doors and signs. One tween per property at a time.
- **ParticleEmitter**: sprays small textured cards (particles) from a part or an **Attachment** (an invisible point inside a part). `Rate` for a steady stream, `emitter:Emit(n)` for a one-off burst.
- **Beam**: a textured strip drawn between two Attachments (light shafts, a glowing line between two things).
- **Trail**: a fading ribbon left behind by two moving Attachments (a swoosh). Keep `Lifetime` under 0.3 s.
- **Highlight**: an outline and fill drawn around a model, visible through walls if you want it to be.
- **PointLight / SpotLight**: real lights. `Shadows` on a light is the expensive part.
- **Bloom**: a post effect that makes Neon parts and bright particles glow. Keep it low and do not raise it to make one effect read.

## 2. Which tool for which job
| Job | Tool | Where it runs | Owner |
|---|---|---|---|
| Buttons, popups, counters, progress bars | TweenService on GuiObjects (the UI's own tween helper) | client | ui-designer |
| Props: a gate opening, a sign flipping, an item dropping | TweenService on anchored parts, or a `CFrameValue` driving `model:PivotTo` | client | vfx-animator |
| Simple character life: idle bob, look at a target, tail or ear motion | Step 1: procedural `Motor6D.Transform` on a few joints | client | vfx-animator (rig set-up by engineer) |
| Authored clips that need hand-keyed timing | Step 2: the same Motor6D rig keyed in the Animation Editor, published, played by an Animator | client | vfx-animator |
| Bendy characters: spine, walking legs | Step 3: a Blender armature and skinned mesh | client | vfx-animator with asset-artist |
| NPCs that walk | The server moves the pivot; the client adds joint motion on top | server pivot, client joints | engineer, vfx-animator |
| Bursts, sparkles, glows, light shafts, outlines | ParticleEmitter, Beam, Highlight, Neon plus lights | client | vfx-animator |

Rule of thumb: start on the cheapest row that looks good. Procedural motion costs nothing to upload and can be tuned in code review; a published animation is a separate asset with ownership rules (section 4).

## 3. The rig ladder

### Step 1: Motor6D rig built in code, procedural motion
The engineer turns a cloned model into a rig when it spawns (one shared function). The rig is `Root -> Body -> Head, Tail...`: `Root` is an invisible, anchored, non-colliding 1 x 1 x 1 Part at the floor pivot and becomes the `PrimaryPart`. The root part has no joint of its own, so it cannot be animated; giving the Body a joint to Root is what lets a clip or the code bob, lean or hop the whole model.

Animation clips find parts by name, so the rig renames the imported MeshParts to plain `Body`, `Head` and so on and keeps the asset name in an attribute. That lets one clip play on every character built the same way.

```lua
-- jointWorld is where the joint sits in world space (the model pivot for Body, the neck for Head).
local function joint(part0: BasePart, part1: BasePart, jointWorld: CFrame): Motor6D
	local motor = Instance.new("Motor6D")
	motor.Name = part1.Name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = part0.CFrame:ToObjectSpace(jointWorld)
	motor.C1 = part1.CFrame:ToObjectSpace(jointWorld)
	motor.Parent = part0
	part1.Anchored = false -- only Root stays anchored, so Root is the assembly root
	part1.CanCollide = false
	part1.Massless = true
	return motor
end
```

Then add an `AnimationController` with a child `Animator` to the model so step 2 needs no rebuild. Code that welds things to the model must not weld parts that already have a Motor6D, or the joint freezes.

The client drives motion with one `RunService.PreSimulation` connection for all characters (not one per character), writing `motor.Transform = offset` from a sine or a small state machine. Because `Transform` is not replicated, the server moving a pivot never fights the client's head bob. The Animator writes `Transform` for every joint a playing track uses each frame; leave a joint alone while a track drives it.

### Step 2: Animation Editor clips on the same rig
1. In Studio open the Animation Editor and select a rigged model in Workspace. Root must be the assembly root: it is the only anchored part.
2. Key the clip. Name events with markers (`Land`) so code can sync a sparkle or a sound via `track:GetMarkerReachedSignal("Land")`.
3. Save, then save the KeyframeSequence to a file under `assets/<game-slug>/anim/keyframes/` so the source is in Git.
4. Publish to Roblox under the **creator that owns the experience** (section 4). Copy the asset id into `src/client/Effects/AnimationIds.luau` with the creator next to it.

Playback on the client:
```lua
local track = animator:LoadAnimation(animation) -- once per Animator per clip, then reuse
track.Priority = Enum.AnimationPriority.Idle    -- Core < Idle < Movement < Action
track.Looped = true
track:Play(0.2)                                  -- 0.2 s fade in
```
Play NPC clips on the client: each player animates their own copy and nothing goes over the network.

### Step 3: Blender skinned rig
Generate the armature and weights in Python next to the asset-artist's meshes so it rebuilds like everything else. Rules from `blender-to-roblox`: bones frozen (scale 1, rotation 0), root bone at the origin, at most 4 influences per vertex, nothing weighted to the root, one animation per FBX, no leaf bones. Keep the bone count low (about 20 for a small character).

## 4. Animation ownership (why clips silently fail live)
- An animation plays in a live server only if its owner can use it in that experience. Publish every clip under the same creator that owns the experience (the group, when a group owns the game). In Studio a clip may still play for its uploader, so a clip that works in Studio and not live is almost always this.
- Moving the game to a group later means re-publishing each clip under the group or granting the experience on each animation's permissions page. Check the current rules in the Creator Docs before a move.
- Keep every id in `AnimationIds.luau` with its creator, so the reviewer can see no id came from someone else's account.
- Never use animation ids found in other games or the Creator Store; they are someone else's asset and break live. The one exception is Roblox's own default character animations (the ids inside the default `Animate` script). Copy the ids from that script, not from memory.
- Particle and beam textures are image assets with the same rule. Prefer Roblox's built-in textures until a custom texture earns its upload.

## 5. Tweens for UI and props
- Tween on the client only. A server tween replicates every frame and stutters on phones; the server sets the final state (an attribute or a property) and every client tweens towards it.
- Anchored parts only. For a Model, tween a `CFrameValue` and call `model:PivotTo(value.Value)` in its `Changed` handler, or tween the one part the rest is welded to.
- Easing: `Back, Out` for pops (0.2 to 0.3 s), `Quad, Out` for rises and slides (0.3 to 0.9 s), `Sine, InOut` for loops.
- Cancel before restarting: keep the Tween in a table keyed by instance and call `:Cancel()` when a new one starts, or two tweens fight over the same property. A looping tween that shares a property with a one-shot must restart itself after the one-shot.
- UI motion stays in the UI's tween helper (ui-designer). World motion goes through `src/client/Effects/`.

## 6. VFX style rules
Write the game's own palette and shapes in the style guide. These rules hold for any game with a young audience:
- **Short and readable**: feedback bursts last 0.3 to 0.8 s. Transparency fades over the lifetime; size shrinks or holds, never balloons.
- **A ladder for rarity or importance**: the common case stays plain so the rare case feels like a reward. Add one element per step (colour, a ring, an outline).
- **Colours from the palette only**, as `ColorSequence` stops. Add a new colour to the palette before using it.
- **Accessibility**: no more than three flashes per second, no full-screen white flash, no camera shake by default. When `GuiService.ReducedMotionEnabled` is true, skip screen-space bursts, scale pops and idle loops.
- **Effects never promise what the game does not give.** "Boosted luck" is shown as luck, not as a guaranteed prize.

## 7. Budgets for low-end phones
Roblox caps a single emitter's rate (lower on mobile), particles live at most 20 s, and only 31 Highlights render on a client at once (a disabled Highlight still takes a slot). Set the game's budgets far below those caps. Starting values:

| Item | Phone (low tier) | PC (high tier) |
|---|---|---|
| Live particles on screen, all effects | 150 | 400 |
| One burst (`Emit`) | 12 | 24 |
| Steady emitters within 60 studs | 4, Rate 8 or less | 8, Rate 16 or less |
| Particle lifetime | 1.5 s | same |
| Beams visible | 4 | 8 |
| Trails active | 2, Lifetime 0.3 s or less | 4 |
| Highlights from our code | 2 at once, destroyed after use (never left disabled) | 4 |
| Lights we add | `Shadows = false` on every one | same |
| World tweens running | 30 | 60 |
| Procedural motion | one loop for everything within 60 studs, half rate past 30 | same, wider |
| Animation tracks | 3 loaded per character, stopped past 80 studs | same |

Tier: low if the device is touch-only (`UserInputService.TouchEnabled` and not `KeyboardEnabled`) or the saved graphics quality is low. Low tier halves bursts and drops ambient emitters. Pick the tier once on join.

Measure, do not guess: a Studio playtest with the device emulator on a phone profile, the MicroProfiler (Ctrl+F6) for the frame cost of the Effects loop. Record the numbers in the handoff.

## 8. Code shape (`games/<game-slug>/src/client/Effects/`)
- `--!strict`, luau-conventions, one module per concern: `init.luau` (public API), `Presets.luau` (every burst and loop as data), a motion module, `AnimationIds.luau`.
- Effects only listen. They subscribe to named moment signals the engineer fires (one signal per moment, shared with the sound designer so sound and effects hook the same events) and to replicated world state (CollectionService tags, attributes, models appearing). They never fire remotes, never change gameplay state and never move a part the server also moves.
- Keep one shared list of moment names with the sound designer. Do not keep a second copy.
- Pool and clean up: one emitter per preset moved to the effect point, `Emit(n)`, back to the pool. Anything created per effect is destroyed when it ends. No per-frame table allocation in the motion loop.
- An effect another player must see is driven by replicated state every client already has, so it needs no new remote.

## 9. Known traps
- **Beam and Trail textures:** the built-in particle textures can draw as nothing on a Beam or a Trail. Leave the texture empty and soften a beam by stacking two or three thinner, faint beams over a wider one (start near 0.7 to 0.8 transparency each).
- **Tagged templates** stored in ReplicatedStorage carry their tags too, so check `IsDescendantOf(workspace)` before treating a tagged instance as live.
- **A remote or signal that may not exist yet:** hook it with `FindFirstChild` plus `ChildAdded` rather than a wait that can hang forever.
- **Climbable invisible parts:** a model's hidden TrussPart ladders are real gameplay. Before changing Humanoid states or character physics globally, search the models for the classes it would affect.
- **Effects high above the camera** cannot be judged in a normal playtest. Give such an effect a test height or a test command.
- **Never say "live"** until a publish run that contains the merge has succeeded.

## 10. Studio tools
Allowed: dropping a test emitter or a rigged model into the dev place and tuning numbers live, playtests and screen captures for evidence, console output for errors. Then copy the tuned numbers into `Presets.luau`; nothing tuned in Studio survives unless it is in a file. Never edit a Rojo-managed script in Studio and never save the test place.

## 11. Handoff note
Effects or clips added (name, moment, where it plays), files changed, animation ids with their creator, budget numbers measured on the phone profile, a capture per effect in `docs/vfx/<game-slug>/`, and what the engineer must hook. Hand code to luau-reviewer and the result to qa-playtester; never sign off your own work.
