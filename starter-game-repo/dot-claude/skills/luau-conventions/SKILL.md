---
name: luau-conventions
description: How the game's Luau is written and laid out: strict mode, naming, server/client/shared folders, one Service or Controller per ModuleScript, the typed Remotes module, UI-in-code helper and comment style. Use before writing or reviewing any Luau in games/<game-slug>/src.
---

# Luau conventions

Luau is Roblox's typed Lua dialect. Files end in `.luau`. Rojo (`games/<game-slug>/default.project.json`) maps folders on disk to the Roblox instance tree, so a file's location decides where and how it runs.

## 1. File types and where they go
| Disk | Becomes | Runs on |
|---|---|---|
| `src/server/Main.server.luau` | Script in `ServerScriptService.Server` | server only |
| `src/server/Services/*.luau` | ModuleScripts | server (required by Main) |
| `src/client/Main.client.luau` | LocalScript in `StarterPlayerScripts.Client` | each player's device |
| `src/client/Controllers/*.luau`, `src/client/UI/*.luau` | ModuleScripts | client |
| `src/shared/*.luau` | ModuleScripts in `ReplicatedStorage.Shared` | both (never trust the client here) |

One system per ModuleScript. A **Service** (server) or **Controller** (client) is a table with `Init()` and `Start()`. `Init` wires dependencies and creates state; `Start` connects events and begins loops. Main calls every `Init` before any `Start`, so services can find each other in `Init` without ordering bugs.

## 2. Every file starts the same way
```lua
--!strict
-- ShopService: validates purchases and grants items. Server authoritative.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))
```
Order: strict directive, one-line purpose comment, `game:GetService` calls, shared requires, sibling requires, constants, module table. StyLua's `sort_requires` keeps requires alphabetical within a block.

## 3. Naming
- Files and ModuleScripts: `PascalCase` (`ShopService.luau`). Folders: `PascalCase` too (`Services`, `UI`, `Components`).
- Variables and functions: `camelCase`. Module tables and types: `PascalCase`. Constants: `UPPER_SNAKE`.
- Private helpers: local functions above the module table; no leading underscore needed.
- Instances created in code: `PascalCase` names (`SpawnPoints`, `PH_Counter` for placeholders).
- Remote names are verbs from the client's point of view (`RequestCollect`) or past-tense facts from the server (`ItemCollected`).

## 4. Service template (server)
The starter repo already ships the house versions of the pieces below: `src/shared/Remotes.luau` (the list), `src/server/Services/NetService.luau` (creates the remotes; `NetService.on` adds the rate limit and pcall), `src/shared/Guard.luau` and `src/server/Util/RateLimiter.luau`. Use them. This template shows what a handler does by hand, so the checks are clear.
```lua
--!strict
-- PickupService: spawns pickups in the world, validates collect attempts, grants them to profiles.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Guard = require(Shared:WaitForChild("Guard"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))

local RateLimiter = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RateLimiter"))

local PickupService = {}

local DataService -- set in Init
local active: { [string]: Types.Pickup } = {}
local collectLimiter = RateLimiter.new(Config.Pickups.CollectRemotesPerSecond, 1)

local function tryCollect(player: Player, pickupId: unknown)
	-- Drop floods before doing any work.
	if not collectLimiter:allow(player) then
		return
	end
	local id = Guard.id(pickupId)
	if id == nil then
		return
	end
	local pickup = active[id]
	if not pickup then
		return
	end
	-- Distance is checked here, on the server, so a client cannot collect from across the map.
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - pickup.Position).Magnitude > Config.Pickups.CollectRange then
		return
	end
	-- Remove before granting, so two racing requests cannot both win.
	active[id] = nil
	DataService.AddItem(player, pickup.KindId)
	Remotes.get("ItemCollected"):FireClient(player, id, pickup.KindId)
end

function PickupService.Init(services: { [string]: any })
	DataService = services.DataService
end

function PickupService.Start()
	Remotes.get("RequestCollect").OnServerEvent:Connect(tryCollect)
end

return PickupService
```

## 5. Main bootstrap
`src/server/Main.server.luau` and `src/client/Main.client.luau` in the starter repo load every module in `Services/` or `Controllers/`, run `Init` on all and then `Start` on all. Add a service by adding a file; Main needs no edit.

