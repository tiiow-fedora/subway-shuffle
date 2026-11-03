-- Ventilation Shaft (medium): climb the maintenance ledges spiralling up the
-- inside of the big ventilation shaft. Small steps, short gaps; the yellow
-- striped ledges slide, and the wall vents glow orange before they puff steam.
-- Three rest landings have checkpoints. The exit is on the top floor.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D, HGT = 44, 44, 104
local INSET_X, Z0, Z1 = 18, 6, 38
local SPACING, RISE = 7, 2.2
local COUNT = 42
local TOP_Y = COUNT * RISE
local STEEL = Color3.fromRGB(110, 116, 124)
local YELLOW = Color3.fromRGB(240, 190, 40)
local TRIM = Color3.fromRGB(60, 220, 255) -- neon edge on every ledge you can use
local DEPTH = 22 - (INSET_X - 2.5) -- ledges run from the wall out to the path

-- size of a ledge: `along` in the walking direction, DEPTH out from the wall
local function ledgeSize(wallDir, along, h)
	if wallDir.X ~= 0 then
		return Vector3.new(DEPTH, h, along)
	end
	return Vector3.new(along, h, DEPTH)
end

-- the open edge of a ledge gets a neon strip, and a chevron on top points
-- the way to the next one
local function markLedge(B, center, y, wallDir, dir, parent)
	local edge = center - wallDir * (DEPTH / 2 - 0.15)
	local strip = B:part(Vector3.new(edge.X, y + 0.03, edge.Z), ledgeSize(wallDir, 5, 0.08) * (Vector3.new(1, 1, 1) - Vector3.new(math.abs(wallDir.X), 0, math.abs(wallDir.Z)) * (1 - 0.3 / DEPTH)), { Color = TRIM, Material = Enum.Material.Neon, Parent = parent or "Decor", CanCollide = false, CastShadow = false, Name = "LedgeTrim" })
	local tip = center + dir * 1.1 - wallDir * 0.4
	for _, side in { -1, 1 } do
		local back = tip - dir * 0.9 + Vector3.new(dir.Z, 0, -dir.X) * side * 0.9
		local mid = (tip + back) / 2
		local bar = B:part(Vector3.new(mid.X, y + 0.03, mid.Z), Vector3.new(0.35, 0.08, (tip - back).Magnitude + 0.3), { Color = TRIM, Material = Enum.Material.Neon, Parent = parent or "Decor", CanCollide = false, CastShadow = false, Name = "Chevron" })
		bar.CFrame = CFrame.lookAt(B:w(Vector3.new(mid.X, y + 0.03, mid.Z)), B:w(Vector3.new(tip.X, y + 0.03, tip.Z)))
	end
	return strip
end

-- position and walking direction at distance s along the loop of ledges
local function loop(s)
	local sides = {
		{ Vector2.new(-INSET_X, Z0), Vector2.new(-INSET_X, Z1) },
		{ Vector2.new(-INSET_X, Z1), Vector2.new(INSET_X, Z1) },
		{ Vector2.new(INSET_X, Z1), Vector2.new(INSET_X, Z0) },
		{ Vector2.new(INSET_X, Z0), Vector2.new(-INSET_X, Z0) },
	}
	local total = 0
	for _, sd in sides do
		total += (sd[2] - sd[1]).Magnitude
	end
	s = s % total
	for i, sd in sides do
		local len = (sd[2] - sd[1]).Magnitude
		if s <= len then
			local dir = (sd[2] - sd[1]).Unit
			local p = sd[1] + dir * s
			-- wall normal points away from the centre
			local wallDir = ({ Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), Vector3.new(0, 0, -1) })[i]
			return Vector3.new(p.X, 0, p.Y), Vector3.new(dir.X, 0, dir.Y), wallDir
		end
		s -= len
	end
end

local function kind(i)
	if i % 12 == 0 then
		return "landing"
	elseif i % 7 == 3 then
		return "moving"
	elseif i % 9 == 5 then
		return "vent"
	end
	return "ledge"
end

