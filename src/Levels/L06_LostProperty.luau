-- Lost Property (easy): the lost property storeroom. Eight suitcases with
-- sparkles are tucked among the shelves; the board behind the counter shows
-- an outline for each one, and fills it in when someone finds it. Find all
-- eight and the exit door opens.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 84, 104
local CASES = {
	{ color = Color3.fromRGB(200, 50, 50), pos = Vector3.new(-30, 0, 34) },
	{ color = Color3.fromRGB(50, 110, 200), pos = Vector3.new(-12, 3.2, 46) },
	{ color = Color3.fromRGB(60, 160, 80), pos = Vector3.new(26, 0, 60) },
	{ color = Color3.fromRGB(230, 170, 40), pos = Vector3.new(-24, 3.2, 74) },
	{ color = Color3.fromRGB(150, 70, 190), pos = Vector3.new(36, 3.2, 86) },
	{ color = Color3.fromRGB(240, 120, 40), pos = Vector3.new(6, 0, 90) },
	{ color = Color3.fromRGB(40, 170, 170), pos = Vector3.new(-36, 3.2, 92) },
	{ color = Color3.fromRGB(230, 100, 160), pos = Vector3.new(12, 3.2, 32) },
}

-- a proper little suitcase standing on its end, with a luggage tag
local function suitcase(B, base, color, i)
	local hit = B:part(base + Vector3.new(0, 1.8, 0), Vector3.new(3, 3.6, 3), {
		Name = "Suitcase" .. i,
		Transparency = 1,
		CanCollide = false,
		Parent = "Pickups",
		Attr = { Collectible = true, Index = i },
		Light = { Range = 10, Brightness = 1.2, Color = color },
	})
	local function add(off, size, col, props)
		props = props or {}
		props.Color = col
		props.Parent = hit
		props.CanCollide = false
		props.Name = props.Name or "Piece"
		return B:part(base + off, size, props)
	end
	add(Vector3.new(0, 1.6, 0), Vector3.new(2.2, 2.8, 1), color, { Material = Enum.Material.SmoothPlastic, Name = "Shell" })
	add(Vector3.new(0, 1.6, 0), Vector3.new(2.3, 0.25, 1.05), color:Lerp(Color3.new(0, 0, 0), 0.35))
	for _, x in { -0.45, 0.45 } do
		add(Vector3.new(x, 3.4, 0), Vector3.new(0.12, 0.8, 0.12), Color3.fromRGB(170, 170, 175))
	end
	add(Vector3.new(0, 3.8, 0), Vector3.new(1.1, 0.18, 0.25), Color3.fromRGB(30, 30, 30))
	for _, x in { -0.8, 0.8 } do
		add(Vector3.new(x, 0.15, 0.35), Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(20, 20, 20), { Shape = Enum.PartType.Ball })
	end
	add(Vector3.new(1.18, 2.6, 0), Vector3.new(0.05, 0.7, 0.45), Color3.fromRGB(245, 235, 200), { Name = "Tag" })
	local sparkle = Instance.new("Sparkles")
	sparkle.SparkleColor = color
	sparkle.Parent = hit
end

-- a long steel shelving unit with three shelves and boxes on them
local function shelving(B, x, z0, z1, rng)
	local len = z1 - z0
	for _, dz in { 0.3, len - 0.3 } do
		for _, dx in { -1.6, 1.6 } do
			B:part(Vector3.new(x + dx, 4.75, z0 + dz), Vector3.new(0.3, 9.5, 0.3), { Color = Color3.fromRGB(90, 96, 104), Material = Enum.Material.Metal, Name = "Upright" })
		end
	end
	for _, y in { 0.4, 3.2, 6.4, 9.4 } do
		B:part(Vector3.new(x, y - 0.1, (z0 + z1) / 2), Vector3.new(3.6, 0.2, len), { Color = Color3.fromRGB(120, 126, 134), Material = Enum.Material.Metal, Name = "Shelf" })
		if y < 9 then
			local z = z0 + 1.2
			while z < z1 - 1.5 do
				local w = rng:NextNumber(1.2, 2.4)
				local clear = true
				for _, cdef in CASES do
					if math.abs(cdef.pos.X - x) < 1 and math.abs(cdef.pos.Y - y) < 0.5 and math.abs(cdef.pos.Z - (z + w / 2)) < 3 then
						clear = false
					end
				end
				if clear and rng:NextNumber() < 0.75 then
					local h = rng:NextNumber(0.9, 2.2)
					B:part(Vector3.new(x + rng:NextNumber(-0.4, 0.4), y + h / 2, z + w / 2), Vector3.new(2.4, h, w), {
						Color = ({ Color3.fromRGB(170, 130, 90), Color3.fromRGB(150, 110, 75), Color3.fromRGB(120, 90, 60), Color3.fromRGB(70, 90, 130), Color3.fromRGB(140, 50, 50) })[rng:NextInteger(1, 5)],
						Material = Enum.Material.Cardboard,
						Parent = "Decor",
						Name = "Box",
					})
				end
				z += w + 0.4
			end
		end
	end
