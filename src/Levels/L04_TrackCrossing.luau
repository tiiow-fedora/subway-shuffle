-- Track Crossing (medium): a big open-air rail yard. Trains come from far
-- away on both sides; the signals at the crossing go red while one is near.
-- Cross all eight tracks to the exit hut.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local TrainKit = require(root.TrainKit)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 120, 236
local TRACKS = { 22, 46, 70, 94, 136, 160, 184, 208 }
local RUN = 260 -- how far out the trains start

local function signal(B, x, z, n)
	B:part(Vector3.new(x, 3, z), Vector3.new(0.5, 6, 0.5), { Color = C.darkSteel, Material = Enum.Material.Metal, Parent = "Decor", Name = "SignalPost" })
	B:part(Vector3.new(x, 6.8, z), Vector3.new(1.4, 3, 1.1), { Color = Color3.fromRGB(20, 20, 22), Parent = "Decor", Name = "SignalHead" })
	B:part(Vector3.new(x, 7.6, z - 0.6), Vector3.new(0.8, 0.8, 0.1), {
		Name = "Warn" .. n,
		Color = C.green,
		Material = Enum.Material.Neon,
		Parent = "Signals",
		CanCollide = false,
		Light = { Range = 10, Brightness = 1, Color = C.green },
	})
end

return {
	Order = 4,
	Name = "Track Crossing",
	Mode = "escape",
	TimeLimit = 110,
	Ambience = { { "birds", 0.3 } },
	Build = function(B)
		local clear = {}
		for _, z in TRACKS do
			table.insert(clear, { z - 10, z + 10 })
		end
		B:room({ W = W, D = D, outdoor = true, noHedge = { left = true, right = true }, clearZ = clear, groundMat = Enum.Material.Grass, exit = { x = 0, z = D - 12 } })
		B:checkpoint(Vector3.new(0, 0.1, 7), Vector3.new(7, 0.2, 5))
		-- side boundaries: hedge sections between the tracks (trains pass through the gaps)
		local gaps = {}
		for _, z in TRACKS do
			table.insert(gaps, { z - 7, z + 7 })
		end
		for _, side in { -1, 1 } do
			local x = side * (W / 2 + 1.5)
			local z = 1
			for _, g in gaps do
				if g[1] > z then
					B:hedge(Vector3.new(x - 1.5, 0, z), Vector3.new(x + 1.5, 0, g[1]), 4)
				end
				z = g[2]
			end
			B:hedge(Vector3.new(x - 1.5, 0, z), Vector3.new(x + 1.5, 0, D), 4)
		end
		for i, z in TRACKS do
			Decor.track(B, Vector3.new(-W / 2 - RUN, 0.3, z), Vector3.new(W / 2 + RUN, 0.3, z), false)
			local dir = i % 2 == 0 and 1 or -1
			local train = TrainKit.shell(B, Vector3.new(-dir * (W / 2 + RUN - 70), 0.3, z), { Name = "Train" .. i, Hazard = true, Parent = "Trains", flip = dir < 0 })
			if train then
				train:SetAttribute("MoveFrom", train:GetPivot().Position)
				train:SetAttribute("MoveTo", B:w(Vector3.new(dir * (W / 2 + RUN - 70), 0.3, z)))
				train:SetAttribute("Speed", 46 + i * 2)
				train:SetAttribute("Pause", 1.2 + (i % 3) * 0.8)
				train:SetAttribute("Phase", i * 0.137)
			end
			-- signals beside each crossing point
			for _, x in { -44, -15, 15, 44 } do
				signal(B, x, z - 8.5, i)
			end
		end
		-- the middle: a raised walkway with a yard hut, oil drums and floodlights
		B:span(Vector3.new(-W / 2, -0.2, 106), Vector3.new(W / 2, 0.4, 124), { Name = "Walkway", Color = Color3.fromRGB(150, 146, 140), Material = Enum.Material.Concrete })
		for _, z in { 106.6, 123.4 } do
			B:part(Vector3.new(0, 0.42, z), Vector3.new(W, 0.04, 0.6), { Color = C.yellow, Parent = "Decor", CanCollide = false })
		end
		B:checkpoint(Vector3.new(0, 0.5, 115), Vector3.new(10, 0.2, 6))
		B:span(Vector3.new(-46, 0.4, 109), Vector3.new(-34, 9.4, 121), { Color = Color3.fromRGB(60, 100, 70), Material = Enum.Material.WoodPlanks, Name = "Hut" })
		B:span(Vector3.new(-46.6, 9.4, 108.4), Vector3.new(-33.4, 10, 121.6), { Color = Color3.fromRGB(50, 50, 52), Material = Enum.Material.CorrodedMetal, Name = "HutRoof" })
		B:part(Vector3.new(-40, 5.4, 108.95), Vector3.new(4, 2.4, 0.1), { Color = Color3.fromRGB(220, 200, 150), Material = Enum.Material.Glass, Parent = "Decor", CanCollide = false })
		B:part(Vector3.new(-36, 4.2, 108.95), Vector3.new(2.4, 7.6, 0.1), { Color = Color3.fromRGB(90, 60, 40), Parent = "Decor", CanCollide = false })
		for k = 0, 2 do
			B:cyl(Vector3.new(36 + k * 2.6, 2.0, 115), 3.2, 2.2, "Y", { Color = ({ C.blue, Color3.fromRGB(180, 60, 40), C.darkSteel })[k + 1], Material = Enum.Material.Metal, Name = "Drum" })
		end
		for _, z in { 30, 115, 200 } do
			for _, x in { -W / 2 + 4, W / 2 - 4 } do
				B:part(Vector3.new(x, 11, z), Vector3.new(0.7, 22, 0.7), { Color = C.darkSteel, Material = Enum.Material.Metal, Name = "LightPole" })
				B:lamp(Vector3.new(x - math.sign(x) * 1, 22, z), Vector3.new(2.2, 1.2, 1.4), { Color = Color3.fromRGB(255, 236, 200), Range = 45, Brightness = 0.6, Face = Enum.NormalId.Bottom, Angle = 140, Glow = true })
			end
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local list = {}
		for _, t in level.Trains:GetChildren() do
			local n = t.Name:match("%d+")
			for _, lamp in level.Signals:GetChildren() do
				if lamp.Name == "Warn" .. n then
					table.insert(list, { train = t, lamp = lamp })
				end
			end
		end
		-- red while a train is over the crossing, or heading for it and less
		-- than ~2.5 seconds away; green again as soon as its tail has passed
		local warned, lastX = {}, {}
		local HALF = W / 2 + 62
		ctx:every(0.1, function()
			for _, e in list do
				local x = e.train:GetPivot().Position.X - ctx.origin.X
				local prev = lastX[e] or x
				lastX[e] = x
				local approaching = (x - prev) * x < 0
				local danger = math.abs(x) < HALF or (approaching and math.abs(x) < HALF + 125)
				e.lamp.Color = danger and C.red or C.green
				local l = e.lamp:FindFirstChildWhichIsA("Light")
				if l then
					l.Color = e.lamp.Color
				end
				if danger and not warned[e.train] then
					warned[e.train] = true
					Audio.play(e.train:GetPivot().Position, "trainPass", 1, 200)
				elseif not danger then
					warned[e.train] = nil
				end
			end
		end)
	end,
}
