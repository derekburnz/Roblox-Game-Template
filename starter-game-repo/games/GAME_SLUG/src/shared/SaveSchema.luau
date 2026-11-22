--!strict
-- SaveSchema: what one player's save holds, and how an old save is brought up to date. Pure (no Roblox services),
-- so tests/specs/SaveSchema.spec.luau checks it.
--
-- Adding a field:
-- 1. Add it to Save and to template() with its starting value.
-- 2. If old saves need a value other than the template's, raise VERSION and add a step to migrate().
-- 3. A field old saves can simply lack (read as nil until first written) needs no VERSION bump. Then keep the
--    feature that writes it behind a live switch (shared/LiveFlags) that stays off until every running server has
--    the new code: an old server loads the save without that field and writes it back without it.
-- Never rename or reuse a field: old saves still hold the old name.

export type Save = {
	version: number,
	createdAt: number, -- os.time() of the first join
	lastSeen: number, -- os.time() of the last save
	playSeconds: number,
	coins: number, -- an example currency; rename or remove it for your game
	funnel: { [string]: boolean }, -- Telemetry funnel steps this save already logged
}

local SaveSchema = {}

SaveSchema.VERSION = 1

function SaveSchema.template(now: number): Save
	return {
		version = SaveSchema.VERSION,
		createdAt = now,
		lastSeen = now,
		playSeconds = 0,
		coins = 0,
		funnel = {},
	}
end

-- Steps from each old version to the next. migrate() runs them in order. Example for VERSION 2:
--   [1] = function(data) data.gems = 0 end,
local STEPS: { [number]: (data: { [string]: any }) -> () } = {}

-- Takes whatever the DataStore held and returns a save of the current shape, or nil plus a reason when the save
-- is newer than this server understands (an old server must never load and overwrite a newer save).
function SaveSchema.migrate(raw: unknown, now: number): (Save?, string?)
	if type(raw) ~= "table" then
		return SaveSchema.template(now), nil
	end
	local data = raw :: { [string]: any }
	local version = if type(data.version) == "number" then data.version else 0
	if version > SaveSchema.VERSION then
		return nil, `save version {version} is newer than this server's {SaveSchema.VERSION}`
	end
	for v = version, SaveSchema.VERSION - 1 do
		local step = STEPS[v]
		if step ~= nil then
			step(data)
		end
	end
	-- Missing fields take the template's value, so a save from before a field existed still works.
	for key, value in SaveSchema.template(now) :: any do
		if data[key] == nil then
			data[key] = value
		end
	end
	data.version = SaveSchema.VERSION
	return (data :: any) :: Save, nil
end

return SaveSchema
