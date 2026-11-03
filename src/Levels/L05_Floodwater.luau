-- Floodwater (medium): a water main has burst in the old pump hall and it is
-- filling up. Climb out before the water reaches you: crates, a piston lift,
-- a shuttle across the hall, a ladder, a second piston, then the exit at the
-- top. Touch the water and you're out.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D, HGT = 60, 70, 66
local EXIT_Y = 46
local WATER_START, WATER_END = -1, EXIT_Y - 6
local STEEL = Color3.fromRGB(90, 96, 104)
local YELLOW = Color3.fromRGB(235, 190, 40)

return {
	Order = 5,
	Name = "Floodwater",
	Mode = "escape",
	TimeLimit = 90,
	Ambience = { { "waterRush", 0.5 } },
	-- the tall pale hall washed out completely; pull the exposure down
	Lighting = { ExposureCompensation = -0.5 },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = HGT,
			wallColor = Color3.fromRGB(150, 160, 154),
			wallMat = Enum.Material.Concrete,
			lowerColor = Color3.fromRGB(40, 100, 90),
			trim = Color3.fromRGB(240, 240, 240),
			floorColor = Color3.fromRGB(150, 150, 146),
			lampColor = Color3.fromRGB(240, 248, 255),
			brightness = 0.85,
			exit = { x = 0, y = EXIT_Y },
		})
		B:checkpoint(Vector3.new(0, 0.1, 6), Vector3.new(7, 0.2, 5))
		local function plat(x, y, z, sx, sz, props)
			props = props or {}
			props.Color = props.Color or STEEL
			props.Material = props.Material or Enum.Material.DiamondPlate
			props.Name = props.Name or "Platform"
			return B:part(Vector3.new(x, y - 0.5, z), Vector3.new(sx, 1, sz), props)
		end
		-- 1. stacked crates up to the first piston (left side)
		for i, c in { { -22, 2.2, 14 }, { -22, 4.4, 20 }, { -16, 6.6, 24 } } do
			B:part(Vector3.new(c[1], c[2] / 2, c[3]), Vector3.new(5, c[2], 5), { Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.WoodPlanks, Name = "Crate" .. i })
		end
		-- 2. piston lift: carries you from crate height up to the left ledge
		local piston = Instance.new("Model")
		piston.Name = "PistonA"
		local top = plat(-8, 6.6, 28, 6, 6, { Color = YELLOW, Parent = B.model, Name = "PistonTop" })
		top.Parent = piston
		local shaft = B:cyl(Vector3.new(-8, -1, 28), 13, 2.2, "Y", { Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Parent = B.model, CanCollide = false, Name = "Shaft" })
		shaft.Parent = piston
		piston.PrimaryPart = top
		piston:SetAttribute("MoveFrom", B:w(Vector3.new(-8, 6.1, 28)))
		piston:SetAttribute("MoveTo", B:w(Vector3.new(-8, 16.1, 28)))
		piston:SetAttribute("Speed", 4)
		piston:SetAttribute("Pause", 1.6)
		piston.Parent = B:folder("Structure")
		-- 3. left ledge along the wall
		plat(-24, 16.6, 34, 12, 20, { Name = "LedgeL" })
		B:checkpoint(Vector3.new(-24, 16.7, 30), Vector3.new(6, 0.2, 5))
		-- 4. shuttle platform across the hall to the right ledge
		plat(-12, 16.6, 50, 7, 7, { Color = YELLOW, Name = "Shuttle", Move = Vector3.new(12, 16.6, 50), Speed = 5, Pause = 1.4 })
		B:part(Vector3.new(0, 26, 50), Vector3.new(36, 0.8, 1.2), { Color = STEEL, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "ShuttleRail" })
		plat(24, 16.6, 47, 12, 20, { Name = "LedgeR" })
		-- 5. ladder (truss) up to the upper walkway
		B:truss(Vector3.new(27, 16.6, 37.9), 10.4)
		plat(22, 27, 30, 16, 14, { Name = "Upper" })
		B:checkpoint(Vector3.new(22, 27.1, 30), Vector3.new(6, 0.2, 5))
		-- 6. step platforms back across, then the second piston
		for i, s in { { 10, 29, 26 }, { 0, 31, 24 }, { -10, 33, 28 } } do
			plat(s[1], s[2], s[3], 6, 6, { Name = "Step" .. i })
		end
		local pistonB = Instance.new("Model")
		pistonB.Name = "PistonB"
		local topB = plat(-12, 33, 40, 6, 6, { Color = YELLOW, Parent = B.model, Name = "PistonTop" })
		topB.Parent = pistonB
		local shaftB = B:cyl(Vector3.new(-12, 20, 40), 26, 2.2, "Y", { Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Parent = B.model, CanCollide = false, Name = "Shaft" })
		shaftB.Parent = pistonB
		pistonB.PrimaryPart = topB
		pistonB:SetAttribute("MoveFrom", B:w(Vector3.new(-12, 32.5, 40)))
		pistonB:SetAttribute("MoveTo", B:w(Vector3.new(-12, 45.5, 40)))
		pistonB:SetAttribute("Speed", 4)
		pistonB:SetAttribute("Pause", 1.6)
		pistonB.Parent = B:folder("Structure")
		-- 7. top gantry to the exit
		plat(-10, EXIT_Y, 57, 40, 26, { Name = "TopGantry" })
		-- burst main gushing water (left wall)
		local pipe = B:cyl(Vector3.new(-W / 2 + 2, 12, 60), 4, 3, "X", { Color = Color3.fromRGB(110, 70, 50), Material = Enum.Material.CorrodedMetal, Name = "BurstMain" })
		local gush = Instance.new("ParticleEmitter")
		gush.Texture = "rbxasset://textures/particles/smoke_main.dds"
		gush.Color = ColorSequence.new(Color3.fromRGB(180, 220, 240))
		gush.EmissionDirection = Enum.NormalId.Right
		gush.Rate = 80
		gush.Speed = NumberRange.new(18, 24)
		gush.Acceleration = Vector3.new(0, -40, 0)
		gush.Lifetime = NumberRange.new(0.8, 1.2)
		gush.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 3.5) })
		gush.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		gush.Parent = pipe
		-- big pumps along the right wall (decor)
		for _, z in { 12, 26 } do
			B:cyl(Vector3.new(W / 2 - 4, 4.1, z), 8, 6, "Y", { Color = Color3.fromRGB(40, 90, 140), Material = Enum.Material.Metal, Name = "Pump" })
			-- cap overlaps the drum's top so no two faces share a plane
			B:cyl(Vector3.new(W / 2 - 4, 8.3, z), 0.8, 6.6, "Y", { Color = STEEL, Parent = "Decor", CanCollide = false })
		end
		Decor.pipe(B, Vector3.new(W / 2 - 1, 9, 6), Vector3.new(W / 2 - 1, 9, D - 6), 1.4, Color3.fromRGB(40, 90, 140))
		-- pendant lamps hanging over the middle of the hall, so the climb in
		-- the centre is as well lit as the walls
		for _, spec in { { -6, 22 }, { 8, 40 }, { -4, 56 } } do
			local x, z = spec[1], spec[2]
			B:part(Vector3.new(x, (HGT + 55.6) / 2, z), Vector3.new(0.2, HGT - 55.6, 0.2), { Color = C.black, Parent = "Decor", CanCollide = false, Name = "LampChain" })
			B:cyl(Vector3.new(x, 55, z), 1.2, 3.6, "Y", { Color = Color3.fromRGB(40, 90, 80), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "LampShade" })
			B:lamp(Vector3.new(x, 54.3, z), Vector3.new(2.4, 0.2, 2.4), { Color = Color3.fromRGB(255, 240, 215), Range = 50, Brightness = 0.55, Face = Enum.NormalId.Bottom, Angle = 150 })
		end
		-- the water itself, with a foamy surface
		B:part(Vector3.new(0, WATER_START - 25, D / 2), Vector3.new(W, 50, D), {
			Name = "Water",
			-- murky flood water: matte, slightly see-through, not mirror-shiny
			Color = Color3.fromRGB(62, 104, 110),
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.3,
			CanCollide = false,
			CastShadow = false,
			Deadly = true,
			Parent = B.model,
		})
		B:part(Vector3.new(0, WATER_START + 0.05, D / 2), Vector3.new(W, 0.1, D), {
			Name = "Foam",
			Color = Color3.fromRGB(200, 214, 210),
			Material = Enum.Material.Sand,
			Transparency = 0.82,
			CanCollide = false,
			CastShadow = false,
			Parent = B.model,
		})
	end,
	Run = function(ctx)
		local level = ctx.level
		local water, foam = level.Water, level.Foam
		local wBase, fBase = water.CFrame, foam.CFrame
		ctx:waitForStart()
		ctx:broadcast("The water's rising! Climb!")
		local t0 = os.clock()
		ctx:heartbeat(function()
			local frac = math.clamp((os.clock() - t0 - 4) / (ctx.timeLimit - 10), 0, 1)
			local rise = (WATER_END - WATER_START) * frac
			local bob = math.sin(os.clock() * 1.7) * 0.15
			water.CFrame = wBase + Vector3.new(0, rise + bob, 0)
			foam.CFrame = fBase + Vector3.new(0, rise + bob, 0)
		end)
	end,
}