end

return {
	Order = 6,
	Name = "Lost Property",
	Mode = "escape",
	ExitLocked = true,
	TimeLimit = 120,
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 20,
			wallColor = Color3.fromRGB(226, 220, 204),
			floorColor = Color3.fromRGB(150, 120, 90),
			floorMat = Enum.Material.WoodPlanks,
			lowerColor = Color3.fromRGB(46, 96, 70),
			trim = Color3.fromRGB(230, 180, 50),
			brightness = 1.3,
			exit = { x = 0, y = 0 },
		})
		B:checkpoint(Vector3.new(0, 0.1, 5), Vector3.new(7, 0.2, 4))
		-- the counter and the board of outlines behind it (front-left corner)
		B:span(Vector3.new(-36, 0, 12), Vector3.new(-12, 3.6, 14), { Color = Color3.fromRGB(120, 84, 52), Material = Enum.Material.Wood, Name = "Counter" })
		B:span(Vector3.new(-36.2, 3.6, 11.8), Vector3.new(-11.8, 3.9, 14.2), { Color = Color3.fromRGB(230, 226, 214), Material = Enum.Material.Marble, Name = "CounterTop" })
		B:part(Vector3.new(-30, 4.3, 13), Vector3.new(1.2, 0.8, 1.2), { Color = Color3.fromRGB(200, 170, 60), Material = Enum.Material.Metal, Parent = "Decor", Name = "Bell" })
		B:part(Vector3.new(-24, 9, 1.15), Vector3.new(24, 7, 0.3), { Color = Color3.fromRGB(46, 96, 70), Parent = "Decor", CanCollide = false, Name = "Board" })
		for i, cdef in CASES do
			local x = -32.5 + ((i - 1) % 4) * 5.7
			local y = ((i - 1) < 4) and 10.6 or 7.3
			B:part(Vector3.new(x, y, 1.35), Vector3.new(2.6, 2.6, 0.1), {
				Name = "Slot" .. i,
				Color = Color3.fromRGB(30, 60, 45),
				Parent = "Board",
				CanCollide = false,
			})
			B:part(Vector3.new(x, y + 1.6, 1.35), Vector3.new(0.6, 0.4, 0.1), { Color = Color3.fromRGB(30, 60, 45), Parent = "Decor", CanCollide = false })
		end
		local clerk = require(root.LevelHelpers).figure(B, Vector3.new(-24, 0, 8), { Name = "Clerk", Shirt = C.tileGreen, Avatar = "TylerLeprune", Label = "Tyler" })
		clerk:PivotTo(clerk:GetPivot() * CFrame.Angles(0, math.rad(180), 0))
		-- shelving rows (aisles are 9 studs wide)
		local rng = Random.new(6)
		for _, x in { -36, -24, -12, 12, 24, 36 } do
			shelving(B, x, 26, 58, rng)
			shelving(B, x, 66, 98, rng)
		end
		-- a sorting table and trolleys in the central aisle
		B:span(Vector3.new(-3, 3, 40), Vector3.new(3, 3.4, 52), { Color = Color3.fromRGB(120, 84, 52), Material = Enum.Material.Wood, Name = "Table" })
		for _, pos in { Vector3.new(-2.6, 0, 40.4), Vector3.new(2.6, 0, 40.4), Vector3.new(-2.6, 0, 51.6), Vector3.new(2.6, 0, 51.6) } do
			B:part(pos + Vector3.new(0, 1.5, 0), Vector3.new(0.4, 3, 0.4), { Color = Color3.fromRGB(80, 60, 40), Name = "TableLeg" })
		end
		for i, cdef in CASES do
			suitcase(B, cdef.pos, cdef.color, i)
		end
		Decor.plant(B, Vector3.new(36, 0, 6))
		Decor.cctv(B, Vector3.new(W / 2 - 0.2, 16, 30), "-X")
	end,
	Run = function(ctx)
		local level = ctx.level
		local slots = {}
		for _, s in level.Board:GetChildren() do
			slots[tonumber(s.Name:match("%d+"))] = s
		end
		ctx.def.OnCollect = function(_, _, part)
			local i = part:GetAttribute("Index")
			local slot = slots[i]
			if slot then
				-- fill in that suitcase's outline on the board
				slot.Color = CASES[i].color
				slot.Material = Enum.Material.Neon
				Audio.play(slot, "ding", 0.6, 200)
			end
		end
	end,
}