return {
	Order = 21,
	Name = "Ventilation Shaft",
	Mode = "escape",
	TimeLimit = 130,
	Ambience = { { "fan", 0.4 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = HGT,
			wallColor = Color3.fromRGB(150, 158, 166),
			wallMat = Enum.Material.DiamondPlate,
			lowerColor = Color3.fromRGB(70, 76, 84),
			trim = YELLOW,
			brightness = 1,
			lampStep = 14,
			exit = { x = 0, y = TOP_Y },
		})
		B:checkpoint(Vector3.new(0, 0.1, 5), Vector3.new(6, 0.2, 5))
		-- a painted path from the door to the foot of the first ledge
		for k = 0, 4 do
			B:part(Vector3.new(-3 - k * 3, 0.03, 6 + k * 1.2), Vector3.new(2.2, 0.06, 0.6), { Color = TRIM, Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false, Name = "FloorArrow", Rot = Vector3.new(0, 22, 0) })
		end
		for i = 1, COUNT do
			local p, dir, wallDir = loop(i * SPACING)
			local y = i * RISE
			local k = kind(i)
			if k == "landing" then
				B:part(Vector3.new(p.X, y - 0.5, p.Z), Vector3.new(8, 1, 8), { Name = "Landing", Color = STEEL, Material = Enum.Material.DiamondPlate })
				B:checkpoint(Vector3.new(p.X, y + 0.1, p.Z), Vector3.new(6, 0.2, 6))
				markLedge(B, p, y, wallDir, dir)
			elseif k == "moving" then
				-- slides along a rail on the wall, out of step with its neighbours
				local a = p - dir * 2.5
				local b = p + dir * 2.5
				local ca, cb = a + wallDir * (DEPTH / 2 - 2.5), b + wallDir * (DEPTH / 2 - 2.5)
				local m = Instance.new("Model")
				m.Name = "MovingLedge" .. i
				local slab = B:part(Vector3.new(ca.X, y - 0.5, ca.Z), ledgeSize(wallDir, 5, 1), { Name = "MovingLedge", Color = YELLOW, Material = Enum.Material.DiamondPlate, Parent = B.model })
				slab.Parent = m
				markLedge(B, ca, y, wallDir, dir, B.model)
				for _, d in B.model:GetChildren() do
					if (d.Name == "LedgeTrim" or d.Name == "Chevron") and d.Parent == B.model then
						d.Parent = m
					end
				end
				m.PrimaryPart = slab
				m:SetAttribute("MoveFrom", B:w(Vector3.new(ca.X, y - 0.5, ca.Z)))
				m:SetAttribute("MoveTo", B:w(Vector3.new(cb.X, y - 0.5, cb.Z)))
				m:SetAttribute("Speed", 3)
				m:SetAttribute("Pause", 0.8)
				m:SetAttribute("Phase", (i % 3) / 3)
				m.Parent = B:folder("Structure")
				-- the wall rail it runs on
				local rail = (a + b) / 2 + wallDir * 3.8
				B:part(Vector3.new(rail.X, y - 0.5, rail.Z), ledgeSize(wallDir, 11, 0.6) * (Vector3.new(1, 1, 1) - Vector3.new(math.abs(wallDir.X), 0, math.abs(wallDir.Z)) * (1 - 0.4 / DEPTH)), { Color = Color3.fromRGB(60, 62, 68), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "WallRail" })
			else
				-- a ledge bolted to the wall: runs right back to it
				local c = p + wallDir * (DEPTH / 2 - 2.5)
				B:part(Vector3.new(c.X, y - 0.5, c.Z), ledgeSize(wallDir, 5, 1), { Name = "Ledge", Color = STEEL, Material = Enum.Material.DiamondPlate })
				markLedge(B, c, y, wallDir, dir)
				-- angled bracket underneath, into the wall
				local w = c + wallDir * (DEPTH / 2 - 1)
				B:part(Vector3.new(w.X, y - 1.6, w.Z), ledgeSize(wallDir, 0.8, 1.2) * (Vector3.new(1, 1, 1) - Vector3.new(math.abs(wallDir.X), 0, math.abs(wallDir.Z)) * (1 - 2 / DEPTH)), { Color = Color3.fromRGB(80, 84, 90), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "Bracket" })
				if k == "vent" then
					-- a vent in the wall next to this ledge that puffs steam across it
					local vpos = p + wallDir * 3.6 + Vector3.new(0, y + 2.4, 0)
					local vent = B:part(vpos, Vector3.new(1, 1, 1) + Vector3.new(0, 1, 0) + Vector3.new(math.abs(wallDir.Z), 0, math.abs(wallDir.X)) * 2.6, { Name = "Vent" .. i, Color = Color3.fromRGB(50, 52, 56), Parent = "Vents", CanCollide = false })
					local steam = Instance.new("ParticleEmitter")
					steam.Name = "Steam"
					steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
					steam.Rate = 0
					steam.Speed = NumberRange.new(10, 14)
					steam.Lifetime = NumberRange.new(0.5, 0.7)
					steam.Size = NumberSequence.new(1, 3.5)
					steam.Transparency = NumberSequence.new(0.2, 1)
					steam.EmissionDirection = ({ [-1] = Enum.NormalId.Right, [1] = Enum.NormalId.Left })[wallDir.X ~= 0 and math.sign(wallDir.X) or 0] or (wallDir.Z > 0 and Enum.NormalId.Front or Enum.NormalId.Back)
					steam.Parent = vent
					B:part(Vector3.new(p.X, y + 2.5, p.Z), Vector3.new(5, 5, 5), { Name = "VentZone" .. i, Transparency = 1, CanCollide = false, Parent = "VentZones" })
				end
			end
		end
		-- the top floor (back half of the shaft) with the exit
		B:span(Vector3.new(-W / 2, TOP_Y - 1, 25.5), Vector3.new(W / 2, TOP_Y, D), { Name = "TopFloor", Color = STEEL, Material = Enum.Material.DiamondPlate })
		B:part(Vector3.new(0, TOP_Y + 0.02, 25.8), Vector3.new(W, 0.04, 0.6), { Color = YELLOW, Parent = "Decor", CanCollide = false, Name = "Edge" })
		-- the big fan at the bottom of the shaft (behind a grille)
		-- the grille you walk on: an invisible solid disc, drawn as a grid of bars
		-- so the fan shows through
		B:cyl(Vector3.new(0, 2.4, 22), 0.4, 26, "Y", { Name = "FanGrille", Transparency = 1, CastShadow = false })
		for k = -12, 12, 2 do
			local half = math.sqrt(math.max(0, 13 * 13 - k * k))
			if half > 0.5 then
				B:part(Vector3.new(k, 2.45, 22), Vector3.new(0.22, 0.3, half * 2), { Color = Color3.fromRGB(70, 72, 78), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "GrilleBar" })
				B:part(Vector3.new(0, 2.47, 22 + k), Vector3.new(half * 2, 0.2, 0.22), { Color = Color3.fromRGB(70, 72, 78), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "GrilleBar" })
			end
		end
		-- an industrial fan: shroud with hazard banding, five pitched blades with
		-- yellow tips on a heavy hub, struts, a red glow, and a real blast of air
		local FC = Vector3.new(0, 1.1, 22)
		local GUN = Color3.fromRGB(58, 60, 66)
		local segs = 24
		for k = 0, segs - 1 do
			local a = (k + 0.5) / segs * math.pi * 2
			local r = 12.3
			B:part(FC + Vector3.new(math.cos(a) * r, 0.1, math.sin(a) * r), Vector3.new(1, 2.2, 2 * r * math.sin(math.pi / segs) + 0.1), {
				Color = k % 2 == 0 and YELLOW or C.black,
				Material = Enum.Material.Metal,
				Rot = Vector3.new(0, -math.deg(a), 0),
				Parent = "Decor",
				CanCollide = false,
				Name = "FanShroud",
			})
		end
		for k = 0, 3 do
			B:part(FC + Vector3.new(0, -0.6, 0), Vector3.new(24, 0.5, 0.6), { Color = GUN, Material = Enum.Material.Metal, Rot = Vector3.new(0, k * 45 + 22.5, 0), Parent = "Decor", CanCollide = false, Name = "FanStrut" })
		end
		-- a black pit under the blades, so they stand out
		B:cyl(Vector3.new(0, 0.03, 22), 0.06, 24, "Y", { Color = Color3.fromRGB(10, 10, 12), Parent = "Decor", CanCollide = false, Name = "FanPit" })
		B:part(FC + Vector3.new(0, -0.9, 0), Vector3.new(1, 0.2, 1), { Transparency = 1, Parent = "Decor", CanCollide = false, Name = "FanGlow", Light = { Range = 22, Brightness = 2.2, Color = Color3.fromRGB(255, 50, 30) } })
		local fan = Instance.new("Model")
		fan.Name = "Fan"
		local hub = B:part(FC, Vector3.new(1, 1, 1), { Name = "Root", Transparency = 1, CanCollide = false, Parent = B.model })
		hub.Parent = fan
		local hubBody = B:cyl(FC, 1.4, 3.4, "Y", { Color = GUN, Material = Enum.Material.Metal, Parent = B.model, CanCollide = false, Name = "Hub" })
		hubBody.Parent = fan
		local cap = B:cyl(FC + Vector3.new(0, 0.75, 0), 0.2, 2.2, "Y", { Color = Color3.fromRGB(200, 40, 30), Material = Enum.Material.Neon, Parent = B.model, CanCollide = false, Name = "HubCap" })
		cap.Parent = fan
		for k = 0, 4 do
			local yaw = k * 72
			local rot = CFrame.Angles(0, math.rad(yaw), 0)
			-- each blade: a pitched slab out from the hub, with a yellow tip
			for _, piece in { { 1.6, 8.6, Color3.fromRGB(160, 166, 176) }, { 10.2, 1.4, YELLOW } } do
				local x0, len, col = piece[1], piece[2], piece[3]
				local centre = rot * Vector3.new(x0 + len / 2, 0, 0)
				local blade = B:part(FC + centre, Vector3.new(len, 0.25, 3.4), { Color = col, Material = Enum.Material.Metal, Parent = B.model, CanCollide = false, Name = "Blade" })
				blade.CFrame = CFrame.new(B:w(FC + centre)) * rot * CFrame.Angles(math.rad(22), 0, 0)
				blade.Parent = fan
			end
		end
		fan.PrimaryPart = hub
		fan:SetAttribute("Spin", 220)
		fan.Parent = B:folder("Decor")
		-- the blast: fast stretched streaks plus a big billowing haze, across
		-- the whole fan, straight up the shaft
		local blastArea = B:part(FC + Vector3.new(0, 1.6, 0), Vector3.new(22, 0.2, 22), { Transparency = 1, Parent = "Decor", CanCollide = false, Name = "FanBlast" })
		local streaks = Instance.new("ParticleEmitter")
		streaks.Name = "Streaks"
		streaks.Texture = "rbxasset://textures/particles/smoke_main.dds"
		streaks.Color = ColorSequence.new(Color3.fromRGB(235, 240, 245))
		streaks.EmissionDirection = Enum.NormalId.Top
		streaks.Orientation = Enum.ParticleOrientation.VelocityParallel
		streaks.Rate = 70
		streaks.Speed = NumberRange.new(38, 52)
		streaks.Lifetime = NumberRange.new(0.9, 1.3)
		streaks.Size = NumberSequence.new(0.5, 1.2)
		streaks.Squash = NumberSequence.new(-2.2)
		streaks.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.55), NumberSequenceKeypoint.new(1, 1) })
		streaks.Parent = blastArea
		local haze = Instance.new("ParticleEmitter")
		haze.Name = "Haze"
		haze.Texture = "rbxasset://textures/particles/smoke_main.dds"
		haze.Color = ColorSequence.new(Color3.fromRGB(210, 214, 220))
		haze.EmissionDirection = Enum.NormalId.Top
		haze.Rate = 30
		haze.Speed = NumberRange.new(16, 24)
		haze.SpreadAngle = Vector2.new(12, 12)
		haze.Lifetime = NumberRange.new(2, 3)
		haze.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 11) })
		haze.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.75), NumberSequenceKeypoint.new(1, 1) })
		haze.RotSpeed = NumberRange.new(-40, 40)
		haze.Parent = blastArea
	end,
	Run = function(ctx)
		local level = ctx.level
		local vents = {}
		for _, v in level.Vents:GetChildren() do
			local i = tonumber(v.Name:match("%d+"))
			vents[i] = { part = v, zone = level.VentZones["VentZone" .. i] }
		end
		-- vents: 2.4s quiet, 0.8s orange warning, 1.2s of steam
		for i, v in vents do
			task.spawn(function()
				task.wait((i % 4) * 0.7)
				while not ctx.ended do
					task.wait(2.4)
					v.part.Color = C.orange
					v.part.Material = Enum.Material.Neon
					task.wait(0.8)
					v.part.Steam.Rate = 50
					Audio.play(v.part, "steam", 0.5, 50)
					ctx:setHazard(v.zone, true)
					task.wait(1.2)
					ctx:setHazard(v.zone, false)
					v.part.Steam.Rate = 0
					v.part.Color = Color3.fromRGB(50, 52, 56)
					v.part.Material = Enum.Material.SmoothPlastic
				end
			end)
		end
		-- falling back down the shaft returns you to your last landing
		ctx.def.OnPlayerTick = function(_, player, rootPart)
			local idx = ctx.checkpoint[player] or 1
			local pad = ctx.checkpoints[idx]
			if idx > 1 and pad and rootPart.Position.Y < pad.Position.Y - 12 then
				ctx:reset(player)
			end
		end
	end,
}
