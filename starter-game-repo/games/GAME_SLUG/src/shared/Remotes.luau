--!strict
-- The one list of RemoteEvents. The server (NetService) creates them in ReplicatedStorage.Remotes at start;
-- the client waits for them. Every client -> server call is validated and rate limited in NetService.
-- Write each remote's arguments and what the server checks beside its name, so a reviewer can compare.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

Remotes.FolderName = "Remotes"

-- Client -> server: (args) and what the server checks.
Remotes.ClientToServer = {
	"Ping", -- ()  an example to copy: no arguments, 2 a second at most
}

-- Server -> client.
Remotes.ServerToClient = {
	"Notice", -- (kind: "info" | "warning", text: string)  a short line the client shows as a toast
}

function Remotes.folder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(Remotes.FolderName)
	if existing ~= nil then
		return existing :: Folder
	end
	return ReplicatedStorage:WaitForChild(Remotes.FolderName) :: Folder
end

function Remotes.event(name: string): RemoteEvent
	return Remotes.folder():WaitForChild(name) :: RemoteEvent
end

return Remotes
