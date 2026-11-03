-- Studio-only panel for the DevLevels level browser (see DevLevels.server).
-- Buttons: lobby, previous, restart, next, and a box to jump to a level
-- number. Keys: [ previous, ] next, \ restart.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local remote = ReplicatedStorage:WaitForChild("DevLevel", 15)
if not remote then
	return
end

local gui = Instance.new("ScreenGui")
gui.Name = "DevLevels"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -12)
bar.Size = UDim2.fromOffset(470, 40)
bar.BackgroundColor3 = Color3.fromRGB(20, 22, 26)
bar.BackgroundTransparency = 0.2
bar.Parent = gui
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = bar

local function button(text, order, width, action)
	local b = Instance.new("TextButton")
	b.LayoutOrder = order
	b.Size = UDim2.fromOffset(width, 30)
	b.BackgroundColor3 = Color3.fromRGB(60, 64, 72)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = bar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.Activated:Connect(action)
	return b
end

button("Lobby", 1, 56, function()
	remote:FireServer("lobby")
end)
button("<", 2, 30, function()
	remote:FireServer("prev")
end)

local label = Instance.new("TextLabel")
label.LayoutOrder = 3
label.Size = UDim2.fromOffset(200, 30)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.Gotham
label.TextSize = 14
label.TextTruncate = Enum.TextTruncate.AtEnd
label.Text = "Level browser"
label.Parent = bar

button(">", 4, 30, function()
	remote:FireServer("next")
end)
button("Retry", 5, 52, function()
	remote:FireServer("restart")
end)

local box = Instance.new("TextBox")
box.LayoutOrder = 6
box.Size = UDim2.fromOffset(44, 30)
box.BackgroundColor3 = Color3.fromRGB(40, 42, 48)
box.TextColor3 = Color3.new(1, 1, 1)
box.PlaceholderText = "#"
box.Font = Enum.Font.Gotham
box.TextSize = 14
box.Text = ""
box.ClearTextOnFocus = true
box.Parent = bar
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
box.FocusLost:Connect(function(enter)
	local n = tonumber(box.Text)
	if enter and n then
		remote:FireServer("goto", n)
	end
	box.Text = ""
end)

remote.OnClientEvent:Connect(function(kind, index, total, name)
	if kind == "state" then
		label.Text = index > 0 and string.format("%d/%d  %s", index, total, name) or ("Lobby  (" .. total .. " levels)")
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightBracket then
		remote:FireServer("next")
	elseif input.KeyCode == Enum.KeyCode.LeftBracket then
		remote:FireServer("prev")
	elseif input.KeyCode == Enum.KeyCode.BackSlash then
		remote:FireServer("restart")
	end
end)

remote:FireServer("hello")
