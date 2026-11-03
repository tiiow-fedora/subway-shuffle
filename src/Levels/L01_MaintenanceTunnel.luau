-- Maintenance Tunnel (medium): the track-maintenance tunnel behind the
-- station. Hop across the concrete pillars over the live rails, ride the
-- maintenance trolley, then jump the swinging power cables to the exit.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local C = BuildLib.C

local W, D = 44, 152
local CONCRETE = Color3.fromRGB(150, 146, 140)

local function pillar(B, x, z, top, size)
	size = size or 4.5
	B:span(Vector3.new(x - size / 2, -14, z - size / 2), Vector3.new(x + size / 2, top, z + size / 2), { Name = "Pillar", Color = CONCRETE, Material = Enum.Material.Concrete })
	-- yellow caution edge round the top
	B:part(Vector3.new(x, top + 0.03, z), Vector3.new(size, 0.06, size), { Color = Color3.fromRGB(235, 190, 40), Parent = "Decor", CanCollide = false, Name = "Cap" })
	B:part(Vector3.new(x, top + 0.05, z), Vector3.new(size - 0.8, 0.06, size - 0.8), { Color = CONCRETE, Material = Enum.Material.Concrete, Parent = "Decor", CanCollide = false, Name = "CapInner" })
end

return {
	Order = 1,
	Name = "Maintenance Tunnel",
	Mode = "escape",
	TimeLimit = 110,
	KillY = -10,
	Ambience = { { "electricBuzz", 0.06 }, { "refinery", 0.15 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 24,
			floor = false,
			bottom = -16,
			wallColor = Color3.fromRGB(150, 150, 146),
			wallMat = Enum.Material.Concrete,
			lowerColor = Color3.fromRGB(70, 72, 78),
			trim = Color3.fromRGB(235, 190, 40),
			lampColor = Color3.fromRGB(255, 225, 170),
			exit = { x = 0, y = 0 },
		})
		-- the pit: ballast and three live rails glowing along the bottom
		B:span(Vector3.new(-W / 2, -16, 1), Vector3.new(W / 2, -14, D), { Name = "Ballast", Color = Color3.fromRGB(70, 66, 62), Material = Enum.Material.Pebble })
		for _, x in { -12, 0, 12 } do
			local rail = B:part(Vector3.new(x, -13.6, D / 2), Vector3.new(1, 0.8, D - 2), { Name = "LiveRail", Color = Color3.fromRGB(80, 170, 255), Material = Enum.Material.Neon, Hazard = true, Light = { Range = 14, Brightness = 1, Color = Color3.fromRGB(80, 170, 255) } })
			local sparks = Instance.new("Sparkles")
			sparks.SparkleColor = Color3.fromRGB(150, 210, 255)
			sparks.Parent = rail
		end
		-- start platform
		B:span(Vector3.new(-W / 2, -14, 1), Vector3.new(W / 2, 0, 14), { Name = "StartPlatform", Color = CONCRETE, Material = Enum.Material.Concrete })
		B:part(Vector3.new(0, 0.03, 13.4), Vector3.new(W, 0.06, 1.2), { Color = Color3.fromRGB(235, 190, 40), Parent = "Decor", CanCollide = false, Name = "Edge" })
		B:checkpoint(Vector3.new(0, 0.1, 7), Vector3.new(7, 0.2, 5))
		-- pillars, zig-zagging and getting further apart
		local pillars = { { -6, 19 }, { 4, 25 }, { -4, 31.5 }, { 7, 38 }, { -2, 45 } }
		for i, p in pillars do
			pillar(B, p[1], p[2], i * 0.3)
		end
		B:span(Vector3.new(-W / 2, -14, 50), Vector3.new(W / 2, 1.5, 60), { Name = "MidPlatform", Color = CONCRETE, Material = Enum.Material.Concrete })
		B:checkpoint(Vector3.new(0, 1.6, 55), Vector3.new(7, 0.2, 5))
		-- maintenance trolley on an overhead rail
		local trolley = Instance.new("Model")
		trolley.Name = "Trolley"
		local deck = B:part(Vector3.new(0, 1, 65), Vector3.new(7, 1, 7), { Name = "Deck", Color = Color3.fromRGB(230, 170, 40), Material = Enum.Material.DiamondPlate, Parent = B.model })
		deck.Parent = trolley
		for _, x in { -3.2, 3.2 } do
			local rail = B:part(Vector3.new(x, 2.6, 65), Vector3.new(0.3, 2.2, 7), { Color = Color3.fromRGB(230, 170, 40), Parent = B.model, Name = "Guard" })
			rail.Parent = trolley
		end
		for _, x in { -3, 3 } do
			local hanger = B:part(Vector3.new(x, 10.5, 65), Vector3.new(0.4, 18, 0.4), { Color = C.darkSteel, Parent = B.model, Name = "Hanger", CanCollide = false })
			hanger.Parent = trolley
		end
		trolley.PrimaryPart = deck
		trolley:SetAttribute("MoveFrom", B:w(Vector3.new(0, 1, 65)))
		trolley:SetAttribute("MoveTo", B:w(Vector3.new(0, 1, 91)))
		trolley:SetAttribute("Speed", 6)
		trolley:SetAttribute("Pause", 1.5)
		trolley.Parent = B:folder("Structure")
		B:part(Vector3.new(0, 19.6, 78), Vector3.new(8, 0.8, 34), { Color = C.darkSteel, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "TrolleyRail" })
		B:span(Vector3.new(-W / 2, -14, 96), Vector3.new(W / 2, 1.5, 104), { Name = "Platform3", Color = CONCRETE, Material = Enum.Material.Concrete })
		B:checkpoint(Vector3.new(0, 1.6, 100), Vector3.new(7, 0.2, 5))
		-- girder walkway with two swinging cables
		B:span(Vector3.new(-2, -14, 104), Vector3.new(2, 1.5, 132), { Name = "Girder", Color = Color3.fromRGB(150, 70, 50), Material = Enum.Material.CorrodedMetal })
		-- each cable hangs from a reel on a ceiling mount: rope down to a live
		-- cable end that swings side to side across the girder (LiveCableN is
		-- the hazard; the rope is just rope)
		for i, z in { 112, 124 } do
			B:part(Vector3.new(0, 21.4, z), Vector3.new(1, 5.2, 1), { Color = C.darkSteel, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "ReelMount" })
			B:part(Vector3.new(0, 23.7, z), Vector3.new(4, 0.6, 2.4), { Color = C.darkSteel, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "ReelPlate" })
			B:cyl(Vector3.new(0, 18, z), 1.8, 2.2, "Z", { Color = Color3.fromRGB(60, 62, 68), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "CableReel" })
			for _, dz in { -1.05, 1.05 } do
				B:cyl(Vector3.new(0, 18, z + dz), 0.2, 2.8, "Z", { Color = Color3.fromRGB(235, 190, 40), Parent = "Decor", CanCollide = false, Name = "ReelFlange" })
			end
			local swing = Instance.new("Model")
			swing.Name = "Swing" .. i
			local rope = B:part(Vector3.new(0, 18 - 7.4, z), Vector3.new(0.35, 14.8, 0.35), { Color = Color3.fromRGB(30, 30, 32), Parent = B.model, CanCollide = false, Name = "Rope" })
			rope.Parent = swing
			local clamp = B:part(Vector3.new(0, 3.5, z), Vector3.new(0.9, 0.9, 0.9), { Color = C.darkSteel, Material = Enum.Material.Metal, Parent = B.model, CanCollide = false, Name = "Clamp" })
			clamp.Parent = swing
			local live = B:cyl(Vector3.new(0, 2.6, z), 5, 1.2, "Z", {
				Name = "LiveCable" .. i,
				Color = Color3.fromRGB(80, 170, 255),
				Material = Enum.Material.Neon,
				Hazard = true,
				CanCollide = false,
				Parent = B.model,
				Light = { Range = 10, Brightness = 0.8, Color = Color3.fromRGB(80, 170, 255) },
			})
			live.Parent = swing
			swing.Parent = B:folder("Structure")
		end
		B:span(Vector3.new(-W / 2, -14, 132), Vector3.new(W / 2, 0, D), { Name = "EndPlatform", Color = CONCRETE, Material = Enum.Material.Concrete })
		B:part(Vector3.new(0, 0.03, 132.6), Vector3.new(W, 0.06, 1.2), { Color = Color3.fromRGB(235, 190, 40), Parent = "Decor", CanCollide = false, Name = "Edge" })
		-- tunnel dressing: cable trays down both walls, work lamps in cages
		for _, x in { -W / 2 + 0.6, W / 2 - 0.6 } do
			for _, y in { 8, 9.2, 10.4 } do
				Decor.pipe(B, Vector3.new(x, y, 2), Vector3.new(x, y, D - 2), 0.35, y == 9.2 and Color3.fromRGB(160, 40, 30) or C.black)
			end
		end
		Decor.cctv(B, Vector3.new(W / 2 - 0.2, 16, 52), "-X")
	end,
	Run = function(ctx)
		-- the live cables swing like pendulums across the girder
		local swings = {}
		for _, m in ctx.level.Structure:GetChildren() do
			if m:IsA("Model") and m.Name:match("^Swing") then
				local parts = {}
				local pivot
				for _, p in m:GetChildren() do
					parts[p] = p.CFrame
					if p.Name == "Rope" then
						pivot = p.Position + Vector3.new(0, p.Size.Y / 2, 0)
					end
				end
				table.insert(swings, { parts = parts, pivot = CFrame.new(pivot) })
			end
		end
		local t0 = os.clock()
		ctx:heartbeat(function()
			local t = os.clock() - t0
			for i, s in swings do
				local a = math.sin(t * (1.1 + i * 0.25) + i) * math.rad(62)
				local rot = s.pivot * CFrame.Angles(0, 0, a) * s.pivot:Inverse()
				for p, base in s.parts do
					p.CFrame = rot * base
				end
			end
		end)
	end,
}
