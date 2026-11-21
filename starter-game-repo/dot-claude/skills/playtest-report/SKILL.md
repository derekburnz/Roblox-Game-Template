---
name: playtest-report
description: How playtests are run and written up: the feedback form fields, the automated Studio smoke test, summary format, ticket format and severity scale. Use after any feature lands, after any human playtest, and when turning raw feedback into tickets in docs/playtests/.
---

# Playtest report

## 1. Feedback form (a web form feeding a sheet, or a chat template)
Fields, in order. Keep it under 3 minutes to fill in.
1. Name or nickname (text)
2. Device (phone / tablet / PC / console)
3. How long did you play? (under 5 min / 5 to 15 / 15 to 30 / over 30)
4. Did you understand what to do in the first minute? (yes / mostly / no) plus what confused you (text)
5. What was the most fun moment? (text)
6. What was boring or annoying? (text)
7. Did anything break? Describe what you did right before. (text)
8. Fun score 1 to 5, and would you play again tomorrow? (yes / maybe / no)
9. One thing you would add (text)
10. Screenshot or clip link (optional)

The QA agent reads the export (CSV) and writes the report.

## 2. Automated smoke test (Studio tools, run before every human playtest)
Write the steps from the design's core loop. The shape is always the same:
1. Start play, confirm no errors in the console output within 10 s.
2. Do the core action once (walk there, interact) and confirm the reward shows on the HUD with a screen capture.
3. Spend the reward (open the shop, buy the cheapest thing) and confirm it applies and the balance drops.
4. Do the second loop step (the thing the reward unlocks).
5. Stop play, start again and confirm progress persisted. A local Studio place may not save data at all; if so, mark this step "needs a published test server" rather than pass.
6. Abuse pass: spam the interact key 50 times, buy with a zero balance, act on something from across the map (teleport the test character). Anything the server accepted is a **blocker** and goes to luau-reviewer.
Record: pass or fail per step, console errors (full text), screenshot paths.

Rules for every Studio test:
- Use an unsaved dev copy built from main. Never the real place window, and never save the test place.
- Never join live servers to test. Live players are not test subjects, and a tester's actions pollute the stats.
- Studio cannot fake touch or a real gamepad. Check phone-only and gamepad paths with the device emulator, by reading the code, or by asking the owner to try on a real device.
- Never say a test passed until its result is in.

## 3. Report format (docs/playtests/YYYY-MM-DD.md)
```markdown
# Playtest YYYY-MM-DD: <build or branch>
Testers: N (devices). Session lengths: ... Fun score: avg x/5, "play again": y yes / z maybe / w no.
Automated smoke test: pass | fail (link to section)

## Summary (5 lines max)
What worked, what did not, the one thing to fix first.

## Bugs
## Balance
## Confusion
## Requests
(one ticket each, format below, ranked by impact on the core loop)

## Quotes
One sentence per tester that captures their experience.
```

## 4. Ticket format
```
### [SEV] Short title  (raised by N of M testers)
Owner: engineer | ui-designer | asset-artist | designer
Repro: 1. ... 2. ... 3. ...
Expected: ...
Actual: ...
Evidence: docs/playtests/evidence/YYYY-MM-DD-<n>.png, console line
Notes: hypothesis if you have one; never a fix.
```
Each ticket becomes a GitHub issue (the Task form) with its area label.

## 5. Severity scale
| Level | Meaning | Example |
|---|---|---|
| **blocker** | core loop cannot be completed, data loss, or an exploit works | progress resets on rejoin; an action works from 200 studs away |
| **major** | loop completes but a system is broken or clearly unfair | the shop charges but the upgrade never appears |
| **minor** | annoying, wrong, but playable | an NPC walks through a table |
| **cosmetic** | visual or copy only | a PH_ placeholder still visible (expected in a rough draft) |
Balance tickets use the same scale by effect on fun: "every tester quit at the second upgrade price" is major.

## 6. Counting rules
- A point raised by one tester is noted; by two or more it is a ticket; by half or more it goes to the top of its section.
- Separate "I did not understand X" (confusion, usually a UI or onboarding fix) from "X is boring" (balance or design).
- Quote testers, do not paraphrase into agreement with your own hypothesis.
- If the repo is public, never write a tester's username or user id in it.
