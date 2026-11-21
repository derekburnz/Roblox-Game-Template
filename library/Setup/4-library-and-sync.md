# Library and sync

The library repo is this repo: the copy of the template the owner made for one game. It holds the setup, each thread's files and a word for word copy of project memory. It has one branch, `main`. Keep it private: it can hold money numbers and plans that do not belong in a public game repo.

Why it exists: a Claude project's shared folder and memory can be lost, and a thread's context resets. The library is what lets a new thread, or a whole new project, start where the last one stopped.

## Layout
- `library/<Thread>/`: each thread's context file `<Thread Name>.md` on top, then its deliverables (write-ups, sheets, previews, plans) in dated task folders named `<topic>-YYYY-MM-DD/`. Helper agents sit in subfolders.
- `library/Setup/`: this setup.
- `memory/`: `project-instructions.md` and `project-memory.md` (word for word copies), plus one file per memory topic.
- Shared folder: `<Thread>/` in the project's shared files mirrors `library/<Thread>/`. Sync-Agent copies both ways, newer file wins.

## Writing
1. `git pull --rebase origin main`.
2. Add or update files in your own folder.
3. Secret scan the change: `ghp_`, `gho_` or `github_pat_` followed by 30 or more characters, `sk-` followed by 20 or more, `AKIA` followed by 16, `BEGIN ... PRIVATE KEY`. Stop and tell the owner on a hit.
4. Commit with a clear message and `git push origin main`. If rejected, pull with rebase and push again. Never force-push: a forced snapshot once wiped hundreds of files from a library like this one.

Do not delete in normal work. Replace your own stale file in place rather than adding a new version beside it.

## When to sync
- A thread pushes its `<Thread Name>.md` before every reset.
- Whenever project memory or the instructions change (Sync-Agent, word for word).
- At about 95% of the weekly usage limit, so nothing is stranded while Claude is paused.
- When the owner asks, or a hand-off needs it.

No scheduled sync by default: each one costs usage.

## Sync routine (Sync-Agent)
1. Pull. Confirm the last known head is an ancestor of `origin/main`.
2. Copy newer-wins from the shared folder. Never let a `.md` shrink without reading why: a shared copy can be a short stub, so merge rather than overwrite.
3. Secret scan, commit, one push per sync.
4. Check the indexes: every memory topic file is linked from `project-memory.md`.

## Cleanup (on demand, with the owner's OK)
Delete only what is superseded, in one commit that says what went and why, and keep anything a hand-off note references. Git history keeps the rest.

## Size
Every thread with the repo attached clones it. Keep files under 95 MB, prefer compressed previews, and keep rendered video drafts out: store finals only, or a link to where they live.
