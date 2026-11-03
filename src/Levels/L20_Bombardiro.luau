-- Bombardiro Crocodilo (medium, survive): an open-air country station, and a
-- crocodile bomber plane is making runs overhead. Red circles show where its
-- bombs will land - keep out of them until the train comes back.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Kit = require(root.LevelKit)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local TrainKit = require(root.TrainKit)
local C = BuildLib.C

local CROC = Color3.fromRGB(70, 130, 60)
local ALT = 46
local W, D = 130, 124
local PLATFORM = Color3.fromRGB(176, 172, 164)
local GREEN = Color3.fromRGB(50, 100, 70)

local function buildPlane(B, pos)
	local m = Instance.new("Model")
	m.Name = "Bombardiro"
	local function add(offset, size, color, props)
		props = props or {}
		props.Color = color
		props.Parent = B.model
		props.CanCollide = false
		local p = B:part(pos + offset, size, props)
		p.Parent = m
		return p
	end
	local body = add(Vector3.new(0, 0, 0), Vector3.new(22, 4, 4.5), CROC, { Name = "Body", Material = Enum.Material.Slate })
	add(Vector3.new(13, -0.4, 0), Vector3.new(6, 2, 3.5), CROC, { Name = "Snout" })
	for z = -1.2, 1.2, 0.8 do
		add(Vector3.new(12.5, -1.5, z), Vector3.new(0.4, 0.6, 0.4), C.white, { Name = "Tooth" })
	end
	for _, z in { -1.2, 1.2 } do
		add(Vector3.new(8, 2.1, z), Vector3.new(1.2, 1.2, 1.2), C.yellow, { Name = "Eye", Shape = Enum.PartType.Ball })
	end
	add(Vector3.new(1, 0.5, 0), Vector3.new(7, 0.6, 30), C.steel, { Name = "Wing", Material = Enum.Material.Metal })
	add(Vector3.new(-11, 1.5, 0), Vector3.new(3, 5, 0.6), CROC, { Name = "Tail" })
	add(Vector3.new(-11, 0.5, 0), Vector3.new(3, 0.5, 10), C.steel, { Name = "TailWing" })
	for _, z in { -8, 8 } do
		add(Vector3.new(4.5, 0.5, z), Vector3.new(0.3, 5, 1), C.darkSteel, { Name = "Propeller" })
		add(Vector3.new(3, 0.5, z), Vector3.new(3, 2, 2), C.darkSteel, { Name = "Engine" })
	end
	add(Vector3.new(0, -2.6, 0), Vector3.new(6, 1.2, 1.2), C.red, { Name = "BombBay" })
	m.PrimaryPart = body
	m.Parent = B.model
	return m
end

