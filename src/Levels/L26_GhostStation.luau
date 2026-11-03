-- Ghost Station (easy-medium): a station that closed decades ago. The local
-- graffiti crew left their tags half-finished - faded outlines on the walls.
-- Their spray cans are hidden around the platform; every can you find paints
-- one tag in. Find all six and the exit opens.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local TrainKit = require(root.TrainKit)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 76, 112
local TRACK_Z = 96
local TILE = Color3.fromRGB(196, 190, 170)
local TAGS = {
	{ text = "LAST STOP", color = Color3.fromRGB(255, 80, 160), wall = "-X", pos = Vector3.new(-W / 2, 7, 24) },
	{ text = "NO SIGNAL", color = Color3.fromRGB(60, 220, 255), wall = "+X", pos = Vector3.new(W / 2, 7, 30) },
	{ text = "TUNNEL RATS", color = Color3.fromRGB(255, 220, 40), wall = "-X", pos = Vector3.new(-W / 2, 7, 56) },
	{ text = "DEAD END", color = Color3.fromRGB(120, 255, 90), wall = "+X", pos = Vector3.new(W / 2, 7, 62) },
	{ text = "STAY OUT", color = Color3.fromRGB(255, 140, 40), wall = "front", pos = Vector3.new(-20, 7, 1) },
	{ text = "MIND THE GAP", color = Color3.fromRGB(180, 110, 255), wall = "front", pos = Vector3.new(20, 7, 1) },
}
-- where the cans are hidden (local positions)
local CANS = {
	Vector3.new(-32.5, 0, 26), -- knocked over beside the ticket booth
	Vector3.new(26, 7.4, 40), -- on top of the old vending machines
	Vector3.new(-8, 0, 70), -- under the collapsed bench
	Vector3.new(30, 0, 80), -- by the platform edge, next to the rubble
	Vector3.new(-33, 12.2, 44), -- up on the broken balcony (ladder)
	Vector3.new(-32, 0, 109), -- over the tracks, on the far platform
}

local function sprayCan(B, pos, color, i, fallen)
	local hit = B:part(pos + Vector3.new(0, 1.2, 0), Vector3.new(2.4, 2.6, 2.4), {
		Name = "Can" .. i,
		Transparency = 1,
		CanCollide = false,
		Parent = "Pickups",
		Attr = { Collectible = true, Index = i },
		Light = { Range = 8, Brightness = 1, Color = color },
	})
	if fallen then
		-- lying on its side, nozzle out, with a little puddle of spilt paint
		B:cyl(pos + Vector3.new(0, 0.4, 0), 1.6, 0.8, "Z", { Color = color, Material = Enum.Material.SmoothPlastic, Parent = hit, CanCollide = false, Name = "Body" })
		B:cyl(pos + Vector3.new(0, 0.4, 0.95), 0.3, 0.7, "Z", { Color = Color3.fromRGB(220, 220, 220), Material = Enum.Material.Metal, Parent = hit, CanCollide = false, Name = "Shoulder" })
		B:cyl(pos + Vector3.new(0, 0.4, 1.25), 0.3, 0.3, "Z", { Color = C.white, Parent = hit, CanCollide = false, Name = "Nozzle" })
		B:cyl(pos + Vector3.new(0.3, 0.02, 1.9), 0.04, 1.6, "Y", { Color = color, Material = Enum.Material.SmoothPlastic, Parent = hit, CanCollide = false, Name = "Spill" })
	else
		B:cyl(pos + Vector3.new(0, 0.8, 0), 1.6, 0.8, "Y", { Color = color, Material = Enum.Material.SmoothPlastic, Parent = hit, CanCollide = false, Name = "Body" })
		B:cyl(pos + Vector3.new(0, 1.75, 0), 0.3, 0.7, "Y", { Color = Color3.fromRGB(220, 220, 220), Material = Enum.Material.Metal, Parent = hit, CanCollide = false, Name = "Shoulder" })
		B:cyl(pos + Vector3.new(0, 2.05, 0), 0.3, 0.3, "Y", { Color = C.white, Parent = hit, CanCollide = false, Name = "Nozzle" })
	end
	local sparkle = Instance.new("Sparkles")
	sparkle.SparkleColor = color
	sparkle.Parent = hit
