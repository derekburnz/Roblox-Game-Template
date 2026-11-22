---
name: remote-security-checklist
description: Server-side security rules for remotes and saved data: never trust the client, validate types, ranges and ownership, rate-limit, server cooldowns, distance checks, text filtering, DataStore session locking and retries. Use when writing or reviewing any RemoteEvent handler, purchase, world interaction or save code.
---

# Remote security checklist

Roblox runs one server per game instance and a client on every player's device. The client is the player's own computer, so an exploiter can run any code there: fire any RemoteEvent with any arguments, teleport, read everything in ReplicatedStorage. For someone from networking: treat every remote like an unauthenticated API endpoint on the public internet. The server is the only trusted party.

## The checklist (apply to every remote handler)
1. **Type check every argument** with a guard before using it. Luau types are compile-time only; a client can send a table where you expect a string.
2. **Range check** numbers (quantities 1 to 99, no NaN, no negative, no `math.huge`). Use `Guard.int(n, min, max)` (it returns nil for anything else).
3. **Id check** against `Catalog`: an unknown item id means drop the request, with no error reply.
4. **Ownership check**: the item, slot or order must belong to that player on the server's own record.
5. **State check**: can this action happen now (the order is pending, the pickup still exists, the slot is empty)?
6. **Distance check** for world interactions: the player's HumanoidRootPart within `Config.*.Range` studs of the target, computed on the server.
7. **Rate limit** every remote per player (`NetService.on(name, { perSecond = n }, handler)` does it); drop silently when exceeded; log repeat offenders with `warn`.
8. **Server cooldowns** for gameplay actions, stored on the server, never read from the client.
9. **Never let the client set** currency, inventory, ownership, upgrade level or the position of anything that matters. The client sends intents, the server computes outcomes.
10. **Reply with facts, not acknowledgements**: after a purchase the server sends the new profile snapshot; the client renders what it receives.
11. **Filter user text** (names a player types) with `TextService:FilterStringAsync` on the server before storing or showing it to anyone else. Show player text in a plain TextLabel, never RichText.
12. **Protect the save**: session locking, retries, no overwriting a profile that failed to load.
13. **No yield between check and spend.** Check the balance and deduct it in one step, or two racing requests both pass the check.

## Threat table (fill in one row per remote the game adds)
| Remote | What an exploiter tries | Server rule |
|---|---|---|
| `RequestBuy(itemId)` | buy with fake ids, negative prices, buy twice in one frame | id in Catalog; price read from Catalog on the server; `balance >= price` checked and deducted in one step on the server record; rate limit |
| `RequestCollect(pickupId)` | collect from across the map, collect the same pickup twice, spoof its kind | pickup exists in the server table; distance check; remove from the table before granting; kind from the server record |
| `RequestUse(slotId)` | use things that are not theirs, 100 times a second | slot owned by the player; server cooldown; rate limit |
| `RequestRename(text)` | profanity, personal info | filter with TextService; length 1 to 20; rate limit 1 per 10 s |
| Any | flood remotes to lag the server | global per-player limiter plus per-remote limiters; kick after N warnings only if clearly abusive |

## The starter's modules
The game repo ships these, so a new remote is a few lines. Read them before writing a handler.
- `src/shared/Guard.luau`: each check returns the cleaned value or nil. `Guard.id(v)`, `Guard.int(v, min, max)`, `Guard.number(v, min, max)` (finite only), `Guard.bool(v)`, `Guard.oneOf(v, list)`, `Guard.text(v, maxLength)`. A catalog check (the id exists, the player owns it) is the handler's own, after `Guard.id`.
- `src/server/Util/RateLimiter.luau`: a token bucket per key, `RateLimiter.new(maxCalls, windowSeconds)` then `limiter:allow(player)`.
- `src/server/Services/NetService.luau`: creates every remote listed in `src/shared/Remotes.luau` and is the only way client calls come in. `NetService.on(name, { perSecond = 2 }, handler)` drops calls over the limit before the handler runs, runs the handler in a pcall, and forgets each player's buckets when they leave.

```lua
NetService.on("RequestUse", { perSecond = 4 }, function(player: Player, rawSlot: unknown)
	local slotId = Guard.id(rawSlot)
	if slotId == nil then
		return
	end
	-- ownership, range and cooldown checks here, on the server
end)
```

## Data saving
DataStoreService is Roblox's key and value store, with request budgets and occasional failures. Rules:
- **Session locking**: a profile may be open on one server at a time. If a player hops servers while the old one still holds the lock, wait or steal only after a timeout. The starter ships ProfileStore (a proven save library, MIT) in `src/server/Vendor/` and `Services/DataService.luau` on top of it; it implements locking, retries and autosave. Never edit or reformat a vendored file. The save's shape and migrations are in `src/shared/SaveSchema.luau`.
- **Load before play**: if the load fails, do not give the player a default profile that will later overwrite their real one. Kick with a friendly message ("Could not load your save, please rejoin") instead.
- **Reconcile, never reset**: new fields get defaults; existing fields are never dropped on a schema change. Keep a `Version` field.
- **Mixed servers**: a publish does not restart servers, so old and new code run at the same time. Ask what an old server does with a save a new server wrote, and the other way round. A new saved id (a new item or prize) goes behind a live switch that stays off until old servers are gone, or an old server's save check may drop it.
- **A cap raised behind a switch** (a higher max level) must also be allowed by the save's load-time clamp, or a fresh server that has not read its switches yet cuts the player's level back down.
- **Save on leave and on shutdown**: `Players.PlayerRemoving` releases the profile; `game:BindToClose` waits for all saves (a save library handles both).
- **Autosave** every 30 to 60 s for long sessions.
- **Robux purchases** (`ProcessReceipt`) grant only after the profile is loaded and are idempotent on `PurchaseId`; return granted only after the save succeeds.
- **Studio**: DataStores need "Enable Studio Access to API Services" on the dev place, and the dev place must use a different DataStore name than the live place.

## Review questions (the luau-reviewer asks these)
- Which line proves the player owns the thing they are acting on?
- Where is the price read from? (It must be the server's Catalog.)
- What happens if this remote is fired 1000 times in a second?
- What does the player see if the save fails?
- Can two remotes racing each other (buy plus buy, collect plus collect) double-grant? (Deduct or remove before granting.)
- What does a server running last week's code do with this save?
