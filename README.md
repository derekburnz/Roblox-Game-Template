# Roblox game starter for a Claude agent team

This repo is a starting point for making a Roblox game with a small team of Claude agents. It holds no game. It holds the working setup: the agent roles, the skills they read, the review and publish pipeline, the rules that protect players and the owner, and playbooks for growth and video.

Each new game gets its own copy of this repo. That copy becomes the game's private **library**: the place its agents keep their files and a copy of project memory. The game's code lives in a second repo that setup creates from `starter-game-repo/`.

## For the person

### What you need first
- A **GitHub** account.
- **Roblox Studio** on a Windows or Mac PC, and a Roblox account.
- A **Claude plan with projects**, with Remote Control into your PC for Studio work.

You do not need a game idea. If you have none, setup starts with a Planning agent that helps you find one.

### How to start
1. On GitHub, press **Use this template** on this repo (or copy it) to make a private repo for your game, for example `my-game-library`.
2. Create a Claude project and attach that repo.
3. In the project chat, type **setup**.

Claude asks a few questions in one message, then sets everything up and tells you what is done and what waits on you. It explains Roblox terms the first time they come up.

### What you will be asked to do yourself
Things only you can do: create the game repo on GitHub, create the Roblox experience, make the Open Cloud key and paste it into GitHub, and say yes before any thread is started. Claude gives you the exact clicks. Claude never types a password or a code.

## For Claude, when the person types "setup"

You are the coordinator of a new project. Follow these steps in order. Do not start any thread until step 7, and only with the owner's OK. Keep every message to the owner short and lead with the answer.

**1. Read.** `library/Setup/` in this order: `1-coordinator-guide.md`, `2-threads-and-models.md`, `3-working-rules.md`, `4-library-and-sync.md`, `5-secrets-and-ids.md`, `owner-preferences.md`, `scheduled-tasks.md`. Then `library/Coordinator/Coordinator.md`.

**2. Ask the setup questions, all in one message.**
1. Your name and GitHub login.
2. Do you have a game idea? If yes: one sentence and a working name. If no, say so: that is fine.
3. What time zone are you in? (Default ET.)
4. What is your PC's name, and which folder should the game live in? (For Remote Control. This can wait until Studio is needed.)
5. Will a Roblox group own the game, or your own account? (A group is recommended. This can wait until the game repo step.)
6. Which Claude plan are you on? (It decides which models and how many threads; see `2-threads-and-models.md`.)
7. Here are the default working preferences [paste the numbered list from `owner-preferences.md`]. Keep them all, or change any?

**3. Project instructions.** Fill the brackets in `library/Setup/0-project-instructions.txt` with the answers and any changed preferences. Save it as the project's instructions, or ask the owner to paste it if you cannot. Write the filled text to `memory/project-instructions.md` in this repo.

**4. Project memory.** Fill `library/Setup/memory-seed/MEMORY.md` and save it to project memory as `MEMORY.md`. Write the same text to `memory/project-memory.md` in this repo. Never put a secret in either.

**5. Shared folder.** Copy each `library/<Thread>/` folder to the project's shared files as `<Thread>/`, helper folders included. Scheduled prompts and hand-offs use those paths.

**6. Branch on the idea.**

- **No game idea yet:** with the owner's OK, start **Planning-Agent** only (Fable 5.2 high) with the brief in `2-threads-and-models.md`. It reads `library/Planning-Agent/Planning Agent.md` and uses the skills under `starter-game-repo/dot-claude/skills/` in this repo, since no game repo exists yet. Relay its questions and proposals to the owner. Go no further until the owner agrees a one-page design. Then stop Planning-Agent and continue below with the game's name.
- **There is an idea:** if it is one sentence and not yet a one-page design, still run Planning-Agent for one short session (its steps 3 to 5) to write the design and the first milestone plan. If the owner already has a written design, use it.

**7. The game repo.** Only once there is an agreed one-page design.
1. Ask the owner to create an empty GitHub repo for the game and attach it to the project. Public gives free Actions minutes; private keeps everything unseen. Either works. If public, nothing private ever goes in it.
2. Copy everything inside `starter-game-repo/` into the new repo's root.
3. In the new repo run `tools/init-game.sh <game-slug> <GamePrefix> "<Game Name>" <owner>/<game-repo>`. It names the game folder, moves `dot-claude/` to `.claude/` and fills the game's name into every file.
4. Put the agreed design at `docs/design/<game-slug>/gdd.md`. Commit and push to `main`.
5. The `repo-labels` workflow creates the labels in `.github/labels.json` on that first push; if it did not run, start it from Actions.
6. Walk the owner through `docs/setup-guide.md` steps 8 and 9: the Open Cloud key and repo variables, then the required check and auto-merge. Leave `AUTO_PUBLISH` unset until the first build is worth publishing. Leave `AUTO_RESTART` unset.
7. Open the first issues from the milestone plan (Task form, one area label each).
8. Update the project instructions and memory with the repo names and the Roblox ids.

**8. Threads.** Propose the day-one set (Gameplay-Engineer, Design-Agent, Review-QA-Agent) and start only what the owner OKs, with the exact names and models from the roster below and the brief in `2-threads-and-models.md`. Each thread reads its own `library/<Thread>/<Thread Name>.md` first, then `library/Setup/3-working-rules.md`. Add Motion-FX-Agent, Model-Agent and Growth-Agent when their work exists.

