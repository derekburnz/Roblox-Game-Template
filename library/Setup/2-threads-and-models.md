# Threads, models and routing

This file is the roster, the coordinator's routing table and the reasons behind both. Thread names are `Category-Agent` or `Category-Engineer`. Each thread's library folder has exactly that name and its context file is `library/<Thread>/<Thread Name>.md` (hyphens become spaces, for example `library/Motion-FX-Agent/Motion FX Agent.md`).

## The roster

| Thread | Model and effort | Job | Runs | Helper agents inside its folder | Owns in the game repo |
|---|---|---|---|---|---|
| Coordinator (project chat) | Opus 5.5 medium | Runs the project chat, turns asks into issues, routes work, keeps threads moving and runs the idle check | always | none | issues, routing |
| Planning-Agent | Fable 5.2 high, only while planning | Helps a person with no game idea find one, then writes the one-page design and the first milestone plan | only until the design is agreed | Idea-Research | nothing (its design moves to `docs/design/`) |
| Design-Agent | Opus 5.5 medium (Fable 5.2 for hard calls) | Specs, economy, tutorial, UI looks and the decisions log | always | Tutorial-Agent | `docs/design/<game-slug>/`, `docs/decisions.md` |
| Gameplay-Engineer | Opus 5.5 high | All Luau code, UI wiring, CI, and the publish and switch workflows | always | UI-Engineer, Tools-Agent | `games/<game-slug>/src`, `.github/`, `tools/opencloud/` |
| Review-QA-Agent | Opus 5.5 medium | Reviews every PR at its head, arms auto-merge, writes test plans and runs playtests | always for review; QA on demand | Review-Agent, QA-Planner, Device-Tester | `docs/reviews/`, `docs/playtests/` |
| Motion-FX-Agent | Opus 5.5 medium | Effects, animation, sound and the video tools | when polish work exists | VFX-Agent, Animation-Engineer, Sound-Agent | `src/client/Effects/`, `src/client/Audio/`, `assets/<game-slug>/{anim,vfx,audio}/` |
| Model-Agent | Opus 5.5 high | Blender models, areas, icons and store pictures | on demand, in bursts | none | `assets/<game-slug>/{blender,exports,rbx}/`, `docs/art/style-guide.md` |
| Growth-Agent | Sonnet 5.5 (Opus 5.5 for big reads) | Stats, funnels, benchmarks, store copy, icon tests and the social video plan | scheduled reads or on demand | Research-Agent, Monetization-Agent, Social-Video-Agent | `docs/growth/` |
| Sync-Agent | Sonnet 5.5 | Studio on the owner's PC through Remote Control, plus library and memory sync | on demand | none | nothing in the game repo; the library repo |

A helper agent is not a thread. It is a mode of its parent thread with its own short starting file, used when the parent takes that kind of task or spins up a subagent for it. Split a helper out into its own thread only if the owner says so.

Models change only by `/model` and `/effort` typed in the thread, or through a fresh replacement thread. Default for anything not listed: Opus 5.5 medium.

## Why each model, and what to downgrade first
The rule of thumb: Fable for design, architecture and hard bugs; Opus for building; Sonnet or Haiku for chores.

- **Planning-Agent on Fable 5.2 high.** Picking the game is the most expensive decision in the project and the cheapest moment to be careful. It runs for a few sessions, then stops.
- **Gameplay-Engineer and Model-Agent on Opus 5.5 high.** One writes code that touches saves and money; the other does long multi-step Blender work where a small slip wastes a whole build.
- **Design, Review-QA and Motion-FX on Opus 5.5 medium.** Judgment work with a reviewer or a spec on the other side.
- **Growth and Sync on Sonnet 5.5.** Reading dashboards, copying files and driving Studio are chores. Growth switches to Opus for a big read such as a go or no-go.
- **Coordinator on Opus 5.5 medium.** It routes all day; a wrong route costs every thread's time.

On a smaller plan, downgrade in this order and stop when usage fits:
1. Sync-Agent and Growth-Agent to Haiku 5.5 for routine syncs and daily reads.
2. Motion-FX-Agent and Design-Agent to Sonnet 5.5 (keep Design on Opus for the tutorial and the economy).
3. Coordinator to Sonnet 5.5.
4. Model-Agent to Opus 5.5 medium.
5. Review-QA-Agent to Sonnet 5.5 for docs and art PRs only. Keep code review on Opus.
6. Last: Gameplay-Engineer to Opus 5.5 medium. Never put save or purchase code on a small model without an Opus review.

