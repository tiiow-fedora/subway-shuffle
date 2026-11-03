-- Arch: the shared level shell. Every level is built with B:room(), which
-- makes complete walls (with real openings - nothing is just painted on), a
-- matching entrance doorway, trim that stops at openings, lighting, and an
-- EXIT: an alcove behind the back wall closed by a copy of the station's own
-- Metal Door, which slides open (LevelKit animates it). Outdoor levels get open
-- sky, grass, hedges and trees instead of walls, with invisible bounds.
-- Requiring this module installs the methods onto BuildLib.
local B = require(script.Parent.BuildLib)
local C = B.C

local DOOR_W, DOOR_H = 5.2, 8.8 -- every doorway (entrance and exit)
B.DOOR_W, B.DOOR_H = DOOR_W, DOOR_H
B.SIGN_FONT = Enum.Font.Highway

-- ------------------------------------------------------------------ walls

-- A wall slab in the plane z = [z0, z1] spanning x = [xa, xb], y = [ya, yb],
-- with rectangular holes {x0, x1, y0, y1}. Builds the solid pieces only.
function B:wallZ(z0, z1, xa, xb, ya, yb, holes, props)
	holes = holes or {}
	table.sort(holes, function(a, b)
		return a[1] < b[1]
	end)
	local x = xa
	for _, h in holes do
		if h[1] > x then
			self:span(Vector3.new(x, ya, z0), Vector3.new(h[1], yb, z1), props)
		end
		if h[3] > ya then
			self:span(Vector3.new(h[1], ya, z0), Vector3.new(h[2], h[3], z1), props)
		end
		if h[4] < yb then
			self:span(Vector3.new(h[1], h[4], z0), Vector3.new(h[2], yb, z1), props)
		end
		x = h[2]
	end
	if xb > x then
		self:span(Vector3.new(x, ya, z0), Vector3.new(xb, yb, z1), props)
	end
end

-- Same in the plane x = [x0, x1] spanning z = [za, zb]; holes are {z0, z1, y0, y1}.
function B:wallX(x0, x1, za, zb, ya, yb, holes, props)
	holes = holes or {}
	table.sort(holes, function(a, b)
		return a[1] < b[1]
	end)
	local z = za
	for _, h in holes do
		if h[1] > z then
			self:span(Vector3.new(x0, ya, z), Vector3.new(x1, yb, h[1]), props)
		end
		if h[3] > ya then
			self:span(Vector3.new(x0, ya, h[1]), Vector3.new(x1, h[3], h[2]), props)
		end
		if h[4] < yb then
			self:span(Vector3.new(x0, h[4], h[1]), Vector3.new(x1, yb, h[2]), props)
		end
		z = h[2]
	end
	if zb > z then
		self:span(Vector3.new(x0, ya, z), Vector3.new(x1, yb, zb), props)
	end
end

-- a horizontal strip (band/trim) along a wall, interrupted by holes
local function strips(spanFn, from, to, holes, y0, y1)
	local cuts = {}
	for _, h in holes do
		if h[3] < y1 and h[4] > y0 then
			table.insert(cuts, { h[1] - 0.6, h[2] + 0.6 })
		end
	end
	table.sort(cuts, function(a, b)
		return a[1] < b[1]
	end)
	local p = from
	for _, c in cuts do
		if c[1] > p + 0.2 then
			spanFn(p, c[1])
		end
		p = math.max(p, c[2])
	end
	if to > p + 0.2 then
		spanFn(p, to)
	end
end

-- ------------------------------------------------------------------ doors

