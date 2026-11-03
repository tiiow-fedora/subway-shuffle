-- Train Wash (medium): the depot's automatic train wash, and you're walking
-- through it. Slip between the side brushes when they open, jump the floor
-- roller, time the spray arches (nozzles glow before they fire), and walk
-- round with the revolving brush gate. Brushes and spray knock you back.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 44, 140
local BLUE = Color3.fromRGB(40, 110, 200)
local YELLOW = Color3.fromRGB(240, 190, 40)
local GANTRY = Color3.fromRGB(70, 74, 82)

-- a vertical brush: a core with bristle slabs round it, built at local pos
local function brush(B, name, pos, h, color, folder)
	local m = Instance.new("Model")
	m.Name = name
	local core = B:cyl(pos + Vector3.new(0, h / 2, 0), h, 1.2, "Y", { Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Parent = B.model, Name = "Core", CanCollide = false })
	core.Parent = m
	for k = 0, 7 do
		local a = math.rad(k * 45)
		local slab = B:part(pos + Vector3.new(math.cos(a) * 1.8, h / 2, math.sin(a) * 1.8), Vector3.new(2.6, h - 0.4, 0.5), {
			Name = "Bristles",
			Color = k % 2 == 0 and color or color:Lerp(Color3.new(1, 1, 1), 0.3),
			Material = Enum.Material.Fabric,
			Rot = Vector3.new(0, -k * 45, 0),
			Parent = B.model,
			Hazard = true,
		})
		slab.Parent = m
	end
	m.PrimaryPart = core
	m.Parent = B:folder(folder)
	return m
end

local function gantry(B, z)
	for _, x in { -W / 2 + 1, W / 2 - 1 } do
		B:part(Vector3.new(x, 7, z), Vector3.new(1.4, 14, 1.4), { Color = GANTRY, Material = Enum.Material.Metal, Name = "GantryLeg" })
	end
	B:part(Vector3.new(0, 14.5, z), Vector3.new(W, 1.6, 1.6), { Color = GANTRY, Material = Enum.Material.Metal, Name = "GantryBeam" })
	for _, x in { -6, 6 } do
		B:part(Vector3.new(x, 13.6, z - 0.9), Vector3.new(1, 1, 0.2), { Color = YELLOW, Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false, Name = "GantryLamp" })
	end
end

