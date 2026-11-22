--!strict
-- NetService: creates every remote in shared/Remotes and is the only place client calls come in.
--
--   NetService.on("BuyItem", { perSecond = 2 }, function(player, rawId)
--       local id = Guard.id(rawId)
--       if id == nil then return end
--       ...
--   end)
--
-- Each handler gets the calling player first and the raw arguments after. NetService drops a call when the
-- player is over the remote's rate limit, and runs the handler in a pcall so one bad call can't break the remote.
-- The handler still checks every argument with Guard and every rule (ownership, range, cooldowns) on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local NetService = {}

export type Limit = {
	perSecond: number, -- calls a second, refilled continuously
	burst: number?, -- calls allowed at once (default: perSecond, at least 1)
}

local events: { [string]: RemoteEvent } = {}
local limiters: { RateLimiter.RateLimiter } = {}

local function ensureFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild(Remotes.FolderName)
	if folder == nil then
		local made = Instance.new("Folder")
		made.Name = Remotes.FolderName
		made.Parent = ReplicatedStorage
		folder = made
	end
	return folder :: Folder
end

local function create(name: string)
	local existing: RemoteEvent? = events[name]
	if existing ~= nil then
		return
	end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = ensureFolder()
	events[name] = event
end

-- Listens for a client -> server remote. Call it in a service's Init or Start.
function NetService.on(name: string, limit: Limit, handler: (Player, ...unknown) -> ())
	assert(
		table.find(Remotes.ClientToServer, name),
		`NetService.on: {name} is not in Remotes.ClientToServer`
	)
	create(name)
	local burst = math.max(1, limit.burst or limit.perSecond)
	local limiter = RateLimiter.new(burst, burst / limit.perSecond)
	table.insert(limiters, limiter)
	events[name].OnServerEvent:Connect(function(player: Player, ...: unknown)
		if not limiter:allow(player) then
			return
		end
		local args = table.pack(...)
		local ok, err = pcall(function()
			handler(player, table.unpack(args, 1, args.n))
			return nil :: any
		end)
		if not ok then
			warn(`NetService: {name} failed: {err}`)
		end
	end)
end

function NetService.fire(player: Player, name: string, ...: any)
	assert(
		table.find(Remotes.ServerToClient, name),
		`NetService.fire: {name} is not in Remotes.ServerToClient`
	)
	create(name)
	events[name]:FireClient(player, ...)
end

function NetService.fireAll(name: string, ...: any)
	assert(
		table.find(Remotes.ServerToClient, name),
		`NetService.fireAll: {name} is not in Remotes.ServerToClient`
	)
	create(name)
	events[name]:FireAllClients(...)
end

-- A short toast on one player's screen.
function NetService.notice(player: Player, text: string, kind: ("info" | "warning")?)
	NetService.fire(player, "Notice", kind or "info", text)
end

function NetService.Init(_services: { [string]: any })
	-- Every remote exists before any client asks for it, even ones no service listens to yet.
	for _, name in Remotes.ClientToServer do
		create(name)
	end
	for _, name in Remotes.ServerToClient do
		create(name)
	end
end

function NetService.Start()
	NetService.on("Ping", { perSecond = 2 }, function(_player: Player) end)
	Players.PlayerRemoving:Connect(function(player: Player)
		for _, limiter in limiters do
			limiter:forget(player)
		end
	end)
end

return NetService