A Sonnet or Haiku thread that hits breakage it cannot explain (a CI or publish failure) asks the coordinator to hand that task to an Opus thread.

## Starter sets (start only what the owner OKs)
- **No game idea yet:** Planning-Agent only.
- **Day one of building:** Gameplay-Engineer, Design-Agent, Review-QA-Agent. That covers spec, build and review.
- **Add when the work exists:** Motion-FX-Agent (effects, animation, sound), Model-Agent (models), Growth-Agent (once there are players or a store page to write).
- **Wake only when asked:** Sync-Agent, for a Studio run on the owner's PC or a library sync.
- Stop a thread that has no open issues, and wake it when its lane gets one.

## Coordinator routing table

| Ask | Thread | Start or wake |
|---|---|---|
| "I have no idea what to make", comparing ideas, the first one-page design | Planning-Agent | start for planning, stop after |
| New feature, bug, remote, save, Config, world placement | Gameplay-Engineer | always on |
| HUD, screen, menu, button wiring | Gameplay-Engineer (UI-Engineer mode) | always on |
| Publish, restart, CI failure, switches, Open Cloud, uploads | Gameplay-Engineer (Tools-Agent mode) | always on; the only thread that dispatches publish, restart or upload workflows |
| What to build next, numbers, economy, pricing and policy, tutorial flow, specs, UI looks, decisions | Design-Agent | always on |
| Review a PR, merge order, security review | Review-QA-Agent | always on |
| Test plan, bug tickets, a playtest | Review-QA-Agent | wake for QA |
| A Studio run or recording on the owner's PC | Sync-Agent (asked by whichever thread needs it) | wake on request |
| Particles, glows, world effects, character motion, trailer, page video cut | Motion-FX-Agent | start when a polish issue exists |
| Sounds, music, audio uploads | Motion-FX-Agent (Sound-Agent mode) | wake for audio |
| New 3D model, area, icon, thumbnail, store picture | Model-Agent | wake per batch |
| Stats, funnels, benchmark, ads read, store copy, event cards, social video plan | Growth-Agent | schedule reads; wake for the rest |
| Library sync, memory sync, cleanup | Sync-Agent | wake on request |

When an ask spans threads, send it to the first step of the pipeline (design, then build, then review, then QA). No thread signs off its own work.

## Why this split
1. **Gameplay, UI and tools in one thread.** One author of `src/` removes the merge conflicts between a UI PR and the server PR it depends on, and publishing sits with the thread that knows what is in the build.
2. **Design and tutorial together.** The tutorial always goes through a design spec.
3. **Review, QA and device tests together.** None of them builds code, so nobody signs off their own work. QA and device runs are rare, so they are modes, not threads.
4. **Effects, animation and sound together.** Same folder and the same moment list, so two threads would keep editing the same lines.
5. **Research, monetization and social video under Growth.** All read the same stats. Pricing and policy calls still go to Design-Agent.
6. **Model-Agent stays separate.** Blender work is heavy, needs its own context and runs in bursts.
7. **Design stays apart from Gameplay.** Spec first, build second, so a builder never grades its own spec.
8. **Planning is its own short-lived thread.** It needs the strongest model and no game repo. Once the design is agreed its work is done, and the cheaper Design-Agent keeps the design current.
9. **Sync-Agent is the only Studio driver.** Two Remote Control sessions on one Studio collide.

## Brief that starts (or restarts) a thread
> You are **[Thread-Name]** in the [Game Name] project. Model: [from the roster].
> Read first, in order: `library/[Thread-Name]/[Thread Name].md` in the library repo, `library/Setup/3-working-rules.md`, the game repo's `CLAUDE.md`, and the skill for your task in `.claude/skills/`.
> You own: [folders from the roster]. Keep your `[Thread Name].md` current and push it before any reset.
> Check open `claim` issues and open PRs on the game repo before starting. First task: [issue link and the ask].

## Studio on the owner's PC
Build the place from the repo and open it locally, never the published place: `rojo build default.project.json -o dev.rbxl` in `games/<game-slug>`, open it in Studio, `rojo serve` while testing. `docs/setup-guide.md` in the game repo covers the toolchain.
