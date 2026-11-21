# Playbook: funnels with analytics events

A funnel is an ordered list of steps a new player should pass. It shows where they stop. Set it up before launch: a game with no funnel can only guess why players leave.

Roblox concept: `AnalyticsService` lets the server log funnel steps and custom events. Creator Hub draws them under Analytics > Funnels and the custom events pages, about a day late.

## The two funnels every game needs

### 1. The onboarding funnel (overall)
Only must-do steps, in order, about ten of them. Optional things do not belong: a step most players may skip shows a false drop.

| # | Step name | When it is logged |
|---|---|---|
| 1 | joined | the player's first join |
| 2 | loaded | the client finished loading and can move |
| 3 | first_move | the first input |
| 4 | first_action | the first use of the core mechanic |
| 5 | first_reward | the first payout from it |
| 6 | actions_3 | the third success |
| 7 | upgrade_ready | the first upgrade can be afforded |
| 8 | upgrade_1 | the first upgrade bought |
| 9 | area_2 | arrived in the second place |
| 10 | upgrade_2 | the second big milestone |

Rename the steps to the game's own words. Keep names short, lower case with underscores.

### 2. The playtime funnel
Time marks for every player who joins: moved, 30 s, 1, 2, 3, 4, 5, 10, 15 and 30 minutes, 1 hour. It answers "how long do they stay" without waiting for retention numbers. The 30 second and 1 to 3 minute marks line up with the Home recommendation signals.

## A detail funnel for the first five minutes
When the overall funnel shows a big drop, add a detail funnel of about twenty steps for that stretch: every prompt shown, every first tap, each arrival. A funnel must be one ordered line, so optional things go in side events instead.

## Side events (custom events)
- **Time to milestone:** one event per milestone with the seconds since load as its value, so averages can be read per step.
- **Misses and stalls:** a failed attempt, a hint shown and whether the player moved on within 10 seconds.
- **Windows opened** in the first minutes. By plan there should be few; each one is a bug or the player's own tap.
- **Skips:** which scenes players skip and after how many seconds.
- **Left at:** on leave, the last step reached, for players who quit in the first session.

## Rules
- **Log on the server.** The client can lie and can leave before sending.
- **Each step once per save,** and decide whether a later step fills in a missed earlier one. Either is fine; know which you chose.
- **Custom fields are few.** Only a small number of custom fields are sent per event and an extra one is dropped without an error. Use them for the cohort or test group and for one detail. The device comes from Roblox's own platform filter.
- **A changed funnel gets a new name** (`onboarding_v2`). Old data stays under the old name and is never compared across the change.
- **One group at a time.** If an A/B test splits players, put the arm in a custom field so both arms log the same funnel.
- **Keep an event budget.** Roblox limits how many analytics events a server sends per minute. Do not log per frame or per small action.
- **Tell Growth the minute** every switch, publish and restart happens. Reads split on those minutes.
- **Leave broken hours out.** If a build was broken for an hour, drop that hour from both sides of a comparison and say so.

## Reading a funnel
- Read by device. A step that is fine on a computer can lose a third of phone players.
- The biggest single drop is the first fix.
- Give the count behind each percentage.
- A drop between "loaded" and "first move" is load time or a confusing first screen, not the gameplay.
- A drop right after a scene or a pop-up is that scene or pop-up.
- Check the funnel still matches the game after any change to the start. A removed step leaves a hole that looks like a cliff.

## Handing a funnel to the engineer
Write a table: step number, step name, exactly when it fires, whether it is logged today. Add the side events with their fields. Open one issue for Gameplay-Engineer and ask for the funnel name to be new if any step changed.
