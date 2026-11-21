---
name: concept-visuals
description: The rough-visual process: style options in words, a Studio graybox of the game's main area, one Blender hero asset, an HTML or SVG HUD mockup, saved to docs/concepts/<game-slug>/ with captions. Use for mood, graybox, hero asset and mockup tasks, and when assembling a comparison page for the owner and friends to vote on.
---

# Concept visuals

Claude does not paint. Rough visuals come from the real tools: Roblox Studio generation tools for grayboxes, Blender for one hero asset, HTML or SVG for UI mockups. This doubles as a test of the pipeline.

## 1. Style options
Offer three named styles in words before building anything. For each: a palette with 5 hex codes, the shape language (rounded, chunky or angular), the camera (third person over the shoulder or raised), the lighting mood and one reference word. Record the winner in `docs/decisions.md` and write it up as `docs/art/style-guide.md`. Keep the other two as alternates.

## 2. Studio graybox (style neutral until a style is picked)
One hero area: the place where the core loop happens, plus the first place the player travels to.
- Build with the Studio generation tools and plain Parts. Name everything `PH_<Thing>` so the engineer can hook gameplay to it and the artist can swap it later.
- Scale check against a Roblox avatar (about 5 studs tall): a counter about 3 studs high, a door about 7.
- Lighting: one `Lighting` preset per style option (ClockTime, Ambient, OutdoorAmbient, one key light) saved as a snippet in `docs/concepts/<game-slug>/lighting.md`, so the looks can be compared on the same graybox.
- Capture 3 or 4 angles: from the entrance, from the player's usual spot, from outside looking in and top-down. Save as `docs/concepts/<game-slug>/<date>-graybox-<n>.png`.

## 3. One Blender hero asset
The thing players will see most (the main character, creature or prop). Follow asset-pipeline for scale, pivot and naming. Bring it into the graybox and screenshot it next to its `PH_` stand-in so the size reads.

## 4. HUD mockup (ui-designer)
An HTML or SVG page at `assets/<game-slug>/ui/hud.html` showing the two or three numbers the player needs, the main buttons and one toast. Phone portrait and landscape at minimum. Real copy, the style palette, 44 px touch targets. Screenshot to `docs/concepts/<game-slug>/<date>-hud-<device>.png`.

## 5. Comparison page for the vote
`docs/concepts/<game-slug>/comparison.html`: the three style options side by side, each with its palette, the graybox under its lighting preset, the hero asset and the HUD recoloured. One sentence per option on what it would cost to maintain (textures against flat colours). The owner shares it; the vote result goes in `docs/decisions.md`.

## 6. Rules
- Original art only. Never placeholder characters or art lifted from another game in a render or mockup.
- Every picture shows scale with one of the game's own characters or props.
- Check every picture small: about 150 px wide for a thumbnail, 48 px for an icon. If the subject does not read, make it bigger.
- Every image gets one line in `docs/concepts/<game-slug>/README.md`: filename, what it shows, which style option, date. Captions are what the devlog reuses.