-- A door in the station's Metal Door style (grey slab, dark border, kick
-- plate, levers both sides) built to exactly fill a B.DOOR_W x B.DOOR_H
-- doorway whose bottom centre is local `pos` in a Z-facing wall. It stands in
-- the middle of the wall's thickness. Hinged on its -X edge: LevelKit swings it
-- open (attribute OpenAngle, degrees about the Hinge point; -90 swings it
-- towards +Z, i.e. away from someone approaching from -Z).
function B:metalDoor(pos, name, parent, openAngle)
	local m = Instance.new("Model")
	local W, H, T = DOOR_W - 0.08, DOOR_H - 0.06, 0.4
	local cx, by, cz = pos.X, pos.Y + 0.03, pos.Z
	local grey = { Color = Color3.fromRGB(163, 162, 165), Material = Enum.Material.Metal, Parent = self.model }
	local dark = { Color = Color3.fromRGB(91, 93, 105), Material = Enum.Material.Metal, Parent = self.model }
	local function add(p)
		p.Parent = m
		return p
	end
	local base = add(self:part(Vector3.new(cx, by + H / 2, cz), Vector3.new(W - 0.4, H - 0.4, T), table.clone(grey)))
	base.Name = "Base"
	-- border all round (covers the slab's edges, so nothing shares a face)
	for _, sx in { -1, 1 } do
		add(self:part(Vector3.new(cx + sx * (W / 2 - 0.1), by + H / 2, cz), Vector3.new(0.2, H, T + 0.09), table.clone(dark))).Name = "Border"
	end
	for _, y in { by + 0.1, by + H - 0.1 } do
		add(self:part(Vector3.new(cx, y, cz), Vector3.new(W - 0.4, 0.2, T + 0.09), table.clone(dark))).Name = "Border"
	end
	add(self:part(Vector3.new(cx, by + 0.75, cz), Vector3.new(W - 0.8, 0.9, T + 0.05), table.clone(dark))).Name = "KickPlate"
	-- lever handles on both faces, by the free (+X) edge
	local hx = cx + W / 2 - 0.55
	for _, sz in { -1, 1 } do
		add(self:part(Vector3.new(hx, by + 4.2, cz + sz * (T / 2 + 0.04)), Vector3.new(0.34, 1.2, 0.04), table.clone(dark))).Name = "Rose"
		local lever = add(self:part(Vector3.new(hx - 0.25, by + 3.9, cz + sz * (T / 2 + 0.17)), Vector3.new(0.65, 0.11, 0.11), { Color = Color3.fromRGB(237, 234, 234), Material = Enum.Material.Metal, Parent = self.model }))
		lever.Name = "Lever"
		add(self:part(Vector3.new(hx, by + 3.9, cz + sz * (T / 2 + 0.1)), Vector3.new(0.11, 0.11, 0.14), { Color = Color3.fromRGB(237, 234, 234), Material = Enum.Material.Metal, Parent = self.model })).Name = "LeverPost"
	end
	for _, p in m:GetChildren() do
		p.CanCollide = true
	end
	m.PrimaryPart = base
	m.Name = name or "Metal Door"
	m:SetAttribute("Hinge", self:w(Vector3.new(cx - DOOR_W / 2, pos.Y, cz)))
	m:SetAttribute("OpenAngle", openAngle or -90)
	m.Parent = parent or self:folder("Doors")
	return m
end

-- Door frame (jambs + head) around a doorway in a Z-facing wall, sitting on
-- the face at local z = faceZ, sticking out toward `dir` (+1 or -1).
function B:doorFrame(x, y, faceZ, dir, color)
	color = color or Color3.fromRGB(60, 62, 68)
	local d = 0.35
	for _, s in { -1, 1 } do
		self:part(Vector3.new(x + s * (DOOR_W / 2 + 0.3), y + DOOR_H / 2, faceZ + dir * d / 2), Vector3.new(0.6, DOOR_H, d), { Color = color, Material = Enum.Material.Metal, Parent = "Decor", Name = "DoorFrame", CanCollide = false })
	end
	self:part(Vector3.new(x, y + DOOR_H + 0.3, faceZ + dir * d / 2), Vector3.new(DOOR_W + 1.2, 0.6, d), { Color = color, Material = Enum.Material.Metal, Parent = "Decor", Name = "DoorFrame", CanCollide = false })
end

-- Lit EXIT box mounted flat on a Z-facing wall face.
function B:exitSign(x, y, faceZ, dir)
	local face = dir < 0 and Enum.NormalId.Front or Enum.NormalId.Back
	local s = self:sign(Vector3.new(x, y, faceZ + dir * 0.3), Vector3.new(3.2, 1.2, 0.6), "EXIT", {
		Name = "ExitSign",
		Color = Color3.fromRGB(20, 140, 60),
		TextColor = Color3.fromRGB(255, 255, 255),
		Face = face,
		Font = B.SIGN_FONT,
		Parent = "Decor",
		CanCollide = false,
		Light = { Range = 10, Brightness = 1, Color = Color3.fromRGB(90, 255, 130) },
	})
	s.Material = Enum.Material.Neon
end

-- ------------------------------------------------------------------ room

-- o: W, D, H, x0, floor, ceiling, bottom, wallColor, wallMat, lowerColor,
-- lowerMat, floorColor, floorMat, ceilColor, lamps, lampColor, lampStep,
-- brightness, trim (Color3), trimNeon (bool), beams, trays,
-- exit = { x = 0, y = 0 } (or false for levels that end differently),
-- sideHoles = { {side = -1|1, z0, z1, y0, y1}, ... } openings in side walls,
-- outdoor = true for open-air levels (see B:outdoors)
function B:room(o)
	o = o or {}
	local W, D, H = o.W or 40, o.D or 80, o.H or 18
	local x0 = o.x0 or -W / 2
	local x1 = x0 + W
	local bottom = o.floor == false and (o.bottom or -30) or -4
	local wallColor = o.wallColor or Color3.fromRGB(205, 198, 182)
	local wallMat = o.wallMat or Enum.Material.Concrete
	local lowerColor = o.lowerColor or Color3.fromRGB(64, 66, 74)
	local lowerMat = o.lowerMat or Enum.Material.Slate
	local trim = o.trim or Color3.fromRGB(230, 180, 40)
	local wall = { Color = wallColor, Material = wallMat, Name = "Wall" }
	self.bounds = { x0 = x0, x1 = x1, D = D, H = H }
	-- LevelKit picks the level's base lighting from these
	self.model:SetAttribute("RoomBrightness", o.brightness or 1.2)
	self.model:SetAttribute("Outdoor", o.outdoor == true)

	if o.outdoor then
		return self:outdoors(o)
	end

	-- front wall: entrance doorway at x = 0 matching the station door
	local frontHoles = { { -DOOR_W / 2, DOOR_W / 2, -1, DOOR_H } }
	self:wallZ(0, 1, x0 - 1, x1 + 1, bottom, H, frontHoles, wall)
	self:doorFrame(0, 0, 1, 1)
	self:floor(-DOOR_W / 2, 0, DOOR_W / 2, 1, 0, { Color = Color3.fromRGB(80, 80, 84), Material = Enum.Material.DiamondPlate, Name = "Threshold" })

	-- back wall with the exit opening
	local backHoles = {}
	local ex = o.exit
	if ex ~= false then
		ex = ex or {}
		ex.x = ex.x or 0
		ex.y = ex.y or 0
		self.exitSpec = ex
		table.insert(backHoles, { ex.x - DOOR_W / 2, ex.x + DOOR_W / 2, ex.y - 0.01, ex.y + DOOR_H })
	end
	self:wallZ(D, D + 1, x0 - 1, x1 + 1, bottom, H, backHoles, wall)

	-- side walls (with any openings the level asks for)
	local left, right = {}, {}
	for _, h in o.sideHoles or {} do
		table.insert(h.side < 0 and left or right, { h[1], h[2], h[3], h[4] })
	end
	self:wallX(x0 - 1, x0, 0, D + 1, bottom, H, left, wall)
	self:wallX(x1, x1 + 1, 0, D + 1, bottom, H, right, wall)

	if o.floor ~= false then
		self:floor(x0, 1, x1, D, 0, {
			Name = "Floor",
			Color = o.floorColor or Color3.fromRGB(96, 94, 92),
			Material = o.floorMat or Enum.Material.Concrete,
			Thick = 4,
		})
	else
		self:floor(x0, 1, x1, D, bottom, { Name = "PitBottom", Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Slate, Thick = 2 })
	end
	if o.ceiling ~= false then
		self:span(Vector3.new(x0 - 1, H, 0), Vector3.new(x1 + 1, H + 1, D + 1), {
			Name = "Ceiling",
			Color = o.ceilColor or Color3.fromRGB(86, 84, 82),
			Material = Enum.Material.Concrete,
		})
	end

	-- lower band + trim strip on the inside of every wall, stopping at openings
	if o.band ~= false then
		local bandTop = 4
		local band = { Color = lowerColor, Material = lowerMat, Parent = "Decor", Name = "WallBand", CanCollide = false }
		local trimP = { Color = trim, Material = o.trimNeon and Enum.Material.Neon or Enum.Material.SmoothPlastic, Parent = "Decor", Name = "Trim", CanCollide = false }
		local by = o.floor == false and 0 or 0
		-- side walls
		for _, spec in { { x0, 1, left }, { x1, -1, right } } do
			local xs = spec[1] + spec[2] * 0.15
			local xt = spec[1] + spec[2] * 0.2
			strips(function(a, b)
				self:span(Vector3.new(xs - 0.15, by, a), Vector3.new(xs + 0.15, by + bandTop, b), band)
			end, 1, D, spec[3], by, by + bandTop)
			strips(function(a, b)
				self:span(Vector3.new(xt - 0.2, by + bandTop, a), Vector3.new(xt + 0.2, by + bandTop + 0.4, b), trimP)
			end, 1, D, spec[3], by + bandTop, by + bandTop + 0.4)
		end
		-- back wall
		strips(function(a, b)
			self:span(Vector3.new(a, by, D - 0.3), Vector3.new(b, by + bandTop, D), band)
		end, x0 + 0.3, x1 - 0.3, backHoles, by, by + bandTop)
		strips(function(a, b)
			self:span(Vector3.new(a, by + bandTop, D - 0.4), Vector3.new(b, by + bandTop + 0.4, D), trimP)
		end, x0 + 0.4, x1 - 0.4, backHoles, by + bandTop, by + bandTop + 0.4)
		-- front wall (inside face)
		strips(function(a, b)
			self:span(Vector3.new(a, by, 1), Vector3.new(b, by + bandTop, 1.3), band)
		end, x0 + 0.3, x1 - 0.3, { { -DOOR_W / 2 - 0.6, DOOR_W / 2 + 0.6, -1, DOOR_H } }, by, by + bandTop)
		strips(function(a, b)
			self:span(Vector3.new(a, by + bandTop, 1), Vector3.new(b, by + bandTop + 0.4, 1.4), trimP)
		end, x0 + 0.4, x1 - 0.4, { { -DOOR_W / 2 - 0.6, DOOR_W / 2 + 0.6, -1, DOOR_H } }, by + bandTop, by + bandTop + 0.4)
	end

	-- ceiling details + lights
	if o.ceiling ~= false then
		if o.beams ~= false then
			for z = 6, D - 2, o.beamStep or 12 do
				self:part(Vector3.new((x0 + x1) / 2, H - 0.5, z), Vector3.new(W, 1, 1), { Color = Color3.fromRGB(70, 68, 68), Material = Enum.Material.Concrete, Parent = "Decor", Name = "Beam", CanCollide = false })
			end
		end
		if o.lamps ~= false then
			local step = o.lampStep or 12
			local cols = W > 34 and { x0 + W * 0.3, x0 + W * 0.7 } or { (x0 + x1) / 2 }
			if W > 70 then
				cols = { x0 + W * 0.2, x0 + W * 0.5, x0 + W * 0.8 }
			end
			for z = 10, D - 4, step do
				for _, x in cols do
					-- soft and wide: rooms read evenly instead of bright pools
					-- with dark gaps between them (ambient does the rest)
					self:ceilingLight(Vector3.new(x, H - 1.15, z), 6, {
						Color = o.lampColor,
						Brightness = (o.brightness or 1.2) * 0.5,
						Range = math.max(30, H + 12),
						Flicker = o.flicker and math.random() < 0.3,
					})
				end
			end
		end
	end
	if H > 30 and o.lamps ~= false then
		for y = 14, H - 8, 14 do
			for z = 10, D - 6, 18 do
				for _, spec in { { x0, 1 }, { x1, -1 } } do
					self:lamp(Vector3.new(spec[1] + spec[2] * 0.25, y, z), Vector3.new(0.3, 0.8, 3), {
						Color = o.lampColor or C.lamp,
						Range = 30,
						Brightness = 0.45,
					})
				end
			end
		end
	end

	if ex ~= false then
		self:exitAlcove(ex.x, ex.y, D + 1, o)
	end
	return self
end

-- The exit: a small lit alcove behind the back wall (wall inner face at
-- local z = D, outer face at backZ = D + 1). The station-style Metal Door
-- closes the doorway; the Finish pad is inside, so you only finish by
-- actually walking through the opened door.
function B:exitAlcove(x, y, backZ, o)
	o = o or {}
	local depth, half, h = 9, 4.5, 10
	local z0, z1 = backZ, backZ + depth
	local mat = { Color = Color3.fromRGB(70, 74, 80), Material = Enum.Material.Concrete, Name = "ExitAlcove" }
	self:floor(x - half - 1, z0, x + half + 1, z1 + 1, y, { Color = Color3.fromRGB(80, 80, 84), Material = Enum.Material.DiamondPlate, Name = "ExitFloor", Thick = 2 })
	self:span(Vector3.new(x - half - 1, y - 2, z0), Vector3.new(x - half, y + h, z1 + 1), mat)
	self:span(Vector3.new(x + half, y - 2, z0), Vector3.new(x + half + 1, y + h, z1 + 1), mat)
	self:span(Vector3.new(x - half - 1, y - 2, z1), Vector3.new(x + half + 1, y + h, z1 + 1), mat)
	self:span(Vector3.new(x - half - 1, y + h, z0), Vector3.new(x + half + 1, y + h + 1, z1 + 1), mat)
	self:lamp(Vector3.new(x, y + h - 0.2, (z0 + z1) / 2), Vector3.new(3, 0.2, 3), { Color = Color3.fromRGB(150, 255, 170), Glow = true, Range = 14, Brightness = 1.4 })
	-- inside: a green stairwell-style arrow on the back of the alcove
	self:part(Vector3.new(x, y + 4, z1 - 0.1), Vector3.new(6, 6, 0.2), { Color = Color3.fromRGB(30, 120, 60), Parent = "Decor", CanCollide = false, Name = "ExitPanel" })
	-- the door, its frame, and the EXIT box above it on the level side
	self:metalDoor(Vector3.new(x, y, backZ - 0.5), "ExitDoor", self.model)
	self:doorFrame(x, y, backZ - 1, -1)
	self:exitSign(x, y + DOOR_H + 1.6, backZ - 1, -1)
	-- the finish pad, inside the alcove
	self:part(Vector3.new(x, y + 0.05, (z0 + z1) / 2 + 0.5), Vector3.new(2 * half, 0.1, depth - 1), {
		Name = "Finish",
		Color = Color3.fromRGB(70, 200, 110),
		Material = Enum.Material.SmoothPlastic,
		Parent = self.model,
		CanCollide = false,
	})
end

-- Legacy calls: levels no longer place their own finish pads; the exit comes
-- from B:room. Kept so older code doesn't break.
function B:finish() end
function B:exitDoor() end
function B:header() end

-- ------------------------------------------------------------------ outdoors

-- Classic Roblox tree: trunk + a few chunky leaf balls.
function B:tree(pos, scale)
	local s = scale or 1
	self:cyl(pos + Vector3.new(0, 4 * s, 0), 8 * s, 1.6 * s, "Y", { Color = Color3.fromRGB(105, 72, 44), Material = Enum.Material.Wood, Parent = "Scenery", Name = "Trunk" })
	local green = Color3.fromRGB(64, 140, 60)
	for i, off in { Vector3.new(0, 10, 0), Vector3.new(2.2, 8.4, 0.8), Vector3.new(-2, 8.6, -1), Vector3.new(0.4, 12, -0.6), Vector3.new(-0.6, 8.2, 2) } do
		self:ball(pos + off * s, (i == 1 and 7.5 or 5) * s, { Color = green:Lerp(Color3.fromRGB(100, 170, 70), (i % 3) / 4), Material = Enum.Material.Grass, Parent = "Scenery", Name = "Leaves", CanCollide = false })
	end
end

-- Neat green hedge block.
function B:hedge(a, b, h)
	return self:span(Vector3.new(a.X, 0, a.Z), Vector3.new(b.X, h or 4, b.Z), { Color = Color3.fromRGB(58, 120, 54), Material = Enum.Material.Grass, Name = "Hedge" })
end

-- Outdoor shell: the station building facade you walk out of, grass all
-- around, hedges + trees as the boundary, invisible walls so nobody wanders
-- off, and an exit hut (a little brick station entrance with the Metal Door).
-- o: W, D, x0, exit = {x, z} (exit hut position, default back-centre),
-- ground (Color3), groundMat, facadeColor, noHedge (sides to skip)
function B:outdoors(o)
	local W, D = o.W or 80, o.D or 100
	local x0 = o.x0 or -W / 2
	local x1 = x0 + W
	local FAR = 220
	-- the station building you came out of
	local facade = { Color = o.facadeColor or Color3.fromRGB(150, 86, 66), Material = Enum.Material.Brick, Name = "StationFacade" }
	self:wallZ(0, 1, x0 - FAR, x1 + FAR, -4, 26, { { -DOOR_W / 2, DOOR_W / 2, -1, DOOR_H } }, facade)
	self:span(Vector3.new(x0 - FAR, 26, -6), Vector3.new(x1 + FAR, 27, 1.6), { Color = Color3.fromRGB(200, 196, 186), Material = Enum.Material.Concrete, Name = "Cornice" })
	self:doorFrame(0, 0, 1, 1, Color3.fromRGB(200, 196, 186))
	self:floor(-DOOR_W / 2, 0, DOOR_W / 2, 1, 0, { Color = Color3.fromRGB(120, 118, 112), Material = Enum.Material.Concrete, Name = "Threshold" })
	-- windows along the facade
	for x = x0 - FAR + 10, x1 + FAR - 10, 12 do
		if math.abs(x) > 8 then
			for _, y in { 6, 16 } do
				self:part(Vector3.new(x, y, 1.05), Vector3.new(4, 5, 0.1), { Color = Color3.fromRGB(60, 80, 100), Material = Enum.Material.Glass, Parent = "Scenery", CanCollide = false, Name = "Window" })
				self:part(Vector3.new(x, y - 2.7, 1.2), Vector3.new(4.6, 0.4, 0.4), { Color = Color3.fromRGB(200, 196, 186), Parent = "Scenery", CanCollide = false, Name = "Sill" })
			end
		end
	end
	-- ground: a wide grass field, with any track pits cut out of it.
	-- o.pitsZ = { {z0, z1, depth, color}, ... } pits running the full width
	local groundProps = { Name = "Ground", Color = o.ground or Color3.fromRGB(86, 150, 70), Material = o.groundMat or Enum.Material.Grass }
	local pits = table.clone(o.pitsZ or {})
	table.sort(pits, function(a, b)
		return a[1] < b[1]
	end)
	local z = 1
	for _, pit in pits do
		if pit[1] > z then
			self:span(Vector3.new(x0 - FAR, -6, z), Vector3.new(x1 + FAR, -0.02, pit[1]), groundProps)
		end
		local depth = pit[3] or 6
		-- concrete pit walls and a ballast bed
		self:span(Vector3.new(x0 - FAR, -depth - 2, pit[1]), Vector3.new(x1 + FAR, -0.02, pit[1] + 0.8), { Name = "PitWall", Color = Color3.fromRGB(120, 116, 110), Material = Enum.Material.Concrete })
		self:span(Vector3.new(x0 - FAR, -depth - 2, pit[2] - 0.8), Vector3.new(x1 + FAR, -0.02, pit[2]), { Name = "PitWall", Color = Color3.fromRGB(120, 116, 110), Material = Enum.Material.Concrete })
		self:span(Vector3.new(x0 - FAR, -depth - 2, pit[1] + 0.8), Vector3.new(x1 + FAR, -depth, pit[2] - 0.8), { Name = "PitBed", Color = pit[4] or Color3.fromRGB(84, 78, 72), Material = Enum.Material.Pebble })
		z = pit[2]
	end
	self:span(Vector3.new(x0 - FAR, -6, z), Vector3.new(x1 + FAR, -0.02, D + FAR), groundProps)
	-- hedges around the play area and rows of trees beyond
	local skip = o.noHedge or {}
	-- side hedges run in pieces, stopping at any track cuttings
	local function sideHedge(xa, xb)
		local z = 1
		for _, pit in pits do
			if pit[1] > z then
				self:hedge(Vector3.new(xa, 0, z), Vector3.new(xb, 0, pit[1]), 4)
			end
			z = pit[2]
		end
		if D > z then
			self:hedge(Vector3.new(xa, 0, z), Vector3.new(xb, 0, D), 4)
		end
	end
	if not skip.left then
		sideHedge(x0 - 3, x0)
	end
	if not skip.right then
		sideHedge(x1, x1 + 3)
	end
	if not skip.back then
		self:hedge(Vector3.new(x0 - 3, 0, D), Vector3.new(x1 + 3, 0, D + 3), 4)
	end
	-- side tree rows, kept clear of cuttings and of any tracks the level
	-- lists in o.clearZ = { {z0, z1}, ... } (trains run out through there)
	local clear = table.clone(o.clearZ or {})
	for _, pit in pits do
		table.insert(clear, { pit[1] - 5, pit[2] + 5 })
	end
	local function blocked(z)
		for _, c in clear do
			if z > c[1] and z < c[2] then
				return true
			end
		end
		return false
	end
	local rng = Random.new(W * 7 + D)
	for z = 8, D + 30, 14 do
		for _, x in { x0 - 10, x0 - 24, x1 + 10, x1 + 24 } do
			local tz = z + rng:NextNumber(-4, 4)
			local tx = x + rng:NextNumber(-3, 3)
			local sc = rng:NextNumber(0.9, 1.3)
			if not blocked(tz) then
				self:tree(Vector3.new(tx, 0, tz), sc)
			end
		end
	end
	for x = x0 - 20, x1 + 20, 14 do
		for _, z in { D + 10, D + 24 } do
			self:tree(Vector3.new(x + rng:NextNumber(-3, 3), 0, z + rng:NextNumber(-3, 3)), rng:NextNumber(0.9, 1.3))
		end
	end
	-- invisible bounds (just outside the hedges)
	local inv = { Transparency = 1, CastShadow = false, Name = "Bounds" }
	self:span(Vector3.new(x0 - 4, -6, 0), Vector3.new(x0 - 3, 60, D + 4), inv)
	self:span(Vector3.new(x1 + 3, -6, 0), Vector3.new(x1 + 4, 60, D + 4), inv)
	self:span(Vector3.new(x0 - 4, -6, D + 3), Vector3.new(x1 + 4, 60, D + 4), inv)
	-- the exit hut
	local ex = o.exit
	if ex ~= false then
		ex = ex or {}
		self:exitHut(ex.x or 0, ex.z or (D - 8), ex.y or 0)
	end
	return self
end

-- A small brick station entrance with the Metal Door on its -Z face; the
-- Finish pad is inside. Door bottom centre at local (x, y, z).
function B:exitHut(x, z, y)
	local w, d, h = 12, 10, 11
	local brick = { Color = Color3.fromRGB(150, 86, 66), Material = Enum.Material.Brick, Name = "ExitHut" }
	self:wallZ(z, z + 1, x - w / 2, x + w / 2, y, y + h, { { x - DOOR_W / 2, x + DOOR_W / 2, y - 0.01, y + DOOR_H } }, brick)
	self:span(Vector3.new(x - w / 2, y, z + 1), Vector3.new(x - w / 2 + 1, y + h, z + d), brick)
	self:span(Vector3.new(x + w / 2 - 1, y, z + 1), Vector3.new(x + w / 2, y + h, z + d), brick)
	self:span(Vector3.new(x - w / 2, y, z + d - 1), Vector3.new(x + w / 2, y + h, z + d), brick)
	self:span(Vector3.new(x - w / 2 - 0.6, y + h, z - 0.6), Vector3.new(x + w / 2 + 0.6, y + h + 0.8, z + d + 0.6), { Color = Color3.fromRGB(60, 62, 68), Material = Enum.Material.Slate, Name = "HutRoof" })
	self:floor(x - w / 2 + 1, z + 1, x + w / 2 - 1, z + d - 1, y + 0.2, { Color = Color3.fromRGB(110, 108, 104), Material = Enum.Material.Concrete, Name = "HutFloor", Thick = 0.4 })
	self:lamp(Vector3.new(x, y + h - 0.3, z + d / 2), Vector3.new(3, 0.2, 3), { Color = Color3.fromRGB(255, 236, 200), Glow = true, Range = 14, Brightness = 1.2 })
	self:metalDoor(Vector3.new(x, y, z + 0.5), "ExitDoor", self.model)
	self:doorFrame(x, y, z, -1, Color3.fromRGB(200, 196, 186))
	self:exitSign(x, y + DOOR_H + 1.3, z, -1)
	self:part(Vector3.new(x, y + 0.45, z + d / 2), Vector3.new(w - 2.4, 0.1, d - 2.4), {
		Name = "Finish",
		Color = Color3.fromRGB(70, 200, 110),
		Parent = self.model,
		CanCollide = false,
	})
end

-- A dark passage behind an opening in a side wall (side = -1 left, +1 right),
-- centred on local z = zc, w wide and h tall, `depth` studs deep. Use with a
-- matching sideHoles entry in B:room so the wall really has a hole there.
function B:recess(side, zc, w, h, depth, floorY)
	depth = depth or 8
	floorY = floorY or 0
	local b = self.bounds
	local wx = side < 0 and b.x0 - 1 or b.x1 + 1 -- outer face of the wall
	local xa, xb = wx, wx + side * depth
	if xa > xb then
		xa, xb = xb, xa
	end
	local dark = { Color = Color3.fromRGB(14, 14, 16), Material = Enum.Material.SmoothPlastic, Name = "Recess" }
	self:span(Vector3.new(xa, floorY - 1, zc - w / 2 - 1), Vector3.new(xb, floorY + h + 1, zc - w / 2), dark)
	self:span(Vector3.new(xa, floorY - 1, zc + w / 2), Vector3.new(xb, floorY + h + 1, zc + w / 2 + 1), dark)
	self:span(Vector3.new(xa, floorY + h, zc - w / 2), Vector3.new(xb, floorY + h + 1, zc + w / 2), dark)
	self:span(Vector3.new(xa, floorY - 1, zc - w / 2), Vector3.new(xb, floorY, zc + w / 2), { Color = Color3.fromRGB(70, 70, 72), Material = Enum.Material.Concrete, Name = "RecessFloor" })
	local endX = side < 0 and xa or xb
	self:span(Vector3.new(endX - 0.5, floorY, zc - w / 2), Vector3.new(endX + 0.5, floorY + h, zc + w / 2), dark)
	-- archway frame on the room side
	local inner = side < 0 and b.x0 or b.x1
	local fx = inner - side * 0.2
	for _, dz in { -1, 1 } do
		self:part(Vector3.new(fx, floorY + h / 2, zc + dz * (w / 2 + 0.3)), Vector3.new(0.4, h, 0.6), { Color = Color3.fromRGB(60, 62, 68), Material = Enum.Material.Metal, Parent = "Decor", Name = "ArchFrame", CanCollide = false })
	end
	self:part(Vector3.new(fx, floorY + h + 0.3, zc), Vector3.new(0.4, 0.6, w + 1.2), { Color = Color3.fromRGB(60, 62, 68), Material = Enum.Material.Metal, Parent = "Decor", Name = "ArchFrame", CanCollide = false })
	return { side = side, zc - w / 2, zc + w / 2, floorY - 0.01, floorY + h }
end

return B
