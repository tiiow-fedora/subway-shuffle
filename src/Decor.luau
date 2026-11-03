-- Decor: props that make a room read as a real place. All take a BuildLib
-- builder `B` and local positions. `face` is the direction the prop faces
-- (the wall it hangs on is behind it): "+X", "-X", "+Z" or "-Z".
local BuildLib = require(script.Parent.BuildLib)
local C = BuildLib.C

local D = {}

local FACE_ROT = { ["+Z"] = 0, ["-Z"] = 180, ["+X"] = 90, ["-X"] = -90 }
local FACE_NORMAL = {
	["+Z"] = Enum.NormalId.Back,
	["-Z"] = Enum.NormalId.Front,
	["+X"] = Enum.NormalId.Right,
	["-X"] = Enum.NormalId.Left,
}
local FACE_DIR = {
	["+Z"] = Vector3.new(0, 0, 1),
	["-Z"] = Vector3.new(0, 0, -1),
	["+X"] = Vector3.new(1, 0, 0),
	["-X"] = Vector3.new(-1, 0, 0),
}

-- size along the wall (w), height (h) and depth off the wall (d) -> world size
local function wallSize(face, w, h, d)
	if face == "+X" or face == "-X" then
		return Vector3.new(d, h, w)
	end
	return Vector3.new(w, h, d)
end

local ADS = {
	{ "Fresh bread\nevery morning", Color3.fromRGB(200, 120, 50) },
	{ "Travel smarter.\nTap in, tap out.", Color3.fromRGB(40, 90, 160) },
	{ "NEW\nSparkling water\n0 sugar", Color3.fromRGB(40, 150, 170) },
	{ "Summer sale\n50% off", Color3.fromRGB(190, 50, 60) },
	{ "Learn a language\nin 10 minutes a day", Color3.fromRGB(90, 150, 70) },
	{ "Please give up\nyour seat", Color3.fromRGB(70, 70, 150) },
	{ "Lost something?\nAsk a member of staff", Color3.fromRGB(60, 120, 90) },
	{ "Big cat exhibition\nNow open", Color3.fromRGB(170, 120, 40) },
	{ "See it. Say it.\nSorted.", Color3.fromRGB(30, 30, 30) },
	{ "Coffee to go\n2 for 1", Color3.fromRGB(110, 70, 40) },
}

-- Framed advert board on a wall, showing one of the place's advert decals.
function D.advert(B, pos, face)
	-- keep the whole poster (and frame) clear of the wall's lower band + trim,
	-- which run up to y = 4.4 in every room
	pos = Vector3.new(pos.X, math.max(pos.Y, 8.4), pos.Z)
	return require(script.Parent.Ads).board(B, pos, face, 5, 6.5)
end

-- Grey staff door with a small plate.
function D.staffDoor(B, floorPos, face)
	local dir = FACE_DIR[face]
	local p = floorPos + Vector3.new(0, 3.75, 0)
	B:part(p + dir * 0.1, wallSize(face, 4, 7.5, 0.2), { Color = Color3.fromRGB(110, 115, 120), Material = Enum.Material.Metal, Parent = "Decor", Name = "StaffDoor", CanCollide = false })
	B:part(p + dir * 0.15 + Vector3.new(0, 0.1, 0) + ((face == "+X" or face == "-X") and Vector3.new(0, 0, 1.4) or Vector3.new(1.4, 0, 0)), Vector3.new(0.3, 0.3, 0.3), { Color = C.steel, Parent = "Decor", Name = "Handle", CanCollide = false })
	B:sign(p + dir * 0.25 + Vector3.new(0, 2.3, 0), wallSize(face, 2, 0.6, 0.05), "STAFF ONLY", {
		Color = C.white,
		TextColor = C.black,
		Face = FACE_NORMAL[face],
		Font = Enum.Font.GothamBold,
		Parent = "Decor",
		CanCollide = false,
		LightInfluence = 1,
	})
	for _, off in { -2.2, 2.2 } do
		local o = (face == "+X" or face == "-X") and Vector3.new(0, 0, off) or Vector3.new(off, 0, 0)
		B:part(p + dir * 0.15 + o, wallSize(face, 0.35, 7.8, 0.3), { Color = C.darkSteel, Parent = "Decor", Name = "DoorFrame", CanCollide = false })
	end
