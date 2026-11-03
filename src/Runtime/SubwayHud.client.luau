-- SubwayHud: no permanent HUD - just classic Roblox notifications for events,
-- and a quick fade to black when the server teleports you.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local notify = ReplicatedStorage:WaitForChild("Notify")

local gui = Instance.new("ScreenGui")
gui.Name = "SubwayFade"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local fade = Instance.new("Frame")
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BackgroundTransparency = 1
fade.BorderSizePixel = 0
fade.Parent = gui

local function doFade()
	TweenService:Create(fade, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
	task.delay(0.6, function()
		TweenService:Create(fade, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	end)
end

local function send(title, text)
	-- SetCore isn't ready for the first few seconds after joining
	for _ = 1, 10 do
		local ok = pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
			Title = title,
			Text = text,
			Duration = 4,
		})
		if ok then
			return
		end
		task.wait(0.5)
	end
end

notify.OnClientEvent:Connect(function(text, _color, title)
	if text == "__fade" then
		doFade()
	else
		task.spawn(send, title or "Subway Shuffle", text)
	end
end)
