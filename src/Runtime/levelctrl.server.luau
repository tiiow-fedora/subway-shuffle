-- levelctrl: loads a random level every time the train reaches a station.
-- (Installed into ServerScriptService by BuildAll; the original levelctrl is
-- kept disabled as ServerScriptService.levelctrl_original.)
-- an edit-mode preview left in the workspace (Dev/Preview) would sit inside
-- every level that loads at the door; never let one into a running game
do
	local stale = workspace:FindFirstChild("_Preview")
	if stale then
		stale:Destroy()
	end
end

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunState = require(ServerStorage:WaitForChild("SubwayShuffle"):WaitForChild("RunState"))

local levelsFolder = ServerStorage:WaitForChild("Levels")
local stationArrived = game.ServerScriptService:WaitForChild("StationArrived")
local levelFinished = game.ServerScriptService:WaitForChild("LevelFinished")
local levelComplete = game.ServerScriptService:WaitForChild("LevelComplete")
local notify = ReplicatedStorage:WaitForChild("Notify")
local gameState = ReplicatedStorage:FindFirstChild("GameState")

local train = workspace:WaitForChild("SubwayTrain")
local returnPoint = train:WaitForChild("ReturnPoint")

-- where the Metal Door sits (closed) when the station stops perfectly
local DOOR_REF = Vector3.new(147.836, 24.403, 99.412)

local currentLevel = nil
local availableLevels = {}

local function pickLevel()
	local forced = gameState and gameState:GetAttribute("ForceLevel")
	if forced and forced ~= "" then
		local lvl = levelsFolder:FindFirstChild(forced)
		if lvl then
			return lvl
		end
		warn("ForceLevel not found:", forced)
	end
	if #availableLevels == 0 then
		availableLevels = levelsFolder:GetChildren()
	end
	if #availableLevels == 0 then
		return nil
	end
	return table.remove(availableLevels, math.random(1, #availableLevels))
end

-- The station can stop a stud or two off; slide the level along X so its
-- doorway lines up with the station's actual door.
local function doorOffset(station)
	local best, bestDist = nil, 15
	for _, d in (station or workspace:FindFirstChild("TunnelSystem") or workspace):GetDescendants() do
		if d:IsA("Model") and d.Name == "Metal Door" and not d:GetAttribute("Opened") then
			local dist = (d:GetPivot().Position - DOOR_REF).Magnitude
			if dist < bestDist then
				best, bestDist = d, dist
			end
		end
	end
	if not best then
		return Vector3.zero
	end
	return Vector3.new(best:GetPivot().Position.X - DOOR_REF.X, 0, 0)
end

local function shift(model, offset)
	if offset.Magnitude < 0.01 then
		return
	end
	model:PivotTo(model:GetPivot() + offset)
	for _, inst in { model, table.unpack(model:GetDescendants()) } do
		for k, v in inst:GetAttributes() do
			if typeof(v) == "Vector3" then
				inst:SetAttribute(k, v + offset)
			end
		end
	end
	if model:GetAttribute("LevelModule") then
		model:SetAttribute("Origin", Vector3.new(147.7, 21.4, 100.6) + offset)
	end
end

stationArrived.Event:Connect(function(station)
	if currentLevel or not RunState.active then
		-- nobody aboard: the train just waits here until someone boards
		return
	end
	local template = pickLevel()
	if not template then
		warn("No levels found!")
		return
	end
	RunState.stop += 1
	RunState.completed = nil
	print("Selected level:", template.Name)

	local level = template:Clone()
	shift(level, doorOffset(station))
	currentLevel = level
	level.Parent = workspace

	local name = template:GetAttribute("DisplayName") or template.Name
	for _, player in RunState.participants() do
		notify:FireClient(player, name, nil, "Now arriving")
	end
end)

levelFinished.Event:Connect(function()
	if not currentLevel then
		return
	end
	local isKitLevel = currentLevel:GetAttribute("LevelModule") ~= nil
	local completed = RunState.completed
	local i = 0
	for _, player in (RunState.active and RunState.participants() or {}) do
		i += 1
		if player.Character then
			player.Character:PivotTo(returnPoint.CFrame + Vector3.new((i % 6) * 3 - 7.5, 3, 0))
		end
		notify:FireClient(player, "__fade")
		-- Wins = stops completed
		local done = (not isKitLevel) or (completed and completed[player])
		local stats = player:FindFirstChild("leaderstats")
		if done and stats and stats:FindFirstChild("Wins") then
			stats.Wins.Value += 1
			notify:FireClient(player, "Stop cleared! Back to the train.")
		else
			notify:FireClient(player, "Back to the train.")
		end
	end

	currentLevel:Destroy()
	currentLevel = nil
	RunState.completed = nil

	if RunState.active then
		levelComplete:Fire()
	end
end)