end

-- Ventilation grille.
function D.vent(B, pos, face, w, h)
	local dir = FACE_DIR[face]
	w, h = w or 3, h or 2
	B:part(pos + dir * 0.05, wallSize(face, w, h, 0.1), { Color = Color3.fromRGB(30, 30, 32), Parent = "Decor", Name = "Vent", CanCollide = false })
	for i = 1, math.floor(h / 0.4) - 1 do
		B:part(pos + dir * 0.15 + Vector3.new(0, -h / 2 + i * 0.4, 0), wallSize(face, w - 0.2, 0.1, 0.12), { Color = C.steel, Parent = "Decor", Name = "VentSlat", CanCollide = false })
	end
end

-- Red fire extinguisher on a wall bracket.
function D.extinguisher(B, floorPos, face)
	-- a proper extinguisher: domed red cylinder with a white label band, black
	-- valve head and lever, a hose down to a nozzle, on a wall bracket
	local n = FACE_DIR[face]
	local side = Vector3.new(0, 1, 0):Cross(n)
	local base = floorPos + n * 0.55
	local red = Color3.fromRGB(196, 28, 28)
	local black = Color3.fromRGB(28, 28, 30)
	local function p(pos, size, props)
		props.Parent = "Decor"
		props.CanCollide = false
		props.Name = props.Name or "Extinguisher"
		return B:part(pos, size, props)
	end
	B:cyl(base + Vector3.new(0, 2.05, 0), 1.9, 0.78, "Y", { Color = red, Material = Enum.Material.SmoothPlastic, Parent = "Decor", CanCollide = false, Name = "Extinguisher" })
	B:ball(base + Vector3.new(0, 3.0, 0), 0.78, { Color = red, Material = Enum.Material.SmoothPlastic, Parent = "Decor", CanCollide = false, Name = "Extinguisher" })
	B:cyl(base + Vector3.new(0, 2.15, 0), 0.6, 0.8, "Y", { Color = Color3.fromRGB(235, 235, 230), Parent = "Decor", CanCollide = false, Name = "Label" })
	B:cyl(base + Vector3.new(0, 1.12, 0), 0.06, 0.8, "Y", { Color = black, Parent = "Decor", CanCollide = false, Name = "Foot" })
	B:cyl(base + Vector3.new(0, 3.42, 0), 0.24, 0.34, "Y", { Color = black, Parent = "Decor", CanCollide = false, Name = "Valve" })
	p(base + Vector3.new(0, 3.62, 0), Vector3.new(0.3, 0.2, 0.3), { Color = black, Material = Enum.Material.Metal })
	p(base + Vector3.new(0, 3.82, 0) + n * 0.12, Vector3.new(0.14, 0.08, 0.7) + Vector3.new(0, 0, 0), { Color = black, Material = Enum.Material.Metal, Name = "Lever", Rot = (face == "+X" or face == "-X") and Vector3.new(0, 90, 12) or Vector3.new(12, 0, 0) })
	-- hose from the valve, down the side, to the nozzle
	B:cyl(base + Vector3.new(0, 3.55, 0) + side * 0.3, 0.12, 0.6, (face == "+X" or face == "-X") and "Z" or "X", { Color = black, Parent = "Decor", CanCollide = false, Name = "Hose" })
	B:cyl(base + Vector3.new(0, 2.6, 0) + side * 0.55, 1.9, 0.12, "Y", { Color = black, Parent = "Decor", CanCollide = false, Name = "Hose" })
	B:cyl(base + Vector3.new(0, 1.55, 0) + side * 0.55, 0.3, 0.2, "Y", { Color = black, Parent = "Decor", CanCollide = false, Name = "Nozzle" })
	-- bracket on the wall behind it
	p(floorPos + n * 0.08 + Vector3.new(0, 2.6, 0), wallSize(face, 0.5, 0.9, 0.16), { Color = Color3.fromRGB(60, 60, 64), Material = Enum.Material.Metal, Name = "Bracket" })
