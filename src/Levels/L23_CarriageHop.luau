-- Carriage Hop (medium-hard): a train yard where the trains sit down in deep
-- cuttings, roofs level with the ground. They shunt back and forth - hop from
-- roof to roof across both cuttings to the exit hut. Fall in and you're back
-- at your checkpoint.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local TrainKit = require(root.TrainKit)
local C = BuildLib.C

local W, D = 170, 160
local CUTS = { { 13, 56 }, { 70, 135 } }
-- lift = how far each train's roof sits above the ground
local LANES = {
	{ z = 24, lift = 0, speed = 8, phase = 0 },
	{ z = 45, lift = 0.5, speed = 10, phase = 0.4 },
	{ z = 81, lift = 0, speed = 9, phase = 0.2 },
	{ z = 102, lift = 0.7, speed = 12, phase = 0.65 },
	{ z = 123, lift = 0, speed = 11, phase = 0.85 },
}
local GROUND = Color3.fromRGB(110, 104, 96)

return {
	Order = 23,
	Name = "Carriage Hop",
	Mode = "escape",
	TimeLimit = 120,
	KillY = -10,
	Ambience = { { "refinery", 0.25 }, { "birds", 0.2 } },
	Build = function(B)
		-- the cuttings are exactly as deep as a train is tall (roofs at ground level)
		local ROOF = TrainKit.roofAboveTrack()
		local DEPTH = ROOF
		for _, lane in LANES do
			lane.rail = -ROOF + lane.lift
		end
		local pits = {}
		for _, c in CUTS do
			table.insert(pits, { c[1], c[2], DEPTH })
		end
		B:room({ W = W, D = D, outdoor = true, pitsZ = pits, ground = GROUND, groundMat = Enum.Material.Pebble, exit = { x = 0, z = D - 14 } })
		B:checkpoint(Vector3.new(0, 0.1, 6), Vector3.new(7, 0.2, 5))
		B:checkpoint(Vector3.new(0, 0.1, 63), Vector3.new(8, 0.2, 6))
		for i, lane in LANES do
			if lane.lift > 0 then
				-- a ballast embankment lifts this track off the cutting floor
				B:span(Vector3.new(-W / 2 - 100, -DEPTH, lane.z - 4), Vector3.new(W / 2 + 100, lane.rail, lane.z + 4), { Color = Color3.fromRGB(84, 78, 72), Material = Enum.Material.Pebble, Name = "Embankment" })
			end
			Decor.track(B, Vector3.new(-W / 2 - 100, lane.rail, lane.z), Vector3.new(W / 2 + 100, lane.rail, lane.z), false)
			local dir = i % 2 == 0 and 1 or -1
			local train = TrainKit.shell(B, Vector3.new(-dir * 32, lane.rail, lane.z), { Name = "Train" .. i, Parent = "Trains", flip = dir < 0 })
			if train then
				train:SetAttribute("MoveFrom", train:GetPivot().Position)
				train:SetAttribute("MoveTo", B:w(Vector3.new(dir * 32, lane.rail, lane.z)))
				train:SetAttribute("Speed", lane.speed)
				train:SetAttribute("Pause", 0.8)
				train:SetAttribute("Phase", lane.phase)
			end
		end
		-- yard dressing: floodlight towers, a signal gantry, sleeper stacks, relay huts
		for _, z in { 8, 63, 145 } do
			for _, x in { -70, 70 } do
				B:part(Vector3.new(x, 13, z), Vector3.new(1, 26, 1), { Color = C.darkSteel, Material = Enum.Material.Metal, Name = "FloodTower" })
				B:lamp(Vector3.new(x - math.sign(x) * 1.2, 26, z), Vector3.new(3, 1.6, 1.2), { Color = Color3.fromRGB(255, 240, 210), Range = 60, Brightness = 0.6, Face = Enum.NormalId.Bottom, Angle = 150, Glow = true })
			end
		end
		for _, x in { -60, 60 } do
			B:part(Vector3.new(x, 7, 59), Vector3.new(1, 14, 1), { Color = C.darkSteel, Material = Enum.Material.Metal, Name = "GantryLeg" })
		end
		B:part(Vector3.new(0, 14.5, 59), Vector3.new(122, 1.4, 1.4), { Color = C.darkSteel, Material = Enum.Material.Metal, Name = "Gantry" })
		for _, x in { -36, -12, 12, 36 } do
			B:part(Vector3.new(x, 12.6, 59), Vector3.new(1.4, 2.6, 1), { Color = C.black, Parent = "Decor", CanCollide = false, Name = "GantrySignal" })
			B:part(Vector3.new(x, 13.2, 58.45), Vector3.new(0.7, 0.7, 0.1), { Color = Color3.fromRGB(60, 220, 90), Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false })
		end
		for i, pos in { Vector3.new(-40, 0, 64), Vector3.new(44, 0, 6), Vector3.new(-50, 0, 145) } do
			for layer = 0, 3 do
				for k = 0, 4 do
					B:part(pos + Vector3.new(k * 1.2 - 2.4, 0.3 + layer * 0.6, 0), Vector3.new(1, 0.5, 7), { Color = Color3.fromRGB(100, 76, 52), Material = Enum.Material.Wood, Name = "Sleeper", Rot = Vector3.new(0, layer % 2 == 0 and 0 or 90, 0) })
				end
			end
		end
		for _, pos in { Vector3.new(24, 0, 64), Vector3.new(-24, 0, 6) } do
			B:span(pos - Vector3.new(4, 0, 3), pos + Vector3.new(4, 7, 3), { Color = Color3.fromRGB(120, 130, 120), Material = Enum.Material.Metal, Name = "RelayHut" })
			B:part(pos + Vector3.new(0, 7.2, 0), Vector3.new(8.6, 0.4, 6.6), { Color = Color3.fromRGB(80, 84, 88), Parent = "Decor", Name = "HutRoof" })
		end
		-- warning chevrons along the cutting edges
		for _, c in CUTS do
			for _, z in { c[1] - 0.6, c[2] + 0.6 } do
				B:part(Vector3.new(0, 0.02, z), Vector3.new(W, 0.04, 0.8), { Color = C.yellow, Parent = "Decor", CanCollide = false, Name = "EdgeLine" })
			end
		end
	end,
}
