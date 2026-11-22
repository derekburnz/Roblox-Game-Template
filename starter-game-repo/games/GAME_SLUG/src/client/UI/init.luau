--!strict
-- UI: a starter HUD with one menu button, one example window and toasts, built in code. It is a small working
-- example for the UI gate (tools/cloudcheck/uigate.mjs) to check at every screen size; replace it with the game's
-- own screens (skills roblox-gui and ui-review). UI never fires remotes: controllers do, and call UI to show things.
--
--   UI.init()                 builds the HUD once, under the local player's PlayerGui
--   UI.open("Example")        opens a window by name; UI.closeAll() closes every window
--   UI.toast(text, kind)      a short line at the top of the screen for a few seconds
local Players = game:GetService("Players")

local UI = {}

local TAP = 52 -- px: comfortable on a phone (the UI gate fails anything pressable under 44 px on touch)
local FONT = Enum.Font.GothamMedium

local windows: { [string]: Frame } = {}
local toastLabel: TextLabel? = nil
local toastToken = 0

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function button(text: string, parent: Instance): TextButton
	local b = Instance.new("TextButton")
	b.Name = text:gsub("%s", "")
	b.Size = UDim2.fromOffset(120, TAP)
	b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	b.TextColor3 = Color3.fromRGB(30, 30, 30)
	b.Font = FONT
	b.TextSize = 20
	b.Text = text
	b.AutoButtonColor = true
	corner(b, 12)
	b.Parent = parent
	return b
end

local function window(name: string, title: string, gui: ScreenGui): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.new(0.6, 0, 0.6, 0)
	frame.BackgroundColor3 = Color3.fromRGB(250, 246, 240)
	frame.Visible = false
	corner(frame, 16)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(560, 400)
	limit.MinSize = Vector2.new(300, 220)
	limit.Parent = frame

	local heading = Instance.new("TextLabel")
	heading.Name = "Title"
	heading.BackgroundTransparency = 1
	heading.Position = UDim2.fromOffset(20, 12)
	heading.Size = UDim2.new(1, -40 - TAP, 0, 40)
	heading.Font = Enum.Font.GothamBold
	heading.TextSize = 26
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.TextColor3 = Color3.fromRGB(30, 30, 30)
	heading.Text = title
	heading.Parent = frame

	local close = button("X", frame)
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10)
	close.Size = UDim2.fromOffset(TAP, TAP)
	close.Activated:Connect(function()
		frame.Visible = false
	end)
	frame.Parent = gui
	windows[name] = frame
	return frame
end

function UI.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local hud = Instance.new("ScreenGui")
	hud.Name = "HUD"
	hud.ResetOnSpawn = false
	hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = hud

	-- Left column, centred: clear of Roblox's top bar and of the phone thumbstick (bottom left).
	local menu = button("Menu", root)
	menu.AnchorPoint = Vector2.new(0, 0.5)
	menu.Position = UDim2.new(0, 16, 0.5, 0)
	menu.Activated:Connect(function()
		UI.open("Example")
	end)

	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.new(0.5, 0, 0, 70)
	toast.Size = UDim2.new(0.8, 0, 0, 40)
	toast.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	toast.BackgroundTransparency = 0.2
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.Font = FONT
	toast.TextSize = 18
	toast.TextWrapped = true
	toast.Visible = false
	corner(toast, 10)
	toast.Parent = root
	toastLabel = toast

	local example = window("Example", "Example window", hud)
	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(20, 64)
	body.Size = UDim2.new(1, -40, 1, -84)
	body.Font = FONT
	body.TextSize = 18
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextColor3 = Color3.fromRGB(60, 60, 60)
	body.Text =
		"Replace this window with the game's own. The UI gate checks every window at phone, tablet and desktop sizes."
	body.Parent = example

	hud.Parent = playerGui
end

function UI.open(name: string)
	UI.closeAll()
	local frame: Frame? = windows[name]
	assert(frame ~= nil, `UI.open: no window {name}`)
	frame.Visible = true
end

function UI.closeAll()
	for _, frame in windows do
		frame.Visible = false
	end
end

function UI.windowNames(): { string }
	local names = {}
	for name in windows do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function UI.toast(text: string, kind: ("info" | "warning")?)
	local label = toastLabel
	if label == nil then
		return
	end
	toastToken += 1
	local token = toastToken
	label.Text = text
	label.BackgroundColor3 = if kind == "warning"
		then Color3.fromRGB(150, 60, 20)
		else Color3.fromRGB(30, 30, 30)
	label.Visible = true
	task.delay(5, function()
		if token == toastToken then
			label.Visible = false
		end
	end)
end

return UI