return {
	Order = 20,
	Name = "Bombardiro Crocodilo",
	Mode = "survive",
	TimeLimit = 60,
	Ambience = { { "birds", 0.35 } },
	Build = function(B)
		B:room({ W = W, D = D, outdoor = true, pitsZ = { { 52, 76, 4 } }, exit = false })
		-- platforms either side of the cutting
		B:span(Vector3.new(-56, -0.2, 6), Vector3.new(56, 0.6, 52), { Name = "NearPlatform", Color = PLATFORM, Material = Enum.Material.Concrete })
		B:span(Vector3.new(-56, -0.2, 76), Vector3.new(56, 0.6, 114), { Name = "FarPlatform", Color = PLATFORM, Material = Enum.Material.Concrete })
		B:span(Vector3.new(-B.DOOR_W / 2 - 1, -0.2, 1), Vector3.new(B.DOOR_W / 2 + 1, 0.6, 6), { Name = "Path", Color = PLATFORM, Material = Enum.Material.Concrete })
		for _, z in { 51.4, 76.6 } do
			B:part(Vector3.new(0, 0.62, z), Vector3.new(112, 0.04, 1.2), { Color = C.yellow, Parent = "Decor", CanCollide = false, Name = "EdgeLine" })
		end
		Decor.track(B, Vector3.new(-W / 2 - 200, -4, 58), Vector3.new(W / 2 + 200, -4, 58), false)
		Decor.track(B, Vector3.new(-W / 2 - 200, -4, 70), Vector3.new(W / 2 + 200, -4, 70), false)
		-- express trains whizz through on both lines (deadly if you're down there)
		for i, z in { 58, 70 } do
			local dir = i == 1 and 1 or -1
			local train = TrainKit.shell(B, Vector3.new(-dir * (W / 2 + 160), -4, z), { Name = "Express" .. i, Deadly = true, Parent = "Trains", flip = dir < 0 })
			if train then
				train:SetAttribute("MoveFrom", train:GetPivot().Position)
				train:SetAttribute("MoveTo", B:w(Vector3.new(dir * (W / 2 + 160), -4, z)))
				train:SetAttribute("Speed", 110)
				train:SetAttribute("Pause", 5 + i * 1.5)
				train:SetAttribute("Phase", i * 0.31)
			end
		end
		-- canopies: tall green posts with glass roofs
		for _, spec in { { 14, 46 }, { 82, 104 } } do
			for x = -50, 26, 15 do
				for _, z in { spec[1] + 3, spec[2] - 3 } do
					B:part(Vector3.new(x, 0.6 + 6.5, z), Vector3.new(0.8, 13, 0.8), { Color = GREEN, Material = Enum.Material.Metal, Name = "CanopyPost" })
				end
			end
			B:span(Vector3.new(-54, 13.6, spec[1]), Vector3.new(30, 14, spec[2]), { Name = "CanopyGlass", Color = Color3.fromRGB(180, 210, 220), Material = Enum.Material.Glass, Transparency = 0.6, CanCollide = false, CastShadow = false })
			for x = -50, 26, 15 do
				B:part(Vector3.new(x, 13.3, (spec[1] + spec[2]) / 2), Vector3.new(0.6, 0.6, spec[2] - spec[1]), { Color = GREEN, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "Rafter" })
			end
		end
		-- the platform clock, on its own post
		B:part(Vector3.new(-8, 4.6, 30), Vector3.new(0.6, 8, 0.6), { Color = GREEN, Material = Enum.Material.Metal, Name = "ClockPost" })
		Decor.clock(B, Vector3.new(-8, 9.6, 29.7), "-Z")
		Decor.clock(B, Vector3.new(-8, 9.6, 30.3), "+Z")
		-- benches, bins, lamp posts
		for _, x in { -42, -28, -14, 10 } do
			Decor.bench(B, Vector3.new(x, 0.6, 36), 0)
			Decor.bench(B, Vector3.new(x, 0.6, 92), 180)
		end
		for _, pos in { Vector3.new(18, 0.6, 30), Vector3.new(18, 0.6, 96) } do
			Decor.bin(B, pos)
		end
		for _, z in { 22, 100 } do
			for _, x in { -54, 54 } do
				B:part(Vector3.new(x, 0.6 + 6, z), Vector3.new(0.5, 12, 0.5), { Color = GREEN, Material = Enum.Material.Metal, Name = "LampPost" })
				B:lamp(Vector3.new(x, 12.9, z), Vector3.new(1.4, 1, 1.4), { Color = Color3.fromRGB(255, 230, 190), Range = 24, Brightness = 1, Glow = true })
			end
		end
		-- the station building on the far platform
		B:span(Vector3.new(-50, 0.6, 106), Vector3.new(30, 16, 114), { Name = "StationBuilding", Color = Color3.fromRGB(160, 96, 72), Material = Enum.Material.Brick })
		B:span(Vector3.new(-51, 16, 105), Vector3.new(31, 17.4, 115), { Name = "Cornice", Color = Color3.fromRGB(210, 206, 196), Material = Enum.Material.Concrete })
		for x = -44, 24, 8 do
			B:part(Vector3.new(x, 8, 105.9), Vector3.new(3.4, 5, 0.2), { Color = Color3.fromRGB(50, 66, 84), Material = Enum.Material.Glass, Parent = "Decor", CanCollide = false, Name = "Window" })
			B:part(Vector3.new(x, 5.2, 105.8), Vector3.new(4, 0.4, 0.4), { Color = Color3.fromRGB(210, 206, 196), Parent = "Decor", CanCollide = false, Name = "Sill" })
		end
		-- fences along the platform ends (standing on the platform)
		for _, x in { -56, 56 } do
			for _, spec in { { 6, 52 }, { 76, 114 } } do
				B:span(Vector3.new(x - 0.2, 0.6, spec[1]), Vector3.new(x + 0.2, 4.6, spec[2]), { Name = "Fence", Color = GREEN, Material = Enum.Material.Metal })
			end
		end
		buildPlane(B, Vector3.new(-160, ALT, 60))
	end,
	Run = function(ctx)
		local level = ctx.level
		local plane = level.Bombardiro
		-- you hear the expresses coming
		for _, t in (level:FindFirstChild("Trains") and level.Trains:GetChildren() or {}) do
			if t.PrimaryPart then
				Audio.loop(t.PrimaryPart, "trainRumble", 0.8, 150)
			end
		end
		local floorY = ctx.origin.Y
		local passZ = ctx.origin.Z + 60
		local dirX = 1
		local x = ctx.origin.X - 180
		ctx:heartbeat(function(dt)
			x += dirX * 42 * dt
			if math.abs(x - ctx.origin.X) > 180 then
				dirX = -dirX
				passZ = ctx.origin.Z + math.random(12, 110)
				x = ctx.origin.X + math.sign(x - ctx.origin.X) * 179
			end
			local pos = Vector3.new(x, floorY + ALT + math.sin(os.clock() * 2) * 1.5, passZ)
			local face = dirX > 0 and 0 or math.pi
			plane:PivotTo(CFrame.new(pos) * CFrame.Angles(0, face, math.sin(os.clock() * 1.3) * 0.08))
		end)

		local function bomb(target)
			local marker = Instance.new("Part")
			marker.Shape = Enum.PartType.Cylinder
			marker.Anchored = true
			marker.CanCollide = false
			marker.CanQuery = false
			marker.Size = Vector3.new(0.2, 11, 11)
			marker.CFrame = CFrame.new(target + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
			marker.Color = C.red
			marker.Material = Enum.Material.Neon
			marker.Transparency = 0.45
			marker.Parent = level
			local b = Instance.new("Part")
			b.Shape = Enum.PartType.Ball
			b.Size = Vector3.new(2.4, 2.4, 2.4)
			b.Anchored = true
			b.CanCollide = false
			b.Color = C.black
			b.Parent = level
			local startY = floorY + ALT - 3
			local t0 = os.clock()
			local fall = 1.3
			while os.clock() - t0 < fall and not ctx.ended do
				local a = (os.clock() - t0) / fall
				b.Position = Vector3.new(target.X, startY + (target.Y - startY) * a * a, target.Z)
				task.wait()
			end
			b:Destroy()
			marker:Destroy()
			if ctx.ended then
				return
			end
			local boom = Instance.new("Part")
			boom.Shape = Enum.PartType.Ball
			boom.Size = Vector3.new(11, 11, 11)
			boom.Anchored = true
			boom.CanCollide = false
			boom.Color = C.orange
			boom.Material = Enum.Material.Neon
			boom.Transparency = 0.2
			boom.Position = target + Vector3.new(0, 1, 0)
			boom:SetAttribute("Hazard", true)
			boom.Parent = level
			Audio.play(boom.Position, "explosion", 0.9, 220)
			local ex = Instance.new("Explosion")
			ex.BlastPressure = 0
			ex.DestroyJointRadiusPercent = 0
			ex.BlastRadius = 5
			ex.Position = boom.Position
			ex.Parent = workspace
			for i = 1, 6 do
				task.wait(0.05)
				boom.Transparency = 0.2 + i * 0.13
			end
			boom:Destroy()
		end

		ctx:waitForStart()
		Audio.loop(plane.PrimaryPart, "propeller", 0.9, 220)
		task.wait(3)
		ctx:broadcast("Bombardiro Crocodilo incoming! Stay out of the red circles!")
		while not ctx.ended do
			local frac = math.clamp(ctx:elapsed() / ctx.timeLimit, 0, 1)
			local target
			local players = ctx:activeInside()
			if #players > 0 and math.random() < 0.65 then
				local r = Kit.rootOf(players[math.random(1, #players)])
				if r then
					target = Vector3.new(r.Position.X + math.random(-4, 4), r.Position.Y - 3, r.Position.Z + math.random(-4, 4))
				end
			end
			if not target then
				target = ctx:w(Vector3.new(math.random(-55, 55), 0.6, math.random(8, 110)))
			end
			task.spawn(bomb, target)
			task.wait(0.9 - 0.55 * frac)
		end
	end,
}
