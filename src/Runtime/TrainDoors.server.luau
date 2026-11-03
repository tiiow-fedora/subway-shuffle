-- TrainDoors: sliding doors for the train's two door openings. They close
-- while the train is moving and open at stations. Anyone who still ends up
-- outside the train while it's moving is put back aboard.
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RunState = require(ServerStorage:WaitForChild("SubwayShuffle"):WaitForChild("RunState"))
local Kit = require(ServerStorage.SubwayShuffle.LevelKit)
local Audio = require(ServerStorage.SubwayShuffle.Audio)

local train = workspace:WaitForChild("SubwayTrain")
local returnPoint = train:WaitForChild("ReturnPoint")
local sss = game.ServerScriptService

-- door openings on the platform (+Z) side, measured from the train model
local OPENINGS = { { 117, 123.5 }, { 135, 141 } }
local FLOOR_Y, TOP_Y = 12.36, 21.3
local LEAF_Z = 38.45
-- the inside of the train
local INSIDE_MIN = Vector3.new(110.5, 9, 24.4)
local INSIDE_MAX = Vector3.new(231, 25, 39.9)

local GREY = Color3.fromRGB(150, 155, 160)
local DARK = Color3.fromRGB(60, 62, 66)

local folder = Instance.new("Folder")
folder.Name = "ShuffleDoors"
folder.Parent = train

local leaves = {}
local lamps = {}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	p.Parent = folder
	return p
end

for _, o in OPENINGS do
	local x0, x1 = o[1], o[2]
	local w = (x1 - x0) / 2
	local h = TOP_Y - FLOOR_Y
	for side = -1, 1, 2 do
		-- closed: the two leaves meet in the middle; open: slid out by one leaf width
		local closedX = side < 0 and x0 + w / 2 or x1 - w / 2
		local closed = CFrame.new(closedX, FLOOR_Y + h / 2, LEAF_Z)
		local open = closed + Vector3.new(side * (w - 0.2), 0, 0)
		local leaf = part({ Name = "DoorLeaf", Size = Vector3.new(w, h, 0.3), CFrame = open, Color = GREY, Material = Enum.Material.Metal })
		local window = part({
			Name = "DoorWindow",
			Size = Vector3.new(w - 0.8, h * 0.4, 0.34),
			CFrame = open + Vector3.new(0, h * 0.12, 0),
			Color = Color3.fromRGB(40, 50, 60),
			Material = Enum.Material.Glass,
			Transparency = 0.45,
			CanCollide = false,
		})
		local edge = part({
			Name = "DoorEdge",
			Size = Vector3.new(0.2, h, 0.36),
			CFrame = open + Vector3.new(-side * (w / 2 - 0.1), 0, 0),
			Color = Color3.fromRGB(240, 190, 30),
			CanCollide = false,
		})
		table.insert(leaves, { parts = { leaf, window, edge }, open = open, closed = closed, base = { leaf.CFrame, window.CFrame, edge.CFrame } })
	end
	-- door status lamp above the opening
	local lamp = part({
		Name = "DoorLamp",
		Size = Vector3.new(1.2, 0.4, 0.3),
		CFrame = CFrame.new((x0 + x1) / 2, TOP_Y + 0.5, LEAF_Z),
		Color = Color3.fromRGB(60, 220, 90),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	table.insert(lamps, lamp)
	part({ Name = "DoorHeader", Size = Vector3.new(x1 - x0 + 0.4, 0.3, 0.4), CFrame = CFrame.new((x0 + x1) / 2, TOP_Y + 0.05, LEAF_Z), Color = DARK, CanCollide = false })
end

-- sound: music aboard all the time, rumble while moving, chimes at the doors
local speaker = Instance.new("Part")
speaker.Name = "TrainSpeaker"
speaker.Anchored = true
speaker.CanCollide = false
speaker.CanQuery = false
speaker.CanTouch = false
speaker.Transparency = 1
speaker.Size = Vector3.new(1, 1, 1)
speaker.Position = Vector3.new(170, 18, 32)
speaker.Parent = folder
local music = Audio.loop(speaker, "elevatorMusic", 0.25, 75)
local rumble = Audio.loop(speaker, "trainInterior", 0, 80)

local isClosed = false
local function setDoors(close)
	if close == isClosed then
		return
	end
	isClosed = close
	rumble.Volume = close and 0.45 or 0
	if close then
		Audio.play(Vector3.new(130, 18, 38), "doorChime", 0.8, 90)
	end
	task.delay(close and 0.6 or 0, function()
		Audio.play(Vector3.new(120, 18, 38), "doorOpen", 0.7, 70)
		Audio.play(Vector3.new(138, 18, 38), "doorOpen", 0.7, 70)
	end)
	for _, lamp in lamps do
		lamp.Color = close and Color3.fromRGB(230, 50, 40) or Color3.fromRGB(60, 220, 90)
	end
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	for _, leaf in leaves do
		local target = close and leaf.closed or leaf.open
		local delta = target.Position - leaf.parts[1].Position
		for _, p in leaf.parts do
			TweenService:Create(p, info, { CFrame = p.CFrame + delta }):Play()
		end
	end
end

sss:WaitForChild("StationArrived").Event:Connect(function()
	setDoors(false)
end)
local function departing()
	setDoors(true)
end
sss:WaitForChild("GameStarted").Event:Connect(departing)
sss:WaitForChild("LevelComplete").Event:Connect(departing)

local function insideTrain(pos)
	return pos.X > INSIDE_MIN.X and pos.X < INSIDE_MAX.X and pos.Y > INSIDE_MIN.Y and pos.Y < INSIDE_MAX.Y and pos.Z > INSIDE_MIN.Z and pos.Z < INSIDE_MAX.Z
end

-- while moving, nobody gets to wander off into the tunnel
while true do
	task.wait(0.5)
	if isClosed then
		for player in RunState.riders do
			local root = Kit.rootOf(player)
			if root and not insideTrain(root.Position) then
				player.Character:PivotTo(returnPoint.CFrame + Vector3.new(math.random(-6, 6), 3, 0))
				root.AssemblyLinearVelocity = Vector3.zero
				Kit.notify(player, "Stay inside the train while it's moving!")
			end
		end
	end
end
