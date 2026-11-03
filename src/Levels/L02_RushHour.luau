-- Rush Hour (medium): a busy interchange concourse. Streams of commuters come
-- out of the archways on one side and disappear into the other. Get across
-- without being bowled over (that sends you back to your checkpoint).
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local H = require(root.LevelHelpers)
local Decor = require(root.Decor)
local C = BuildLib.C

local W, D = 72, 132
local LANES = { 18, 29, 40, 51, 81, 92, 103, 114 }
local PER_LANE = 3
local ARCH_W, ARCH_H = 7, 9

return {
	Order = 2,
	Name = "Rush Hour",
	Mode = "escape",
	TimeLimit = 100,
	Ambience = { { "crowd", 0.5 }, { "stationAmbience", 0.3 } },
	Build = function(B)
		local holes = {}
		for _, z in LANES do
			table.insert(holes, { side = -1, z - ARCH_W / 2, z + ARCH_W / 2, -0.01, ARCH_H })
			table.insert(holes, { side = 1, z - ARCH_W / 2, z + ARCH_W / 2, -0.01, ARCH_H })
		end
		B:room({
			W = W,
			D = D,
			H = 22,
			floorColor = Color3.fromRGB(176, 170, 160),
			floorMat = Enum.Material.Marble,
			wallColor = Color3.fromRGB(226, 218, 200),
			lowerColor = Color3.fromRGB(140, 60, 40),
			trim = Color3.fromRGB(230, 170, 40),
			sideHoles = holes,
			exit = { x = 0, y = 0 },
		})
		B:checkpoint(Vector3.new(0, 0.1, 6), Vector3.new(7, 0.2, 5))
		-- the archways and the wayfinding sign over each
		local signs = { "Platforms 1-2", "Way out", "Northbound", "Southbound", "Platforms 3-4", "Interchange", "Eastbound", "Westbound" }
		for i, z in LANES do
			for _, side in { -1, 1 } do
				B:recess(side, z, ARCH_W, ARCH_H, 8)
				local x = side * (W / 2 - 0.3)
				local face = side < 0 and "+X" or "-X"
				B:sign(Vector3.new(x, ARCH_H + 2.2, z), Decor.wallSize(face, 7, 1.4, 0.3), signs[(i + (side > 0 and 4 or 0) - 1) % #signs + 1], {
					Color = Color3.fromRGB(30, 50, 110),
					Face = Decor.FACE_NORMAL[face],
					Parent = "Decor",
					CanCollide = false,
				})
			end
		end
		-- ads on the side walls by the island
		for _, z in { 62, 70 } do
			Decor.advert(B, Vector3.new(-W / 2, 7, z), "+X")
			Decor.advert(B, Vector3.new(W / 2, 7, z), "-X")
		end
		-- the island in the middle: benches, a newsagent kiosk, the departure board
		B:span(Vector3.new(-16, 0, 59), Vector3.new(16, 0.4, 73), { Color = Color3.fromRGB(130, 126, 120), Material = Enum.Material.Concrete, Name = "Island" })
		B:checkpoint(Vector3.new(0, 0.5, 66), Vector3.new(8, 0.2, 5))
		Decor.bench(B, Vector3.new(-10, 0.4, 62), 0)
		Decor.bench(B, Vector3.new(-10, 0.4, 70), 180)
		B:span(Vector3.new(6, 0.4, 61), Vector3.new(14, 3.6, 71), { Color = Color3.fromRGB(30, 90, 60), Material = Enum.Material.Wood, Name = "Kiosk" })
		B:span(Vector3.new(5.6, 3.6, 60.6), Vector3.new(14.4, 4, 71.4), { Color = Color3.fromRGB(240, 236, 228), Name = "KioskCounter" })
		B:span(Vector3.new(6, 4, 70.6), Vector3.new(14, 9, 71), { Color = Color3.fromRGB(30, 90, 60), Name = "KioskBack" })
		for _, x in { 6.3, 13.7 } do
			B:part(Vector3.new(x, 6.5, 61.3), Vector3.new(0.5, 5, 0.5), { Color = Color3.fromRGB(30, 90, 60), Name = "KioskPost" })
		end
		B:span(Vector3.new(5.4, 9, 60.4), Vector3.new(14.6, 9.6, 71.6), { Color = Color3.fromRGB(200, 40, 40), Name = "KioskRoof" })
		for k = 0, 5 do
			B:part(Vector3.new(6.7 + k * 1.2, 4.7, 70.5), Vector3.new(1, 1.3, 0.1), { Color = ({ C.red, C.blue, C.yellow, C.green, C.orange, C.purple })[k + 1], Parent = "Decor", CanCollide = false, Name = "Magazine" })
		end
		for _, x in { -3, 3 } do
			B:part(Vector3.new(x, 11, 66), Vector3.new(1.6, 22, 1.6), { Color = Color3.fromRGB(226, 218, 200), Material = Enum.Material.Concrete, Name = "Column" })
		end
		B:sign(Vector3.new(0, 14, 66), Vector3.new(4.4, 3, 0.6), "12:04  NORTH\n12:07  SOUTH\n12:09  EAST", {
			Name = "Departures",
			Color = C.black,
			TextColor = Color3.fromRGB(255, 170, 40),
			Face = Enum.NormalId.Front,
			Font = Enum.Font.Arcade,
		})
		Decor.plant(B, Vector3.new(-14, 0.4, 60))
		Decor.plant(B, Vector3.new(-14, 0.4, 72))
		Decor.bin(B, Vector3.new(3.5, 0.4, 72))
		-- back wall either side of the exit
		Decor.plant(B, Vector3.new(-9, 0, D - 3))
		Decor.plant(B, Vector3.new(9, 0, D - 3))
		Decor.bench(B, Vector3.new(-22, 0, D - 3), 0)
		Decor.bench(B, Vector3.new(22, 0, D - 3), 0)
		Decor.advert(B, Vector3.new(-30, 7, D), "-Z")
		Decor.advert(B, Vector3.new(30, 7, D), "-Z")
		Decor.clock(B, Vector3.new(-14, 15, D - 0.4), "-Z")
		Decor.cctv(B, Vector3.new(W / 2 - 0.2, 17, 8), "-X")
		-- the commuters
		local rng = Random.new(2)
		for i, z in LANES do
			local dir = i % 2 == 0 and 1 or -1
			for k = 1, PER_LANE do
				local kind = rng:NextNumber() < 0.5 and "noob" or "guest"
				local npc = H.npc(B, Vector3.new(0, 0, z), kind, dir > 0 and -90 or 90, { Name = "Commuter", Hazard = true, Parent = "Crowd" })
				local speed = 8 + (i % 4) * 1.5
				npc:SetAttribute("Anim", "walk")
				npc:SetAttribute("Dir", dir)
				npc:SetAttribute("Speed", speed)
				npc:SetAttribute("AnimSpeed", speed / 14)
				npc:SetAttribute("Offset", (k - 1) / PER_LANE + rng:NextNumber() * 0.05)
			end
		end
	end,
	Run = function(ctx)
		-- walk each commuter across its lane forever, out of one archway's
		-- passage and into the opposite one
		local left = ctx.origin.X - W / 2 - 7
		local len = W + 14
		local crowd = {}
		for _, npc in ctx.level.Crowd:GetChildren() do
			local p = npc:GetPivot()
			table.insert(crowd, {
				m = npc,
				y = p.Position.Y,
				z = p.Position.Z,
				rot = p.Rotation,
				dir = npc:GetAttribute("Dir"),
				speed = npc:GetAttribute("Speed"),
				offset = npc:GetAttribute("Offset"),
			})
		end
		local t0 = os.clock()
		ctx:heartbeat(function()
			local t = os.clock() - t0
			for _, c in crowd do
				local u = (c.offset + t * c.speed / len) % 1
				local x = c.dir > 0 and left + u * len or left + (1 - u) * len
				c.m:PivotTo(CFrame.new(x, c.y, c.z) * c.rot)
			end
		end)
	end,
}
