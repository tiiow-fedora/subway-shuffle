-- DevLevels: a Studio-only level browser, so every level can be walked
-- without riding the train. The DevLevelsUI panel (bottom of the screen in
-- Play-solo) sends prev/next/restart/goto/lobby; this loads the level at the
-- station door and drops you at its entrance. Clear a level and the next one
-- loads; fail it and it restarts. Does nothing in a live server, and steps
-- aside while a real train run is going.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RunState = require(ServerStorage:WaitForChild("SubwayShuffle"):WaitForChild("RunState"))
local levelsFolder = ServerStorage:WaitForChild("Levels")
local notify = ReplicatedStorage:WaitForChild("Notify")

local ORIGIN = Vector3.new(147.7, 21.4, 100.6)

local remote = Instance.new("RemoteEvent")
remote.Name = "DevLevel"
remote.Parent = ReplicatedStorage

local function list()
	local t = {}
	for _, l in levelsFolder:GetChildren() do
		if l:GetAttribute("LevelModule") then
			table.insert(t, l)
		end
	end
	table.sort(t, function(a, b)
		return a.Name < b.Name
	end)
	return t
end

local current, index = nil, 0
local loading = false

local function entrance()
	return CFrame.lookAt(ORIGIN + Vector3.new(0, 3, 4), ORIGIN + Vector3.new(0, 3, 40))
end

local function broadcastState()
	local levels = list()
	local l = levels[index]
	remote:FireAllClients("state", index, #levels, l and (l:GetAttribute("DisplayName") or l.Name) or "Lobby")
end

local function unload()
	local lvl = current
	current = nil
	if lvl and lvl.Parent then
		-- let the kit run its cleanups (lighting, gravity, sounds) first
		lvl:SetAttribute("Abort", true)
		local t0 = os.clock()
		while lvl.Parent and not lvl:GetAttribute("Ended") and os.clock() - t0 < 2 do
			task.wait(0.05)
		end
		lvl:Destroy()
	end
	for _, p in Players:GetPlayers() do
		RunState.respawnAt[p] = nil
	end
end

local function load(i)
	if loading then
		return
	end
	if RunState.active then
		for _, p in Players:GetPlayers() do
			notify:FireClient(p, "A train run is in progress - level browser paused.")
		end
		return
	end
	loading = true
	local levels = list()
	unload()
	if i < 1 or #levels == 0 then
		index = 0
		for _, p in Players:GetPlayers() do
			p:LoadCharacter()
		end
		broadcastState()
		loading = false
		return
	end
	index = (i - 1) % #levels + 1
	local tpl = levels[index]
	local lvl = tpl:Clone()
	lvl:SetAttribute("Origin", ORIGIN)
	lvl:SetAttribute("DevLevel", true)
	current = lvl
	lvl.Parent = workspace
	task.wait(0.3)
	for _, p in Players:GetPlayers() do
		local char = p.Character
		if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
			char:PivotTo(entrance())
		else
			p:LoadCharacter()
		end
		notify:FireClient(p, (tpl:GetAttribute("DisplayName") or tpl.Name), nil, string.format("Level %d / %d", index, #levels))
	end
	broadcastState()
	-- when it ends: cleared -> next level, otherwise try again
	lvl:GetAttributeChangedSignal("Ended"):Connect(function()
		if current ~= lvl then
			return
		end
		local reason = lvl:GetAttribute("Ended")
		if reason == "SKIPPED" then
			return
		end
		local cleared = false
		for _, p in Players:GetPlayers() do
			if RunState.completed and RunState.completed[p] then
				cleared = true
			end
		end
		for _, p in Players:GetPlayers() do
			notify:FireClient(p, cleared and "Cleared! Next level..." or (tostring(reason) .. " Restarting..."))
		end
		task.wait(3)
		if current == lvl then
			load(cleared and index + 1 or index)
		end
	end)
	loading = false
end

remote.OnServerEvent:Connect(function(_, action, arg)
	if action == "next" then
		load(index + 1)
	elseif action == "prev" then
		load(index <= 1 and #list() or index - 1)
	elseif action == "restart" then
		load(math.max(index, 1))
	elseif action == "goto" and typeof(arg) == "number" then
		load(math.floor(arg))
	elseif action == "lobby" then
		load(0)
	elseif action == "hello" then
		broadcastState()
	end
end)

-- dying in a browser level with no checkpoint puts you back at its entrance
-- (RunCtrl handles checkpoints, and would otherwise send you to the lobby)
local function hook(p)
	p.CharacterAdded:Connect(function(char)
		if current and not RunState.respawnAt[p] and not RunState.active then
			task.defer(function()
				char:WaitForChild("HumanoidRootPart", 5)
				if current then
					char:PivotTo(entrance())
				end
			end)
		end
	end)
end
Players.PlayerAdded:Connect(hook)
for _, p in Players:GetPlayers() do
	hook(p)
end

-- a real run starting takes over
task.spawn(function()
	while true do
		task.wait(1)
		if RunState.active and current then
			unload()
			index = 0
			broadcastState()
		end
	end
end)
