--!strict
-- Main: loads every Controller, runs Init on all of them, then Start on all of them (the client twin of the
-- server's Main). Controllers hold client state; UI modules read it and never fire remotes themselves.
local controllersFolder = (script.Parent :: Instance):WaitForChild("Controllers")
local controllers: { [string]: any } = {}

for _, module in controllersFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		controllers[module.Name] = require(module) :: any
	end
end
for _, controller in controllers do
	if controller.Init then
		controller.Init(controllers)
	end
end
for _, controller in controllers do
	if controller.Start then
		task.spawn(controller.Start)
	end
end
