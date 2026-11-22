# <Game Name> studio rules

Game name: **<Game Name>**. Game slug used in paths: `<game-slug>`. Code names and asset names start with `<GamePrefix>`.
Repo: `<owner>/<game-repo>`. This repo is the source of truth for the game. Work on a branch, open a pull request and let CI run the check gate. Once a pull request is reviewed, GitHub auto-merge is turned on (merge commit) and it merges itself when the required check passes. Merges to main publish to Roblox from GitHub Actions (skill `merge-and-publish`).

These rules load in every Claude session that opens this repo. Each rule has its reason, so you can use judgment when a case is not covered.

## Read first, in this order
1. `docs/design/<game-slug>/gdd.md` (the one-page design; owned by the game-designer).
2. `docs/decisions.md` (what has been decided and why). Append, never rewrite.
3. The skill for your task in `.claude/skills/<name>/SKILL.md`.
4. `docs/setup-guide.md` when a tool is missing on the PC.

## Where things live
| What | Path | Owner role |
|---|---|---|
| Luau code (Rojo synced) | `games/<game-slug>/src/{server,client,shared}` | luau-engineer; `src/client/UI/` is the ui-designer's |
| Rojo project, tool configs, check gate | `games/<game-slug>/` | lead |
| CI, Open Cloud publish, live switches | `.github/`, `games/<game-slug>/tools/opencloud/` | lead |
| Tool versions | `rokit.toml` (repo root) | lead |
| Design docs | `docs/design/<game-slug>/` | game-designer |
| Style guide | `docs/art/style-guide.md` | asset-artist |
| Concept screenshots, UI mockups | `docs/concepts/<game-slug>/`, `assets/<game-slug>/ui/` | asset-artist, ui-designer |
| 3D sources and exports | `assets/<game-slug>/blender/`, `assets/<game-slug>/exports/` | asset-artist |
| Rojo-synced model files | `assets/<game-slug>/rbx/` (becomes `ReplicatedStorage.Assets`) | asset-artist |
| Animation and VFX code (client only) | `games/<game-slug>/src/client/Effects/` | vfx-animator |
| Animation sources, VFX textures | `assets/<game-slug>/anim/`, `assets/<game-slug>/vfx/` | vfx-animator |
| Client audio code, audio files and license log | `games/<game-slug>/src/client/Audio/`, `assets/<game-slug>/audio/`, `docs/audio/` | sound-designer |
| Code reviews | `docs/reviews/<date>-<topic>.md` | luau-reviewer |
| Playtest reports and tickets | `docs/playtests/<date>.md` | qa-playtester |
| Research, analytics plan, store page, launch plan | `docs/growth/` | growth-analyst |
| Decisions, devlog, setup guide | `docs/decisions.md`, `docs/devlog.md`, `docs/setup-guide.md` | lead |

Most of these folders do not exist yet. Create one when its first file arrives. Write only inside the folders your role owns. If you need a change elsewhere, open an issue for the owner or write a note in `docs/decisions.md` under "Proposed". Reason: two agents editing one file is the main source of merge conflicts and lost work.

