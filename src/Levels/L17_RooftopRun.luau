-- Rooftop Run (easy-medium): the stairs come out on the station roof. Run
-- across the city rooftops - gaps, a plank, a window-cleaner's cradle,
-- chimney stacks - to the stairwell hut on the last roof. Don't look down.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Ads = require(root.Ads)
local C = BuildLib.C

local STREET_Y = -70
local ROOF = Color3.fromRGB(140, 136, 130)
local BRICKS = { Color3.fromRGB(160, 90, 70), Color3.fromRGB(180, 160, 130), Color3.fromRGB(120, 120, 130), Color3.fromRGB(150, 110, 90), Color3.fromRGB(200, 196, 186) }

-- a building whose roof is the rectangle x0..x1, z0..z1 at height top
local function building(B, x0, x1, z0, z1, top, color)
	B:span(Vector3.new(x0, STREET_Y, z0), Vector3.new(x1, top - 0.6, z1), { Color = color, Material = Enum.Material.Brick, Name = "Building" })
	B:span(Vector3.new(x0, top - 0.6, z0), Vector3.new(x1, top, z1), { Color = ROOF, Material = Enum.Material.Concrete, Name = "Roof" })
	-- low parapet ledge round the roof edge (visual, walkable)
	for _, e in { { x0, x1, z0, z0 + 0.6 }, { x0, x1, z1 - 0.6, z1 }, { x0, x0 + 0.6, z0, z1 }, { x1 - 0.6, x1, z0, z1 } } do
		B:span(Vector3.new(e[1], top, e[3]), Vector3.new(e[2], top + 0.5, e[4]), { Color = color:Lerp(Color3.new(1, 1, 1), 0.2), Material = Enum.Material.Concrete, Name = "Parapet" })
	end
	-- windows down the sides you can see
	for y = top - 6, STREET_Y + 10, -8 do
		for x = x0 + 3, x1 - 3, 5 do
			B:part(Vector3.new(x, y, z0 - 0.05), Vector3.new(2.4, 3.4, 0.1), { Color = Color3.fromRGB(70, 100, 130), Material = Enum.Material.Glass, Parent = "Scenery", CanCollide = false, Name = "Window" })
		end
	end
end

local function acUnit(B, pos)
	B:span(pos - Vector3.new(2, 0, 1.5), pos + Vector3.new(2, 2.6, 1.5), { Color = Color3.fromRGB(190, 194, 198), Material = Enum.Material.Metal, Name = "ACUnit" })
	B:cyl(pos + Vector3.new(0, 2.65, 0), 0.1, 2.4, "Y", { Color = Color3.fromRGB(40, 40, 44), Parent = "Decor", CanCollide = false, Name = "Fan" })
end