**9. Scheduled tasks.** Create the coordinator idle check from `library/Setup/scheduled-tasks.md` once issues are open. Add others only when their job exists.

**10. Studio.** When the first Studio check is needed, start Sync-Agent with the owner's OK and have it open Remote Control into the owner's PC, using the PC name and folder from step 2. The toolchain steps are in the game repo's `docs/setup-guide.md` steps 1 to 6.

**11. Tell the owner,** in one short message: what is set up, which threads are running, and the list of things that wait on them, each with its exact next click.

After setup, your daily routine is `library/Coordinator/Coordinator.md`.

## For later

### The roster
| Agent | Model and effort | Job | Runs | Helper agents in its folder |
|---|---|---|---|---|
| Coordinator | Opus 5.5 medium | Runs the project chat, turns asks into issues, routes work, keeps threads moving and runs the idle check | always | none |
| Planning-Agent | Fable 5.2 high, only while planning | Helps a person with no game idea find one, then writes the one-page design and the first milestone plan | until the design is agreed | Idea-Research |
| Design-Agent | Opus 5.5 medium (Fable 5.2 for hard calls) | Specs, economy, tutorial, UI looks and the decisions log | always | Tutorial-Agent |
| Gameplay-Engineer | Opus 5.5 high | All Luau code, UI wiring, CI, and the publish and switch workflows | always | UI-Engineer, Tools-Agent |
| Review-QA-Agent | Opus 5.5 medium | Reviews every PR at its head, arms auto-merge, writes test plans and runs playtests | always for review, QA on demand | Review-Agent, QA-Planner, Device-Tester |
| Motion-FX-Agent | Opus 5.5 medium | Effects, animation, sound and the video tools | when polish work exists | VFX-Agent, Animation-Engineer, Sound-Agent |
| Model-Agent | Opus 5.5 high | Blender models, areas, icons and store pictures | on demand, in bursts | none |
| Growth-Agent | Sonnet 5.5 (Opus 5.5 for big reads) | Stats, funnels, benchmarks, store copy, icon tests and the social video plan | scheduled reads or on demand | Research-Agent, Monetization-Agent, Social-Video-Agent |
| Sync-Agent | Sonnet 5.5 | Studio on the owner's PC through Remote Control, plus library and memory sync | on demand | none |

The rule of thumb for models: Fable for design, architecture and hard bugs; Opus for building; Sonnet or Haiku for chores. What to downgrade first on a smaller plan is in `library/Setup/2-threads-and-models.md`. A helper agent is a mode of its parent thread with its own short starting file, not a separate thread.

### How the work moves
1. Every ask becomes a GitHub issue with an area label. A thread claims it before starting.
2. One feature per branch and pull request, with a test plan.
3. A separate agent reviews it. No agent signs off its own work.
4. Auto-merge once the review passes and the check gate is green.
5. Merges to main publish to Roblox from GitHub Actions, to new servers only.
6. New features ship behind a live on/off switch. The switch goes on as soon as the publish lands, and the off switch stays for instant rollback.
7. Servers are never restarted unless the owner says so.
8. Threads never sit idle while issues are open: they park what is stuck and take the next one.
9. Every deliverable is a file in the shared folder and the library, so nothing lives only in a chat.

### What is where
| Path | Holds |
|---|---|
| `README.md` | This file: what the repo is, the setup steps, the roster |
| `library/Setup/` | Project instructions text, coordinator guide, roster and routing, working rules, sync rules, secret names, owner preferences, scheduled tasks, the memory seed |
| `library/Coordinator/` | The coordinator's own file: routing table, top rules, idle check, how to start threads |
| `library/<Thread>/<Thread Name>.md` | Each agent's starting file: lane, model, what to read first, how it takes work, known traps, skills |
| `library/<Thread>/<Helper>/` | Each helper agent's starting file |
| `library/Growth-Agent/playbooks/` | Home recommendations, funnels, the benchmark sheet, go or no-go, A/B tests, store copy and event cards, ads basics, short video format, reels study, Buffer posting |
| `library/Growth-Agent/story-kit/` | Tools for the animated story video: voice, re-voice, assemble |
| `library/Motion-FX-Agent/video-tools/` | Recording tips, a shot list template, the page video cut and the story clip cut |
| `memory/` | Word for word copies of the project instructions and project memory, written during setup and kept current by Sync-Agent |
| `starter-game-repo/` | Everything a new game repo starts with: `CLAUDE.md` (studio rules), `dot-claude/` (agent definitions and skills; becomes `.claude/`), issue forms and labels, the Rojo layout, `rokit.toml`, the check gate, starter modules (remotes, saves, analytics, restart notice), unit tests and the UI gate (`tools/cloudcheck`), and the check, automerge, labels, publish, restart, flags, upload and asset permission workflows |
| `.github/ISSUE_TEMPLATE/` | A form for reporting a problem with this template |
| `.github/labels.json` | The `template` label the problem form uses |
| `CHOICES.md` | The choices made in this template, one line each |

### Licences
The skills under `starter-game-repo/dot-claude/skills/` include third-party skills under the MIT licence. Each keeps its `LICENSE` file, and `THIRD_PARTY.md` in that folder lists where each came from. Keep those files if you share or publish a copy.

The game repo's `src/server/Vendor/ProfileStore.luau` is [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) by loleris, under the MIT licence, kept exactly as shipped. The UI gate and test runner in `tools/cloudcheck` use [`@luau-rs/luau`](https://www.npmjs.com/package/@luau-rs/luau) from npm.
