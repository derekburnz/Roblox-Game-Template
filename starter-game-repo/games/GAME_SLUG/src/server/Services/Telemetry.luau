--!strict
-- Telemetry: the one place the game sends analytics to Roblox (AnalyticsService). Server only: Roblox records
-- nothing from a client or from Studio, and a client could send anything.
--
--   Telemetry.funnelStep(player, "onboarding_v1", 2, "first_win")   once per save (remembered in save.funnel)
--   Telemetry.event(player, "shop_opened", 1, { "phone", "tier_2" })  a custom event, 3 fields at most
--   Telemetry.economy(player, "coins", "source", 50, balance, "Gameplay", "quest_reward")
--
-- Every call is wrapped in pcall: analytics must never break gameplay. A wrong call (a bad name, a 4th field)
-- warns in Studio and the log and is not sent. In Studio the last LOG_SIZE calls are kept in Telemetry.recent for QA.
-- Read the results in Creator Hub > Analytics (funnels and custom events), about a day late.
local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DataService = require(script.Parent.DataService)
local TelemetryRules = require(Shared:WaitForChild("TelemetryRules"))

local Telemetry = {}

local LOG_SIZE = 200
Telemetry.recent = {} :: { string }

local function remember(line: string)
	if not RunService:IsStudio() then
		return
	end
	table.insert(Telemetry.recent, line)
	if #Telemetry.recent > LOG_SIZE then
		table.remove(Telemetry.recent, 1)
	end
end

local function send(what: string, fn: () -> ())
	local ok, err = pcall(function()
		fn()
		return nil :: any
	end)
	if not ok then
		warn(`Telemetry: {what} failed: {err}`)
	end
end

-- One step of a funnel, sent once per save. Steps are numbered from 1 in the order players reach them.
function Telemetry.funnelStep(
	player: Player,
	funnel: string,
	step: number,
	stepName: string,
	fields: { string }?
)
	if not TelemetryRules.validName(funnel) or not TelemetryRules.validName(stepName) then
		warn(`Telemetry: bad funnel or step name {funnel} {stepName}`)
		return
	end
	local custom, reason = TelemetryRules.fields(fields)
	if custom == nil then
		warn(`Telemetry: {funnel} {stepName}: {reason}`)
		return
	end
	local save = DataService.get(player)
	if save == nil then
		return
	end
	local key = `{funnel}:{step}`
	if save.funnel[key] then
		return
	end
	save.funnel[key] = true
	remember(`funnel {funnel} {step} {stepName}`)
	send(`funnel {funnel}`, function()
		AnalyticsService:LogFunnelStepEvent(
			player,
			funnel,
			tostring(player.UserId),
			step,
			stepName,
			custom
		)
	end)
end

-- A custom event with a number value (a count, seconds, an amount) and up to 3 short fields.
function Telemetry.event(player: Player, name: string, value: number?, fields: { string }?)
	if not TelemetryRules.validName(name) then
		warn(`Telemetry: bad event name {name}`)
		return
	end
	local custom, reason = TelemetryRules.fields(fields)
	if custom == nil then
		warn(`Telemetry: {name}: {reason}`)
		return
	end
	remember(`event {name} {value or 1}`)
	send(`event {name}`, function()
		AnalyticsService:LogCustomEvent(player, name, value or 1, custom)
	end)
end

-- Currency in (a source) or out (a sink). transactionType is an Enum.AnalyticsEconomyTransactionType name, such
-- as "Gameplay", "Shop" or "IAP"; sku names what it was for.
function Telemetry.economy(
	player: Player,
	currency: string,
	flow: "source" | "sink",
	amount: number,
	balance: number,
	transactionType: string,
	sku: string,
	fields: { string }?
)
	if amount <= 0 then
		return
	end
	local custom, reason = TelemetryRules.fields(fields)
	if custom == nil then
		warn(`Telemetry: economy {sku}: {reason}`)
		return
	end
	remember(`economy {flow} {currency} {amount} {sku}`)
	send(`economy {sku}`, function()
		AnalyticsService:LogEconomyEvent(
			player,
			if flow == "source"
				then Enum.AnalyticsEconomyFlowType.Source
				else Enum.AnalyticsEconomyFlowType.Sink,
			currency,
			amount,
			math.max(0, math.floor(balance)),
			transactionType,
			sku,
			custom
		)
	end)
end

return Telemetry
