# Choices in this template

The choices made in this starter, one line each, so a reader knows what is on purpose.

- The agent files ship in `starter-game-repo/dot-claude/`, and `tools/init-game.sh` moves them to `.claude/` in the game repo, so the template can be edited freely.
- A stray `starter-game-repo/.claude/` is ignored by `.gitignore` as a safety net and never committed.
- The game folder is `games/GAME_SLUG/` in the starter, and `tools/init-game.sh` renames it and fills the game's name into every file.
- Setup has three files beyond the numbered four: `5-secrets-and-ids.md`, `owner-preferences.md` and `scheduled-tasks.md`.
- The one secret is `ROBLOX_PUBLISH_KEY`. The repo variables are `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID`, `AUTO_PUBLISH` and `AUTO_RESTART`.
- `AUTO_PUBLISH` stays unset until the first build is worth publishing, and `AUTO_RESTART` stays unset.
- A helper agent is a mode of its parent thread with its own short starting file, not a separate thread.
- The day-one threads are Gameplay-Engineer, Design-Agent and Review-QA-Agent. The others start when their work exists.
- Planning-Agent runs only until the one-page design is agreed.
- The person who owns the game is called "the owner" in every file.
- Shared files such as a `Config` or `Remotes` module in `src/shared/` are named as files the game creates later, since the starter does not ship them.
- The reels study is kept game neutral in `library/Growth-Agent/playbooks/reels-study.md`, with the reasons behind the short video format.
- The template problem form uses a `template` label, defined in `.github/labels.json`.
- `library/Growth-Agent/playbooks/README.md` lists every playbook with one line each.
