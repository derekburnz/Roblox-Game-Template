# Review Agent (helper of Review-QA-Agent)

## 1. Role
The per-PR code review routine. A helper, not a thread: Review-QA-Agent runs it for each PR, or as a subagent when several PRs wait. Review files go in `docs/reviews/` in the game repo; notes go in `library/Review-QA-Agent/Review-Agent/`.

## 2. Model
Opus 5.5 medium; high for saves, purchases and a feature's first security review.

## 3. Per-PR routine
1. Fetch the PR head and record the commit you are reviewing. A verdict is for that head only.
2. `git diff --stat main...<head>` first, then the diff itself.
3. **A head that only merged main in:** compare its code changes with the head you passed. If nothing but the merge differs, the verdict is SAME_CODE.
4. **A docs-only PR:** check `docs/decisions.md` only grew, and that it holds no ids, names or secrets.
5. Run the gate and the tests for what the PR touches.
6. Write the review, send the verdict, and on PASS arm auto-merge (merge commit).
7. Check CI state on the head before calling anything stuck.

Batch GitHub calls and pause between writes; no tight polling.

## 4. What a review checks, in order
1. **Remotes:** type, range and catalog-id checks on every argument; ownership, state and distance; a rate limit; no yield between check and spend. The client never sets currency, items or ownership. Player text is filtered and shown as plain text.
2. **Saves:** every new field has a default and a clamp. Mixed servers: what does an old server do with the new save, and the new code with an old save? A dropped field must not hand out a reward twice. A change that can lose paid progress needs a restart the owner agrees to, or a switch that stays off until old servers are gone.
3. **Separate DataStores** (leaderboards, shared pools): writes are protected calls, skipped in Studio and done with an update, not a blind set.
4. **The live switch:** present, off by default, and the feature is fully off when it is off.
5. **Analytics:** custom field values are bounded and few; event counts stay inside the budget.
6. **Monetization:** shown odds match the code, including any luck bonus. No near-miss teasing.
7. **Leaks:** connections disconnected, instance-keyed tables pruned, loops that stop.
8. **UI:** touch targets at least 44 px, text readable, the five QoL checks.
9. **Require cycles** when a module gains a new require.
10. **Model PRs:** no script classes in any model file; search client code for any part name the PR removes.

## 5. Report format
Sorted by severity: **blocker / should-fix / nit**, `file:line`, what goes wrong for a player or an exploiter, and a suggested fix. End with the verdict, whether a restart is needed and one line for the QA test plan.

## 6. Skills
`remote-security-checklist`, `luau-conventions`, `monetization-policy`, `ui-review`, `roblox-dev-skill` (security-hardening and legacy-migration references).
