-- Boiler Room: the station's old boiler hall has flooded with molten slag.
-- Stepping stones, a shuttle lift, pistons rising out of the lava and a
-- catwalk swept by steam jets.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local C = BuildLib.C

local W, D = 44, 136
local IRON = Color3.fromRGB(62, 58, 56)
local COPPER = Color3.fromRGB(150, 90, 50)

-- steam jets: pipe on the right wall blowing across the catwalk at these z
local JETS = { 100, 108 }

local function boiler(B, x, z)
	-- a big riveted boiler drum lying along Z on a brick plinth, with a flue
	B:span(Vector3.new(x - 4, -6, z - 7), Vector3.new(x + 4, 3, z + 7), { Color = Color3.fromRGB(110, 60, 45), Material = Enum.Material.Brick, Name = "BoilerPlinth" })
	B:cyl(Vector3.new(x, 7, z), 14, 8, "Z", { Color = IRON, Material = Enum.Material.CorrodedMetal, Name = "Boiler" })
	for dz = -5, 5, 5 do
		B:cyl(Vector3.new(x, 7, z + dz), 0.4, 8.3, "Z", { Color = Color3.fromRGB(40, 38, 36), Material = Enum.Material.Metal, Parent = "Decor", Name = "Band", CanCollide = false })
	end
	B:cyl(Vector3.new(x, 7, z - 7.05), 0.2, 5, "Z", { Color = Color3.fromRGB(40, 38, 36), Parent = "Decor", CanCollide = false, Name = "Hatch" })
	-- firebox glow under the front hatch
	B:part(Vector3.new(x, 4.2, z - 7.15), Vector3.new(3, 1.2, 0.1), { Color = Color3.fromRGB(255, 120, 30), Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false, Name = "FireboxGlow", Light = { Range = 12, Brightness = 1.2, Color = Color3.fromRGB(255, 120, 40) } })
	-- flue up to the ceiling header
	B:cyl(Vector3.new(x, 18, z + 3), 14, 1.8, "Y", { Color = IRON, Material = Enum.Material.CorrodedMetal, Parent = "Decor", CanCollide = false, Name = "Flue" })
	-- pressure gauge
	B:cyl(Vector3.new(x + (x < 0 and 4.05 or -4.05), 9, z - 3), 0.2, 1.4, "X", { Color = C.white, Parent = "Decor", CanCollide = false, Name = "Gauge" })
end

