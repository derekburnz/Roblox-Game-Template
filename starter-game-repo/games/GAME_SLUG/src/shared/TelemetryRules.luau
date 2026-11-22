--!strict
-- TelemetryRules: the checks every analytics call passes before it goes to Roblox. Pure, so
-- tests/specs/TelemetryRules.spec.luau covers it; server/Services/Telemetry uses it.
--
-- Roblox facts these rules follow (AnalyticsService):
-- - At most 3 custom fields per event (CustomField01 to 03). A 4th is dropped without an error, so we refuse it.
-- - A field with more than about 8,000 distinct values is folded into "Other": send short words ("phone", "tier_2"),
--   never a player's name, an id or free text.
-- - Funnel and event names show up in Creator Hub about a day later. Keep names stable; a funnel whose steps
--   change gets a new name (onboarding_v2) and is never compared across the change.

local TelemetryRules = {}

TelemetryRules.MAX_FIELDS = 3
TelemetryRules.MAX_FIELD_LENGTH = 50
TelemetryRules.MAX_NAME_LENGTH = 50

-- Lower case letters, digits and underscores: the same name everywhere, easy to search for in Creator Hub.
function TelemetryRules.validName(name: string): boolean
	return #name > 0
		and #name <= TelemetryRules.MAX_NAME_LENGTH
		and name:match("^[a-z][a-z0-9_]*$") ~= nil
end

-- A field value as sent: trimmed to MAX_FIELD_LENGTH, with anything but letters, digits, _ - . and spaces removed.
function TelemetryRules.cleanField(value: string): string
	local cleaned = value:gsub("[^%w_%-%. ]", "")
	return cleaned:sub(1, TelemetryRules.MAX_FIELD_LENGTH)
end

-- The custom fields table AnalyticsService takes, or nil plus a reason when the call is wrong.
function TelemetryRules.fields(values: { string }?): ({ [string]: string }?, string?)
	if values == nil or #values == 0 then
		return {}, nil
	end
	if #values > TelemetryRules.MAX_FIELDS then
		return nil, `{#values} custom fields; Roblox keeps only {TelemetryRules.MAX_FIELDS}`
	end
	local out: { [string]: string } = {}
	for i, value in values do
		out[string.format("CustomField%02d", i)] = TelemetryRules.cleanField(value)
	end
	return out, nil
end

return TelemetryRules