end

return {
	Order = 26,
	Name = "Ghost Station",
	Mode = "escape",
	ExitLocked = true,
	TimeLimit = 120,
	Ambience = { { "eerie", 0.45 } },
	Build = function(B)
		local tunnelH = 16
		B:room({
			W = W,
			D = D,
			H = 24,
			wallColor = TILE,
			wallMat = Enum.Material.Concrete,
			lowerColor = Color3.fromRGB(90, 60, 50),
			trim = Color3.fromRGB(150, 120, 60),
			floorColor = Color3.fromRGB(110, 106, 98),
			brightness = 0.8,
			flicker = true,
			sideHoles = { { side = -1, TRACK_Z - 10, TRACK_Z + 10, -4.01, tunnelH }, { side = 1, TRACK_Z - 10, TRACK_Z + 10, -4.01, tunnelH } },
			exit = { x = -20, y = 0 },
		})
		B:checkpoint(Vector3.new(0, 0.1, 5), Vector3.new(6, 0.2, 4))
		-- the track bed: a sunken strip along the back with the derelict train
		local floor = B:folder("Structure"):FindFirstChild("Floor")
		floor.Size = Vector3.new(floor.Size.X, floor.Size.Y, 84 - 1)
		floor.Position = B:w(Vector3.new(0, -floor.Size.Y / 2, 1 + 83 / 2))
		B:span(Vector3.new(-W / 2, -6, 84), Vector3.new(W / 2, -4, D), { Name = "TrackBed", Color = Color3.fromRGB(70, 66, 60), Material = Enum.Material.Pebble })
		B:span(Vector3.new(-W / 2, -4, 83.4), Vector3.new(W / 2, 0, 84), { Name = "PlatformEdge", Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Concrete })
		B:part(Vector3.new(0, 0.02, 82.6), Vector3.new(W, 0.04, 1.2), { Color = Color3.fromRGB(170, 150, 60), Parent = "Decor", CanCollide = false, Name = "FadedEdgeLine" })
		Decor.track(B, Vector3.new(-W / 2 - 20, -4, TRACK_Z), Vector3.new(W / 2 + 20, -4, TRACK_Z), false)
		B:recess(-1, TRACK_Z, 20, tunnelH + 4, 30, -4)
		B:recess(1, TRACK_Z, 20, tunnelH + 4, 92, -4)
		-- the train sits half out of the right-hand tunnel, leaving the left
		-- end of the tracks clear to cross
		local train = TrainKit.place(B, Vector3.new(63, -4, TRACK_Z - 0.5), { Name = "DerelictTrain", Parent = "Structure", flip = true })
		if train then
			-- grime it up
			for _, p in train:GetDescendants() do
				if p:IsA("BasePart") then
					p.Color = p.Color:Lerp(Color3.fromRGB(90, 80, 70), 0.35)
				end
			end
		end
		-- the far platform along the back wall, and a couple of crates to climb out
		B:span(Vector3.new(-W / 2, -4, 106), Vector3.new(W / 2, 0, D), { Name = "FarPlatform", Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Concrete })
		B:crate(Vector3.new(-26, -4, 86), 2.5, Color3.fromRGB(100, 80, 60))
		B:crate(Vector3.new(-14, -4, 103.6), 2.5, Color3.fromRGB(100, 80, 60))
		-- ticket booth: little room with a window and counter
		local bx, bz = -24, 26 -- well back from the entrance
		B:span(Vector3.new(bx - 6, 0, bz - 4), Vector3.new(bx + 6, 1, bz + 4), { Color = Color3.fromRGB(120, 60, 40), Material = Enum.Material.Wood, Name = "BoothBase" })
		B:wallZ(bz - 4, bz - 3.6, bx - 6, bx + 6, 1, 9, { { bx - 3, bx + 3, 3.6, 7 } }, { Color = Color3.fromRGB(120, 60, 40), Material = Enum.Material.WoodPlanks, Name = "BoothFront" })
		B:span(Vector3.new(bx - 6, 1, bz - 3.6), Vector3.new(bx - 5.6, 9, bz + 4), { Color = Color3.fromRGB(120, 60, 40), Material = Enum.Material.WoodPlanks, Name = "BoothSide" })
		B:span(Vector3.new(bx + 5.6, 1, bz - 3.6), Vector3.new(bx + 6, 9, bz + 4), { Color = Color3.fromRGB(120, 60, 40), Material = Enum.Material.WoodPlanks, Name = "BoothSide" })
		B:span(Vector3.new(bx - 6.4, 9, bz - 4.4), Vector3.new(bx + 6.4, 9.6, bz + 4.4), { Color = Color3.fromRGB(70, 40, 30), Name = "BoothRoof" })
		B:part(Vector3.new(bx, 5.3, bz - 3.8), Vector3.new(6, 3.4, 0.1), { Color = Color3.fromRGB(160, 170, 160), Material = Enum.Material.Glass, Transparency = 0.5, Name = "BoothGlass" })
		B:part(Vector3.new(bx, 6.3, bz - 3.75), Vector3.new(6, 1.4, 0.06), { Color = Color3.fromRGB(200, 190, 150), Parent = "Decor", CanCollide = false, Name = "Blind" })
		B:span(Vector3.new(bx - 3.2, 3.4, bz - 4.8), Vector3.new(bx + 3.2, 3.6, bz - 3.6), { Color = Color3.fromRGB(150, 110, 70), Name = "Counter" })
		B:sign(Vector3.new(bx, 10.6, bz - 4.3), Vector3.new(8, 1.6, 0.3), "TICKETS", { Color = Color3.fromRGB(40, 50, 70), TextColor = Color3.fromRGB(200, 190, 150), Face = Enum.NormalId.Front, Font = Enum.Font.Antique, Parent = "Decor", CanCollide = false })
		-- old vending machines (one can on top)
		for i, x in { 22, 26, 30 } do
			B:span(Vector3.new(x - 1.9, 0, 38), Vector3.new(x + 1.9, 7.4, 41), { Color = ({ Color3.fromRGB(120, 40, 40), Color3.fromRGB(50, 70, 110), Color3.fromRGB(60, 90, 60) })[i], Material = Enum.Material.SmoothPlastic, Name = "OldVending" })
			B:part(Vector3.new(x, 4.6, 37.95), Vector3.new(3, 3.6, 0.1), { Color = Color3.fromRGB(80, 80, 70), Material = Enum.Material.Glass, Transparency = 0.3, Parent = "Decor", CanCollide = false })
		end
		B:span(Vector3.new(18, 0, 41), Vector3.new(20, 5.4, 43), { Color = Color3.fromRGB(100, 80, 60), Material = Enum.Material.WoodPlanks, Name = "Crate" })
		-- a broken balcony up on the left wall, reached by a ladder
		B:span(Vector3.new(-W / 2, 11.4, 38), Vector3.new(-W / 2 + 6, 12.2, 52), { Color = Color3.fromRGB(110, 90, 70), Material = Enum.Material.CorrodedMetal, Name = "Balcony" })
		B:truss(Vector3.new(-W / 2 + 7, 0, 50), 12.2)
		-- the collapsed bench, rubble, cobwebs, litter
		B:part(Vector3.new(-8, 1.2, 70), Vector3.new(6, 0.4, 2), { Color = Color3.fromRGB(100, 76, 52), Material = Enum.Material.Wood, Rot = Vector3.new(0, 0, 14), Name = "BrokenBench" })
		B:part(Vector3.new(-10.6, 0.6, 70), Vector3.new(0.4, 1.2, 1.8), { Color = C.darkSteel, Name = "BenchLeg" })
		local rng = Random.new(26)
		for k = 1, 10 do
			local p = Vector3.new(28 + rng:NextNumber(-5, 5), rng:NextNumber(0.4, 1.5), 74 + rng:NextNumber(-4, 4))
			B:part(p, Vector3.new(rng:NextNumber(1.5, 4), rng:NextNumber(0.8, 2.4), rng:NextNumber(1.5, 4)), { Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Concrete, Rot = Vector3.new(rng:NextNumber(-20, 20), rng:NextNumber(0, 90), rng:NextNumber(-20, 20)), Name = "Rubble" })
		end
		for _, c in { Vector3.new(-W / 2 + 1, 22, 2), Vector3.new(W / 2 - 1, 22, 2), Vector3.new(-W / 2 + 1, 22, 80), Vector3.new(W / 2 - 1, 22, 80) } do
			for k = 1, 3 do
				B:part(c + Vector3.new(0, -k * 0.6, 0), Vector3.new(0.05, 0.05, 4 - k), { Color = C.white, Transparency = 0.5, Rot = Vector3.new(0, 45 * (c.X > 0 and -1 or 1), 30), Parent = "Decor", CanCollide = false, Name = "Cobweb" })
			end
		end
		for _ = 1, 14 do
			B:part(Vector3.new(rng:NextNumber(-34, 34), 0.03, rng:NextNumber(4, 80)), Vector3.new(rng:NextNumber(0.6, 1.4), 0.05, rng:NextNumber(0.6, 1.4)), { Color = Color3.fromRGB(220, 214, 200), Rot = Vector3.new(0, rng:NextNumber(0, 90), 0), Parent = "Decor", CanCollide = false, Name = "Litter" })
		end
		-- peeling old adverts
		for _, z in { 40, 74 } do
			Decor.advert(B, Vector3.new(W / 2, 8, z), "-X")
		end
		-- the half-finished tags: faint outlines that get painted in
		for i, t in TAGS do
			local face, size
			if t.wall == "-X" then
				face, size = Enum.NormalId.Right, Vector3.new(0.1, 4, 14)
			elseif t.wall == "+X" then
				face, size = Enum.NormalId.Left, Vector3.new(0.1, 4, 14)
			else
				face, size = Enum.NormalId.Back, Vector3.new(14, 4, 0.1)
			end
			local off = t.wall == "-X" and Vector3.new(0.4, 0, 0) or t.wall == "+X" and Vector3.new(-0.4, 0, 0) or Vector3.new(0, 0, 0.45)
			local _, label = B:sign(t.pos + off, size, t.text, {
				Name = "Tag" .. i,
				Color = C.black,
				TextColor = Color3.fromRGB(150, 146, 136),
				Face = face,
				Font = Enum.Font.PermanentMarker,
				Parent = "Tags",
				CanCollide = false,
				LightInfluence = 1,
			})
			B:folder("Tags"):FindFirstChild("Tag" .. i).Transparency = 1
			label.TextTransparency = 0.6
		end
		for i, pos in CANS do
			-- 1 and 3 lie on their sides (3 is under the bench plank, which an
			-- upright can poked through)
			sprayCan(B, pos, TAGS[i].color, i, i == 1 or i == 3)
		end
		-- dust in the air
		local dustPart = B:part(Vector3.new(0, 12, 45), Vector3.new(70, 20, 80), { Name = "Dust", Transparency = 1, CanCollide = false, CanQuery = false, Parent = "Decor" })
		local dust = Instance.new("ParticleEmitter")
		dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		dust.Color = ColorSequence.new(Color3.fromRGB(220, 210, 190))
		dust.Rate = 15
		dust.Speed = NumberRange.new(0.2, 0.6)
		dust.Lifetime = NumberRange.new(6, 9)
		dust.Size = NumberSequence.new(0.15)
		dust.Transparency = NumberSequence.new(0.4, 1)
		dust.Parent = dustPart
	end,
	Run = function(ctx)
		local level = ctx.level
		ctx.def.OnCollect = function(_, _, part)
			local i = part:GetAttribute("Index")
			local tag = level.Tags:FindFirstChild("Tag" .. i)
			local label = tag and tag:FindFirstChild("Label", true)
			if label then
				label.TextColor3 = TAGS[i].color
				label.TextTransparency = 0
				Audio.play(tag, "steam", 0.4, 80)
			end
		end
	end,
}
