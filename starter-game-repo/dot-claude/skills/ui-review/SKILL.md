---
name: ui-review
description: The game's UI checklist. Use before building, changing or reviewing any screen, HUD piece, card or toast in games/<game-slug>/src/client/UI, and before signing off a UI pull request.
---

# UI review

The house rules for the game's screens, in one place. Use it with:

- `roblox-gui` for layout, safe insets, input, gamepad focus and cleanup (the engineering rules).
- `roblox-ui-genre-studs` for the simulator look (outlines, colour meanings, HUD zones, motion numbers). Its numbers are starting values. Where it and the game's own theme differ, the game's `Theme.luau` and this file win.

These are the owner's default tastes from a first game. Setup confirms them, and the game's style guide may change them.

## 1. Boundaries
- The UI is a view. It reads the state it is given and reports presses. It never fires a remote and never decides an outcome. A Claim button shows "..." until the server says the claim happened.
- Logic that can be tested goes in a pure module with no Roblox services, so it can be unit tested without Studio.
- Colours, sizes and fonts come from one `Theme.luau`. No hex codes in a screen.

## 2. Standing rules
- **Brief by default.** A screen shows the one thing the player needs; details sit behind a tap. Hide rows and pictures that say nothing new.
- **Pictures over writing** where a picture says it.
- **HUD status is outlined text with no box.** Only pressable things look like buttons. A number with a plate behind it reads as a button.
- **A red "!" or count means something to claim or new to buy.** Never light it for news the player cannot act on. Anything the player cannot afford or use is grey.
- **Fewer pop-ups.** No banner for every small event, and none while a full-screen menu is open except warnings and purchase confirmations. Many rewards at once get one Claim all and one summary.
- **One window at a time.** A new window replaces the old. Only the window's X or its key closes it.
- **No menu opens by itself.** The player opens every window. A window that pops open unasked reads as an ad and gets closed unread.
- **Tutorial steps are tapped by the player:** dim the screen, point an arrow at the one thing to press and wait. Never press it for them, and never auto-open the menu the step is about.
- **Clear wording.** A description says exactly what the item gives (numbers, durations, contents). A rename reaches every label.
- **Original art only**, and no placeholder characters in mockups.

## 3. Sizes and fit
Check every changed screen on a phone (about 844 x 390), a small phone (about 667 x 375), a tablet, a desktop and a 1080p console view.
- Anything pressable is at least 44 real pixels in both directions on touch and at least 36 with a mouse. The X on a window too.
- Body text stays at 14 or more after scaling; nothing renders under 9 real pixels. TextScaled labels get a `UITextSizeConstraint` with a sensible minimum.
- Nothing runs off the screen or under Roblox's top bar, the thumbstick (bottom left) or the jump button (bottom right) on touch.
- Two things that can show at once do not overlap. Reflow before you shrink.
- Long names and big numbers fit: try a 20-letter name and "$1,234,567,890".
- Every menu scrolls on touch, and sideways scrollers get arrows.
- Responses are instant: no visible wait after a press, and images are preloaded rather than loaded on open.

## 4. Look
- One font pair. Buttons use one component, and colour keeps its meaning: green buy or claim, red close, gold rare or featured, grey owned or disabled.
- Motion: windows pop in and close fast (under 0.2 s). Press feedback is a scale, not a size change. Nothing with text pulses forever. Check `GuiService.ReducedMotionEnabled` before shakes, bobs and long tweens.

## 5. Anti-slop check
Adapted from the anti-slop rules in [izzyfrm/roblox-ui-skill](https://github.com/izzyfrm/roblox-ui-skill) (MIT, licence in `LICENSE-anti-slop`) and the list in `roblox-ui-genre-studs`, rewritten in our words. Treat each as a defect unless the design asks for it:

- a card around every group, cards inside cards, or big empty padding;
- an outline on things that are not pressable and not the window itself;
- glow, blur, gradient text or extra shadows added to fill space;
- more accent colours than the screen's header colour plus the button meanings;
- every button the same size whatever its importance;
- pills or badges on everything;
- a permanent upsell button or a timer that nags;
- replacing a working screen with a new one when a fix would do, or dropping a working button or piece of information on the way.

Then ask:
- Does it look like this game and not a generic simulator?
- Did decoration replace good layout?
- Is there anything the player does not need right now?

## 6. Known traps
- **A UIGradient on a TextLabel or TextButton tints its text as well.** Put the letter on a child label.
- **`Active = true` on a Frame does not stop buttons under it firing.** A popover must be a blank button itself or hold a full-size blank sink button.
- **`GuiObject.AbsolutePosition` is measured below the top inset** even in a gui that ignores the inset. Anything placed from a world position needs the inset added.
- **A gui with `ScreenInsets = None` puts text under the phone notch.** Keep words in a safe-area gui and only edge art in a second gui.
- **ScrollingFrame canvas numbers are on-screen pixels** under a UIScale. Multiply design pixels by the scale.
- **SurfaceGui axes are not the part's axes.** On the Top face of a default-oriented part, the canvas top left is the part's (-X, +Z) corner, canvas +X runs along part -Z and canvas +Y along part +X. Probe a face in Studio before drawing on it.
- **SurfaceGuis that hold sliding pieces** need `ClipsDescendants = true`, or the pieces draw past the part.

## 7. Before you open the pull request
- The gate passes (`./check.sh`).
- A visible change has a before and after picture or an HTML mockup saved in the repo or the shared folder, and the pull request says what to look at in Studio.
- The pull request quotes the owner's words for the ask it answers.
- A change to the tutorial or first session sits behind an off switch.