## 6. Remotes: one shared list, typed
The shipped `src/shared/Remotes.luau` is a plain list, with `NetService` creating the remotes on the server. The typed version below is an option when the list grows.
`src/shared/Remotes.luau` is the only place RemoteEvents are created. The server creates the folder; the client waits for it.
```lua
--!strict
-- Remotes: single source of truth for client and server messages.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

export type RemoteName =
	"RequestBuy" | "RequestCollect" -- client to server
	| "ProfileChanged" | "ItemCollected" -- server to client

local NAMES: { RemoteName } = {
	"RequestBuy",
	"RequestCollect",
	"ProfileChanged",
	"ItemCollected",
}

local Remotes = {}
local folder: Folder

if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in NAMES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function Remotes.get(name: RemoteName): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
```
Argument contracts live in a comment above each name and in `Guard.luau` as type guards (see remote-security-checklist). Prefer RemoteEvents; use a RemoteFunction only when the client needs a reply right now and always wrap the client call in `pcall`.

## 7. Shared data modules
- `Config.luau`: tuning numbers grouped by system (`Config.Shop.RefreshSeconds`). Numbers come from `docs/design/<game-slug>/tuning.md`; keep the doc and the file in sync.
- `Catalog.luau`: every purchasable or collectable thing with a stable string id (`"upgrade_speed_2"`). Ids never change once a profile has saved them.
- `Types.luau`: `export type` for profiles and game objects. The client receives trimmed copies, never the server record.
- `LiveFlags.luau`: the live switches. Wrap a new feature in `LiveFlags.isOn("name")` (see merge-and-publish section 3).

## 8. Client controllers and UI
- Controllers hold client state and expose signals and getters. UI modules subscribe; UI never fires remotes directly.
- A new field in the state the server sends must be copied at every hop (server snapshot, client controller, then the screen). A field a hop forgets arrives nil and the feature silently never runs, with green checks.
- UI is built in code with a small helper:
```lua
local function create<T>(className: string, props: { [string]: any }, children: { Instance }?): T
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance :: any
end
```
- Layouts via `UIListLayout` or `UIGridLayout`, sizes in `UDim2.fromScale` with `UIAspectRatioConstraint` or `UISizeConstraint`, never pixel offsets alone.

## 9. Style and comments
- StyLua formats; do not argue with it. Tabs, 100 columns, double quotes.
- Comment the why, not the what. A one-line header per file; a short comment above any validation branch explaining the exploit it blocks.
- No globals, no `wait()` (use `task.wait()`), no `spawn()` (use `task.spawn` or `task.defer`), no `Instance.new` with a parent argument.
- Connections you create you disconnect: store them in a table per player and clear on `PlayerRemoving`. Tables keyed by Instance are pruned by hand; Luau weak tables do not do it for you reliably.
- Errors: `warn` for recoverable, `error` only for programmer mistakes. Never silently swallow a DataStore failure.

## 10. Known traps
- **200 locals per function.** Luau stops compiling a function with more than 200 local variables ("Out of local registers"), and a file's top level counts as one function. A big module full of `local X = require(...)` lines hits it. Group requires into one table or require inside the function that uses them. The type checker does not catch this; only a real compile does.
- **CI's luau-lsp is stricter than a quick local check.** Type a value read from a table before comparing it with nil (`local x: T? = map[key]`), annotate the result of an if-expression before looping over it, and use `local _, x = f()` rather than assigning to a bare `_`.
- **Selene fails the job on any warning.** An unused `local X = require(...)` left behind after moving code is the usual cause.
- **StyLua** runs from `games/<game-slug>` with `--respect-ignores`, never from the repo root, or it reformats vendored files.
- **Deferred signals:** code that connects to a property change right after changing the property should survive handlers running later. Do not rely on a handler firing synchronously.

## 11. Done gate
`cd games/<game-slug>` then `./check.ps1` (or `./check.sh`). It runs `rojo sourcemap`, `luau-lsp analyze`, `selene` and `stylua --check`. All four must pass, then a Studio playtest with no new console errors.
