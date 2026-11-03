-- Builds workspace.Lobby: an underground ticket hall. You spawn by the ticket
-- machines, go through the barriers onto the platform, and step aboard the
-- real train waiting with its doors open (BoardingZone is inside it).
local BuildLib = require(script.Parent.BuildLib)
local LH = require(script.Parent.LevelHelpers)
local Decor = require(script.Parent.Decor)
local TrainKit = require(script.Parent.TrainKit)
local C = BuildLib.C

local ORIGIN = Vector3.new(150, 1, -260)

-- the crew, out and about in the hall (swapped for their real avatars at
-- runtime): name, floor position, turn (degrees; 0 faces -Z, 180 the train)
local CREW = {
	{ "tiiow", Vector3.new(23, 0, -14), 20 },
	{ "TylerLeprune", Vector3.new(-35, 0, -35), 0 },
	{ "Enclave2009", Vector3.new(32, 0, -35), 0 },
	{ "lemonbirdiscool", Vector3.new(-9, 0, 10), 180 },
	{ "United7378", Vector3.new(4, 0, 15), 200 },
	{ "TheAmongo1", Vector3.new(-40, 0, -4), 90 },
}
local TRAIN_X, TRAIN_Z = -12, 33.4 -- the train's centre (its doors face the platform)

local WALL = Color3.fromRGB(214, 206, 186)
local LOWER = Color3.fromRGB(38, 74, 62)
local FLOOR = Color3.fromRGB(92, 88, 84)

