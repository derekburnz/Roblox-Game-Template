# Choices in this template

The choices made in this starter, one line each, so a reader knows what is on purpose.

- The agent files ship in `starter-game-repo/dot-claude/`, and `tools/init-game.sh` moves them to `.claude/` in the game repo, so the template can be edited freely.
- A stray `starter-game-repo/.claude/` is ignored by `.gitignore` as a safety net and never committed.
- The game folder is `games/GAME_SLUG/` in the starter, and `tools/init-game.sh` renames it and fills the game's name into every file.
- Setup has three files beyond the numbered four: `5-secrets-and-ids.md`, `owner-preferences.md` and `scheduled-tasks.md`.
- The main secret is `ROBLOX_PUBLISH_KEY`, with an optional `ROBLOX_GROUP_KEY` for group-owned uploads. The repo variables are `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID`, `ROBLOX_GROUP_ID` or `ROBLOX_OWNER_USER_ID` (who owns uploads), `AUTO_PUBLISH` and `AUTO_RESTART`.
- `AUTO_PUBLISH` stays unset until the first build is worth publishing, and `AUTO_RESTART` stays unset.
- A helper agent is a mode of its parent thread with its own short starting file, not a separate thread.
- The day-one threads are Gameplay-Engineer, Design-Agent and Review-QA-Agent. The others start when their work exists.
- Planning-Agent runs only until the one-page design is agreed.
- The person who owns the game is called "the owner" in every file.
- The starter ships `Remotes` and `SaveSchema` in `src/shared/`; a `Config` module is named as a file the game creates later.
- The reels study is kept game neutral in `library/Growth-Agent/playbooks/reels-study.md`, with the reasons behind the short video format.
- The template problem form uses a `template` label, defined in `.github/labels.json`.
- `library/Growth-Agent/playbooks/README.md` lists every playbook with one line each.
- The game repo ships small starter modules, not a framework: `NetService` (remotes, rate limits), `Guard` (argument checks), `DataService` on a vendored ProfileStore (session-locked saves), `SaveSchema` (save shape and migrations), `Telemetry` with `TelemetryRules` (analytics, 3 custom fields at most) and `RestartNoticeService` (the in-game restart countdown). Game rules sit in pure modules so they get specs.
- Tests and the UI gate run on Node with a WebAssembly Luau (`tools/cloudcheck`), so they need no Studio and run in CI as a second required check. The starter UI is a tiny example HUD so the gate has something to check; replace it.
- The `automerge` label is a fallback: GitHub's own auto-merge comes first. The workflow merges only when both required checks passed on the newest commit.
- One `upload-asset` workflow takes pictures and sounds; who owns the upload comes from repo variables, never from the workflow file.
