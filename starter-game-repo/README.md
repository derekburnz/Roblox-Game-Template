# <Game Name>

A Roblox game built by a small team with Claude agents. This repo is the source of truth for the game's code, assets and docs.

- **Rules for every agent:** `CLAUDE.md`.
- **Setting up a PC, GitHub and the Roblox key:** `docs/setup-guide.md`.
- **The design:** `docs/design/<game-slug>/gdd.md`.
- **Decisions and why:** `docs/decisions.md`.

## Layout
| Path | Holds |
|---|---|
| `games/<game-slug>/` | The Rojo project: `src/server`, `src/client`, `src/shared`, the check gate (`check.sh`, `check.ps1`) and the Open Cloud scripts |
| `.claude/agents/` | Nine role definitions (designer, engineer, reviewer, QA, UI, art, VFX, sound, growth) |
| `.claude/skills/` | The know-how each role reads before a task. Third-party skills keep their licences: see `.claude/skills/THIRD_PARTY.md` |
| `.github/workflows/` | `check` (the gate on every pull request), `publish`, `restart-servers`, `flags` (live switches) |
| `.github/ISSUE_TEMPLATE/` | The Task and Claim work forms. Labels are listed in `.github/labels.json` |
| `docs/` | Design, decisions, setup guide |
| `assets/<game-slug>/` | Blender sources, exports, audio and UI mockups, added as the game grows |

## First run
This repo started from a template. If the folders `games/GAME_SLUG` and `dot-claude` still exist, run `tools/init-game.sh` once (the file explains its arguments). It names the game folder, moves `dot-claude/` to `.claude/` and fills in the game's name everywhere. Then run `./check.sh` in the game folder.
