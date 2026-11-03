-- Run from the Studio command bar:
--   require(game.ServerStorage.SubwayShuffle.BuildAll)()            -- everything
--   require(game.ServerStorage.SubwayShuffle.BuildAll)({only = "L05_Floodwater"})
--   require(game.ServerStorage.SubwayShuffle.BuildAll)({skipLobby = true})
-- Builds every level module into ServerStorage.Levels, builds the lobby and
-- installs the runtime scripts. Safe to re-run: it replaces what it built.
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local root = script.Parent

local function install(template, parent, name)
	local old = parent:FindFirstChild(name)
	if old and old:GetAttribute("SubwayShuffle") then
		old:Destroy()
	end
	local s = template:Clone()
	s.Name = name
	s:SetAttribute("SubwayShuffle", true)
	s.Disabled = false
	s.Parent = parent
	return s
end

local function levelDefs()
	local defs = {}
	for _, m in root.Levels:GetChildren() do
		if m:IsA("ModuleScript") then
			local ok, def = pcall(require, m)
			if ok then
				def.ModuleName = m.Name
				table.insert(defs, def)
			else
				warn("Level module failed to load:", m.Name, def)
			end
		end
	end
	table.sort(defs, function(a, b)
		return (a.Order or 99) < (b.Order or 99)
	end)
	return defs
end

