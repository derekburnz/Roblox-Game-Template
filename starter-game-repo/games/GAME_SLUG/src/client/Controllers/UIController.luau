--!strict
-- UIController: starts the UI and passes server notices (toasts) to it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local UI = require(script.Parent.Parent:WaitForChild("UI"))

local UIController = {}

function UIController.Init(_controllers: { [string]: any })
	UI.init()
end

function UIController.Start()
	Remotes.event("Notice").OnClientEvent:Connect(function(kind: unknown, text: unknown)
		if type(text) ~= "string" then
			return
		end
		UI.toast(text, if kind == "warning" then "warning" else "info")
	end)
end

return UIController
