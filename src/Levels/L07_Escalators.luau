-- Escalator Chaos: a deep-level escalator shaft where every escalator is
-- running DOWN - and somebody keeps dropping their luggage at the top.
-- Run up the moving steps, dodge the tumbling suitcases.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local C = BuildLib.C

local W, D = 37, 150
local RUN, RISE = 1.4, 0.8 -- one step
-- flights: bottom nose point -> top nose point (local), two escalators each
local FLIGHTS = {
	{ a = Vector3.new(0, 0, 14), b = Vector3.new(0, 30, 66) },
	{ a = Vector3.new(0, 30, 80), b = Vector3.new(0, 60, 132) },
}
local LANES = { -10.5, 10.5 }
local SPEEDS = { { 5, 7 }, { 7, 9 } }
local TREAD_W = 11

local STEEL = Color3.fromRGB(165, 168, 172)
local TILE = Color3.fromRGB(226, 220, 204)

local function escalator(B, f, x, speed, idx)
	local a, b = f.a + Vector3.new(x, 0, 0), f.b + Vector3.new(x, 0, 0)
	local u = (b - a).Unit
	-- casing under the steps (solid, so nothing can get underneath)
	B:ramp(a - Vector3.new(0, 1.6, 0), b - Vector3.new(0, 1.6, 0), TREAD_W + 1.4, { Name = "Casing", Color = Color3.fromRGB(40, 40, 42), Material = Enum.Material.Metal, Thick = 5 })
	-- balustrades: stainless skirt, glass panel, moving black handrail
	for _, side in { -1, 1 } do
		local off = Vector3.new(side * (TREAD_W / 2 + 0.35), 0, 0)
		B:ramp(a + off + Vector3.new(0, 1.2, 0), b + off + Vector3.new(0, 1.2, 0), 0.5, { Name = "Skirt", Color = STEEL, Material = Enum.Material.Metal, Thick = 1.2 })
		B:ramp(a + off + Vector3.new(0, 3.4, 0), b + off + Vector3.new(0, 3.4, 0), 0.25, { Name = "Glass", Color = Color3.fromRGB(190, 220, 230), Material = Enum.Material.Glass, Transparency = 0.6, Thick = 2.2, CastShadow = false })
		B:ramp(a + off + Vector3.new(0, 3.75, 0), b + off + Vector3.new(0, 3.75, 0), 0.7, { Name = "Handrail", Color = Color3.fromRGB(25, 25, 25), Material = Enum.Material.Rubber, Thick = 0.35, Conveyor = -u * speed })
	end
	-- steps, laid out along the slope; Run moves them down continuously
	local len = (b - a).Magnitude
	local pitch = math.sqrt(RUN * RUN + RISE * RISE)
	local n = math.floor(len / pitch)
	for k = 0, n - 1 do
		local s = k * pitch
		local p = a + u * s
		local tread = B:part(Vector3.new(p.X, p.Y - 0.8, p.Z + RUN / 2), Vector3.new(TREAD_W, 1.6, RUN), {
			Name = "Step",
			Color = Color3.fromRGB(70, 72, 76),
			Material = Enum.Material.DiamondPlate,
			Parent = "Steps",
			Attr = { Esc = idx, S = s },
		})
		tread:SetAttribute("Kind", "tread")
		local edge = B:part(Vector3.new(p.X, p.Y + 0.02, p.Z + 0.15), Vector3.new(TREAD_W, 0.06, 0.3), {
			Name = "StepEdge",
			Color = Color3.fromRGB(230, 190, 30),
			Parent = "Steps",
			CanCollide = false,
			CastShadow = false,
			Attr = { Esc = idx, S = s },
		})
		edge:SetAttribute("Kind", "edge")
	end
	-- comb plates where the steps disappear
	B:part(a + Vector3.new(0, 0.03, -1), Vector3.new(TREAD_W, 0.06, 2), { Name = "CombPlate", Color = STEEL, Material = Enum.Material.DiamondPlate, Parent = "Decor", CanCollide = false })
	B:part(b + Vector3.new(0, 0.03, 1), Vector3.new(TREAD_W, 0.06, 2), { Name = "CombPlate", Color = STEEL, Material = Enum.Material.DiamondPlate, Parent = "Decor", CanCollide = false })
	return { a = a, b = b, u = u, len = len, speed = speed }
end