end

-- CCTV camera on a short arm, high on a wall.
function D.cctv(B, pos, face)
	local dir = FACE_DIR[face]
	B:part(pos + dir * 0.4, wallSize(face, 0.3, 0.3, 0.8), { Color = C.darkSteel, Parent = "Decor", Name = "CamArm", CanCollide = false })
	B:part(pos + dir * 1 - Vector3.new(0, 0.3, 0), wallSize(face, 0.6, 0.6, 1.3), { Color = Color3.fromRGB(220, 220, 215), Parent = "Decor", Name = "Camera", CanCollide = false })
	B:part(pos + dir * 1.66 - Vector3.new(0, 0.3, 0), wallSize(face, 0.3, 0.3, 0.02), { Color = C.black, Material = Enum.Material.Glass, Parent = "Decor", CanCollide = false })
end

-- Pot plant: pot, soil and a few overlapping leaf clumps.
function D.plant(B, floorPos, scale)
	local s = scale or 1
	B:cyl(floorPos + Vector3.new(0, 1.1 * s, 0), 2.2 * s, 2.4 * s, "Y", { Color = Color3.fromRGB(120, 70, 50), Material = Enum.Material.Slate, Parent = "Decor", Name = "Pot" })
	B:cyl(floorPos + Vector3.new(0, 2.22 * s, 0), 0.05, 2.1 * s, "Y", { Color = Color3.fromRGB(60, 40, 30), Material = Enum.Material.Ground, Parent = "Decor", Name = "Soil", CanCollide = false })
	local green = Color3.fromRGB(58, 110, 52)
	for i, off in { Vector3.new(0, 3.6, 0), Vector3.new(0.7, 3, 0.4), Vector3.new(-0.6, 3.1, -0.5), Vector3.new(0.2, 4.4, -0.3) } do
		B:ball(floorPos + off * s, (i == 1 and 2.6 or 1.8) * s, { Color = green:Lerp(Color3.fromRGB(90, 150, 70), i / 5), Material = Enum.Material.Grass, Parent = "Decor", Name = "Leaves", CanCollide = false })
	end
end

-- Tall potted palm for bigger spaces.
function D.palm(B, floorPos)
	B:cyl(floorPos + Vector3.new(0, 1.4, 0), 2.8, 3.4, "Y", { Color = Color3.fromRGB(60, 60, 64), Material = Enum.Material.Concrete, Parent = "Decor", Name = "Planter" })
	B:cyl(floorPos + Vector3.new(0, 5, 0), 6, 0.6, "Y", { Color = C.wood, Material = Enum.Material.Wood, Parent = "Decor", Name = "Trunk", CanCollide = false })
	for k = 0, 5 do
		local a = math.rad(k * 60)
		local tip = Vector3.new(math.cos(a) * 2.6, 7.4, math.sin(a) * 2.6)
		B:part(floorPos + tip, Vector3.new(3.6, 0.2, 1.1), {
			Color = Color3.fromRGB(60, 120, 55),
			Material = Enum.Material.Grass,
			Rot = Vector3.new(0, -k * 60, -18),
			Parent = "Decor",
			Name = "Frond",
			CanCollide = false,
		})
	end
end

