-- Moon Base (medium): this line goes further than you thought. Low gravity -
-- take giant leaps across the moon rocks to the landing pad and through the
-- airlock.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local C = BuildLib.C

local W, D, HGT = 64, 166, 70
local MOON = Color3.fromRGB(176, 176, 182)
local PAD_Y = 24

return {
	Order = 18,
	Name = "Moon Base",
	Mode = "escape",
	TimeLimit = 100,
	KillY = -30,
	Ambience = { { "eerie", 0.35 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = HGT,
			floor = false,
			bottom = -50,
			wallColor = Color3.fromRGB(10, 10, 22),
			wallMat = Enum.Material.SmoothPlastic,
			ceilColor = Color3.fromRGB(8, 8, 18),
			band = false,
			beams = false,
			lamps = false,
			exit = { x = 0, y = PAD_Y },
		})
		local rng = Random.new(18)
		-- stars on every wall and the ceiling
		local function star(pos)
			local s = rng:NextNumber(0.2, 0.55)
			B:part(pos, Vector3.new(s, s, s), { Color = C.white, Material = Enum.Material.Neon, Parent = "Stars", CanCollide = false, CastShadow = false, Name = "Star" })
		end
		for _ = 1, 110 do
			star(Vector3.new(-W / 2 + 0.2, rng:NextNumber(-45, HGT - 2), rng:NextNumber(2, D - 2)))
			star(Vector3.new(W / 2 - 0.2, rng:NextNumber(-45, HGT - 2), rng:NextNumber(2, D - 2)))
		end
		for _ = 1, 70 do
			star(Vector3.new(rng:NextNumber(-W / 2, W / 2), HGT - 0.2, rng:NextNumber(2, D - 2)))
		end
		for _ = 1, 40 do
			local x, y = rng:NextNumber(-W / 2, W / 2), rng:NextNumber(-45, HGT - 2)
			if math.abs(x) > 4 or y > 10 then
				star(Vector3.new(x, y, 1.2))
			end
			star(Vector3.new(rng:NextNumber(-W / 2, W / 2), rng:NextNumber(-45, HGT - 2), D - 0.2))
		end
		-- a softly lit station dome you start in
		B:span(Vector3.new(-12, -10, 1), Vector3.new(12, 0, 16), { Name = "StartDeck", Color = Color3.fromRGB(200, 204, 210), Material = Enum.Material.DiamondPlate })
		B:checkpoint(Vector3.new(0, 0.1, 8), Vector3.new(7, 0.2, 5))
		for _, x in { -11, 11 } do
			B:lamp(Vector3.new(x, 0.6, 15), Vector3.new(0.6, 0.6, 0.6), { Color = Color3.fromRGB(120, 200, 255), Range = 16, Brightness = 1.5, Glow = true })
		end
		-- moon rocks to leap between: {x, top, z, size}
		local rocks = {
			{ -12, 4, 34, 11 },
			{ 10, 10, 58, 10 },
			{ -4, 6, 84, 12 },
			{ 14, 13, 108, 9 },
			{ -8, 19, 130, 10 },
		}
		for i, r in rocks do
			local size = r[4]
			-- a floating moon rock: a flat cratered top on a rounded, lumpy underside
			B:cyl(Vector3.new(r[1], r[2] - 0.8, r[3]), 1.6, size, "Y", { Name = "MoonRock", Color = MOON, Material = Enum.Material.Slate })
			for k = 1, 5 do
				local a = k / 5 * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
				local d = size * rng:NextNumber(0.42, 0.62)
				B:ball(Vector3.new(r[1] + math.cos(a) * size * 0.24, r[2] - 1.4 - d * 0.32, r[3] + math.sin(a) * size * 0.24), d, { Name = "RockLump", Color = MOON:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0.05, 0.2)), Material = Enum.Material.Slate })
			end
			B:ball(Vector3.new(r[1], r[2] - size * 0.45, r[3]), size * 0.7, { Name = "RockLump", Color = MOON:Lerp(Color3.new(0, 0, 0), 0.2), Material = Enum.Material.Slate })
			for _ = 1, 2 do
				B:cyl(Vector3.new(r[1] + rng:NextNumber(-size / 4, size / 4), r[2] + 0.02, r[3] + rng:NextNumber(-size / 4, size / 4)), 0.05, rng:NextNumber(1.5, 3), "Y", { Color = Color3.fromRGB(140, 140, 148), Parent = "Decor", CanCollide = false, Name = "Crater" })
			end
			if i == 3 then
				B:checkpoint(Vector3.new(r[1], r[2] + 0.1, r[3]), Vector3.new(6, 0.2, 6))
			end
		end
		-- the moon's surface far below, and the Earth hanging over the airlock
		B:span(Vector3.new(-W / 2, -42, 1), Vector3.new(W / 2, -40, D), { Name = "MoonSurface", Color = MOON:Lerp(Color3.new(0, 0, 0), 0.1), Material = Enum.Material.Slate })
		for _ = 1, 14 do
			local d = rng:NextNumber(4, 12)
			B:cyl(Vector3.new(rng:NextNumber(-W / 2 + d / 2, W / 2 - d / 2), -39.95, rng:NextNumber(10, D - 10)), 0.1, d, "Y", { Color = Color3.fromRGB(140, 140, 148), Parent = "Decor", CanCollide = false, Name = "Crater" })
		end
		B:ball(Vector3.new(-14, HGT - 18, D - 8), 16, { Name = "Earth", Color = Color3.fromRGB(50, 110, 200), Material = Enum.Material.SmoothPlastic, Parent = "Decor", CanCollide = false })
		for k = 1, 4 do
			B:ball(Vector3.new(-14 + ({ -3, 2, 4, -1 })[k], HGT - 18 + ({ 3, -2, 4, -4 })[k], D - 13.5), ({ 6, 5, 4, 5 })[k], { Name = "Land", Color = Color3.fromRGB(70, 150, 80), Material = Enum.Material.SmoothPlastic, Parent = "Decor", CanCollide = false })
		end
		-- the landing pad, the lander, and the moon rock sample case by the airlock
		B:span(Vector3.new(-W / 2, -10, 146), Vector3.new(W / 2, PAD_Y, D), { Name = "LandingDeck", Color = Color3.fromRGB(150, 150, 156), Material = Enum.Material.Slate })
		B:cyl(Vector3.new(14, PAD_Y + 0.05, 156), 0.1, 14, "Y", { Color = C.yellow, Parent = "Decor", CanCollide = false, Name = "PadRing" })
		B:cyl(Vector3.new(14, PAD_Y + 0.07, 156), 0.1, 12, "Y", { Color = Color3.fromRGB(150, 150, 156), Parent = "Decor", CanCollide = false, Name = "PadInner" })
		-- lander: gold foil body on four legs
		B:part(Vector3.new(14, PAD_Y + 5.5, 156), Vector3.new(6, 5, 6), { Color = Color3.fromRGB(220, 180, 70), Material = Enum.Material.Foil, Name = "Lander" })
		B:part(Vector3.new(14, PAD_Y + 9, 156), Vector3.new(4, 2, 4), { Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Name = "LanderCabin" })
		-- splayed legs: struts from under each corner of the body out to a
		-- footpad, with a brace back to the body's side
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local top = Vector3.new(14 + sx * 2.5, PAD_Y + 3.3, 156 + sz * 2.5)
				local foot = Vector3.new(14 + sx * 4, PAD_Y + 0.35, 156 + sz * 4)
				for _, seg in { { top, foot, 0.4 }, { Vector3.new(14 + sx * 2.9, PAD_Y + 4.6, 156 + sz * 2.9), (top + foot) / 2, 0.25 } } do
					local a, b, w = seg[1], seg[2], seg[3]
					local leg = B:part((a + b) / 2, Vector3.new(w, (a - b).Magnitude + w, w), { Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Name = "LanderLeg" })
					leg.CFrame = CFrame.lookAt(B:w((a + b) / 2), B:w(a)) * CFrame.Angles(math.rad(90), 0, 0)
				end
				B:cyl(foot - Vector3.new(0, 0.2, 0), 0.3, 1.6, "Y", { Color = Color3.fromRGB(200, 200, 205), Parent = "Decor", Name = "Foot" })
			end
		end
		-- the moon rock sample, in a glass case on a plinth
		B:span(Vector3.new(-14, PAD_Y, 152), Vector3.new(-10, PAD_Y + 3, 156), { Color = Color3.fromRGB(220, 222, 226), Material = Enum.Material.Marble, Name = "Plinth" })
		B:part(Vector3.new(-12, PAD_Y + 3.8, 154), Vector3.new(1.6, 1.2, 1.4), { Color = MOON, Material = Enum.Material.Slate, Name = "MoonRockSample", Rot = Vector3.new(10, 30, 5) })
		B:span(Vector3.new(-13.8, PAD_Y + 3, 152.2), Vector3.new(-10.2, PAD_Y + 5.4, 155.8), { Color = Color3.fromRGB(200, 230, 240), Material = Enum.Material.Glass, Transparency = 0.7, Name = "Case", CastShadow = false })
		B:lamp(Vector3.new(-12, PAD_Y + 5.5, 154), Vector3.new(3.6, 0.1, 3.6), { Color = Color3.fromRGB(200, 230, 255), Range = 8, Brightness = 1.2 })
		-- floodlights on the deck so it reads as the goal
		for _, x in { -24, 24 } do
			B:part(Vector3.new(x, PAD_Y + 4, D - 3), Vector3.new(0.5, 8, 0.5), { Color = C.darkSteel, Material = Enum.Material.Metal, Name = "LightMast" })
			B:lamp(Vector3.new(x, PAD_Y + 8.2, D - 3.6), Vector3.new(1.6, 1, 0.6), { Color = Color3.fromRGB(240, 245, 255), Range = 40, Brightness = 2, Glow = true })
		end
	end,
	Run = function(ctx)
		ctx:setGravity(40)
		ctx:setHumanoid("JumpPower", 50)
	end,
}
