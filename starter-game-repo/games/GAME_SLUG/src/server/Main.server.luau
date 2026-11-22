--!strict
-- Main: loads every Service, runs Init on all of them, then Start on all of them. Init wires dependencies,
-- Start connects events and begins loops, so services can find each other in Init without ordering bugs.
local servicesFolder = (script.Parent :: Instance):WaitForChild("Services")
local services: { [string]: any } = {}

for _, module in servicesFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		services[module.Name] = require(module) :: any
	end
end
for _, service in services do
	if service.Init then
		service.Init(services)
	end
end
for _, service in services do
	if service.Start then
		task.spawn(service.Start)
	end
end
