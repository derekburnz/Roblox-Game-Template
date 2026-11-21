---
name: asset-pipeline
description: How 3D assets go from Blender to Roblox Studio: scale calibration, triangle budgets, naming, pivots, UV and texture rules, FBX export settings, Studio import checks, saving model files for Rojo and replacing PH_ placeholders. Use for any model, prop or environment task.
---

# Asset pipeline (Blender to Studio to Rojo)

Roblox measures the world in **studs**. A default R15 avatar is about 5 studs tall and a door about 7 studs. Roblox's **MeshPart** is a single mesh with one material or one texture; a model is a `Model` of MeshParts and Parts with a `PrimaryPart`.

## 1. Scale calibration (do once per Blender file)
1. In Studio insert a Part sized 4 x 4 x 4 studs.
2. In Blender make a cube and export it with the settings in section 5; import it to Studio.
3. Adjust Blender's Scene > Units > Unit Scale (or the exporter's scale) until the imported cube matches the 4-stud Part. Write the working value at the top of `docs/art/style-guide.md` and reuse it for every asset.

## 2. Budgets (per asset, triangles after export)
Starting values for a game played mostly on phones. Record the game's own table in the style guide.
| Asset type | Triangles | Texture |
|---|---|---|
| Hero character or creature | 1,500 to 3,000 | 512 px, one atlas or vertex colours |
| Furniture and medium props | 300 to 1,200 | 512 px or plain Roblox materials |
| Small prop | 50 to 400 | vertex colours or 256 px |
| Set piece | 200 to 1,500 | 512 px |
| Whole visible scene | under 150,000 triangles, under 1,500 parts | |
Keep every single mesh under 10,000 triangles. Low-poly, chunky shapes read best at a distance on a small screen.

Instance counts matter as much as triangles: every part a client downloads costs load time, and players leave during a long load. Count what an asset adds, and keep server-only things out of what replicates to clients.

## 3. Naming and structure
- Pattern: `<GamePrefix>_<Category>_<NameVariant>`, for example `<GamePrefix>_Furniture_CounterA`, `<GamePrefix>_Prop_Bowl`.
- Blender object name = Roblox MeshPart name. Group one asset per Collection named the same.
- Pivot (origin) at the base centre, so placing at a floor position needs no offset.
- Apply all transforms before export (Ctrl+A > All Transforms). Front faces -Y in Blender so it faces -Z in Roblox.
- Characters: separate objects for the parts that move (head, tail, arms) with pivots at the joints, and a Model with `PrimaryPart = Root` (an invisible 1 x 1 x 1 Part at the pivot). Animations find parts by name, so changing a name or pivot later breaks them: tell the vfx-animator first.
- Models are solid from every side a player can reach. A building is finished on every visible side, never a front wall acting as a facade.

## 4. UVs, materials, colours
- Prefer flat colours via Roblox `Color3` and `Material` on the MeshPart over textures where possible: zero texture memory and easy to recolour.
- When texturing, one UV set, non-overlapping islands, 8 px padding, power-of-two sizes.
- No transparency on hero meshes (sorting issues); glass and liquids as separate Parts with `Transparency`.

## 5. Export (FBX)
Blender File > Export > FBX: Selected Objects; Object Types: Mesh (and Armature if rigged); Scale per section 1; Apply Transform on; Forward -Z, Up Y; Mesh: Apply Modifiers, Triangulate on; no Leaf Bones. Save to `assets/<game-slug>/exports/<Name>.fbx`. Keep the source in `assets/<game-slug>/blender/`. The `blender-to-roblox` and `blender-export-pipelines` skills have the full rules.

Prefer generating models from Python scripts in the repo over hand-modelling: a style change is then a code edit and a rebuild, and every asset passes the same checks.

## 6. Studio import checks
1. 3D Importer: scene unit per calibration, Insert using scene position off, Anchored on, uncheck "Rig" for static props.
2. Check `MeshPart.Size` against the sizes in the style guide.
3. `CollisionFidelity`: Box for small props, Hull for furniture, PreciseConvexDecomposition only for things players walk on or through. `RenderFidelity`: Automatic.
4. `Anchored = true` for everything static; `CanCollide = false` for decorations players should walk past.
5. Materials: `Material = SmoothPlastic` with `Color3` from the style guide palette unless a texture is intended.
6. Creator Store assets: before use, search the inserted model for `Script`, `LocalScript` and `ModuleScript` and delete any; check for unexpected `Decal`s and `Sound`s (skill `roblox-creator-store-security-audit`). Prefer our own or Roblox-made assets.

## 7. Quality gate
Run `blender-asset-qa` (roblox profile) and `blender-game-optimization` on every asset before calling it done. Check the existing model format against earlier assets before building a new kind, so a new set matches the old ones.

## 8. Save for Rojo and hand off
- Save the finished Model to `assets/<game-slug>/rbx/<Name>.rbxm` (or a `.model.json`). Rojo syncs that folder into `ReplicatedStorage.Assets`, so the engineer can clone it by name.
- A model file never contains a script. Reviewers grep model files for script classes.
- Replacing a placeholder: the engineer names temporary parts `PH_<Thing>`. Match the `PH_` part's size and pivot, then tell the engineer so spawn code switches to the asset name.
- Screenshots: 2 to 4 per asset or scene to `docs/concepts/<game-slug>/<date>-<name>-<n>.png`, with a caption in that folder's README. Every render shows scale with one of the game's own characters.

## 9. Uploads
Images, meshes and audio uploaded to Roblox must be owned by whoever owns the game. When a group owns the game, upload under the group. An asset owned by a personal account does not load in a group-owned game, and fallback art can hide that for days. After an upload, check the asset in the live game.

## 10. Handoff note format
Asset name, triangle count, instance count, paths (source, FBX, model file), Studio size in studs, collision fidelity, which `PH_` it replaces, screenshot paths, anything the style guide should record.
