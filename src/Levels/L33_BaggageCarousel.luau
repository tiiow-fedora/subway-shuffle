-- Baggage Carousel (medium): the airport-link baggage hall, over the luggage
-- chute. Hop across belts that run in opposite directions with suitcases
-- riding them, cross the spinning carousel over its bumpers, ride the bag
-- lifts up to the mezzanine and walk the last belt against the flow -
-- dodging the cases it's carrying - to the exit.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D, H = 64, 150, 26
local BELTS = { 12, 20.5, 29, 37.5, 46 } -- front edge of each belt, 6 deep
local BELT_SPEED = 12
local CAROUSEL_Z, CAROUSEL_R = 78, 14
local TOP = 12
local RUBBER = Color3.fromRGB(34, 34, 38)
local STEEL = Color3.fromRGB(170, 176, 184)
local CASES = { Color3.fromRGB(200, 50, 50), Color3.fromRGB(40, 90, 170), Color3.fromRGB(30, 30, 34), Color3.fromRGB(230, 170, 40), Color3.fromRGB(110, 60, 150), Color3.fromRGB(60, 140, 90) }

-- a suitcase standing on its long edge, as a Model ready to be a mover
local function suitcase(B, pos, color, size)
	size = size or Vector3.new(4, 2.6, 3)
	local m = Instance.new("Model")
	m.Name = "Suitcase"
	local body = B:part(pos + Vector3.new(0, size.Y / 2, 0), size, { Name = "Body", Color = color, Material = Enum.Material.SmoothPlastic, Parent = B.model })
	body.Parent = m
	local handle = B:part(pos + Vector3.new(0, size.Y + 0.25, 0), Vector3.new(1.4, 0.5, 0.4), { Name = "Handle", Color = C.black, Parent = B.model })
	handle.Parent = m
	for _, dx in { -size.X / 4, size.X / 4 } do
		local strap = B:part(pos + Vector3.new(dx, size.Y / 2, 0), Vector3.new(0.3, size.Y + 0.05, size.Z + 0.05), { Name = "Strap", Color = Color3.fromRGB(60, 60, 64), Parent = B.model, CanCollide = false })
		strap.Parent = m
	end
	m.PrimaryPart = body
	return m
end

local function mover(m, a, b, speed, pause, phase)
	m:SetAttribute("MoveFrom", a)
	m:SetAttribute("MoveTo", b)
	m:SetAttribute("Speed", speed)
	m:SetAttribute("Pause", pause)
	m:SetAttribute("Phase", phase)
end

