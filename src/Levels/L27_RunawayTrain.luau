-- Runaway Train (medium): the door opens into the side of a long tunnel.
-- Down to the left, a train's headlight sits in the dark. The alarm lights go
-- red and it starts coming - run right, vault the barriers and get through the
-- EXIT door at the far end before it catches you. It stops just short of it.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local TrainKit = require(root.TrainKit)
local Audio = require(root.Audio)
local C = BuildLib.C

local X0, LEN = -90, 360 -- the tunnel runs along X from X0 to X0 + LEN
local D = 26
local EXIT_X = 250
local START_X = -80 -- train centre at the start (front ~18 studs left of the door)
local STOP_X = EXIT_X - 14 - 62 -- train centre when it stops (front short of the exit)
local BRICK = Color3.fromRGB(120, 78, 62)

return {
	Order = 27,
	Name = "Runaway Train",
	Mode = "escape",
	TimeLimit = 70,
	Ambience = { { "trainRumble", 0.2 } },
	Build = function(B)
		B:room({
			W = LEN,
			x0 = X0,
			D = D,
			H = 22,
			wallColor = BRICK,
			wallMat = Enum.Material.Brick,
			lowerColor = Color3.fromRGB(70, 66, 62),
			trim = Color3.fromRGB(230, 180, 40),
			floorColor = Color3.fromRGB(80, 76, 70),
			floorMat = Enum.Material.Pebble,
			brightness = 0.8,
			lampStep = 20,
			beams = false,
			sideHoles = { { side = -1, 1, D, -0.01, 20 } },
			exit = { x = EXIT_X, y = 0 },
		})
		B:recess(-1, (1 + D) / 2, D - 1, 20, 70)
		B:checkpoint(Vector3.new(0, 0.1, 5), Vector3.new(6, 0.2, 4))
		Decor.track(B, Vector3.new(X0 - 70, 0.3, D / 2), Vector3.new(X0 + LEN, 0.3, D / 2), false)
		-- the tunnel mouth at the left end, where the train waits
		local train = TrainKit.shell(B, Vector3.new(START_X, 0.3, D / 2), { Name = "Runaway", Deadly = true, Parent = "Structure" })
		if train then
			-- big headlight on the front
			local front = B:part(Vector3.new(START_X + 61.8, 6, D / 2), Vector3.new(0.4, 2.6, 8), {
				Name = "Headlight",
				Color = Color3.fromRGB(255, 250, 220),
				Material = Enum.Material.Neon,
				Parent = B.model,
				CanCollide = false,
				Light = { Kind = "SpotLight", Face = Enum.NormalId.Right, Range = 60, Brightness = 6, Angle = 70, Color = Color3.fromRGB(255, 250, 220) },
			})
			local w = Instance.new("WeldConstraint")
			w.Part0 = train.PrimaryPart
			w.Part1 = front
			w.Parent = front
			front.Anchored = false
			front.Parent = train
		end
		-- obstacles between you and the exit
		local x = 18
		local k = 0
		while x < EXIT_X - 22 do
			k += 1
			local kind = k % 5
			if kind == 1 then
				-- a barrier to vault
				B:span(Vector3.new(x, 0, 1), Vector3.new(x + 1.2, 2.4, D), { Name = "Barrier", Color = Color3.fromRGB(230, 180, 40), Material = Enum.Material.SmoothPlastic })
				for z = 2, D - 2, 4 do
					B:part(Vector3.new(x + 0.6, 2.45, z), Vector3.new(1.25, 0.1, 2), { Color = C.black, Parent = "Decor", CanCollide = false })
				end
			elseif kind == 2 then
				-- a half wall: go round the gap
				local side = (k // 3) % 2 == 0 and 1 or -1
				local z0, z1 = side > 0 and 1 or 9, side > 0 and D - 8 or D
				B:span(Vector3.new(x, 0, z0), Vector3.new(x + 1.5, 14, z1), { Name = "HalfWall", Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Concrete })
			elseif kind == 3 then
				-- a crate stack wall: climb up the steps and over
				B:span(Vector3.new(x, 0, 1), Vector3.new(x + 3, 6.5, D), { Name = "Barrier", Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.WoodPlanks })
				for z = 3, D - 3, 6 do
					B:crate(Vector3.new(x - 2, 0, z), 3)
				end
			elseif kind == 4 then
				-- a wall with one narrow gap, somewhere different each time
				local gz = 4 + ((k * 7) % (D - 8))
				B:span(Vector3.new(x, 0, 1), Vector3.new(x + 1.5, 14, gz - 1.6), { Name = "HalfWall", Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Concrete })
				B:span(Vector3.new(x, 0, gz + 1.6), Vector3.new(x + 1.5, 14, D), { Name = "HalfWall", Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Concrete })
				B:part(Vector3.new(x - 0.05, 7, gz), Vector3.new(0.1, 14, 3.2), { Color = Color3.fromRGB(240, 190, 40), Parent = "Structure", CanCollide = false, Name = "HalfWall", Transparency = 0.6 })
			else
				-- a trolley parked on the line, and crates
				B:span(Vector3.new(x - 3, 0, 8), Vector3.new(x + 3, 3, 18), { Name = "Trolley", Color = Color3.fromRGB(70, 90, 140), Material = Enum.Material.Metal })
				B:crate(Vector3.new(x, 0, 4), 3)
			end
			x += 20
		end
		-- alarm beacons along both walls (flash red once the train starts)
		for bx = X0 + 20, X0 + LEN - 10, 30 do
			for _, z in { 1.4, D - 0.4 } do
				B:part(Vector3.new(bx, 14, z), Vector3.new(1, 1, 0.6), { Name = "Beacon", Color = Color3.fromRGB(80, 30, 30), Material = Enum.Material.SmoothPlastic, Parent = "Beacons", CanCollide = false, Light = { Range = 18, Brightness = 0, Color = Color3.fromRGB(255, 40, 30) } })
			end
		end
		for bx = X0 + 10, X0 + LEN - 10, 24 do
			Decor.pipe(B, Vector3.new(bx, 18, 1.4), Vector3.new(bx + 20, 18, 1.4), 0.5, C.black)
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local train = level.Structure:FindFirstChild("Runaway")
		local beacons = level.Beacons:GetChildren()
		if not train then
			return
		end
		local base = train:GetPivot()
		local startX = base.Position.X
		local stopX = ctx.origin.X + STOP_X
		local launched = false
		local first
		ctx.def.OnEnter = function()
			first = first or ctx:elapsed()
		end
		-- alarm lights
		ctx:every(0.35, function()
			if not launched then
				return
			end
			local on = math.floor(os.clock() * 3) % 2 == 0
			for _, b in beacons do
				b.Color = on and Color3.fromRGB(255, 40, 30) or Color3.fromRGB(80, 30, 30)
				b.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
				b:FindFirstChildWhichIsA("Light").Brightness = on and 2 or 0
			end
		end)
		local x = startX
		-- obstacles in order along the tunnel
		local obstacles = {}
		for _, p in level.Structure:GetChildren() do
			if p:IsA("BasePart") and (p.Name == "Barrier" or p.Name == "HalfWall" or p.Name == "Trolley" or p.Name == "Crate") then
				table.insert(obstacles, { x = p.Position.X - p.Size.X / 2, parts = { p } })
			end
		end
		table.sort(obstacles, function(a, b)
			return a.x < b.x
		end)
		ctx:waitForStart()
		task.wait(1)
		ctx:broadcast("A train is coming! RUN for the exit!")
		task.wait(3)
		launched = true
		Audio.play(train.PrimaryPart, "trainHorn", 1, 400)
		Audio.loop(train.PrimaryPart, "trainRumble", 1, 160)
		local t0 = os.clock()
		ctx:heartbeat(function(dt)
			if x < stopX then
				local speed = 10 + 3.5 * math.clamp((os.clock() - t0) / 20, 0, 1)
				x = math.min(stopX, x + speed * dt)
				train:PivotTo(CFrame.new(x, base.Position.Y, base.Position.Z) * base.Rotation)
				-- it smashes through whatever is in its way
				local front = x + 61.5
				while obstacles[1] and obstacles[1].x < front do
					local o = table.remove(obstacles, 1)
					for _, p in o.parts do
						p.Anchored = false
						p.CanCollide = false
						p.AssemblyLinearVelocity = Vector3.new(30, 25, math.random(-15, 15))
						task.delay(3, function()
							p:Destroy()
						end)
					end
					Audio.play(o.parts[1].Position, "drum", 1, 120)
				end
			end
		end)
	end,
}
