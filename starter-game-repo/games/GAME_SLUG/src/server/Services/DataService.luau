--!strict
-- DataService: loads each player's save with session locking (ProfileStore, vendored in server/Vendor), brings it
-- up to date with shared/SaveSchema, and saves it on leave, on shutdown and every few minutes.
--
-- Session locking means only one server can hold a player's save at a time. Without it, a player who hops servers
-- quickly can have an old server overwrite what the new one saved (lost items, or duplicated ones).
--
-- Other services:
--   DataService.get(player)               the loaded save, or nil before it loads or after it is released
--   DataService.onLoaded:Connect(fn)      fn(player, save) once the save is ready
--   DataService.beforeRelease(fn)         fn(player, save) runs, in order, just before the save is written for the
--                                         last time; use it to fold session numbers into the save
--
-- Studio uses its own store (name + "_dev"), so a playtest with API access on never touches live saves. Without
-- "Enable Studio Access to API Services", ProfileStore runs on a mock store: the game works, nothing persists.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ProfileStore = require(script.Parent.Parent.Vendor.ProfileStore)
local SaveSchema = require(Shared:WaitForChild("SaveSchema"))
local Signal = require(Shared:WaitForChild("Signal"))

type Save = SaveSchema.Save
type Session = {
	save: Save,
	profile: any, -- ProfileStore's profile; its Data is the save
	joinedAt: number,
}

local DataService = {}

DataService.STORE_NAME = "GAME_PREFIX_Saves"
DataService.KEY_PREFIX = "Player_"

DataService.onLoaded = Signal.new() :: Signal.Signal<Player, Save>

local sessions: { [Player]: Session } = {}
local finalizers: { (player: Player, save: Save) -> () } = {}
local store: any = nil

function DataService.get(player: Player): Save?
	local session = sessions[player]
	return if session ~= nil then session.save else nil
end

function DataService.beforeRelease(fn: (player: Player, save: Save) -> ())
	table.insert(finalizers, fn)
end

local function finalize(player: Player, session: Session)
	for _, fn in finalizers do
		local ok, err = pcall(function()
			fn(player, session.save)
			return nil :: any
		end)
		if not ok then
			warn("DataService: a beforeRelease step failed:", err)
		end
	end
	local now = os.time()
	session.save.playSeconds += math.max(0, now - session.joinedAt)
	session.joinedAt = now
	session.save.lastSeen = now
	session.profile.Data = session.save
end

local function load(player: Player)
	local profile = store:StartSessionAsync(DataService.KEY_PREFIX .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile == nil then
		-- Never play on a blank save: it would overwrite the real one later.
		player:Kick("Your save could not be loaded. Please rejoin in a minute.")
		return
	end
	profile:AddUserId(player.UserId) -- GDPR: lets Roblox find and erase this player's data on request
	local save, reason = SaveSchema.migrate(profile.Data, os.time())
	if save == nil then
		profile:EndSession()
		player:Kick("This server is out of date. Please rejoin to get the newest version.")
		warn("DataService:", reason)
		return
	end
	profile.Data = save
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end
	local session: Session = { save = save, profile = profile, joinedAt = os.time() }
	sessions[player] = session
	profile.OnSessionEnd:Connect(function()
		sessions[player] = nil
		if player.Parent == Players then
			player:Kick("Your save was opened on another server. Please rejoin.")
		end
	end)
	DataService.onLoaded:Fire(player, save)
end

local function release(player: Player)
	local session = sessions[player]
	if session == nil then
		return
	end
	finalize(player, session)
	sessions[player] = nil
	session.profile:EndSession()
end

function DataService.Init(_services: { [string]: any })
	local name = DataService.STORE_NAME .. (if RunService:IsStudio() then "_dev" else "")
	store = ProfileStore.New(name, SaveSchema.template(0) :: any)
end

function DataService.Start()
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(release)
	-- On shutdown ProfileStore saves every open session itself; folding the session numbers in first keeps them.
	game:BindToClose(function()
		for player in sessions do
			release(player)
		end
	end)
end

return DataService