return {
	Order = 33,
	Name = "Baggage Carousel",
	Mode = "escape",
	TimeLimit = 110,
	Ambience = { { "escalator", 0.35 }, { "crowd", 0.12 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = H,
			floor = false,
			bottom = -20,
			wallColor = Color3.fromRGB(228, 230, 234),
			wallMat = Enum.Material.SmoothPlastic,
			lowerColor = Color3.fromRGB(40, 80, 140),
			trim = Color3.fromRGB(60, 200, 230),
			ceilColor = Color3.fromRGB(210, 212, 216),
			lampColor = Color3.fromRGB(240, 246, 255),
			brightness = 1.2,
			lampStep = 14,
			exit = { x = 0, y = TOP },
		})
		local deck = { Color = Color3.fromRGB(150, 152, 158), Material = Enum.Material.Concrete, Name = "Deck" }
		local function ledge(x0, z0, x1, z1, y)
			local p = table.clone(deck)
			p.Thick = 1
			B:floor(x0, z0, x1, z1, y or 0, p)
			-- yellow safety edge along the open front/back
			for _, z in { z0 + 0.3, z1 - 0.3 } do
				B:part(Vector3.new((x0 + x1) / 2, (y or 0) + 0.01, z), Vector3.new(x1 - x0, 0.04, 0.6), { Color = C.yellow, Parent = "Decor", CanCollide = false, Name = "EdgeLine" })
			end
		end
		-- start, landing between sections, and the carousel exit ledge
		ledge(-W / 2, 1, W / 2, 10)
		ledge(-26, 54, 26, 62)
		ledge(-8, 93.5, 8, 100)
		B:checkpoint(Vector3.new(0, 0.1, 6), Vector3.new(8, 0.2, 5))
		B:checkpoint(Vector3.new(0, 0.1, 58), Vector3.new(8, 0.2, 5))
		B:checkpoint(Vector3.new(0, 0.1, 97), Vector3.new(8, 0.2, 5))

		-- 1: the belts. Each runs the opposite way to the last, with cases riding it
		local rng = Random.new(33)
		for i, z0 in BELTS do
			local dir = i % 2 == 0 and 1 or -1
			local zc = z0 + 3
			B:part(Vector3.new(0, -0.5, zc), Vector3.new(52, 1, 6), { Name = "Belt", Color = RUBBER, Material = Enum.Material.Rubber, Conveyor = Vector3.new(dir * BELT_SPEED, 0, 0), Parent = "Structure" })
			for _, x in { -26.6, 26.6 } do
				B:cyl(Vector3.new(x, -0.6, zc), 6, 1.4, "Z", { Color = STEEL, Material = Enum.Material.Metal, Name = "Roller" })
			end
			for x = -24, 24, 4 do
				B:part(Vector3.new(x, 0.01, zc), Vector3.new(0.2, 0.04, 6), { Color = Color3.fromRGB(56, 56, 62), Parent = "Decor", CanCollide = false, Name = "Slat" })
			end
			-- skirt underneath and direction chevrons on the side
			B:part(Vector3.new(0, -2.2, zc), Vector3.new(52, 2.4, 5), { Color = STEEL, Material = Enum.Material.Metal, Name = "BeltFrame" })
			-- two cases per belt in their own lanes (they ping-pong, so on one
			-- line they'd pass straight through each other)
			for k = 1, 2 do
				local lz = zc + (k == 1 and -1.5 or 1.5)
				local m = suitcase(B, Vector3.new(0, 0, lz), CASES[rng:NextInteger(1, #CASES)], Vector3.new(4, 2.6, 2.4))
				mover(m, B:w(Vector3.new(-dir * 20, 1.3, lz)), B:w(Vector3.new(dir * 20, 1.3, lz)), 10, 0.2, (k - 1) * 0.5 + i * 0.13)
				m.Parent = B:folder("Structure")
			end
		end

		-- 2: the carousel - a turntable with four bumpers to hop
		local carousel = Instance.new("Model")
		carousel.Name = "Carousel"
		local hub = B:part(Vector3.new(0, 0, CAROUSEL_Z), Vector3.new(0.5, 0.5, 0.5), { Name = "Root", Transparency = 1, CanCollide = false, Parent = B.model })
		hub.Parent = carousel
		local function add(p)
			p.Parent = carousel
			return p
		end
		add(B:cyl(Vector3.new(0, -0.5, CAROUSEL_Z), 1, CAROUSEL_R * 2, "Y", { Name = "Turntable", Color = Color3.fromRGB(70, 72, 80), Material = Enum.Material.DiamondPlate, Parent = B.model }))
		add(B:cyl(Vector3.new(0, 1.5, CAROUSEL_Z), 3, 5, "Y", { Name = "Hub", Color = STEEL, Material = Enum.Material.Metal, Parent = B.model }))
		add(B:cyl(Vector3.new(0, 3.1, CAROUSEL_Z), 0.2, 5.4, "Y", { Name = "HubCap", Color = Color3.fromRGB(60, 200, 230), Material = Enum.Material.Neon, Parent = B.model, CanCollide = false }))
		for k = 0, 3 do
			local a = k * math.pi / 2
			local r = 8.4
			add(B:part(Vector3.new(math.cos(a) * r, 0.8, CAROUSEL_Z + math.sin(a) * r), Vector3.new(10.8, 1.6, 0.9), { Name = "Bumper", Color = C.yellow, Material = Enum.Material.SmoothPlastic, Rot = Vector3.new(0, -math.deg(a), 0), Parent = B.model }))
			local m = suitcase(B, Vector3.new(math.cos(a + 0.95) * 10, 0, CAROUSEL_Z + math.sin(a + 0.95) * 10), CASES[k + 1], Vector3.new(3, 2.2, 2.4))
			for _, p in m:GetChildren() do
				add(p)
			end
			m:Destroy()
		end
		carousel.PrimaryPart = hub
		carousel:SetAttribute("Spin", 30)
		carousel.Parent = B:folder("Structure")
		-- the fixed steel rim round it, outside the turntable
		B:cyl(Vector3.new(0, -1.6, CAROUSEL_Z), 1.2, CAROUSEL_R * 2 + 1.6, "Y", { Name = "Rim", Color = STEEL, Material = Enum.Material.Metal, CanCollide = false })

		-- 3: three bag lifts up to the mezzanine
		local lifts = { { z = 104.5, lo = 0, hi = 4, phase = 0 }, { z = 112, lo = 3, hi = 8, phase = 0.33 }, { z = 119.5, lo = 6.5, hi = TOP, phase = 0.66 } }
		for i, l in lifts do
			local p = B:part(Vector3.new(0, l.lo - 0.5, l.z), Vector3.new(7, 1, 6), { Name = "Lift" .. i, Color = Color3.fromRGB(60, 200, 230), Material = Enum.Material.DiamondPlate, Parent = "Structure" })
			mover(p, B:w(Vector3.new(0, l.lo - 0.5, l.z)), B:w(Vector3.new(0, l.hi - 0.5, l.z)), 3, 1, l.phase)
			-- guide rails either side
			for _, x in { -4.2, 4.2 } do
				B:part(Vector3.new(x, (l.hi - 18) / 2, l.z), Vector3.new(0.6, l.hi + 18, 1), { Color = Color3.fromRGB(60, 62, 70), Material = Enum.Material.Metal, Name = "LiftRail", Parent = "Decor" })
			end
		end

		-- 4: the mezzanine belt, running towards you, carrying cases
		B:part(Vector3.new(0, TOP - 0.5, 134), Vector3.new(10, 1, 20), { Name = "TopBelt", Color = RUBBER, Material = Enum.Material.Rubber, Conveyor = Vector3.new(0, 0, -8), Parent = "Structure" })
		for z = 125, 143, 3 do
			B:part(Vector3.new(0, TOP + 0.01, z), Vector3.new(10, 0.04, 0.2), { Color = Color3.fromRGB(56, 56, 62), Parent = "Decor", CanCollide = false, Name = "Slat" })
		end
		B:part(Vector3.new(0, TOP - 2, 134), Vector3.new(9, 2, 20), { Color = STEEL, Material = Enum.Material.Metal, Name = "BeltFrame" })
		for k, x in { -2.6, 2.6 } do
			local m = suitcase(B, Vector3.new(x, TOP, 134), CASES[k + 2], Vector3.new(3, 2.6, 4))
			mover(m, B:w(Vector3.new(x, TOP + 1.3, 141)), B:w(Vector3.new(x, TOP + 1.3, 127)), 9, 0.4, (k - 1) * 0.5)
			m.Parent = B:folder("Structure")
		end
		-- X-ray arch over the belt
		for _, x in { -5.6, 5.6 } do
			B:part(Vector3.new(x, TOP + 4, 132), Vector3.new(1.2, 8, 3), { Color = Color3.fromRGB(220, 222, 226), Name = "Scanner" })
		end
		B:part(Vector3.new(0, TOP + 8.5, 132), Vector3.new(12.4, 1, 3), { Color = Color3.fromRGB(220, 222, 226), Name = "Scanner" })
		B:part(Vector3.new(0, TOP + 7.9, 132), Vector3.new(10, 0.2, 2.4), { Color = Color3.fromRGB(80, 255, 140), Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false, Name = "ScanLight", Light = { Range = 10, Brightness = 1, Color = Color3.fromRGB(80, 255, 140) } })
		-- top landing in front of the exit, with a rail along its edge
		local p = table.clone(deck)
		p.Thick = 1
		B:floor(-W / 2, 144, W / 2, D, TOP, p)
		for _, seg in { { -W / 2, -5 }, { 5, W / 2 } } do
			B:part(Vector3.new((seg[1] + seg[2]) / 2, TOP + 3.3, 144.2), Vector3.new(seg[2] - seg[1], 0.3, 0.3), { Color = STEEL, Material = Enum.Material.Metal, Name = "Railing" })
			B:part(Vector3.new((seg[1] + seg[2]) / 2, TOP + 1.7, 144.2), Vector3.new(seg[2] - seg[1], 3.3, 0.1), { Color = Color3.fromRGB(200, 225, 235), Material = Enum.Material.Glass, Transparency = 0.6, Name = "RailGlass" })
		end
		for _, x in { -20, 20 } do
			-- stops under the landing slab (a shared top face Z-fought)
			B:part(Vector3.new(x, (TOP - 1 - 20) / 2, 147), Vector3.new(2, TOP + 19, 2), { Color = STEEL, Material = Enum.Material.Metal, Name = "Column" })
		end

		-- the luggage chute at the bottom: a pile of lost bags
		for i = 1, 40 do
			local x, z = rng:NextNumber(-28, 28), rng:NextNumber(14, 144)
			B:part(Vector3.new(x, -18.6 + rng:NextNumber(0, 1), z), Vector3.new(rng:NextNumber(2.5, 4), rng:NextNumber(1.6, 2.6), rng:NextNumber(2, 3)), { Color = CASES[rng:NextInteger(1, #CASES)], Parent = "Decor", CanCollide = false, Name = "LostBag", Rot = Vector3.new(0, rng:NextNumber(0, 180), rng:NextNumber(-20, 20)) })
		end
		-- airport-style hanging sign and adverts
		B:sign(Vector3.new(0, 17, 12), Vector3.new(14, 2, 0.4), "BAGGAGE RECLAIM", { Color = Color3.fromRGB(30, 34, 44), TextColor = Color3.fromRGB(255, 210, 40), Face = Enum.NormalId.Front, Parent = "Decor", CanCollide = false })
		for _, z in { 30, 80, 120 } do
			Decor.advert(B, Vector3.new(-W / 2, 14, z), "+X")
			Decor.advert(B, Vector3.new(W / 2, 14, z), "-X")
		end
	end,
	Run = function(ctx)
		-- belt motors hum where the belts are
		for _, p in ctx.level.Structure:GetChildren() do
			if p.Name == "Belt" or p.Name == "TopBelt" then
				Audio.loop(p, "escalator", 0.25, 40)
			end
		end
	end,
}
