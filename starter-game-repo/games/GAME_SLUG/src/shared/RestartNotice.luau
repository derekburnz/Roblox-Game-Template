--!strict
-- RestartNotice: the in-game warning before the running servers restart. Pure, so a spec covers it.
-- tools/opencloud/restart-countdown.sh publishes JSON text {"kind":"restart","seconds":N} on MessagingService topic
-- TOPIC at each mark of its countdown (default 600, 120, 30 and 0 seconds before the restart). Every server reads it
-- with `parse` (RestartNoticeService) and shows its players `text(seconds)` as a toast.
-- Anything that is not such a message, or whose seconds are not a whole number from 0 to MAX_SECONDS, is ignored.
-- Keep the words calm: a scary warning makes players leave early.

local RestartNotice = {}

RestartNotice.TOPIC = "GAME_PREFIX_Announce" -- must match TOPIC in tools/opencloud/restart-countdown.sh
RestartNotice.MAX_SECONDS = 3600
RestartNotice.REPEAT_SECONDS = 20 -- the same mark again this soon (a retried publish) is not shown twice
RestartNotice.WARN_SECONDS = 60 -- from this close the toast is a "warning"; before it, "info"

function RestartNotice.kind(seconds: number): "info" | "warning"
	return if seconds <= RestartNotice.WARN_SECONDS then "warning" else "info"
end

-- The seconds to the restart in a message's Data (the JSON text, or a table already decoded), or nil. `decode`
-- turns JSON text into a value and may error (the server passes HttpService:JSONDecode).
function RestartNotice.parse(data: unknown, decode: (string) -> unknown): number?
	local value: unknown = data
	if type(data) == "string" then
		if #data > 200 then
			return nil
		end
		local ok, decoded = pcall(decode, data)
		if not ok then
			return nil
		end
		value = decoded
	end
	if type(value) ~= "table" then
		return nil
	end
	local message = value :: { [any]: any }
	local seconds = message.seconds
	if message.kind ~= "restart" or type(seconds) ~= "number" then
		return nil
	end
	if
		seconds ~= seconds
		or seconds ~= math.floor(seconds)
		or seconds < 0
		or seconds > RestartNotice.MAX_SECONDS
	then
		return nil
	end
	return seconds
end

-- What players read, `seconds` before the restart.
function RestartNotice.text(seconds: number): string
	if seconds <= 0 then
		return "Updating now. Join again in a moment for the newest version. Your progress is saved."
	end
	if seconds < 60 then
		local whole = math.ceil(seconds)
		return string.format(
			"Quick update in %d second%s. Your progress is saved.",
			whole,
			if whole == 1 then "" else "s"
		)
	end
	local minutes = math.ceil(seconds / 60)
	return string.format(
		"This server updates in %d minute%s. Your progress is saved.",
		minutes,
		if minutes == 1 then "" else "s"
	)
end

return RestartNotice
