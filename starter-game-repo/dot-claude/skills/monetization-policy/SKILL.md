---
name: monetization-policy
description: Roblox monetization rules the game must follow: paid random items odds disclosure, PolicyService checks per player, game passes vs developer products, no dark patterns for a young audience, and a table for recording the game's own calls. Use when designing, building or reviewing anything that costs Robux or looks like gambling.
---

# Monetization policy

The rules below come from Roblox's paid random items guidelines and monetization docs. Roblox changes them, so verify against the live pages before launch and before any new paid feature: https://create.roblox.com/docs/production/monetization/paid-random-items and https://create.roblox.com/docs/production/monetization. The `roblox-policy-compliance` skill has the wider policy checklist.

Why this skill exists: most Roblox players are young. A policy miss can get the game moderated, and a pressure tactic that works on a child is one the owner does not want in their game.

## 1. What Roblox sells and how the game gets paid
- **Game pass**: a one-time purchase that sticks to the player forever (double earnings, an extra slot). Easiest, with no gambling questions.
- **Developer product**: a repeatable purchase (a currency pack, a timed boost). Granted in `MarketplaceService.ProcessReceipt`; the grant must be idempotent and saved before returning `PurchaseGranted`.
- **Private servers**: optional, fine for friends.
- Roblox takes its marketplace cut, and what is left converts to real money through Developer Exchange (DevEx) only above a minimum balance. Read the current rate and minimum on the DevEx page; do not quote them from memory. Retention and session length matter more than the shop in a new game.

## 2. Paid random items (anything random bought with Robux, directly or through a currency that Robux can buy)
Random here means eggs, spins, chests, gacha, re-roll tokens, random lures, mystery boxes.
1. Show every possible outcome's odds as percentages that sum to 100%, **before** purchase, in the purchase UI itself.
2. Luck boosts, pity systems and rate-ups must state their numeric effect before purchase, and the displayed odds must update while they are active. Shown odds must match the code.
3. Call `PolicyService:GetPolicyInfoForPlayerAsync(player)` on the server when the player joins; cache it; respect `ArePaidRandomItemsRestricted` (hide or replace the random feature for that player) and `IsPaidItemTradingAllowed` (no trading of paid items where false).
4. Offer a free, earnable route to the same random items where possible.
5. If a currency can be bought with Robux **and** that currency buys something random, the random thing counts as a paid random item. Either keep the currency unbuyable, or show odds on every random purchase. The safe default for a new game: **currency is not buyable**; Robux buys passes and fixed-content packs only.

## 3. No dark patterns (young audience)
No fake countdown timers, no "only 2 left", no "your friend just bought", no spending streaks, no nagging popups after a decline, no pay-to-win walls that stop the core loop, no confusing currency stacks, no near-miss teasing on a roll. Prices are shown in Robux before any confirm. A decline is respected for the session. Discounts are real: a struck-through price was really the price.

Never reward likes, favourites or follows, and never promise a prize at a future like count. A thank-you code for a mark already reached, open to everyone, is the most that is safe.

## 4. PolicyService snippet (src/server/Services/PolicyService.luau)
```lua
--!strict
-- PolicyService wrapper: fetch once per player, cache, default to the most restrictive values on failure.
local Players = game:GetService("Players")
local RobloxPolicy = game:GetService("PolicyService")

export type Policy = { paidRandomRestricted: boolean, paidTradingAllowed: boolean }

local cache: { [Player]: Policy } = {}
local PolicyService = {}

local function fetch(player: Player): Policy
	local ok, info = pcall(RobloxPolicy.GetPolicyInfoForPlayerAsync, RobloxPolicy, player)
	if not ok then
		warn(`PolicyService failed for {player.Name}; using restrictive defaults`)
		return { paidRandomRestricted = true, paidTradingAllowed = false }
	end
	return {
		paidRandomRestricted = info.ArePaidRandomItemsRestricted == true,
		paidTradingAllowed = info.IsPaidItemTradingAllowed == true,
	}
end

function PolicyService.Get(player: Player): Policy
	local policy = cache[player]
	if not policy then
		policy = fetch(player)
		cache[player] = policy
	end
	return policy
end

function PolicyService.Start()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(PolicyService.Get, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		cache[player] = nil
	end)
end

return PolicyService
```

## 5. The game's own monetization calls
Record each idea here (or in `docs/growth/monetization.md`) when it is decided, so reviewers have one table to check against. The rows below show the usual verdicts for a new game; replace them with the game's real items.

| Idea | Type | Policy | Usual verdict |
|---|---|---|---|
| Double earnings | game pass | none | yes, launch |
| Extra slot or room | game pass | none | yes, launch |
| Cosmetic pack with fixed contents | game pass or dev product | none | yes |
| Buy soft currency with Robux | dev product | turns anything random that currency buys into a paid random item | no at launch |
| Paid item with better random odds | dev product plus random outcome | odds UI, PolicyService, rate-up disclosure | not at launch; if ever, follow section 2 |
| Egg hatch or spin wheel | random | full odds UI | only if free-currency only |
| Trading | social | `IsPaidItemTradingAllowed`, scams | no at launch |

## 6. Review checklist
- Does any Robux path end in a random outcome? Then: odds visible before purchase, sum to 100, PolicyService checked, hidden where restricted.
- Is every price read from the server's Catalog and shown before confirm?
- Is `ProcessReceipt` idempotent and saved before it returns granted?
- Any copy that pressures? Remove it.
- Does store text say exactly what the item gives (numbers, durations, contents)?
