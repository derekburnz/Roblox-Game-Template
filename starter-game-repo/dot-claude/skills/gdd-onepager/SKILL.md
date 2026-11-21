---
name: gdd-onepager
description: Template and rules for a one-page game design document for a whole game or one feature: hook, core loop at three scales, session and progression loops, social, monetization, prototype scope with S/M/L, risks, open questions. Use whenever a design or feature spec is written or updated, and when the Planning agent turns a chosen idea into the first design.
---

# GDD one-pager

A GDD (game design document) is the spec the engineer, artist and QA build from. One page. If it needs more, split a feature out into `docs/design/<game-slug>/features/<feature>.md` using the same template. Write for the owner: plain language, numbers wherever possible and a reference game named for anything hard to describe.

Why one page: a spec nobody reads to the end gets built wrong. One page forces the choice of what the game is not.

## Template
```markdown
# <Game or feature name>  (date, author, status: draft | agreed | built)

**Hook (one sentence):** why a 10 year old tells a friend about it.

**Core loop**
- Every 30 seconds: ...
- Every session (10 to 15 min): ...
- Every week: ...

**First session:** what the first 10 minutes look like, step by step, for a brand new player. The first fun action lands inside the first 20 seconds.

**Progression:** what unlocks, in what order and roughly when (minute 5, session 3, week 2).

**Economy:** sources of currency, sinks for currency, the one number that controls pace.

**Reason to come back tomorrow:** what the player sees before leaving that makes them return.

**Social:** what players see of each other; what is deliberately not in (stealing, trading) and why.

**Monetization:** game passes, developer products; anything random; PolicyService needs. Reference monetization-policy.

**Prototype scope (vertical slice)**
| System | Smallest version | Size | Owner |
|---|---|---|---|

**Risks:** technical, content volume, policy, fun. One line each with a mitigation.

**Out of scope for now:** list, so nobody builds it by accident.

**Open questions for the owner:** numbered, each with a recommended answer.

**Proposed decision line:** `YYYY-MM-DD: <decision>. Why: <reason>.`
```

## Rules
- The core loop sentence must contain a verb the player does, a reward they get and what the reward buys.
- Every system in the scope table gets S (under a day of agent work), M (2 to 3 days) or L (a week or more). Anything L must have a smaller version listed beneath it.
- Name the one tuning number that controls pace (for example earnings per action against the price of the next upgrade) and give the engineer a starting value.
- Numbers go in `docs/design/<game-slug>/tuning.md` as a table with columns: key (matches the `Config` module once the game has one), value, why, last changed.
- The name, icon and first minute must promise the same thing. If the game is called "Catch X", a new player catches an X in the first 20 seconds. Roblox's Home recommendations punish a game whose first minute does not match what the tile promised.
- Flag these on sight: paid random items, trading, stealing from other players, PvP, user-generated text, anything that reads differently for players under 13.
- Reference games may be named for mechanics. Never copy their names, characters or art.
- If pace is too fast, raise the cost rather than cut a reward the player already expects.

## Vertical slice exit test
The slice is done when a new player completes one full loop in under 10 minutes, their data saves and there are no blocker bugs. Build that before any second system.