return function(opts)
	opts = opts or {}
	local BuildLib = require(root.BuildLib)
	require(root.Arch) -- installs room/exit/outdoor methods onto BuildLib
	local levels = ServerStorage:FindFirstChild("Levels")

	-- NPC templates: drop a "Guest" (or "Noob") rig in workspace and the next
	-- build files it here; LevelHelpers.npc clones it for every NPC of that kind
	local templates = ServerStorage:FindFirstChild("NPCTemplates")
	if not templates then
		templates = Instance.new("Folder")
		templates.Name = "NPCTemplates"
		templates.Parent = ServerStorage
	end
	for _, name in { "Guest", "Noob" } do
		local dropped = workspace:FindFirstChild(name)
		if dropped and dropped:IsA("Model") and dropped:FindFirstChildOfClass("Humanoid") then
			local old = templates:FindFirstChild(name)
			if old then
				old:Destroy()
			end
			dropped.Parent = templates
			print("Stored NPC template", name)
		end
	end

	-- retire the 15-second placeholders (kept, just out of the pool)
	local old = ServerStorage:FindFirstChild("OldPlaceholders")
	if not old then
		old = Instance.new("Folder")
		old.Name = "OldPlaceholders"
		old.Parent = ServerStorage
	end
	-- (Level1 too: the rebuilt Maintenance Tunnel is L01)
	for _, name in { "Level1", "Level2", "Level3" } do
		local p = levels:FindFirstChild(name)
		if p then
			p.Parent = old
		end
	end

	local defs = levelDefs()
	local built = 0
	for _, def in defs do
		if opts.only and def.ModuleName ~= opts.only then
			continue
		end
		local existing = levels:FindFirstChild(def.ModuleName)
		if existing then
			existing:Destroy()
		end
		local model = Instance.new("Model")
		model.Name = def.ModuleName
		local B = BuildLib.new(model)
		local ok, err = pcall(def.Build, B, def)
		if not ok then
			warn("BUILD FAILED", def.ModuleName, err)
			model:Destroy()
			continue
		end
		model:SetAttribute("LevelModule", def.ModuleName)
		model:SetAttribute("DisplayName", def.Name)
		model:SetAttribute("Hint", def.Hint or "")
		model:SetAttribute("TimeLimit", def.TimeLimit or 90)
		model:SetAttribute("Mode", def.Mode or "escape")
		model:SetAttribute("DoorPos", Vector3.new(147.8, 24.4, 99.4))
		model:SetAttribute("BuiltBy", "SubwayShuffle")
		if B.bounds then
			model:SetAttribute("Depth", B.bounds.D)
		end
		local ls = root.Runtime.LevelScript:Clone()
		ls.Name = "LevelScript"
		ls.Parent = model
		model.Parent = levels
		built += 1
	end
	print("Built", built, "levels")

	if opts.only then
		return
	end

	-- drop generated levels whose module has been deleted
	local current = {}
	for _, def in defs do
		current[def.ModuleName] = true
	end
	for _, l in levels:GetChildren() do
		if l:GetAttribute("BuiltBy") == "SubwayShuffle" and not current[l.Name] then
			print("Removed old level", l.Name)
			l:Destroy()
		end
	end

	-- lobby
	if not opts.skipLobby then
		require(root.Lobby)()
		print("Built lobby")
	end

	-- shared state objects (so they exist in edit mode too)
	local gs = ReplicatedStorage:FindFirstChild("GameState")
	if not gs then
		gs = Instance.new("Folder")
		gs.Name = "GameState"
		gs.Parent = ReplicatedStorage
	end
	gs:SetAttribute("RunLength", nil)
	if not ReplicatedStorage:FindFirstChild("Notify") then
		local n = Instance.new("RemoteEvent")
		n.Name = "Notify"
		n.Parent = ReplicatedStorage
	end

	-- runtime scripts
	local orig = ServerScriptService:FindFirstChild("levelctrl")
	if orig and not orig:GetAttribute("SubwayShuffle") then
		orig.Name = "levelctrl_original"
		orig.Disabled = true
	end
	install(root.Runtime.levelctrl, ServerScriptService, "levelctrl")
	install(root.Runtime.RunCtrl, ServerScriptService, "RunCtrl")
	local startup = ServerScriptService:FindFirstChild("startupctrl")
	if startup then
		-- the lobby now decides when the train leaves
		startup.Disabled = true
	end
	install(root.Runtime.TrainDoors, ServerScriptService, "TrainDoors")
	install(root.Runtime.AdRotator, ServerScriptService, "AdRotator")

	-- no baseplate: every level, the lobby and the tunnel have their own floors
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
		print("Removed the baseplate")
	end
	install(root.Runtime.SubwayHud, StarterPlayer.StarterPlayerScripts, "SubwayHud")
	install(root.Runtime.Clocks, StarterPlayer.StarterPlayerScripts, "Clocks")
	install(root.Runtime.MusicLeveler, StarterPlayer.StarterPlayerScripts, "MusicLeveler")
	-- Studio-only level browser (both scripts do nothing in a live server)
	install(root.Runtime.DevLevels, ServerScriptService, "DevLevels")
	install(root.Runtime.DevLevelsUI, StarterPlayer.StarterPlayerScripts, "DevLevelsUI")
	print("Installed runtime scripts")

	-- invisible walls that stuck out of the train / station onto the platform
	local train = workspace:FindFirstChild("SubwayTrain")
	if train then
		for _, p in train:GetChildren() do
			if p:IsA("BasePart") and p.Transparency >= 0.95 and math.abs(p.Position.X - 219.72) < 0.1 and p.Size.Z > 20 then
				-- the cab wall: keep it, but only across the inside of the train
				if p.Position.Z > 32 then
					p.CanCollide = false
					p:SetAttribute("ShuffleFix", "was an invisible wall on the platform")
				else
					p.Size = Vector3.new(p.Size.X, p.Size.Y, 15.3)
					p.Position = Vector3.new(p.Position.X, p.Position.Y, 32.15)
					p:SetAttribute("ShuffleFix", "trimmed to the train interior (was 24 long)")
				end
			end
		end
	end
	local station = ServerStorage:FindFirstChild("tunnelpieces") and ServerStorage.tunnelpieces:FindFirstChild("trackwithuncodedshopandstairs")
	if station then
		for _, p in station:GetChildren() do
			if p:IsA("BasePart") and p.Transparency >= 0.95 and p.CanCollide and (p.Position - Vector3.new(117.29, 17.48, 44.54)).Magnitude < 0.5 then
				p.CanCollide = false
				p:SetAttribute("ShuffleFix", "was an invisible wall at the platform edge")
			end
		end
	end
end
