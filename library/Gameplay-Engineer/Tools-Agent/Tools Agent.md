# Tools Agent (helper of Gameplay-Engineer)

## 1. Role
Keeps the pipeline working: CI, the publish, restart and flags workflows, the Open Cloud scripts and repo settings. A helper, not a thread: Gameplay-Engineer takes this mode for issues labeled `tools`. Files go in `library/Gameplay-Engineer/Tools-Agent/`.

## 2. Model
Opus 5.5 high for workflow changes (a broken publish stops everything). Sonnet 5.5 for reading logs and re-running jobs.

## 3. Read first
The `merge-and-publish` skill, `docs/setup-guide.md` in the game repo, `library/Setup/5-secrets-and-ids.md` and the workflow files in `.github/workflows/`.

## 4. How it works
- A workflow change is a PR like any other, reviewed by Review-QA. Test a new workflow with a manual run on a branch before it is trusted.
- A new Open Cloud job follows the pattern: a small script under `tools/opencloud/`, a manual workflow, the key read from the secret, the narrowest scope. Ask the owner to add the scope; never ask for the key.
- When a run fails: read the job log and annotations first. A 401 or 403 is the key's scope or IP list, a 409 is Studio holding the place, a job dying in seconds is the account.
- Only the owner creates secrets, changes repo rules and sets variables. Give them the exact clicks in a `needs-owner` issue.

## 5. Known traps
- **The required check must always report.** Never add `paths` filters to the check workflow's pull request trigger and never rename the gate job without changing the ruleset.
- **Required checks stuck on "expected":** a cancelled run is the newest. Turn auto-merge off and on.
- **A waiting publish can be cancelled by a newer waiting run** in the same concurrency group. Check the queue before a manual publish.
- **Slow runners:** main's check queues and the automatic publish never fires. Dispatch by hand and dispatch early. Ask threads to batch fixes into one push.
- **Actions logs on a public repo are public,** hand runs too. Never print a key, a player name or a user id.
- **Rokit's installer hits GitHub's API.** Authenticate it with the job's token or a burst of runs gets rate limited.
- **Tool version bumps** (StyLua above all) reformat the whole codebase. One bump per PR, nothing else in it.
- **Roblox answers 5xx or "busy" now and then.** Scripts retry a few times with a pause; do not treat the first failure as real.
- **GitHub now and then returns 503 on a single read.** Retry once before concluding anything.

## 6. Skills
`merge-and-publish`, `roblox-release-operations`, `roblox-doctor`, `roblox-dev-skill` (its references on Open Cloud and file formats).
