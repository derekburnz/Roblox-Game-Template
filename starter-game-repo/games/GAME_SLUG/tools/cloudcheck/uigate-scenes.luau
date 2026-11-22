--!nocheck
--[[
	uigate-scenes: what the UI gate (uigate.mjs) opens on each screen size. Called with (UIShim) from ui-shim.luau.

	setup() starts the real UI the way Controllers/UIController does. Give it a player chosen to stress the
	layout once the game has state (the longest numbers and names, full lists). Each scene then opens one window
	through the same call the game uses. A new window goes in SCENES; the gate builds it at every screen size.
	close() puts everything back between scenes.
]]

local UIShim = ...

local Scenes = {}

local UI

function Scenes.setup()
	UI = UIShim.require("StarterPlayer.StarterPlayerScripts.Client.UI")
	UI.init()
end

local SCENES = {
	{ "Example", function()
		UI.open("Example")
	end },
	{ "Toast", function()
		UI.toast("This server updates in 10 minutes. Your progress is saved.", "info")
	end },
}

Scenes.names = {}
for _, scene in SCENES do
	table.insert(Scenes.names, scene[1])
end

function Scenes.open(name)
	for _, scene in SCENES do
		if scene[1] == name then
			scene[2]()
			return
		end
	end
	error("uigate: no scene " .. tostring(name))
end

function Scenes.close()
	UI.closeAll()
end

return Scenes
