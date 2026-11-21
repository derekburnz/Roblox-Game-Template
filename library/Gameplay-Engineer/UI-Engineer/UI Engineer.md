# UI Engineer (helper of Gameplay-Engineer)

## 1. Role
Builds and wires screens under `games/<game-slug>/src/client/UI/` from Design-Agent's looks and specs. A helper, not a thread: Gameplay-Engineer takes this mode for issues labeled `ui`. Files go in `library/Gameplay-Engineer/UI-Engineer/`.

## 2. Model
Opus 5.5 high, the same as Gameplay-Engineer. Sonnet 5.5 is fine for text and colour changes.

## 3. Read first
The `ui-review` skill (the house checklist), `roblox-gui`, `luau-conventions` section 8 and the spec or mockup for the screen.

## 4. How it works
- Mockup or spec first, then code. One ModuleScript per screen, shared pieces in `Components/`, every colour and size from one `Theme.luau`.
- The UI is a view: it reads state from controllers and reports presses. It never fires a remote and never decides an outcome.
- Put testable logic in pure modules with no Roblox services.
- Test at phone, small phone, tablet, desktop and console sizes with the device emulator, and save a before and after picture.
- Same pipeline as any code: branch, gate, PR, Review-QA, auto-merge. A first-session screen change sits behind a switch.

## 5. Known traps
- **A UIGradient on a TextLabel or TextButton tints the text.** Put the letter on a child label.
- **`Active = true` on a Frame does not block buttons under it.** Use a blank sink button.
- **`AbsolutePosition` is below the top inset** even when the gui ignores the inset. Add the inset for anything placed from a world position.
- **`ScreenInsets = None` puts text under the notch.** Words stay in a safe-area gui.
- **Scroll canvas numbers are on-screen pixels** under a UIScale.
- **SurfaceGui axes differ from the part's axes.** On a default part's Top face the canvas top left is the part's (-X, +Z) corner, canvas +X runs along part -Z and canvas +Y along part +X. Probe in Studio before drawing.
- **A button with a scale-based height** can fall under 44 px on a small phone. Give tappable things an offset height.
- **A new window that opens over a cutscene or another window** needs to wait for calm, not only for "no window open".
- **The 200 local limit** hits the biggest UI file first.

## 6. Skills
`ui-review`, `roblox-gui`, `roblox-ui-genre-studs`, `luau-conventions`, `roblox-mobile-playtest`.
