---
name: merge-and-publish
description: How a thread hands a reviewed pull request to GitHub auto-merge instead of waiting on CI, how the game publishes to Roblox from GitHub Actions without Studio, how live switches are flipped and when servers may be restarted. Use when a PR is reviewed and ready, when the owner asks to publish or roll back, when a switch must go on or off, or when a merge, publish or flags run fails.
---

# Merge and publish

GitHub Actions takes the waiting out of the pipeline. The workflows live in the repo, so they work the same from a cloud thread, the owner's PC or the owner's phone.

## 1. Queue a merge with GitHub auto-merge

Rule: a pull request merges once a separate reviewer has passed its exact head and the required check is green. Nobody waits on CI by hand. Auto-merge waits for main's required check (the ruleset in `docs/setup-guide.md` step 9): `Rojo sourcemap, luau-lsp, Selene, StyLua`.

1. Queue only a pull request you would merge by hand right now apart from CI: the reviewer's findings are addressed, its test plan is written, it targets `main`, it is not a draft and it has no `on-hold` label.
2. Turn auto-merge on with a merge commit (never squash or rebase, so history stays one shape). With the GitHub tools: enable auto-merge with merge method MERGE. From a shell: `gh pr merge <n> --auto --merge`.
3. End your turn. A failed check leaves auto-merge on: push the fix and it merges once the new run passes. A push after the review needs the reviewer to confirm the new head first (a push that only merges main in is "same code" and needs only a quick confirmation). A merge conflict blocks auto-merge: merge main in by hand, resolve and push. Never force-push.
4. When GitHub refuses because the pull request is already green ("clean status"), merge it directly with a merge commit, or add the `automerge` label: the `automerge` workflow merges it once both required checks pass on its newest commit, and drops the label with a comment on a conflict.
5. A green pull request that stays "blocked" with required checks "expected" usually has a cancelled run as its newest. Turn auto-merge off and on again to start a fresh run.

The required check must report on every pull request or auto-merge waits forever. So never put `paths` filters on `check.yml`'s `pull_request` trigger and never rename the `gate` job without changing the ruleset with it.

When two pull requests both add a live switch, arm only one at a time. Each edits the same lists in `LiveFlags.luau`; the second merges main in first.

## 2. Publish to Roblox without Studio

`.github/workflows/publish.yml` builds `default.project.json` with Rojo and uploads it through Open Cloud (`games/<game-slug>/tools/opencloud/publish.sh`).

- **Automatic publish:** with the repo variable `AUTO_PUBLISH` set to `true`, the tip of main is published after every check run on main that passes. Every merge ships, so merge only what is ready to ship.
- **By hand:** dispatch `publish.yml` on `main` with `version_type` `Published` (goes live) or `Saved` (adds a version to the place history without going live). The owner can press Run workflow on the Actions tab.
- **Confirm it is live:** read the "Published version N" line in the run log before telling anyone a fix is live. Never say "live" from a merged pull request alone.
- **Who sees it:** running servers keep their old version; new servers start on the new one. That is normal and fine for most changes.
- **Roll back:** Creator Hub > the place > Version History, or flip the feature's switch off (section 3), which is faster.
- **Failures:** a missing secret fails the first step with that message. A 401 or 403 means the key lacks a permission or its IP list blocks GitHub. A 409 means a Studio session has the place open in Team Create. Tell the owner the setup guide step instead of retrying.
- **Limits:** Open Cloud place publishing cannot update some instance types made only in Studio (for example unions and EditableMesh). If assets start using them, publish those changes from Studio.

The same script runs from Git Bash on a PC with the key in the environment: `cd games/<game-slug> && UNIVERSE_ID=... PLACE_ID=... tools/opencloud/publish.sh Published`.

## 3. Live switches (ship dark, switch on, keep the off switch)

A new feature ships behind a switch in `src/shared/LiveFlags.luau`, off by default (`OFF_BY_DEFAULT`). The header of that file explains the two kinds of switch.

1. The pull request adds the key and wraps the feature in `LiveFlags.isOn("name")`. It merges and publishes while off, so nothing changes for players.
2. In the same hour the publish lands, turn it on: dispatch `flags.yml` with `action: set`, `key: name`, `value: true`. Do not stagger switches over days unless the owner asks; held work is unshipped work.
3. Run one flags run at a time and read the job log to confirm: `name = true (ON in every server)`. Servers pick a change up within about a minute.
4. Tell the growth thread the exact UTC minute each switch went on. Before and after reads split on that minute.
5. Something wrong? `value: false` (or `action: clear`) is the instant rollback. Then fix forward in a new pull request.
6. Retire a switch once its feature has been on for good: remove the key and the `isOn` checks in one small pull request. Search the whole repo for the key first, and check nothing was "shipped" by setting the stored value true while the code default stayed off.

Code reaches a server only when that server starts, so a switch turned on is live only on servers new enough to contain the feature. Servers older than the publish ignore a key they do not know.

A feature that changes saved data needs more care: an older server must not drop or mangle a save a newer server wrote. Keep its switch off until no server older than the publish is running, or ask the owner for a restart.

Every change to the tutorial or the first session ships behind a switch, with no exception. A broken first minute loses new players before anyone can react.

## 4. Restarts

A restart moves every running server onto the newest version and disconnects every player. Rule: never restart unless the owner says so in their own words. Publishing silently to new servers is the default.

When the owner does ask:
1. Check the build they want is already published (section 2). Never restart onto an old build.
2. Record the live player count just before and 30 to 60 seconds after, so the cost of the restart is known. The public endpoint `https://games.roblox.com/v1/games?universeIds=<universe id>` has the field `playing`.
3. Dispatch `restart-servers.yml` (with `warn_players` on, every server shows its players a countdown first: 10 and 2 minutes, 30 seconds, then now), or `publish.yml` with `restart_servers` ticked, which runs the same countdown. The countdown needs `universe-messaging-service:publish` on the key; without it the run warns and restarts with no countdown.
4. Tell the owner the minute it finished and both player counts.

`AUTO_RESTART` stays unset unless the owner asks for automatic restarts.

## 5. Other Open Cloud jobs

The starter repo also ships:
- `upload-asset.yml`: uploads pictures (Image or Decal) or sounds (Audio) from the repo, one file or a batch, from any branch, and prints each `rbxassetid`. The owner of the upload is the group in `ROBLOX_GROUP_ID`, else the user in `ROBLOX_OWNER_USER_ID`. Every run makes new assets, so upload once and commit the id. Audio counts against the owner's monthly allowance.
- `asset-permissions.yml`: `list` prints every `rbxassetid` the shipped code uses; `grant` gives the experience Use permission on each, so assets owned by a person keep working in a group-owned game. Run `grant` after new ids land.
- `repo-labels.yml`: creates the labels in `.github/labels.json` whenever that file changes on main.

The same pattern (a small script under `tools/opencloud/`, a manual workflow, the key from the secret, the narrowest permission) fits other jobs when the game needs them: reading analytics, creating game passes and developer products, or setting the store page text. Add each as its own pull request and add its permission to the key in Creator Hub. Remember that Actions logs on a public repo are public: never print a key, a player name or a user id.

After any upload, check the asset is owned by the game's owner (the group, when a group owns the game) and that it draws in the live game. A user-owned asset in a group-owned game fails silently.
