# Playbook: ads basics

This covers Roblox sponsored tiles on Home and Search (Ads Manager), not in-game billboard or video ads. The owner runs the ads. Growth reads Ads Manager view only and never touches budgets, bids or campaign toggles.

## What ads are for
In a new game, ads buy test players for the funnels. They rarely pay for themselves, and Roblox does not count ad-acquired players toward Home ranking. Ads can help a game get considered for Home; whether Home then keeps showing it depends on how Home's own players behave. So fix the first minute before raising a budget. More ads on a game that does not hold players buys nothing lasting.

## How the auction works
1. **You set a daily budget.** Roblox sets the bid from the budget and the campaign length.
2. **Every ad slot is an auction.** Score = bid times predicted play rate (how often people tap and then join). The highest score wins the slot.
3. **Impressions and clicks cost nothing.**
4. **A play is charged:** the player joins within an hour of the tap.
5. **Second price:** you pay just enough to beat the next ad, not your full bid.

Example with made-up numbers: an ad bidding 5 cents with a 4% play rate scores 0.20 and beats an ad bidding 8 cents with a 2% play rate (0.16).

What follows from this:
- **Tap rate is the lever.** A better picture wins more slots and pays less per play.
- **Cost per play = spend divided by plays.** It is a scorecard, not a setting.
- **Click to play matters as much as the click.** A picture that gets taps from people who never join (a slow load, a store page that does not match) scores badly.

## Targeting and objectives
- Targeting: location, age, gender, genre and device.
- Audiences: all players, new players, recent players and lapsed players (the last two need a large existing player base).
- **Plays** objective: the cheapest way to get players in. **Engagement** objective: reaches proven engaged players, costs more per play and often brings players who stay longer. Compare them on minutes per ad player, not on cost alone.
- Age rules and the path to younger audiences change. Read the current Ads Manager and Kids and Select pages before planning around an age group.

## Reading an ad table
For each ad and each campaign: spend, tap rate (CTR), plays, cost per play, click to play share and minutes per play.
- Judge an ad only after it has enough plays. Thirty is a floor; under that it is a direction, not proof.
- The cheapest players often leave soonest. An ad that is cheap and brings two-minute players is worse than a dearer one whose players stay.
- Read by device. Ad mix changes the device mix, which changes every other number in the game.
- Ads Manager reporting lags a day or two.

Starting rules of thumb from a first game (replace with your own once you have data): a decent tap rate is above about 2.5%; cut an ad that stays under about 2% once it has enough impressions; keep at least 8 ads running while learning, so there is something to compare; cut an ad whose cost per play is far above the rest or whose players stay only a few minutes.

## Ad pictures
- One big subject filling most of the frame, cropped close. Ads are tiny on a phone.
- Three words at most, huge and high contrast. Check at about 150 px wide.
- Show a real action from the first minutes of the game. The no-clickbait rule applies to ads too: a tap that turns into a quit in the first minute is paid for twice.
- Show the most appealing thing a new player can really get early, not a late-game rarity.
- Never the word "free".
- Name each ad so the table reads itself: subject, hook, audience.

## Keeping tests clean
- Change one thing at a time: the audience or the pictures, not both.
- During a benchmark or a go or no-go week, keep the budget and audience steady. A change in who the ads reach looks exactly like a change in the game.
- Log the day every campaign starts, stops or changes beside the benchmark.

## What Growth does and does not do
- Does: read the tables when asked, recommend which ads to cut or copy, brief Model-Agent on new pictures.
- Does not: spend, change a budget, start or stop a campaign, or report on ads the owner did not ask about.
- Spend and results are money numbers. They stay in the private library.

## Sources
Roblox Creator Docs: the Ads Manager and Discovery pages (official). The auction steps above are a summary of how Ads Manager describes sponsored tiles; re-read the page before relying on a detail.