-- Metal bench with armrests. rotY = 0 faces -Z (you sit looking toward -Z).
function D.bench(B, floorPos, rotY)
	local rot = CFrame.Angles(0, math.rad(rotY or 0), 0)
	local r = Vector3.new(0, rotY or 0, 0)
	local function at(v)
		return floorPos + rot * v
	end
	B:part(at(Vector3.new(0, 1.6, 0)), Vector3.new(6, 0.3, 1.6), { Color = Color3.fromRGB(120, 125, 130), Material = Enum.Material.DiamondPlate, Rot = r, Parent = "Decor", Name = "BenchSeat" })
	B:part(at(Vector3.new(0, 2.8, 0.75)), Vector3.new(6, 2, 0.2), { Color = Color3.fromRGB(120, 125, 130), Material = Enum.Material.DiamondPlate, Rot = r, Parent = "Decor", Name = "BenchBack", CanCollide = false })
	for _, x in { -2.8, 0, 2.8 } do
		B:part(at(Vector3.new(x, 0.75, 0.1)), Vector3.new(0.2, 1.5, 1.4), { Color = C.darkSteel, Rot = r, Parent = "Decor", Name = "BenchLeg", CanCollide = false })
		B:part(at(Vector3.new(x, 2.2, -0.1)), Vector3.new(0.2, 0.15, 1.3), { Color = C.darkSteel, Rot = r, Parent = "Decor", Name = "BenchArm", CanCollide = false })
	end
end

-- Litter bin.
function D.bin(B, floorPos)
	B:cyl(floorPos + Vector3.new(0, 1.5, 0), 3, 1.8, "Y", { Color = Color3.fromRGB(50, 52, 56), Material = Enum.Material.Metal, Parent = "Decor", Name = "Bin" })
	B:cyl(floorPos + Vector3.new(0, 3.05, 0), 0.1, 1.95, "Y", { Color = Color3.fromRGB(190, 160, 40), Parent = "Decor", Name = "BinRim", CanCollide = false })
end

-- Dark tunnel mouth on a wall: trains pass through the wall here and vanish
-- into the black. w/h are the opening size; floorPos is the bottom-centre.
function D.tunnelPortal(B, floorPos, face, w, h)
	local dir = FACE_DIR[face]
	local c = floorPos + Vector3.new(0, h / 2, 0)
	B:part(c + dir * 0.06, wallSize(face, w, h, 0.1), { Color = Color3.fromRGB(4, 4, 6), Material = Enum.Material.SmoothPlastic, Parent = "Decor", Name = "TunnelDark", CanCollide = false, CastShadow = false })
	-- concrete portal surround
	local side = (face == "+X" or face == "-X") and Vector3.new(0, 0, 1) or Vector3.new(1, 0, 0)
	for _, s in { -1, 1 } do
		B:part(c + side * s * (w / 2 + 0.75) + dir * 0.4, wallSize(face, 1.5, h + 1.5, 0.8), { Color = Color3.fromRGB(90, 88, 84), Material = Enum.Material.Concrete, Parent = "Decor", Name = "Portal", CanCollide = false })
	end
	B:part(c + Vector3.new(0, h / 2 + 0.75, 0) + dir * 0.4, wallSize(face, w + 3, 1.5, 0.8), { Color = Color3.fromRGB(90, 88, 84), Material = Enum.Material.Concrete, Parent = "Decor", Name = "Portal", CanCollide = false })
	-- hazard chevrons along the top
	for i = -2, 2 do
		B:part(c + Vector3.new(0, h / 2 + 0.75, 0) + side * i * (w / 5) + dir * 0.85, wallSize(face, w / 10, 0.9, 0.05), { Color = C.yellow, Parent = "Decor", Name = "Chevron", CanCollide = false })
	end
end