return {
	Order = 11,
	Name = "Train Wash",
	Mode = "escape",
	TimeLimit = 110,
	Ambience = { { "carWash", 0.5 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 22,
			floorColor = Color3.fromRGB(120, 124, 128),
			floorMat = Enum.Material.Concrete,
			wallColor = Color3.fromRGB(220, 226, 232),
			lowerColor = BLUE,
			trim = YELLOW,
			brightness = 1.4,
			exit = { x = 0, y = 0 },
		})
		B:checkpoint(Vector3.new(0, 0.1, 7), Vector3.new(7, 0.2, 5))
		-- rails down the middle and a drainage channel each side
		Decor.track(B, Vector3.new(0, 0.05, 2), Vector3.new(0, 0.05, D - 2), true)
		for _, x in { -12, 12 } do
			B:part(Vector3.new(x, 0.02, D / 2), Vector3.new(1.4, 0.04, D - 4), { Color = Color3.fromRGB(60, 62, 66), Material = Enum.Material.DiamondPlate, Parent = "Decor", CanCollide = false, Name = "Drain" })
		end
		-- 1: side brushes (z = 28)
		gantry(B, 28)
		brush(B, "SideBrushL", Vector3.new(-17, 0, 28), 12, BLUE, "SideBrushes")
		brush(B, "SideBrushR", Vector3.new(17, 0, 28), 12, BLUE, "SideBrushes")
		-- 2: the floor roller (sweeps along z 42..62)
		gantry(B, 40)
		gantry(B, 64)
		local roller = Instance.new("Model")
		roller.Name = "Roller"
		local core = B:cyl(Vector3.new(0, 1.4, 44), W - 4, 1.2, "X", { Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Parent = B.model, Name = "Core", CanCollide = false })
		core.Parent = roller
		for k = 0, 5 do
			local a = math.rad(k * 60)
			local slab = B:part(Vector3.new(0, 1.4 + math.sin(a) * 0.9, 44 + math.cos(a) * 0.9), Vector3.new(W - 4.4, 0.5, 1.6), {
				Name = "Bristles",
				Color = k % 2 == 0 and Color3.fromRGB(220, 60, 60) or Color3.fromRGB(240, 140, 140),
				Material = Enum.Material.Fabric,
				Rot = Vector3.new(k * 60, 0, 0),
				Parent = B.model,
				Hazard = true,
			})
			slab.Parent = roller
		end
		roller.PrimaryPart = core
		roller.Parent = B:folder("Rollers")
		B:checkpoint(Vector3.new(0, 0.1, 69), Vector3.new(8, 0.2, 5))
		-- 3: spray arches
		for i, z in { 82, 91, 100 } do
			for _, x in { -W / 2 + 1.5, W / 2 - 1.5 } do
				B:part(Vector3.new(x, 6, z), Vector3.new(1, 12, 1), { Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Name = "ArchLeg" })
			end
			B:part(Vector3.new(0, 12.5, z), Vector3.new(W - 2, 1, 1), { Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Name = "ArchTop" })
			for x = -16, 16, 4 do
				local nozzle = B:part(Vector3.new(x, 11.8, z), Vector3.new(0.8, 0.6, 0.8), { Name = "Nozzle" .. i, Color = Color3.fromRGB(60, 60, 64), Material = Enum.Material.Metal, Parent = "Nozzles", CanCollide = false })
				local spray = Instance.new("ParticleEmitter")
				spray.Name = "Spray"
				spray.Texture = "rbxasset://textures/particles/smoke_main.dds"
				spray.Color = ColorSequence.new(Color3.fromRGB(180, 220, 255))
				spray.EmissionDirection = Enum.NormalId.Bottom
				spray.Rate = 0
				spray.Speed = NumberRange.new(20, 26)
				spray.Lifetime = NumberRange.new(0.4, 0.5)
				spray.SpreadAngle = Vector2.new(12, 12)
				spray.Size = NumberSequence.new(0.8, 2.4)
				spray.Transparency = NumberSequence.new(0.2, 1)
				spray.Parent = nozzle
			end
			B:part(Vector3.new(0, 5.5, z), Vector3.new(W - 3, 11, 2.2), { Name = "SprayZone" .. i, Transparency = 1, CanCollide = false, Parent = "SprayZones" })
		end
		-- 4: the revolving brush gate (walls either side force you through it)
		local gateZ = 114
		B:span(Vector3.new(-W / 2, 0, gateZ - 0.5), Vector3.new(-9.5, 14, gateZ + 0.5), { Color = Color3.fromRGB(220, 226, 232), Material = Enum.Material.Concrete, Name = "GateWall" })
		B:span(Vector3.new(9.5, 0, gateZ - 0.5), Vector3.new(W / 2, 14, gateZ + 0.5), { Color = Color3.fromRGB(220, 226, 232), Material = Enum.Material.Concrete, Name = "GateWall" })
		B:span(Vector3.new(-9.5, 9, gateZ - 0.5), Vector3.new(9.5, 14, gateZ + 0.5), { Color = Color3.fromRGB(220, 226, 232), Material = Enum.Material.Concrete, Name = "GateWall" })
		local revolver = Instance.new("Model")
		revolver.Name = "Revolver"
		local hub = B:cyl(Vector3.new(0, 4.5, gateZ), 9, 1.4, "Y", { Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Parent = B.model, Name = "Hub" })
		hub.Parent = revolver
		for k = 0, 3 do
			local a = math.rad(k * 90 + 45)
			local paddle = B:part(Vector3.new(math.cos(a) * 4.7, 4.5, gateZ + math.sin(a) * 4.7), Vector3.new(8, 8.6, 0.6), {
				Name = "Paddle",
				Color = k % 2 == 0 and Color3.fromRGB(40, 170, 90) or Color3.fromRGB(90, 200, 130),
				Material = Enum.Material.Fabric,
				Rot = Vector3.new(0, -(k * 90 + 45), 0),
				Parent = B.model,
			})
			paddle.Parent = revolver
		end
		-- spin about a plain upright root (the hub cylinder is rotated)
		local pivotPart = B:part(Vector3.new(0, 4.5, gateZ), Vector3.new(1, 1, 1), { Name = "Root", Transparency = 1, CanCollide = false, Parent = B.model })
		pivotPart.Parent = revolver
		revolver.PrimaryPart = pivotPart
		revolver:SetAttribute("Spin", 50)
		revolver.Parent = B:folder("Structure")
		-- soap tanks and hoses along the walls, puddles on the floor
		for _, z in { 16, 52, 76, 108, 126 } do
			B:cyl(Vector3.new(-W / 2 + 2.2, 3, z), 6, 3.4, "Y", { Color = ({ BLUE, Color3.fromRGB(220, 60, 60), YELLOW })[z % 3 + 1], Material = Enum.Material.SmoothPlastic, Name = "SoapTank" })
		end
		Decor.pipe(B, Vector3.new(W / 2 - 0.8, 10, 2), Vector3.new(W / 2 - 0.8, 10, D - 2), 1, BLUE)
		for _, p in { Vector3.new(-9.5, 0.03, 36), Vector3.new(10, 0.03, 75), Vector3.new(-10, 0.03, 104), Vector3.new(9, 0.03, 126) } do -- clear of the track bed
			B:cyl(p, 0.04, 6, "Y", { Color = Color3.fromRGB(150, 190, 220), Material = Enum.Material.SmoothPlastic, Transparency = 0.45, Parent = "Decor", CanCollide = false, Name = "Puddle" })
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local t0 = os.clock()
		-- side brushes: spin, and slide in to meet in the middle every few seconds
		local sides = {}
		for _, m in level.SideBrushes:GetChildren() do
			local base = m:GetPivot()
			table.insert(sides, { m = m, base = base, side = base.Position.X < ctx.origin.X and -1 or 1 })
		end
		-- the roller travels up and down the bay
		local roller = level.Rollers.Roller
		local rBase = roller:GetPivot()
		ctx:heartbeat(function()
			local t = os.clock() - t0
			-- 0..1: how far in the side brushes are (open 2s, close 1.2s, closed 1s, open 1.2s)
			local cyc = t % 5.4
			local close
			if cyc < 2 then
				close = 0
			elseif cyc < 3.2 then
				close = (cyc - 2) / 1.2
			elseif cyc < 4.2 then
				close = 1
			else
				close = 1 - (cyc - 4.2) / 1.2
			end
			for _, s in sides do
				local x = -s.side * 13 * close
				s.m:PivotTo(CFrame.new(s.base.Position + Vector3.new(x, 0, 0)) * CFrame.Angles(0, t * 5 * s.side, 0) * s.base.Rotation)
			end
			-- roller: ping-pong along z 44..60, rolling as it goes
			local u = (math.sin(t * 0.9) + 1) / 2
			local z = 16 * u
			roller:PivotTo(CFrame.new(rBase.Position + Vector3.new(0, 0, z)) * CFrame.Angles(-z / 1.4, 0, 0) * rBase.Rotation)
		end)
		-- spray arches: nozzles glow orange for 0.8s, then spray for 1.4s
		local zones, nozzles = {}, {}
		for _, z in level.SprayZones:GetChildren() do
			zones[tonumber(z.Name:match("%d+"))] = z
		end
		for _, n in level.Nozzles:GetChildren() do
			local i = tonumber(n.Name:match("%d+"))
			nozzles[i] = nozzles[i] or {}
			table.insert(nozzles[i], n)
		end
		for i, zone in zones do
			task.spawn(function()
				task.wait(i * 0.9)
				while not ctx.ended do
					task.wait(1.6)
					for _, n in nozzles[i] do
						n.Color = C.orange
						n.Material = Enum.Material.Neon
					end
					task.wait(0.8)
					for _, n in nozzles[i] do
						n.Spray.Rate = 60
						n.Color = Color3.fromRGB(150, 210, 255)
					end
					Audio.play(zone, "steam", 0.6, 60)
					ctx:setHazard(zone, true)
					task.wait(1.4)
					ctx:setHazard(zone, false)
					for _, n in nozzles[i] do
						n.Spray.Rate = 0
						n.Color = Color3.fromRGB(60, 60, 64)
						n.Material = Enum.Material.Metal
					end
				end
			end)
		end
	end,
}
