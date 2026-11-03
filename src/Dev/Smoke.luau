-- Play-mode smoke test (run from the SERVER command bar while playing solo):
--   require(<clone of this>)()            -- every level
--   require(<clone of this>)({"L05_Floodwater"})
-- Drops each level at the station door, walks the first player in, then into
-- the middle, and records every script error/warning raised meanwhile.
local ServerStorage = game:GetService("ServerStorage")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")

local ORIGIN = Vector3.new(147.7, 21.4, 100.6)

return function(only, dwell)
	dwell = dwell or 6
	local names = {}
	if only then
		names = only
	else
		for _, l in ServerStorage.Levels:GetChildren() do
			if l:GetAttribute("LevelModule") then
				table.insert(names, l.Name)
			end
		end
		table.sort(names)
	end
	local current = "?"
	local log = {}
	local conn = LogService.MessageOut:Connect(function(msg, kind)
		if (kind == Enum.MessageType.MessageError or kind == Enum.MessageType.MessageWarning) and not msg:find("SMOKE") then
			table.insert(log, current .. ": " .. msg)
		end
	end)
	local player = Players:GetPlayers()[1]
	for _, name in names do
		current = name
		local m = ServerStorage.Levels[name]:Clone()
		m:SetAttribute("Origin", ORIGIN)
		m.Parent = workspace
		task.wait(1)
		local char = player and player.Character
		if char then
			char:PivotTo(CFrame.new(ORIGIN + Vector3.new(0, 3, 4)))
		end
		task.wait(dwell)
		local depth = m:GetAttribute("Depth") or 60
		if char and char.Parent then
			char:PivotTo(CFrame.new(ORIGIN + Vector3.new(0, 8, depth * 0.5)))
		end
		task.wait(dwell * 0.6)
		m:Destroy()
		print("SMOKE done", name)
		task.wait(0.5)
	end
	conn:Disconnect()
	print("SMOKE RESULTS:", #log, "messages")
	for _, l in log do
		print("SMOKE>", l)
	end
	return log
end
