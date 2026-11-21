# Playbook: the benchmark sheet (template)

A benchmark is a clean before and after: one start minute, a set of before numbers, lines to beat written in advance and a schedule of reads. Copy this file to `library/Growth-Agent/benchmark-sheet.md` and fill it in. Every blank is `____`.

Why: when dozens of changes land in the same days, no single number can be credited to any of them. A benchmark draws one line and reads both sides of it.

## Benchmark start
- **Start minute (UTC and owner's time):** ____
- **What defines it:** the last publish or switch before the owner said the game is ready. If anything changes after, the start moves to that change's minute.
- **Build:** place version ____. Every server on it since ____ (a full restart, if the owner ordered one, or the time the last old server closed).
- **Switches on at the start:** ____
- **Switches off on purpose:** ____
- **Hours to leave out of both sides** (a broken build, an outage): ____

## What we measure, and the lines to beat
Write the "keep going" and "stop" columns before the first read and do not move them.

| Measure | Before | Keep going | Stop | Typical game |
|---|---|---|---|---|
| Come back next day (D1) | ____ | ____ | ____ | ____ |
| Come back a week later (D7) | ____ | ____ | ____ | ____ |
| Minutes per player per day | ____ | ____ | ____ | ____ |
| Still playing at 5 minutes | ____ | ____ | ____ | ____ |
| Home: press play when shown | ____ | ____ | | ____ |
| Home: quit in the first minute | ____ | ____ | | ____ |
| Home: quit between 1 and 3 minutes | ____ | ____ | | ____ |

**Where the "Typical game" column comes from.** Roblox publishes a benchmark beside each of these numbers in Creator Hub: the median for your genre and for experiences with similar players (Analytics pages, and Acquisition > Home recommendations for the three Home rows). They are shown to signed-in creators, differ by genre and move over time, so the column is blank here on purpose. Fill it from your own Creator Hub on the day you start, and write the genre and the date beside it: genre ____, read on ____.

## Before numbers
The last clean stretch before the start: at least three full days, ____ to ____ (UTC).

### Milestones, share of players who joined
| Step | All | Phone | Tablet | Computer | Console |
|---|---|---|---|---|---|
| Joined (count) | ____ | ____ | ____ | ____ | ____ |
| Loaded | ____ | ____ | ____ | ____ | ____ |
| First move | ____ | ____ | ____ | ____ | ____ |
| (each onboarding funnel step) | ____ | ____ | ____ | ____ | ____ |

### Still playing after
| Time | All | Phone | Tablet | Computer | Console |
|---|---|---|---|---|---|
| 30 s | ____ | ____ | ____ | ____ | ____ |
| 1 min | ____ | ____ | ____ | ____ | ____ |
| 2 min | ____ | ____ | ____ | ____ | ____ |
| 3 min | ____ | ____ | ____ | ____ | ____ |
| 5 min | ____ | ____ | ____ | ____ | ____ |
| 10 min | ____ | ____ | ____ | ____ | ____ |
| 30 min | ____ | ____ | ____ | ____ | ____ |

## What is not comparable
List anything that makes a number jump for a reason that is not the thing being tested: a step that was removed, a cost that was cut by design, a change in the ad mix. Judge on the steps that mean the same thing on both sides.

## Reads after the start
1. Start + 24 hours: the funnels by device and the playtime marks.
2. Start + 2 days: the first D1.
3. Start + 3 days: three full days, to match the before window.
4. Start + 8 days: the first D7.
5. The decision read: date ____ (see `go-no-go.md`).

Each read adds one line here: date, the headline numbers, what changed.

## To keep it clean
- After the start, every switch change, publish and restart gets its minute logged here.
- No A/B splits during the benchmark unless the owner asks.
- A change that lands after the start is named in every read it could touch.
- Servers started before a publish keep the old build until they close. Treat the first hours after the start as a mix and read from the first full day.

## Standing goals
Goals the owner set that outlive one benchmark (for example both Home quit numbers under a target). Track them here, not in open issues.

| Goal | Set on | Now | Target |
|---|---|---|---|
| ____ | ____ | ____ | ____ |

## Log
| UTC minute | What changed (switch, publish, restart) | Who |
|---|---|---|
| ____ | ____ | ____ |
