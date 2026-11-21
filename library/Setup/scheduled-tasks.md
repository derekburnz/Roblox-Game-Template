# Scheduled tasks

Scheduled tasks live in the Claude project and die when it is deleted, so they are written here. The thread named as owner creates each one. Give times in UTC in the task and in the owner's time zone when reporting. Every firing costs usage: create a task only when its job exists and delete it when the job is done.

## Recurring
| Name | When | Owner | Prompt |
|---|---|---|---|
| Coordinator idle check | every 20 minutes while any issue or PR is open | Coordinator | "Idle check. List every role thread. For each one that is idle while an issue or PR is open in its lane or unclaimed in any lane, send it back to work with the next issue. Collect parked questions for the owner into one short message with recommended picks. If no issue or PR is open, pause this task." |
| Daily stats read (optional, once the game has players) | once a day, a set hour | Growth-Agent | "Daily read. Read yesterday's funnels by device, playtime marks, new and returning players and D1 from Creator Hub analytics. Compare with the benchmark sheet. Save the read in your folder. Tell the owner only if something is clearly better or worse." |

## One-shot patterns (fill in the times when the event happens)
| Name | When | Owner | Prompt |
|---|---|---|---|
| Benchmark read, plus 24 hours | start + 24 h | Growth-Agent | "Benchmark +24 h read. The start minute is in `benchmark-sheet.md`. Read the onboarding funnel and playtime marks by device for players who joined after the start. Compare with the before numbers and the lines to beat. Save the read, add one line to the sheet, tell the owner in plain words." |
| Benchmark read, D1 | start + 2 days | Growth-Agent | "Benchmark D1 read: next day return for the first full day after the start, against the before number and the lines in the sheet. Also minutes per player and still playing at 5 minutes. Save, add a line to the sheet, tell the owner." |
| Benchmark read, three days | start + 3 days | Growth-Agent | "Benchmark +3 d read: the same funnels over three full days, to match the before window. Tell the owner only if something is clearly better or worse." |
| Benchmark read, D7 | start + 8 days | Growth-Agent | "Benchmark D7 read: week later return for the first cohorts, D1 for the week, minutes per player. Save, add a line to the sheet, tell the owner." |
| Go or no-go read | the decision day set in the sheet | Growth-Agent (switch to Opus 5.5) | "Go or no-go read. Use the thresholds written in the benchmark sheet before the test began; do not move them. Send the owner the verdict in plain words with one simple chart, and save it to memory." |
| Switch read | one full day after a switch went on | Growth-Agent | "Before and after read for switch [name], on at [UTC minute]. Read the funnel step it touches, by device, for the day before against the day after. Say how many players and whether that is too few to trust. Send the result to Design-Agent." |

## Rules
- A task that names an event which was cancelled is deleted, not left to fire.
- When a project is remade, recreate only tasks that have not fired, and do by hand any missed one that still matters.