return function()
	local old = workspace:FindFirstChild("Lobby")
	if old then
		old:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "Lobby"
	local B = BuildLib.new(model, ORIGIN)
	-- track level, so the train's floor is level with the platform
	local RAIL_Y = -TrainKit.floorAboveTrack()
	local doors = TrainKit.doorOffsets(true)

	local W, H = 90, 18
	local x0, x1 = -W / 2, W / 2
	local z0, z1 = -40, 44
	local PLATFORM_Z = 24 -- platform edge; tracks beyond

	-- floors
	B:floor(x0, z0, x1, PLATFORM_Z, 0, { Name = "HallFloor", Color = FLOOR, Material = Enum.Material.Slate, Thick = 1 })
	B:floor(x0, PLATFORM_Z, x1, z1, RAIL_Y, { Name = "TrackBed", Color = Color3.fromRGB(50, 48, 46), Material = Enum.Material.Pebble, Thick = 1 })
	B:span(Vector3.new(x0, RAIL_Y, PLATFORM_Z - 0.6), Vector3.new(x1, -0.01, PLATFORM_Z), { Name = "PlatformEdge", Color = Color3.fromRGB(70, 68, 66) })
	B:part(Vector3.new(0, 0.02, PLATFORM_Z - 1.2), Vector3.new(W, 0.04, 1.2), { Name = "EdgeLine", Color = Color3.fromRGB(220, 180, 40), Parent = "Decor", CanCollide = false })
	-- walls, ceiling
	local wall = { Color = WALL, Material = Enum.Material.Concrete, Name = "Wall" }
	-- side walls: solid along the hall, and over the track a tunnel mouth the
	-- train runs out through
	local MOUTH = 13.8
	for _, wx in { { x0 - 1, x0 }, { x1, x1 + 1 } } do
		B:span(Vector3.new(wx[1], RAIL_Y, z0 - 1), Vector3.new(wx[2], H, PLATFORM_Z), wall)
		B:span(Vector3.new(wx[1], MOUTH, PLATFORM_Z), Vector3.new(wx[2], H, z1 + 1), wall)
	end
	B:span(Vector3.new(x0, RAIL_Y, z0 - 1), Vector3.new(x1, H, z0), wall)
	B:span(Vector3.new(x0, RAIL_Y, z1), Vector3.new(x1, H, z1 + 1), wall)
	-- the dark tunnels beyond, closed off far enough back not to be seen
	local dark = { Color = Color3.fromRGB(14, 14, 16), Material = Enum.Material.SmoothPlastic, Name = "Tunnel" }
	for _, t in { { x0 - 46, x0 - 1 }, { x1 + 1, x1 + 24 } } do
		B:span(Vector3.new(t[1], RAIL_Y - 1, PLATFORM_Z - 1), Vector3.new(t[2], RAIL_Y, z1 + 1), dark)
		B:span(Vector3.new(t[1], RAIL_Y, PLATFORM_Z - 1), Vector3.new(t[2], MOUTH + 1, PLATFORM_Z), dark)
		B:span(Vector3.new(t[1], RAIL_Y, z1), Vector3.new(t[2], MOUTH + 1, z1 + 1), dark)
		B:span(Vector3.new(t[1], MOUTH, PLATFORM_Z), Vector3.new(t[2], MOUTH + 1, z1), dark)
	end
	B:span(Vector3.new(x0 - 47, RAIL_Y, PLATFORM_Z - 1), Vector3.new(x0 - 46, MOUTH + 1, z1 + 1), dark)
	B:span(Vector3.new(x1 + 24, RAIL_Y, PLATFORM_Z - 1), Vector3.new(x1 + 25, MOUTH + 1, z1 + 1), dark)
	Decor.track(B, Vector3.new(x0 - 46, RAIL_Y, TRAIN_Z), Vector3.new(x1 + 24, RAIL_Y, TRAIN_Z), false)
	B:span(Vector3.new(x0 - 1, H, z0 - 1), Vector3.new(x1 + 1, H + 1, z1 + 1), { Name = "Ceiling", Color = Color3.fromRGB(60, 58, 56), Material = Enum.Material.Concrete })
	-- lower wall band + trim around the hall (not over the track wall)
	for _, spec in { { x0, 1 }, { x1, -1 } } do
		B:part(Vector3.new(spec[1] + spec[2] * 0.15, 2, (z0 + PLATFORM_Z) / 2), Vector3.new(0.3, 4, PLATFORM_Z - z0), { Color = LOWER, Material = Enum.Material.Slate, Parent = "Decor", Name = "WallBand", CanCollide = false })
		B:part(Vector3.new(spec[1] + spec[2] * 0.2, 4.2, (z0 + PLATFORM_Z) / 2), Vector3.new(0.4, 0.4, PLATFORM_Z - z0), { Color = C.yellow, Parent = "Decor", Name = "Trim", CanCollide = false })
	end
	B:part(Vector3.new(0, 2, z0 + 0.15), Vector3.new(W, 4, 0.3), { Color = LOWER, Material = Enum.Material.Slate, Parent = "Decor", Name = "WallBand", CanCollide = false })
	B:part(Vector3.new(0, 4.2, z0 + 0.2), Vector3.new(W, 0.4, 0.4), { Color = C.yellow, Parent = "Decor", Name = "Trim", CanCollide = false })
	-- adverts round the hall (the train hides the track wall)
	for _, x in { -24, 22 } do
		Decor.advert(B, Vector3.new(x, 10, z0 + 0.4), "+Z")
	end
	for _, z in { -28, 10 } do
		Decor.advert(B, Vector3.new(x0, 10, z), "+X")
	end
	for _, z in { -28, -6, 10 } do
		Decor.advert(B, Vector3.new(x1, 10, z), "-X")
	end
	-- beams + lights
	for z = z0 + 8, z1 - 4, 10 do
		B:part(Vector3.new(0, H - 0.5, z), Vector3.new(W, 1, 1.2), { Color = Color3.fromRGB(50, 48, 46), Parent = "Decor", Name = "Beam", CanCollide = false })
	end
	for z = z0 + 13, z1 - 4, 10 do
		for _, x in { -24, 0, 24 } do
			B:ceilingLight(Vector3.new(x, H - 0.2, z), 8, { Color = Color3.fromRGB(255, 226, 180), Brightness = 0.75, Range = 24 })
		end
	end

	-- columns down the hall
	for _, x in { -22, 22 } do
		for _, z in { -24, -2, 16 } do
			B:part(Vector3.new(x, H / 2, z), Vector3.new(2.6, H, 2.6), { Color = WALL, Material = Enum.Material.Concrete, Name = "Column" })
			B:part(Vector3.new(x, 2, z), Vector3.new(2.8, 4, 2.8), { Color = LOWER, Material = Enum.Material.Slate, Parent = "Decor", Name = "ColumnBase", CanCollide = false })
			B:part(Vector3.new(x, 4.2, z), Vector3.new(2.9, 0.4, 2.9), { Color = C.yellow, Parent = "Decor", Name = "ColumnTrim", CanCollide = false })
		end
	end

	-- spawn by the ticket machines
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.CFrame = CFrame.new(B:w(Vector3.new(0, 0.2, -30)))
	spawn.Color = FLOOR
	spawn.Material = Enum.Material.Slate
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = model
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	for i, x in { -40, -35, -30 } do
		B:span(Vector3.new(x - 2, 0, z0), Vector3.new(x + 2, 7, z0 + 2.4), { Name = "TicketMachine", Color = i == 2 and Color3.fromRGB(40, 90, 150) or Color3.fromRGB(60, 62, 66), Material = Enum.Material.Metal })
		B:part(Vector3.new(x, 4.6, z0 + 2.45), Vector3.new(2.6, 1.8, 0.1), { Color = Color3.fromRGB(30, 60, 90), Material = Enum.Material.Glass, Parent = "Decor", CanCollide = false })
	end
	B:span(Vector3.new(30, 0, z0), Vector3.new(34, 7, z0 + 3), { Name = "Vending", Color = Color3.fromRGB(170, 40, 40), Material = Enum.Material.SmoothPlastic })
	B:part(Vector3.new(32, 4.3, z0 + 3.05), Vector3.new(3, 4, 0.1), { Color = Color3.fromRGB(230, 225, 210), Material = Enum.Material.Glass, Transparency = 0.2, Parent = "Decor", CanCollide = false })
	B:span(Vector3.new(36, 0, z0), Vector3.new(40, 7, z0 + 3), { Name = "Vending", Color = Color3.fromRGB(40, 120, 70), Material = Enum.Material.SmoothPlastic })
	B:part(Vector3.new(38, 4.3, z0 + 3.05), Vector3.new(3, 4, 0.1), { Color = Color3.fromRGB(230, 225, 210), Material = Enum.Material.Glass, Transparency = 0.2, Parent = "Decor", CanCollide = false })
	Decor.clock(B, Vector3.new(0, 12, z0 + 0.4), "+Z")
	Decor.staffDoor(B, Vector3.new(-12, 0, z0 + 0.3), "+Z")
	Decor.extinguisher(B, Vector3.new(-16, 0, z0), "+Z")
	Decor.cctv(B, Vector3.new(x0 + 0.2, 14, -30), "+X")
	Decor.cctv(B, Vector3.new(x1 - 0.2, 14, 10), "-X")

	-- ticket barriers
	for x = -18, 18, 4 do
		B:part(Vector3.new(x, 1.8, -10), Vector3.new(0.9, 3.6, 4), { Color = Color3.fromRGB(150, 155, 160), Material = Enum.Material.Metal, Name = "Barrier" })
		B:part(Vector3.new(x, 3.65, -11.6), Vector3.new(0.9, 0.1, 0.7), { Color = Color3.fromRGB(80, 200, 110), Parent = "Decor", CanCollide = false, Name = "Reader" })
	end
	for _, spec in { { x0, -20 }, { 20, x1 } } do
		B:span(Vector3.new(spec[1], 0, -10.5), Vector3.new(spec[2], 3.6, -9.5), { Color = Color3.fromRGB(150, 155, 160), Material = Enum.Material.Metal, Name = "Railing" })
	end

	-- benches, bins, plants on the platform
	for _, x in { -34, -10, 10, 34 } do
		Decor.bench(B, Vector3.new(x, 0, 6), 180)
	end
	for _, x in { -40, 40 } do
		Decor.bin(B, Vector3.new(x, 0, 8))
	end
	for _, pos in { Vector3.new(-42, 0, -36), Vector3.new(42, 0, -36), Vector3.new(-42, 0, -14), Vector3.new(42, 0, -14) } do
		Decor.plant(B, pos, 1.1)
	end

	-- the real train, waiting at the platform with its doors open. Step in and
	-- stay aboard to ride (the BoardingZone covers the car between its doors).
	TrainKit.place(B, Vector3.new(TRAIN_X, RAIL_Y, TRAIN_Z), { Name = "LobbyTrain", Parent = model, flip = true })
	local zoneX = TRAIN_X + (doors[1] + doors[2]) / 2
	local zone = B:part(Vector3.new(zoneX, 0.05, TRAIN_Z), Vector3.new(math.abs(doors[1] - doors[2]) + 12, 0.1, 12), {
		Name = "BoardingZone",
		Transparency = 1,
		Parent = model,
		CanCollide = false,
	})
	zone.CastShadow = false
	-- the open doors glow on the platform
	for _, dx in doors do
		local x = TRAIN_X + dx
		B:part(Vector3.new(x, 0.03, PLATFORM_Z - 2.4), Vector3.new(6, 0.06, 3), { Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Neon, Transparency = 0.35, Parent = "Decor", CanCollide = false, Name = "DoorGlow", Light = { Range = 12, Brightness = 0.8, Color = Color3.fromRGB(255, 200, 40) } })
	end

	-- departure board on the track wall, above the train
	local board = B:sign(Vector3.new(0, 12.5, z1 - 0.45), Vector3.new(16, 5, 0.5), "NEXT TRAIN\nBoarding now", {
		Name = "DepartureBoard",
		Color = C.black,
		TextColor = Color3.fromRGB(255, 170, 40),
		Face = Enum.NormalId.Front,
		Font = Enum.Font.Arcade,
	})
	board.Parent = model

	-- left wall: the most-stops board
	local wins = B:sign(Vector3.new(x0 + 0.35, 9, -6), Vector3.new(0.3, 9, 14), "MOST STOPS", {
		Name = "WinsBoard",
		Color = Color3.fromRGB(25, 25, 28),
		Face = Enum.NormalId.Right,
		Font = Enum.Font.GothamBold,
		TextColor = Color3.fromRGB(240, 200, 60),
		PPS = 30,
	})
	wins.Parent = model

	-- the crew
	for _, c in CREW do
		local fig = LH.figure(B, c[2], { Name = "Crew_" .. c[1], Shirt = C.tileBlue, Avatar = c[1], Label = c[1], Parent = model })
		fig:PivotTo(fig:GetPivot() * CFrame.Angles(0, math.rad(c[3]), 0))
	end
	-- a couple of regulars waiting on the platform
	local n1 = LH.npc(B, Vector3.new(-28, 0, 12), "noob", 180, { Parent = model })
	n1:SetAttribute("Anim", "idle")
	local n2 = LH.npc(B, Vector3.new(16, 0, 11), "guest", 160, { Parent = model })
	n2:SetAttribute("Anim", "idle")

	model.Parent = workspace
	return model
end
