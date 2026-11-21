# Working rules for every thread

The studio rules in the game repo's `CLAUDE.md` come first; they load in every thread. These are the habits on top. Each has its reason, so you can use judgment in a case the rule does not cover.

## Top rules
1. **No new threads unless the owner says so in their own words.** Every thread costs usage.
2. **Never stop.** No thread idles while any issue or PR is open. When stuck on anything (the owner, Studio, the PC, a build, a review), park it with the coordinator in one line and take a different open, unclaimed issue or PR, in any lane. Never wait for the owner and never end a turn while open work remains. When the owner is asleep or away the same holds: make assumptions, go with the recommended option and record it.
3. **Publish silently, never restart.** Merge and publish each fix as soon as it is done. Changes reaching only new servers is fine. A restart happens only when the owner says so.
4. **Switches on right away.** A live switch goes on the same hour its PR publishes. Off switches stay for rollback.
5. **Auto-merge.** Every PR is armed once Review-QA passes its exact head. Skip PRs labeled `on-hold`.
6. **Tutorial changes ship behind an off switch.** Players tap every tutorial step themselves (dim plus arrow) and no menu opens by itself.

What still waits for the owner even under rule 2: spending money, anything on their accounts beyond a job they handed over, anything that cannot be undone, restarts and new threads.

## Working with the owner
- **Answer first.** Reply with results, blockers or questions, in plain short words. Anything longer than about fifteen lines goes in a file in your folder, linked by its path.
- **Questions go to the coordinator,** one short line each with a recommended pick. Keep working on the recommended option while waiting.
- **Queue rule.** A new ask from the coordinator goes to the bottom of your queue unless it says urgent.
- **Ask once** before anything that cannot be undone: deleting files, changing live settings, a message outside the project.
- **Explain Roblox concepts** the first time they come up.

## Threads
- **Fresh context.** When your task is done or your context is large, update `library/<Thread>/<Thread Name>.md` (open work, decisions, tools and processes, traps, hand-offs), push it, then reset or restart from it. Write lasting rules, not a diary: a starting file that grows a dated section every day stops being read.
- **Models.** Use the model and effort for your thread in `2-threads-and-models.md`.
- **Studio.** Only Sync-Agent drives Studio on the owner's PC. Send it the exact steps and get results back.

## Code and pull requests
- **Issues first.** Work comes from GitHub issues. Before taking one: check it has no `claim` label, search open PRs for its number (an unclaimed issue can still have an armed PR), then add `claim` and comment who took it.
- **One feature per branch and PR,** with a test plan in the description. Start from the latest main and merge main in again before the final checks. Never force-push; merge main in to fix conflicts.
- **Open a claim issue** (the Claim work form) for work that needs more than one PR or touches shared files: the design document, the save service and shared modules in `src/shared/` once the game creates them (for example a `Config` or `Remotes` module). Close it when its last PR merges.
- **The gate.** Run `games/<game-slug>/check.sh` where you can (rojo sourcemap, luau-lsp, selene, stylua). CI runs it on every PR and CI is the judge.
- **Review.** Review-QA-Agent checks every PR at its exact head. No thread signs off its own work. A push after a pass needs the reviewer again (a push that only merges main in is "same code").
- **Merge.** After a pass, GitHub auto-merge is turned on with a merge commit. Report the merge in one line.
- **Ship behind a switch.** New features go behind a `LiveFlags` switch, off by default (the `merge-and-publish` skill, section 3).
- **Saves.** A PR that changes the save shape says so in its first line. Publishes do not restart servers, so old and new code run side by side: say what an old server does with the new save.
- **Only Gameplay-Engineer** dispatches publish, restart and upload workflows.

## Files
- **Deliverables are files** in your shared folder (`<Thread-Name>/`), synced to `library/<Thread-Name>/` in the library repo: write-ups, sheets, previews, plans, decisions. Update the file rather than making a new one.
- **Artifacts are allowed, never on their own.** An artifact can present the work; its content also goes in your folder as a file, and the file path is linked beside it. Why: an artifact lives in one chat, and the next thread cannot read it.
- **Write only in your own library folder.** Read the others freely. Do not delete in normal work.
- **Attachments.** Keep only the ones you are using and move the rest into your folder.
- **No copies of repo files.** Link to the repo instead.
- **Big files.** GitHub refuses files over 100 MB; keep renders and clips under 95 MB, and keep superseded video drafts out of the library.

## Memory
- **Save as you learn.** Save lasting facts to project memory in the turn you learn them: one file per subject, plus a line in `MEMORY.md`.
- **Skip what the repo already records,** such as code structure or merged changes.
- **Never save secrets.**
- **Memory and instructions live in the library too.** Whenever project memory or the project instructions change, Sync-Agent copies both word for word into the library's `memory/` folder. Why: a project can be lost or remade, and the library is how the next one starts where this one stopped.

## Safety and content
- **Secrets** (keys, tokens, passwords) stay in environment variables or GitHub secrets. Never in files, memory, chat or the repo. Claude never types a password or a login code.
- **A public game repo holds nothing private:** no player names or ids, no sales or ad numbers, no unreleased content names.
- **Young audience by default, original IP only.** Paid random items follow the `monetization-policy` skill every time.
- **Creator Store assets** are scanned for scripts before use.
- **Uploads have the same owner as the game.** If a group owns the game, upload under the group and check the asset loads in the live game.

## Known traps (general ones; each agent file has its own list)
- **Luau's 200 local limit.** A function, and a file's top level, may hold at most 200 local variables. A big module of `local X = require(...)` lines stops compiling ("Out of local registers") while the type checker still passes. Group requires in a table or require inside functions.
- **StyLua and vendored files.** Run StyLua from the game folder with `--respect-ignores`. Run from the repo root, or with explicit paths and no flag, it reformats vendored libraries. Any vendored file in an unrelated diff is a review failure.
- **Stuck required checks.** A green PR shown as "blocked" with required checks "expected" has a cancelled run as its newest. Turn auto-merge off and on.
- **Queued CI.** When runners are slow, main's check sits queued and the automatic publish never fires. Dispatch publish by hand rather than waiting, and do not cancel other threads' runs.
- **One-branch threads.** A thread limited to one branch must check its PR has merged before resetting that branch to main. A force push rewrites the open PR's head and armed auto-merge can merge the wrong change.
- **Stacked PRs.** GitHub does not retarget a PR whose base branch merged unless that branch is deleted. Retarget to main by hand.
- **Two switch PRs at once.** Both edit the same lists. Arm one, merge main into the other, then arm it.
- **Cleanup PRs break things quietly.** A PR that removes code, a switch, a remote or a save field passes only with: a search showing nothing still reads it, old saves still loading, and a Studio playtest on a fresh save and an old one.
- **Analytics custom events.** Roblox sends only a few custom fields per event, so a fourth is dropped silently. Count fields in review. Keep event names stable, and when a funnel's steps change, give it a new name (`onboarding_v2`) so old and new data never mix.
- **Never save the QA place and never join live servers for tests.**
- **Shared-folder writes can be lost** when several threads write at once. Re-check a few seconds after appending to a shared file.