return {
	Order = 16,
	Name = "Boiler Room",
	Mode = "escape",
	TimeLimit = 110,
	Ambience = { { "boiler", 0.45 }, { "lavaBubbles", 0.35 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 28,
			floor = false,
			bottom = -24,
			wallColor = Color3.fromRGB(120, 70, 55),
			wallMat = Enum.Material.Brick,
			lowerColor = Color3.fromRGB(60, 50, 46),
			trim = COPPER,
			lampColor = Color3.fromRGB(255, 190, 130),
			brightness = 1.1,
			lampStep = 16,
			exit = { x = 0, y = 7 },
		})
		local metal = { Color = Color3.fromRGB(80, 78, 76), Material = Enum.Material.DiamondPlate, Name = "Platform" }
		local function plat(x, y, z, sx, sz, extra)
			local props = table.clone(metal)
			for k, v in extra or {} do
				props[k] = v
			end
			return B:part(Vector3.new(x, y - 0.5, z), Vector3.new(sx, 1, sz), props)
		end
		-- the lava
		B:part(Vector3.new(0, -5.2, D / 2), Vector3.new(W, 2, D), {
			Name = "Lava",
			Color = Color3.fromRGB(255, 100, 20),
			Material = Enum.Material.Neon,
			Hazard = true,
			Parent = B.model,
			Light = { Range = 30, Brightness = 1, Color = Color3.fromRGB(255, 110, 40) },
		})
		-- a crust of cooling rock drifting on top of the glow
		B:part(Vector3.new(0, -4.15, D / 2), Vector3.new(W, 0.1, D), { Name = "Crust", Color = Color3.fromRGB(200, 70, 20), Material = Enum.Material.CrackedLava, Transparency = 0.45, CanCollide = false, CastShadow = false, Parent = "Decor" })
		-- boilers stand in the lava along both walls
		for _, z in { 30, 62, 94 } do
			boiler(B, -W / 2 + 5, z)
		end
		for _, z in { 46, 78 } do
			boiler(B, W / 2 - 5, z)
		end
		-- steam header pipe along the ceiling, the flues join it
		B:cyl(Vector3.new(-W / 2 + 5, 25, D / 2), D - 2, 2.2, "Z", { Color = IRON, Material = Enum.Material.CorrodedMetal, Parent = "Decor", CanCollide = false, Name = "Header" })
		B:cyl(Vector3.new(W / 2 - 5, 25, D / 2), D - 2, 2.2, "Z", { Color = IRON, Material = Enum.Material.CorrodedMetal, Parent = "Decor", CanCollide = false, Name = "Header" })
		Decor.pipe(B, Vector3.new(-W / 2 + 1, 12, 2), Vector3.new(-W / 2 + 1, 12, D - 2), 1, COPPER)

		-- start
		plat(0, 0, 5.5, W, 9)
		B:checkpoint(Vector3.new(0, 0.1, 5.5), Vector3.new(7, 0.2, 5))
		-- stepping stones (old slag-crusted pier caps)
		for i, s in { { -6, 15 }, { 4, 21 }, { -4, 27 }, { 6, 33 } } do
			plat(s[1], i * 0.4, s[2], 4, 4, { Color = Color3.fromRGB(60, 56, 54), Material = Enum.Material.Basalt })
			B:part(Vector3.new(s[1], i * 0.4 - 5, s[2]), Vector3.new(3, 8, 3), { Color = Color3.fromRGB(50, 46, 44), Material = Enum.Material.Basalt, Name = "Pier" })
		end
		plat(0, 1.6, 42, 16, 8)
		B:checkpoint(Vector3.new(0, 1.7, 42), Vector3.new(7, 0.2, 5))
		-- shuttle lift on a rail
		plat(0, 1.6, 50, 7, 7, { Move = Vector3.new(0, 1.1, 62), Speed = 5, Pause = 1.4, Color = Color3.fromRGB(200, 160, 40), Name = "Lift" })
		-- the lift runs between two I-beam rails on posts, with buffers at each end
		for _, x in { -4.1, 4.1 } do
			B:part(Vector3.new(x, 0.6, 56.5), Vector3.new(0.6, 0.8, 21), { Color = Color3.fromRGB(60, 62, 66), Material = Enum.Material.Metal, Name = "LiftRail" })
			for _, z in { 48, 56.5, 65 } do
				B:part(Vector3.new(x, -2, z), Vector3.new(0.5, 5, 0.5), { Color = Color3.fromRGB(60, 62, 66), Material = Enum.Material.Metal, Name = "RailPost" })
			end
			for _, z in { 46.6, 66.4 } do
				B:part(Vector3.new(x, 1.3, z), Vector3.new(0.8, 0.8, 0.4), { Color = C.yellow, Parent = "Decor", CanCollide = false, Name = "Buffer" })
			end
		end
		plat(0, 1.6, 68.5, 8, 4)
		-- pistons rising out of the lava, out of step with each other
		for i, z in { 75, 81, 87 } do
			local x = ({ -3, 3, -1 })[i]
			local piston = Instance.new("Model")
			piston.Name = "Piston"
			local top = plat(x, 1.6, z, 5, 5, { Color = C.darkSteel, Name = "PistonTop" })
			top.Parent = piston
			local shaft = B:cyl(Vector3.new(x, -4.1, z), 10, 2, "Y", { Color = Color3.fromRGB(170, 170, 170), Material = Enum.Material.Metal, Name = "PistonShaft", CanCollide = false })
			shaft.Parent = piston
			piston.PrimaryPart = top
			piston:SetAttribute("MoveFrom", B:w(Vector3.new(x, 1.1, z)))
			piston:SetAttribute("MoveTo", B:w(Vector3.new(x, -4.6, z)))
			piston:SetAttribute("Speed", 3)
			piston:SetAttribute("Pause", 1.5)
			piston:SetAttribute("Phase", (i - 1) / 3)
			piston.Parent = B:folder("Structure")
		end
		plat(0, 1.6, 93, 8, 4)
		-- steam-swept catwalk
		plat(0, 1.6, 104, 4.5, 18, { Name = "Catwalk", Color = Color3.fromRGB(90, 88, 84) })
		for _, x in { -2.35, 2.35 } do
			B:part(Vector3.new(x, 1.75, 104), Vector3.new(0.2, 0.3, 18), { Color = C.yellow, Parent = "Decor", CanCollide = false, Name = "KickPlate" })
		end
		for i, z in JETS do
			-- the pipe the steam comes out of, sticking out of the right wall
			B:cyl(Vector3.new(W / 2 - 4, 3, z), 8, 1.4, "X", { Color = COPPER, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "SteamPipe" })
			B:cyl(Vector3.new(W / 2 - 8.1, 3, z), 0.3, 1.8, "X", { Color = IRON, Parent = "Decor", CanCollide = false, Name = "Nozzle" .. i })
			local emitterPart = B:part(Vector3.new(W / 2 - 8.4, 3, z), Vector3.new(0.2, 1.4, 1.4), { Name = "Jet" .. i, Transparency = 1, CanCollide = false, Parent = "Steam" })
			local steam = Instance.new("ParticleEmitter")
			steam.Name = "Steam"
			steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
			steam.EmissionDirection = Enum.NormalId.Left
			steam.Speed = NumberRange.new(26, 34)
			steam.Lifetime = NumberRange.new(0.5, 0.8)
			steam.Rate = 0
			steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 5) })
			steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
			steam.SpreadAngle = Vector2.new(8, 8)
			steam.Parent = emitterPart
			-- the hazard volume the steam fills while it's on
			B:part(Vector3.new(0, 3, z), Vector3.new(14, 4, 2.4), { Name = "SteamZone" .. i, Transparency = 1, CanCollide = false, Parent = "Steam" })
		end
		plat(0, 1.6, 116, 14, 6)
		B:checkpoint(Vector3.new(0, 1.7, 116), Vector3.new(7, 0.2, 4))
		-- steps up to the exit gantry
		for i, s in { { -4, 122 }, { 3, 126 } } do
			plat(s[1], 1.6 + i * 2.4, s[2], 4, 3.5)
		end
		plat(0, 7, 132.5, W, 7)
	end,
	Run = function(ctx)
		local level = ctx.level
		local jets = {}
		for i in JETS do
			jets[i] = {
				emitter = level.Steam["Jet" .. i].Steam,
				zone = level.Steam["SteamZone" .. i],
				nozzle = level.Decor["Nozzle" .. i],
			}
		end
		-- each jet: 2.2s off (nozzle turns orange 0.8s before), then 1.2s of steam
		local OFF, ON = 2.2, 1.2
		ctx:heartbeat(function()
			local t = os.clock()
			for i, j in jets do
				local cyc = (t + (i - 1) * (OFF + ON) / 2) % (OFF + ON)
				local on = cyc >= OFF
				local warn = not on and cyc > OFF - 0.8
				j.emitter.Rate = on and 90 or (warn and 6 or 0)
				j.nozzle.Color = on and C.white or (warn and C.orange or Color3.fromRGB(62, 58, 56))
				if (ctx.hazards[j.zone] ~= nil) ~= on then
					ctx:setHazard(j.zone, on)
				end
			end
		end)
	end,
}