-- Track: ballast bed, sleepers and two rails running along X (alongZ = false)
-- or Z, from a to b (local, at ballast top height).
function D.track(B, a, b, alongZ)
	local len = (b - a).Magnitude
	local mid = (a + b) / 2
	local function v(along, across, y)
		if alongZ then
			return Vector3.new(across, y, along)
		end
		return Vector3.new(along, y, across)
	end
	-- the ballast sits a hair proud of track level, so it never shares a face
	-- with a floor or cutting bed laid at the same height
	B:part(mid + v(0, 0, -0.11), v(len, 7, 0.3), { Color = Color3.fromRGB(78, 72, 66), Material = Enum.Material.Pebble, Parent = "Decor", Name = "Ballast", CanCollide = false })
	for t = 1.5, len - 1, 2.5 do
		local p = (alongZ and Vector3.new(mid.X, a.Y, math.min(a.Z, b.Z) + t)) or Vector3.new(math.min(a.X, b.X) + t, a.Y, mid.Z)
		B:part(p + Vector3.new(0, 0.1, 0), v(0.9, 6, 0.2), { Color = Color3.fromRGB(90, 70, 50), Material = Enum.Material.Wood, Parent = "Decor", Name = "Sleeper", CanCollide = false })
	end
	for _, s in { -2.4, 2.4 } do
		B:part(mid + v(0, s, 0.4), v(len, 0.3, 0.4), { Color = Color3.fromRGB(150, 150, 150), Material = Enum.Material.Metal, Parent = "Decor", Name = "Rail", CanCollide = false })
	end
end

-- Station clock on a wall (or back-to-back on a post). Its hour and minute
-- hands are turned to the real time by the Clocks client script, which finds
-- them by their ClockHand attribute.
function D.clock(B, pos, face)
	local n = FACE_DIR[face]
	local axis = (face == "+X" or face == "-X") and "X" or "Z"
	B:cyl(pos, 0.5, 3.2, axis, { Color = C.black, Parent = "Decor", Name = "ClockRim", CanCollide = false })
	B:cyl(pos + n * 0.2, 0.2, 2.8, axis, { Color = C.white, Parent = "Decor", Name = "ClockFace", CanCollide = false })
	local up = Vector3.new(0, 1, 0)
	local right = up:Cross(n)
	-- hour marks
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local d = up * math.cos(a) + right * math.sin(a)
		local len = k % 3 == 0 and 0.32 or 0.18
		local c = pos + n * 0.32 + d * (1.22 - len / 2)
		local cf = CFrame.fromMatrix(B:w(c), d:Cross(n), d)
		local tick = B:part(c, Vector3.new(0.09, len, 0.03), { Color = C.black, Parent = "Decor", CanCollide = false, Name = "ClockTick" })
		tick.CFrame = cf
	end
	-- hands (start at 10:10; the client script keeps them on time)
	for _, h in { { "hour", 0.7, 0.13, 10 / 12 }, { "minute", 1.05, 0.08, 2 / 12 } } do
		local a = h[4] * math.pi * 2
		local d = up * math.cos(a) + right * math.sin(a)
		local off = h[1] == "hour" and 0.34 or 0.37
		local hand = B:part(pos + n * off + d * h[2] / 2, Vector3.new(h[3], h[2], 0.03), { Color = C.black, Parent = "Decor", CanCollide = false, Name = "ClockHand" })
		hand.CFrame = CFrame.fromMatrix(B:w(pos + n * off + d * h[2] / 2), d:Cross(n), d)
		hand:SetAttribute("ClockHand", h[1])
		hand:SetAttribute("ClockCenter", B:w(pos + n * off))
		hand:SetAttribute("ClockFace", face)
		hand:SetAttribute("Len", h[2])
	end
	B:cyl(pos + n * 0.39, 0.05, 0.22, axis, { Color = C.black, Parent = "Decor", Name = "ClockPin", CanCollide = false })
end

-- Wall-mounted pipe run along a wall (horizontal), from a to b.
function D.pipe(B, a, b, d, color)
	local axis = math.abs(b.X - a.X) > math.abs(b.Z - a.Z) and "X" or "Z"
	if math.abs(b.Y - a.Y) > math.max(math.abs(b.X - a.X), math.abs(b.Z - a.Z)) then
		axis = "Y"
	end
	B:cyl((a + b) / 2, (b - a).Magnitude, d or 0.8, axis, { Color = color or Color3.fromRGB(110, 110, 104), Material = Enum.Material.Metal, Parent = "Decor", Name = "Pipe", CanCollide = false })
end

D.FACE_NORMAL = FACE_NORMAL
D.FACE_DIR = FACE_DIR
D.wallSize = wallSize

return D
