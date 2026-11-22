# Setup guide

One-time setup for the owner's PC, GitHub and Roblox. Steps 1 to 6 get a PC ready to build and test. Steps 7 to 10 let GitHub publish the game. Each step says why it exists. Ask Claude to walk you through any step; it explains Roblox terms the first time they come up.

## 1. Accounts
- A **GitHub** account that owns this repo.
- A **Roblox** account with Roblox Studio installed on a Windows or Mac PC.
- Optional but recommended: a **Roblox group** that owns the game. Why: a group lets you add collaborators with roles, and the game is not tied to one personal account. Decide this before uploading art, because uploads must have the same owner as the game (CLAUDE.md rule 18). Moving a game to a group later means re-uploading or sharing every asset.

## 2. Git and the repo
Install Git (on Windows it brings Git Bash, which the scripts need). Clone this repo into a folder you will remember, for example `Documents\<game-slug>`. Tell the Claude coordinator the PC's name and this folder: the Sync agent uses them for Remote Control.

## 3. Rokit (the toolchain manager)
Rokit installs the exact tool versions pinned in `rokit.toml`, so your PC and CI agree.
1. Install Rokit from https://github.com/rojo-rbx/rokit (the README has a one-line installer).
2. In the repo root run `rokit install`.
3. Check: `rojo --version`, `stylua --version`, `selene --version` and `luau-lsp --version` each print a version.

## 4. Roblox Studio and the dev place
1. In Creator Hub (create.roblox.com) create the experience. Note its **universe id** and its start **place id**. Both are in the page URL. They are not secret.
2. Keep a separate dev copy of the place for agents and tests. Why: agents never work in the published place (CLAUDE.md rule 1).
3. In the dev place turn on Game Settings > Security > "Enable Studio Access to API Services" if you want saves and switches to work in Studio. Studio uses its own store names, so tests never touch live data.

## 5. Rojo (files to Studio)
Rojo copies the files under `games/<game-slug>/src` into Studio's tree as you save them.
1. `rojo plugin install` adds the Rojo plugin to Studio.
2. In `games/<game-slug>` run `rojo serve`, then press Connect in the Studio plugin.
3. To make a local place file instead: `rojo build default.project.json -o dev.rbxl` and open it. Never save over the published place from a local build.

## 6. The check gate
In `games/<game-slug>` run `./check.ps1` (PowerShell) or `./check.sh` (Git Bash). All four checks must pass before a pull request. The first run downloads the Roblox API types.

The unit tests, a strict type check and the UI gate (every window at phone, tablet and desktop sizes) need only Node 20 or newer, no Studio: in `games/<game-slug>/tools/cloudcheck` run `npm ci` once, then `npm run check`. CI runs the same on every pull request. See `tools/cloudcheck/README.md`.

## 7. Studio and Blender connectors (optional)
The agents can drive Studio (playtests, screenshots, console output) and Blender through MCP connectors. A connector is a small local program that lets Claude call a tool on your PC. Set them up when the first task needs them. The `roblox-doctor` skill checks the whole setup in one go and says what is missing.

## 8. The Open Cloud key (lets GitHub publish)
Open Cloud is Roblox's web API. A key is a password for it, so it is created by the owner, pasted once into GitHub and never shown to Claude, written in a file or sent in chat.

1. Creator Hub > **Open Cloud** > **API Keys** > **Create API Key**. If a group owns the game, create the key under the group.
2. Name it, for example "GitHub publish".
3. **Access Permissions**: add each API system below, select this experience, and tick only the operations listed.

| API system | Operations | What it allows |
|---|---|---|
| universe-places | Write | Upload and publish the place (`publish` workflow) |
| universe | `universe:write` | Restart servers for updates (`restart-servers` workflow) |
| universe-datastores | `objects:read`, `objects:create`, `objects:update`, `objects:delete` | Read and flip the live switches (`flags` workflow) |

Add more only when a workflow needs them:

| API system | Operations | Workflow |
|---|---|---|
| universe-messaging-service | `universe-messaging-service:publish` | the in-game countdown before a restart (`restart-servers`, and `publish` when it restarts) |
| assets | `asset:read`, `asset:write` | `upload-asset` (pictures and sounds) |
| asset-permissions | `asset-permissions:write` | `asset-permissions` (share the game's pictures and sounds with the experience) |
| universe.analytics | `universe.analytics:read` | reading analytics | Why so narrow: if a key leaks, it can do only what it was given.

4. **Accepted IP addresses**: `0.0.0.0/0`. Why: GitHub's runners have no fixed address.
5. Set an expiry date if you like, then **Save and Generate Key** and copy it.
6. GitHub > this repo > **Settings** > **Secrets and variables** > **Actions**:
   - **Secrets** tab, New repository secret: `ROBLOX_PUBLISH_KEY` = the key.
   - Optional second secret `ROBLOX_GROUP_KEY`: a key created under the group with only `asset:read`, `asset:write` and `asset-permissions:write`, for group-owned uploads. Keep it separate so the publish key cannot upload and the upload key cannot publish.
   - **Variables** tab: `ROBLOX_UNIVERSE_ID` and `ROBLOX_PLACE_ID` (the ids from step 4).
   - **Variables** tab, for uploads: `ROBLOX_GROUP_ID` when a group owns the game (uploads are then owned by the group, and `ROBLOX_GROUP_KEY` must be a key created under the group), otherwise `ROBLOX_OWNER_USER_ID`, the owner's Roblox user id. An upload owned by a person does not load in a group-owned game until `asset-permissions` shares it.
   - **Variables** tab: `AUTO_PUBLISH` = `true` once you want every merge to main to publish itself. Leave `AUTO_RESTART` unset: set to `true` it restarts servers after every automatic publish, which disconnects players.
7. Try it: Actions > **publish** > Run workflow with `Saved`. A green run adds a version to the place history without going live.

A 401 or 403 in a workflow means the key lacks a permission or its IP list blocks GitHub. Fix the key in Creator Hub; never paste a key into a workflow file.

## 9. Required check and auto-merge
1. Settings > General > Pull Requests: tick **Allow auto-merge**.
2. Settings > Rules > Rulesets > New branch ruleset for `main`: require a pull request, and require the two status checks named exactly `Rojo sourcemap, luau-lsp, Selene, StyLua` and `Unit tests, strict types, UI gate`. Why: auto-merge waits for required checks, so with none it would merge at once, before the gate ran.
3. Do not require branches to be up to date unless merges are rare: with many pull requests a day each one would re-run forever.

## 10. Labels and forms
The labels in `.github/labels.json` are created by the `repo-labels` workflow: it runs by itself whenever that file changes on main, or from Actions > **repo-labels** > Run workflow. The Task and Claim work forms in `.github/ISSUE_TEMPLATE/` appear under Issues > New issue.

## Troubleshooting
- **Studio says "Failed to fetch place info":** log out of Studio, close every Studio window and sign in again.
- **A publish fails with HTTP 409:** Studio has the place open in Team Create and holds it. Close that Studio session and run publish again.
- **Every Actions job fails in seconds:** check the account's billing status and the run's annotations. After the fix, update each pull request's branch to get fresh runs.
- **A new picture draws blank in game:** it is still in moderation, or it is owned by a user while the game is group owned.