return {
	Order = 17,
	Name = "Rooftop Run",
	Mode = "escape",
	TimeLimit = 110,
	KillY = -14,
	Ambience = { { "birds", 0.4 } },
	Build = function(B)
		B.model:SetAttribute("Outdoor", true) -- open sky: outdoor base lighting
		-- the station building you step out of (its roof is the first roof)
		B:wallZ(0, 1, -40, 40, STREET_Y, 14, { { -B.DOOR_W / 2, B.DOOR_W / 2, -1, B.DOOR_H } }, { Color = Color3.fromRGB(150, 86, 66), Material = Enum.Material.Brick, Name = "StationWall" })
		B:doorFrame(0, 0, 1, 1, Color3.fromRGB(200, 196, 186))
		B:span(Vector3.new(-12, STREET_Y, 1), Vector3.new(12, -0.6, 16), { Color = Color3.fromRGB(150, 86, 66), Material = Enum.Material.Brick, Name = "StationRoofBlock" })
		B:span(Vector3.new(-12, -0.6, 1), Vector3.new(12, 0, 16), { Color = ROOF, Material = Enum.Material.Concrete, Name = "Roof" })
		B:checkpoint(Vector3.new(0, 0.1, 8), Vector3.new(7, 0.2, 5))
		-- the rooftops
		building(B, -14, 6, 22, 40, 2, BRICKS[1])
		acUnit(B, Vector3.new(-9, 2, 30))
		acUnit(B, Vector3.new(1, 2, 35))
		building(B, 4, 22, 46, 60, 5, BRICKS[2])
		-- billboard on its roof, showing one of the station's ads
		for _, x in { 7, 19 } do
			B:part(Vector3.new(x, 9, 58), Vector3.new(0.6, 8, 0.6), { Color = C.darkSteel, Material = Enum.Material.Metal, Name = "BillboardLeg" })
		end
		Ads.board(B, Vector3.new(13, 12, 58.5), "-Z", 14, 7)
		-- plank across to the next roof, resting on both (it slopes down 2)
		B:part(Vector3.new(6, 3.85, 67), Vector3.new(2.2, 0.4, 15.4), { Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.WoodPlanks, Name = "Plank", Rot = Vector3.new(math.deg(math.atan2(2, 14)), 0, 0) })
		building(B, -6, 14, 74, 92, 3, BRICKS[3])
		B:checkpoint(Vector3.new(4, 3.1, 84), Vector3.new(6, 0.2, 5))
		-- water tower
		for _, dx in { -1.6, 1.6 } do
			for _, dz in { -1.6, 1.6 } do
				B:part(Vector3.new(-1 + dx, 6, 78 + dz), Vector3.new(0.4, 6, 0.4), { Color = Color3.fromRGB(110, 80, 60), Material = Enum.Material.Wood, Name = "TowerLeg" })
			end
		end
		B:cyl(Vector3.new(-1, 11, 78), 5, 5, "Y", { Color = Color3.fromRGB(130, 90, 60), Material = Enum.Material.WoodPlanks, Name = "WaterTower" })
		B:cyl(Vector3.new(-1, 14, 78), 1.2, 5.6, "Y", { Color = Color3.fromRGB(60, 60, 64), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "TowerRoof" })
		-- window-cleaner's cradle: a flat platform hung on two ropes from a
		-- trolley that runs along an overhead I-beam. The beam sits on a post
		-- (with an arm out over the gap) on this roof and a post on the next.
		local BEAM_Y = 20.5
		local STEEL = Color3.fromRGB(70, 74, 82)
		B:span(Vector3.new(11.5, 3, 89.5), Vector3.new(12.5, BEAM_Y + 0.5, 90.5), { Color = STEEL, Material = Enum.Material.Metal, Name = "GantryPost" })
		-- pieces butt against each other instead of overlapping (shared faces
		-- between the post, arm and beam Z-fought)
		B:span(Vector3.new(11.55, BEAM_Y - 0.45, 90.5), Vector3.new(12.45, BEAM_Y + 0.45, 97.4), { Color = STEEL, Material = Enum.Material.Metal, Name = "GantryArm" })
		B:span(Vector3.new(36, 4, 97.5), Vector3.new(37, BEAM_Y - 0.7, 98.5), { Color = STEEL, Material = Enum.Material.Metal, Name = "GantryPost" })
		B:span(Vector3.new(35.2, 4, 96.7), Vector3.new(37.8, 4.4, 99.3), { Color = STEEL, Material = Enum.Material.Metal, Name = "PostFoot" })
		-- the I-beam: web plus top and bottom flanges
		B:span(Vector3.new(11.5, BEAM_Y - 0.5, 97.8), Vector3.new(37, BEAM_Y + 0.5, 98.2), { Color = Color3.fromRGB(230, 180, 40), Material = Enum.Material.Metal, Name = "BeamWeb" })
		for _, y in { BEAM_Y - 0.6, BEAM_Y + 0.6 } do
			B:span(Vector3.new(11.5, y - 0.1, 97.4), Vector3.new(37, y + 0.1, 98.6), { Color = Color3.fromRGB(230, 180, 40), Material = Enum.Material.Metal, Name = "BeamFlange" })
		end
		local cradle = Instance.new("Model")
		cradle.Name = "Cradle"
		local deck = B:part(Vector3.new(16, 3.5, 98), Vector3.new(6, 0.6, 4), { Name = "Deck", Color = Color3.fromRGB(240, 190, 40), Material = Enum.Material.DiamondPlate, Parent = B.model })
		deck.Parent = cradle
		local trolley = B:part(Vector3.new(16, BEAM_Y - 1.2, 98), Vector3.new(3, 0.8, 1.6), { Name = "Trolley", Color = STEEL, Material = Enum.Material.Metal, Parent = B.model, CanCollide = false })
		trolley.Parent = cradle
		for _, s in { -1, 1 } do
			-- rope from the trolley out to each end of the deck
			local top = Vector3.new(16 + s * 1.2, BEAM_Y - 1.6, 98)
			local bottom = Vector3.new(16 + s * 2.7, 3.8, 98)
			local mid = (top + bottom) / 2
			local rope = B:part(mid, Vector3.new(0.14, (top - bottom).Magnitude, 0.14), { Color = C.black, Parent = B.model, Name = "Rope", CanCollide = false })
			rope.CFrame = CFrame.lookAt(B:w(mid), B:w(top)) * CFrame.Angles(math.rad(90), 0, 0)
			rope.Parent = cradle
			local eye = B:part(bottom + Vector3.new(0, 0.1, 0), Vector3.new(0.4, 0.4, 0.4), { Color = STEEL, Parent = B.model, Name = "RopeEye", CanCollide = false })
			eye.Parent = cradle
		end
		cradle.PrimaryPart = deck
		cradle:SetAttribute("MoveFrom", B:w(Vector3.new(16, 3.5, 98)))
		cradle:SetAttribute("MoveTo", B:w(Vector3.new(30, 3.5, 98)))
		cradle:SetAttribute("Speed", 5)
		cradle:SetAttribute("Pause", 1.5)
		cradle.Parent = B:folder("Structure")
		building(B, 34, 50, 92, 112, 4, BRICKS[4])
		acUnit(B, Vector3.new(44, 4, 108))
		-- chimney stacks to hop along
		for i, c in { { 42, 7, 118 }, { 36, 9, 124 }, { 28, 11, 129 } } do
			B:span(Vector3.new(c[1] - 2, STREET_Y, c[3] - 2), Vector3.new(c[1] + 2, c[2], c[3] + 2), { Color = BRICKS[5], Material = Enum.Material.Brick, Name = "Chimney" .. i })
			B:part(Vector3.new(c[1], c[2] + 0.2, c[3]), Vector3.new(4.4, 0.4, 4.4), { Color = Color3.fromRGB(110, 106, 100), Name = "ChimneyCap" })
		end
		-- the last roof and the stairwell down
		building(B, -10, 30, 134, 160, 12, BRICKS[1])
		B:checkpoint(Vector3.new(20, 12.1, 140), Vector3.new(6, 0.2, 5))
		B:exitHut(4, 146, 12)
		-- the city: a street far below, buildings all around
		B:span(Vector3.new(-200, STREET_Y - 2, -10), Vector3.new(220, STREET_Y, 260), { Color = Color3.fromRGB(60, 62, 66), Material = Enum.Material.Asphalt, Name = "Street" })
		local rng = Random.new(17)
		for _, spec in { { -90, -50, -10, 200 }, { 60, 110, -10, 200 }, { -90, 110, 170, 230 } } do
			local x = spec[1]
			while x < spec[2] do
				local w = rng:NextNumber(14, 22)
				local z = spec[3]
				while z < spec[4] do
					local d = rng:NextNumber(16, 26)
					B:span(Vector3.new(x, STREET_Y, z), Vector3.new(x + w - 2, rng:NextNumber(0, 40), z + d - 2), {
						Color = BRICKS[rng:NextInteger(1, #BRICKS)],
						Material = Enum.Material.Brick,
						Name = "CityBlock",
						Parent = "Scenery",
					})
					z += d
				end
				x += w
			end
		end
		-- invisible bounds round the play area
		local inv = { Transparency = 1, CastShadow = false, Name = "Bounds" }
		B:span(Vector3.new(-30, -20, 0), Vector3.new(-29, 80, 170), inv)
		B:span(Vector3.new(56, -20, 0), Vector3.new(57, 80, 170), inv)
		B:span(Vector3.new(-30, -20, 165), Vector3.new(57, 80, 166), inv)
	end,
}
