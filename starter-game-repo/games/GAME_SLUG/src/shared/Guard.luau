--!strict
-- Argument checks for remotes. Each returns the cleaned value or nil, so a handler reads
--   local id = Guard.id(raw) if id == nil then return end
-- An exploiter can send any value of any type, including NaN, huge numbers and very long strings.
-- Never trust the client (skill remote-security-checklist).

local Guard = {}

Guard.MAX_ID_LENGTH = 64

-- A catalog or instance id: ASCII letters, digits, underscores and hyphens, 1 to MAX_ID_LENGTH long.
function Guard.id(value: unknown): string?
	if type(value) ~= "string" or #value == 0 or #value > Guard.MAX_ID_LENGTH then
		return nil
	end
	if value:match("^[%w_%-]+$") == nil then
		return nil
	end
	return value
end

function Guard.bool(value: unknown): boolean?
	if type(value) == "boolean" then
		return value
	end
	return nil
end

-- A whole number between min and max, both included. NaN and infinities fail.
function Guard.int(value: unknown, min: number, max: number): number?
	if type(value) ~= "number" or value ~= value or value ~= math.floor(value) then
		return nil
	end
	if value < min or value > max then
		return nil
	end
	return value
end

-- Any finite number between min and max.
function Guard.number(value: unknown, min: number, max: number): number?
	if type(value) ~= "number" or value ~= value then
		return nil
	end
	if value < min or value > max then
		return nil
	end
	return value
end

-- One of a fixed list of strings.
function Guard.oneOf(value: unknown, allowed: { string }): string?
	if type(value) ~= "string" then
		return nil
	end
	for _, option in allowed do
		if option == value then
			return value
		end
	end
	return nil
end

-- A short piece of player text (not yet filtered: run it through TextService before anyone else sees it).
function Guard.text(value: unknown, maxLength: number): string?
	if type(value) ~= "string" or #value == 0 or #value > maxLength or utf8.len(value) == nil then
		return nil
	end
	return value
end

return Guard
