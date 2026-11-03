-- RunCtrl: the lobby, boarding, and the endless ride.
-- Stand on the lobby's boarding platform for a few seconds and you're put on
-- the train. The first boarder sets the train moving; it then loops forever
-- (levelctrl loads a level at every station). Wins = stops completed.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

local RunState = require(ServerStorage:WaitForChild("SubwayShuffle"):WaitForChild("RunState"))

local BOARD_TIME = 4
Players.RespawnTime = 2.5

local notify = ReplicatedStorage:FindFirstChild("Notify")
if not notify then
	notify = Instance.new("RemoteEvent")
	notify.Name = "Notify"
	notify.Parent = ReplicatedStorage
end

local gameStarted = game.ServerScriptService:WaitForChild("GameStarted")
local train = workspace:WaitForChild("SubwayTrain")
local returnPoint = train:WaitForChild("ReturnPoint")
local lobby = workspace:WaitForChild("Lobby")
local zone = lobby:WaitForChild("BoardingZone")
local lobbySpawn = lobby:WaitForChild("LobbySpawn")
local boardLabel = lobby:FindFirstChild("DepartureBoard", true)
boardLabel = boardLabel and boardLabel:FindFirstChild("Label", true)
local leaderLabel = lobby:FindFirstChild("WinsBoard", true)
leaderLabel = leaderLabel and leaderLabel:FindFirstChild("Label", true)

task.spawn(function()
	require(ServerStorage.SubwayShuffle.FriendAvatars).swapAll(lobby)
end)
require(ServerStorage.SubwayShuffle.LevelKit).animateNpcs(lobby)

-- lobby music, even across the hall
do
	local Audio = require(ServerStorage.SubwayShuffle.Audio)
	local cf, size = lobby:GetBoundingBox()
	local emitter = Instance.new("Part")
	emitter.Name = "LobbyMusic"
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.CanTouch = false
	emitter.Transparency = 1
	emitter.Size = Vector3.one
	emitter.Position = cf.Position
	emitter.Parent = lobby
	local range = math.max(size.X, size.Z) * 0.6 + 10
	Audio.music(emitter, Audio.MUSIC.Lobby, 0.4, range)
end

-- only the lobby spawn is used; riders are moved onto the train on respawn
for _, d in workspace:GetDescendants() do
	if d:IsA("SpawnLocation") and d ~= lobbySpawn then
		d.Enabled = false
	end
end

local function trainCFrame(i)
	return returnPoint.CFrame + Vector3.new(((i or 0) % 6) * 3 - 7.5, 3, 0)
end

-- ------------------------------------------------------------------ data

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("SubwayShuffle_v2")
	end)
	if ok then
		store = result
	else
		warn("DataStore unavailable (enable Studio API access to save):", result)
	end
end

local function save(player)
	local stats = player:FindFirstChild("leaderstats")
	if not store or not stats or not player:GetAttribute("DataLoaded") then
		return
	end
	local wins = stats.Wins.Value
	pcall(function()
		store:SetAsync("p_" .. player.UserId, { Wins = wins })
	end)
end

local function onPlayer(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = stats
	stats.Parent = player

	player.CharacterAdded:Connect(function(char)
		local at = RunState.respawnAt[player]
		-- a checkpoint with nothing under it (its level is gone) is no use
		if at and not workspace:Raycast(at.Position + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), RaycastParams.new()) then
			RunState.respawnAt[player] = nil
			at = nil
		end
		if at or RunState.riders[player] then
			-- died in a level: back to your checkpoint if the level set one,
			-- otherwise aboard the train (never the lobby)
			task.defer(function()
				char:WaitForChild("HumanoidRootPart", 5)
				char:PivotTo(at or trainCFrame(math.random(0, 5)))
			end)
		end
	end)

	if store then
		task.spawn(function()
			local ok, data = pcall(function()
				return store:GetAsync("p_" .. player.UserId)
			end)
			if ok and type(data) == "table" then
				wins.Value = data.Wins or 0
			end
			if ok then
				player:SetAttribute("DataLoaded", true)
			end
		end)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	task.spawn(onPlayer, p)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	RunState.riders[player] = nil
	if RunState.active and next(RunState.riders) == nil then
		-- nobody aboard: the train parks at the next station until someone boards
		RunState.active = false
		print("Train empty - parking at the next station")
	end
end)

game:BindToClose(function()
	for _, p in Players:GetPlayers() do
		save(p)
	end
end)

task.spawn(function()
	while true do
		task.wait(120)
		for _, p in Players:GetPlayers() do
			save(p)
		end
	end
end)

-- ------------------------------------------------------------------ boarding

local function board(player)
	if RunState.riders[player] then
		return
	end
	RunState.riders[player] = true
	notify:FireClient(player, "__fade")
	task.delay(0.35, function()
		if player.Character then
			player.Character:PivotTo(trainCFrame(math.random(0, 5)))
		end
	end)
	if not RunState.active then
		RunState.active = true
		task.delay(1.5, function()
			gameStarted:Fire()
		end)
		print("Train leaving the depot")
	end
end

local function playersOnZone()
	local list = {}
	local seen = {}
	local cf = zone.CFrame + Vector3.new(0, 4, 0)
	for _, part in workspace:GetPartBoundsInBox(cf, Vector3.new(zone.Size.X, 8, zone.Size.Z)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local player = model and Players:GetPlayerFromCharacter(model)
		if player and not seen[player] then
			local hum = model:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				seen[player] = true
				table.insert(list, player)
			end
		end
	end
	return list
end

local function updateLeaderboard()
	if not leaderLabel then
		return
	end
	local rows = {}
	for _, p in Players:GetPlayers() do
		local stats = p:FindFirstChild("leaderstats")
		if stats then
			table.insert(rows, { name = p.DisplayName, wins = stats.Wins.Value })
		end
	end
	table.sort(rows, function(a, b)
		return a.wins > b.wins
	end)
	local lines = { "MOST STOPS" }
	for i = 1, math.min(8, #rows) do
		table.insert(lines, string.format("%d.  %s   %d", i, rows[i].name, rows[i].wins))
	end
	leaderLabel.Text = table.concat(lines, "\n")
end

local onZoneSince = {}
local lastBoard = 0
while true do
	task.wait(0.25)
	local now = os.clock()
	local here = {}
	for _, p in playersOnZone() do
		here[p] = true
		onZoneSince[p] = onZoneSince[p] or now
		if now - onZoneSince[p] >= BOARD_TIME then
			onZoneSince[p] = nil
			board(p)
		end
	end
	for p in onZoneSince do
		if not here[p] then
			onZoneSince[p] = nil
		end
	end
	if boardLabel then
		local riders = 0
		for p in RunState.riders do
			if p.Parent then
				riders += 1
			end
		end
		boardLabel.Text = riders > 0 and string.format("NEXT TRAIN\nBoarding now\n%d aboard", riders) or "NEXT TRAIN\nBoarding now"
	end
	if now - lastBoard > 3 then
		lastBoard = now
		updateLeaderboard()
	end
end