return {
	Order = 7,
	Name = "Escalator Chaos",
	Mode = "escape",
	TimeLimit = 110,
	Ambience = { { "escalator", 0.45 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 74,
			wallColor = TILE,
			lowerColor = Color3.fromRGB(40, 70, 110),
			trim = Color3.fromRGB(40, 70, 110),
			lampColor = Color3.fromRGB(255, 226, 190),
			brightness = 1,
			lampStep = 20,
			exit = { x = 0, y = 60 },
		})
		B:checkpoint(Vector3.new(0, 0.1, 6), Vector3.new(8, 0.2, 5))
		for fi, f in FLIGHTS do
			for li, x in LANES do
				escalator(B, f, x, SPEEDS[fi][li], (fi - 1) * 2 + li)
			end
			-- the steel median between the two escalators: a slide, you can't climb it
			local u = (f.b - f.a).Unit
			B:ramp(f.a + Vector3.new(0, 3.2, 0), f.b + Vector3.new(0, 3.2, 0), 8.4, { Name = "Median", Color = STEEL, Material = Enum.Material.Metal, Thick = 4.8, Conveyor = -u * 35 })
			-- the strips between the outer balustrades and the walls, same deal
			for _, side in { -1, 1 } do
				local off = Vector3.new(side * 17.55, 3.2, 0)
				B:ramp(f.a + off, f.b + off, 1.9, { Name = "Ledge", Color = STEEL, Material = Enum.Material.Metal, Thick = 4.8, Conveyor = -u * 35 })
			end
			-- uplighters on the median
			for t = 0.1, 0.95, 0.12 do
				local p = f.a:Lerp(f.b, t) + Vector3.new(0, 3.2, 0)
				B:cyl(p + Vector3.new(0, 1.2, 0), 2.4, 0.5, "Y", { Color = Color3.fromRGB(150, 120, 60), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "Uplighter" })
				B:lamp(p + Vector3.new(0, 2.55, 0), Vector3.new(0.9, 0.3, 0.9), { Color = Color3.fromRGB(255, 220, 170), Range = 12, Brightness = 0.35, Name = "UplighterLamp" })
			end
		end
		-- solid structure under each flight, so you never see daylight (or the
		-- floor) under the escalators: a sloped wedge just below the casing,
		-- and a block under the upper flight down to the hall floor
		for _, f in FLIGHTS do
			local len = f.b.Z - f.a.Z
			local rise = f.b.Y - f.a.Y
			B:wedge(Vector3.new(0, f.a.Y + rise / 2 - 2.4, (f.a.Z + f.b.Z) / 2), Vector3.new(W, rise, len), { Name = "Understructure", Color = Color3.fromRGB(58, 60, 66), Material = Enum.Material.Concrete })
			if f.a.Y > 0 then
				B:span(Vector3.new(-W / 2, 0, f.a.Z), Vector3.new(W / 2, f.a.Y - 2.4, f.b.Z), { Name = "Understructure", Color = Color3.fromRGB(58, 60, 66), Material = Enum.Material.Concrete })
			end
		end
		-- landings
		B:span(Vector3.new(-W / 2, 0, 66), Vector3.new(W / 2, 30, 80), { Name = "Landing", Color = Color3.fromRGB(150, 146, 140), Material = Enum.Material.Marble })
		B:checkpoint(Vector3.new(0, 30.1, 73), Vector3.new(8, 0.2, 5))
		B:span(Vector3.new(-W / 2, 0, 132), Vector3.new(W / 2, 60, D), { Name = "TopLanding", Color = Color3.fromRGB(150, 146, 140), Material = Enum.Material.Marble })
		-- a bit of life on the landings
		Decor.bin(B, Vector3.new(-13, 30, 77))
		Decor.plant(B, Vector3.new(13, 30, 77))
		Decor.cctv(B, Vector3.new(-W / 2 + 0.2, 40, 73), "+X")
		Decor.bench(B, Vector3.new(-9, 60, D - 3), 0)
		Decor.plant(B, Vector3.new(13, 60, D - 3))
		-- horizontal tile courses on the tall walls
		for y = 12, 70, 10 do
			for _, spec in { { -W / 2, 1 }, { W / 2, -1 } } do
				B:part(Vector3.new(spec[1] + spec[2] * 0.15, y, D / 2 + 0.5), Vector3.new(0.3, 0.5, D - 1), { Color = Color3.fromRGB(40, 70, 110), Parent = "Decor", CanCollide = false, Name = "TileCourse" })
			end
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local escs = {}
		for fi, f in FLIGHTS do
			for li, x in LANES do
				local idx = (fi - 1) * 2 + li
				local a = ctx:w(f.a + Vector3.new(x, 0, 0))
				local b = ctx:w(f.b + Vector3.new(x, 0, 0))
				escs[idx] = { a = a, b = b, u = (b - a).Unit, len = (b - a).Magnitude, speed = SPEEDS[fi][li], parts = {} }
			end
		end
		for _, p in level.Steps:GetChildren() do
			local e = escs[p:GetAttribute("Esc")]
			table.insert(e.parts, { p = p, s = p:GetAttribute("S"), edge = p:GetAttribute("Kind") == "edge" })
		end
		-- keep the steps rolling down (and carrying you with them)
		local t0 = os.clock()
		ctx:heartbeat(function()
			local t = os.clock() - t0
			for _, e in escs do
				local vel = -e.u * e.speed
				for _, s in e.parts do
					local d = (s.s - e.speed * t) % e.len
					local p = e.a + e.u * d
					if s.edge then
						s.p.CFrame = CFrame.new(p.X, p.Y + 0.02, p.Z + 0.15)
					else
						s.p.CFrame = CFrame.new(p.X, p.Y - 0.8, p.Z + RUN / 2)
						s.p.AssemblyLinearVelocity = vel
					end
				end
			end
		end)

		-- somebody keeps dropping their suitcases at the top
		local COLORS = { Color3.fromRGB(150, 30, 40), Color3.fromRGB(30, 60, 120), Color3.fromRGB(40, 40, 44), Color3.fromRGB(200, 120, 40), Color3.fromRGB(60, 110, 70), Color3.fromRGB(120, 60, 130) }
		local function suitcase()
			local m = Instance.new("Model")
			m.Name = "Suitcase"
			local col = COLORS[math.random(1, #COLORS)]
			local function add(size, offset, color, shape)
				local p = Instance.new("Part")
				p.Anchored = true
				p.CanCollide = false
				p.Size = size
				p.Color = color
				p.Material = Enum.Material.SmoothPlastic
				if shape then
					p.Shape = shape
				end
				p:SetAttribute("Hazard", true)
				p:SetAttribute("Off", offset)
				p.Parent = m
				return p
			end
			local body = add(Vector3.new(2.6, 3.4, 1.4), CFrame.new(), col)
			add(Vector3.new(2.7, 0.25, 1.5), CFrame.new(0, 0.9, 0), col:Lerp(Color3.new(0, 0, 0), 0.3))
			add(Vector3.new(2.7, 0.25, 1.5), CFrame.new(0, -0.9, 0), col:Lerp(Color3.new(0, 0, 0), 0.3))
			for _, x in { -0.6, 0.6 } do
				add(Vector3.new(0.15, 1.2, 0.15), CFrame.new(x, 2.3, 0), Color3.fromRGB(160, 160, 165))
			end
			add(Vector3.new(1.5, 0.25, 0.3), CFrame.new(0, 2.9, 0), Color3.fromRGB(30, 30, 30))
			for _, x in { -1, 1 } do
				for _, z in { -0.5, 0.5 } do
					add(Vector3.new(0.3, 0.45, 0.45), CFrame.new(x, -1.85, z) * CFrame.Angles(0, 0, 0), Color3.fromRGB(20, 20, 20), Enum.PartType.Cylinder)
				end
			end
			m.PrimaryPart = body
			return m
		end
		local function drop(e)
			local m = suitcase()
			m.Parent = level
			local pieces = m:GetChildren()
			local t = 0
			local total = e.len
			local spin = 0
			local speed = e.speed + 9 + math.random() * 3
			-- left, middle or right of the escalator, so nowhere is always safe
			local lateral = ({ -3.6, 0, 3.6 })[math.random(1, 3)]
			while t < total and not ctx.ended do
				local dt = task.wait()
				t += speed * dt
				spin += dt * 7
				local pos = e.b - e.u * t + Vector3.new(lateral, 2.2, 0)
				local cf = CFrame.new(pos) * CFrame.Angles(-spin, 0, 0)
				for _, p in pieces do
					p.CFrame = cf * p:GetAttribute("Off")
				end
			end
			m:Destroy()
		end
		ctx:waitForStart()
		for idx, e in escs do
			task.spawn(function()
				task.wait(idx * 0.7)
				while not ctx.ended do
					task.spawn(drop, e)
					task.wait(2.6 - 0.9 * math.clamp(ctx:elapsed() / ctx.timeLimit, 0, 1) + math.random() * 0.8)
				end
			end)
		end
	end,
}