## Rules
1. **Back up first.** Commit before any agent session. Agents work in a dev copy of the place, never the published one. Reason: an agent mistake in the live place reaches players at once.
2. **Code lives in files.** Scripts are edited under `src/` and synced by Rojo. Never edit a Rojo-managed script inside Studio; Rojo overwrites it. Studio tools are for the world, non-script instances, playtests, console output and screenshots.
3. **Server authority.** The client asks and the server decides. Validate every remote argument and rate-limit every remote (skill `remote-security-checklist`). Reason: a player can run any code on their own device.
4. **Pipeline per feature:** design spec, engineer build, reviewer check, QA playtest. No agent signs off its own work. Reason: an author misses their own mistakes.
5. **Small steps.** One feature per branch and pull request, each with a test plan. Reason: a small change is easy to review and easy to roll back.
6. **Done means the gate passes:** `cd games/<game-slug>` then `./check.ps1` (Windows) or `./check.sh`. It runs `rojo sourcemap`, `luau-lsp analyze`, `selene` and `stylua --check`. Then a playtest with no new console errors.
7. **Creator Store assets** are inspected for scripts before use (skill `roblox-creator-store-security-audit`). Reason: free models are the usual way a backdoor gets into a game.
8. **Original IP only.** Mechanics can be inspired by other games; names, characters, art and audio are ours.
9. **Paid random items** follow `monetization-policy` every time: odds always shown before purchase. It also applies when the random thing is bought with a currency that Robux can buy.
10. **Young audience by default.** No dark patterns, filter user text and match content to the maturity label the game declares.
11. **Usage budget.** Fable for design, architecture and hard bugs; Opus for building; Sonnet or Haiku for chores.
12. **Decisions** go in `docs/decisions.md` with date and reason. Append, never rewrite.
13. **Secrets** (Open Cloud keys, tokens) stay in environment variables or GitHub secrets, never in the repo, in chat or in memory. If this repo is public, nothing private goes in it: no player names, user ids or sales numbers.
14. **Explain Roblox concepts** the first time they come up. The owner may know other fields well and still be new to Luau and Studio.
15. **Issues and claims.** Every open request is a GitHub issue (the "Task" form) with an area label from `.github/labels.json` (`ui`, `animation`, `gameplay`, `model`, `sound`, `vfx`, `store-art`, `tools`, `qa`, `design`, plus `needs-owner` when it waits on the owner). Pick your next job from those issues. To take one, first search open pull requests for its number (an issue with no claim label can still have a pull request), then add the `claim` label and comment who is on it. The pull request that finishes it says "Closes" plus the issue number. Open a "Claim work" issue before work that takes more than one pull request or touches shared files (the design document, the save service `Services/DataService.luau` and `src/shared/SaveSchema.luau`, and shared modules in `src/shared/` such as `Remotes.luau` or a later `Config`). Reason: this is how several threads, or two Claude projects sharing this repo, avoid building the same thing twice.
16. **Live switches.** A new feature ships behind a switch in `src/shared/LiveFlags.luau`, off by default. Its pull request merges and publishes while off. The switch goes on with the `flags` workflow in the same hour the publish lands, and the off switch stays for instant rollback. Every change to the tutorial or the first session ships this way with no exception. Reason: a bad first minute loses players before anyone can react, and a switch flips in a minute while a fix takes a publish.
17. **Publishing and restarts.** Merges to main publish by themselves when the repo variable `AUTO_PUBLISH` is true, so merge only what is ready to ship. A publish reaches new servers only. Never restart servers unless the owner says so in their own words. Reason: a restart disconnects every player.
18. **Uploads are group owned** when a Roblox group owns the game. An image, sound or animation uploaded under a personal account does not load in a group-owned game, and placeholder art can hide the failure for days. After any upload, check the asset loads in the live game.

## Luau quick facts (for anyone new to Roblox)
- A **place** is one level or world file. An **experience** (also called a universe) is the published game that holds places. We work in a dev copy of the place.
- **Server scripts** run on Roblox's server (`ServerScriptService`), **client scripts** on each player's device (`StarterPlayerScripts`), and **ModuleScripts** are libraries either side can `require`. `ReplicatedStorage` is visible to both; `ServerStorage` only to the server.
- **RemoteEvents and RemoteFunctions** are how client and server talk. An exploiter can fire any remote with any arguments, so the server validates everything.
- **Rojo** maps folders on disk to that instance tree using `default.project.json`.
- **DataStores** are Roblox's saved key and value storage. Saves and the live switches live there.
- **Open Cloud** is Roblox's web API. GitHub Actions uses it, with a key held as a GitHub secret, to publish the place and flip switches.

## Naming
Files: `PascalCase.luau`. Server entry points end in `.server.luau`, client ones in `.client.luau`. Instances in Studio: `PascalCase`. Assets: `<GamePrefix>_<Category>_<Name>` (see `asset-pipeline`). Placeholder parts: `PH_<Thing>`.

## Known traps
- **Luau allows 200 local variables per function,** and a file's top level counts as one function. A big module with many `local X = require(...)` lines stops compiling with "Out of local registers". Group requires into one table or require inside the function that uses them.
- **Run StyLua from `games/<game-slug>`** with `--respect-ignores`, never from the repo root. Otherwise it reformats vendored files under `src/server/Vendor/`, which must stay exactly as shipped.
- **CI's luau-lsp is the judge.** A looser local checker can pass code that CI fails. Annotate values read from tables before comparing them with nil, and type the result of an if-expression before looping over it.
- **A green pull request stuck "blocked"** with required checks "expected" usually has a cancelled run as its newest. Turn auto-merge off and on again to start a fresh run.
- **Two pull requests that both add a switch** edit the same lists in `LiveFlags.luau`. Merge main into the second one before it is armed.
- **Stacked pull requests:** GitHub does not retarget a pull request whose base branch merged unless that branch is deleted. Retarget it to main by hand before it auto-merges.
- **Never reset a branch to main while its pull request is open.** A force push replaces the head of the open pull request, and armed auto-merge could merge the wrong change.
- More traps per role are in each agent's library file.
