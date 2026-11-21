# Playbook: reading A/B tests

An A/B test gives two groups of players two versions and compares them. It is the only way to credit a result to one change. It is also easy to fool yourself with.

## Setting one up
- **One question, one number.** Write down the step or rate the test should move before it starts.
- **Split new players only,** and keep each player in their group for good. A returning player who flips groups pollutes both.
- **Put the arm in a custom field** of the funnel events, so both arms log the same funnel and can be read side by side. Two arms writing two different funnels is a tracking mess.
- **A switch controls it.** Off means nobody new joins the test.
- **A holdout** is a test too: a small share of new players who do not get a new feature, so its long-run effect (next day, next week) can be read.
- Roblox also has built-in experiments in Creator Hub. A config key must exist before an experiment can use it, and a published base value reaches every player, so use a neutral base and let only the arms change behaviour.

## How many players
Small groups lie. With about 30 players an arm, a gap that looks large shows up by chance about one time in six. As a working rule do not read arm against arm until each arm has several hundred players at the step being judged, and more for a small expected difference. Say the counts every time.

## Reading one
| Reached | Arm A (count) | Arm B (count) |
|---|---|---|
| Step 1 | ____ (____%) | ____ (____%) |
| Step 2 | ____ (____%) | ____ (____%) |
| The target step | ____ (____%) | ____ (____%) |

- Compare the same days for both arms.
- Read by device if the arms are large enough.
- A test of a day-one or day-seven effect needs those days to pass. Do not call it on first-session numbers.
- If the arms are level, say so. "No proven winner" is a result.
- A lean in a small test is one small reason, not a decision.

## Ending one
- End a test that cannot reach a readable size in a reasonable time. It only splits your tracking.
- When a test ends, switch it off, pick the default on purpose and retire its label, so every new player is in one group and one funnel again.
- Write the result in a file even when it is "too few to call", so nobody runs it again without knowing.

## What players skip
A read that pairs well with tests: for each scene, tip and prompt, how many players got it and how many skipped it, by device. In practice, a scene that takes the camera away is skipped by a large share of players and steps without a skip button show their loss in the funnel instead. Cut or shrink what most players skip.

## Traps
- **Many changes at once.** If dozens of switches go on inside two days, no single one can be credited. Their combined result is just "before" for the next test.
- **A changed funnel mid-test** makes the arms incomparable.
- **Ad changes during a test** change who the players are.
- **Counting on the day's partial data.** Today is still filling in.
- **The owner may end all tests** to simplify tracking. No new splits unless they ask.
