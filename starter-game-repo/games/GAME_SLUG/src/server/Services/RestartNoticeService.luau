--!strict
-- RestartNoticeService: listens on MessagingService topic RestartNotice.TOPIC, which only the Open Cloud key can
-- publish to (tools/opencloud/restart-countdown.sh, run by the restart-servers workflow), and shows every player
-- in this server RestartNotice.text as a toast. A player who joins while a restart is coming is told how long is
-- left. A subscribe that fails (a Studio place that was never published) is tried three times, then left with one
-- warning in the log: nothing else depends on it.
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetService = require(script.Parent.NetService)
local RestartNotice =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RestartNotice"))

local RestartNoticeService = {}

local SUBSCRIBE_WAITS = { 5, 15 } -- seconds before the second and third tries

local restartAt: number? = nil -- os.clock() of the coming restart
local lastSeconds: number? = nil
local lastShownAt = -math.huge

local function decode(text: string): unknown
	return HttpService:JSONDecode(text)
end

local function warnAll(seconds: number)
	local now = os.clock()
	if seconds == lastSeconds and now - lastShownAt < RestartNotice.REPEAT_SECONDS then
		return
	end
	lastSeconds, lastShownAt = seconds, now
	restartAt = now + seconds
	for _, player in Players:GetPlayers() do
		NetService.notice(player, RestartNotice.text(seconds), RestartNotice.kind(seconds))
	end
end

local function onMessage(message: any)
	local data = if type(message) == "table" then message.Data else nil
	local seconds = RestartNotice.parse(data, decode)
	if seconds ~= nil then
		warnAll(seconds)
	end
end

function RestartNoticeService.Start()
	Players.PlayerAdded:Connect(function(player: Player)
		local at = restartAt
		local left = if at ~= nil then at - os.clock() else 0
		if left > 0 then
			task.wait(5) -- let the client's UI start first
			NetService.notice(player, RestartNotice.text(left), RestartNotice.kind(left))
		end
	end)
	local lastError = ""
	for attempt = 1, #SUBSCRIBE_WAITS + 1 do
		local ok, err = pcall(function()
			MessagingService:SubscribeAsync(RestartNotice.TOPIC, onMessage)
		end)
		if ok then
			return
		end
		lastError = tostring(err)
		local wait = SUBSCRIBE_WAITS[attempt]
		if wait ~= nil then
			task.wait(wait)
		end
	end
	warn("RestartNoticeService: no restart warnings on this server: " .. lastError)
end

return RestartNoticeService
