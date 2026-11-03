-- BuildLib: geometry helpers used by the level/lobby builders.
-- Positions passed in are LOCAL to the builder's origin. For levels the origin
-- is the centre of the station's Metal Door at floor level; +Z runs away from
-- the station, +Y is up, X is left/right across the room.
local B = {}
B.__index = B

B.LEVEL_ORIGIN = Vector3.new(147.7, 21.4, 100.6)

B.C = {
	concrete = Color3.fromRGB(99, 95, 98),
	darkConcrete = Color3.fromRGB(58, 56, 60),
	tile = Color3.fromRGB(226, 222, 210),
	tileBlue = Color3.fromRGB(64, 112, 168),
	tileGreen = Color3.fromRGB(70, 140, 110),
	tileRed = Color3.fromRGB(170, 60, 55),
	yellow = Color3.fromRGB(245, 200, 30),
	black = Color3.fromRGB(22, 22, 26),
	white = Color3.fromRGB(240, 240, 240),
	steel = Color3.fromRGB(140, 145, 150),
	darkSteel = Color3.fromRGB(70, 74, 80),
	rust = Color3.fromRGB(128, 72, 44),
	wood = Color3.fromRGB(120, 84, 52),
	green = Color3.fromRGB(60, 200, 90),
	red = Color3.fromRGB(230, 50, 45),
	blue = Color3.fromRGB(50, 120, 230),
	orange = Color3.fromRGB(245, 130, 30),
	purple = Color3.fromRGB(140, 70, 200),
	pink = Color3.fromRGB(240, 110, 170),
	cyan = Color3.fromRGB(40, 210, 220),
	lamp = Color3.fromRGB(255, 236, 196),
	water = Color3.fromRGB(40, 110, 140),
	lava = Color3.fromRGB(255, 80, 20),
}
local C = B.C

function B.new(model, origin)
	local self = setmetatable({}, B)
	self.model = model
	self.origin = origin or B.LEVEL_ORIGIN
	self.folders = {}
	self.cp = 0
	return self
end

function B:w(v)
	return self.origin + v
end

function B:folder(name)
	local f = self.folders[name]
	if not f then
		f = self.model:FindFirstChild(name)
		if not f then
			f = Instance.new("Folder")
			f.Name = name
			f.Parent = self.model
		end
		self.folders[name] = f
	end
	return f
end

local function applyColor(p, c)
	if typeof(c) == "Color3" then
		p.Color = c
	elseif typeof(c) == "BrickColor" then
		p.BrickColor = c
	elseif type(c) == "string" then
		p.Color = C[c] or BrickColor.new(c).Color
	end
end

-- Core part factory.
-- props: Name, Color, Material, Transparency, Parent (folder name / Instance),
-- Shape, CanCollide, CanTouch, Rot (Vector3 degrees), Class, Reflectance,
-- Attr (table), Light ({Range, Brightness, Color, Kind}), Move (local target:
-- the part ping-pongs between here and there), Speed/Pause/Phase for Move,
-- Hazard/Collectible/Spin/Conveyor/Bounce shortcuts.
function B:part(pos, size, props)
	props = props or {}
	local p = Instance.new(props.Class or "Part")
	p.Anchored = true
	p.Size = size
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape
	end
	local cf = CFrame.new(self:w(pos))
	if props.Rot then
		cf = cf * CFrame.Angles(math.rad(props.Rot.X), math.rad(props.Rot.Y), math.rad(props.Rot.Z))
	end
	p.CFrame = cf
	applyColor(p, props.Color or C.concrete)
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Transparency = props.Transparency or 0
	p.Reflectance = props.Reflectance or 0
	if props.CanCollide ~= nil then
		p.CanCollide = props.CanCollide
	end
	if props.CanTouch ~= nil then
		p.CanTouch = props.CanTouch
	end
	p.CastShadow = props.CastShadow ~= false
	p.Name = props.Name or "Part"
	if props.Attr then
		for k, v in props.Attr do
			p:SetAttribute(k, v)
		end
	end
	if props.Hazard then
		p:SetAttribute("Hazard", true)
	end
	if props.Deadly then
		p:SetAttribute("Deadly", true)
	end
	if props.Spin then
		p:SetAttribute("Spin", props.Spin)
		if props.SpinAxis then
			p:SetAttribute("SpinAxis", props.SpinAxis)
		end
	end
	if props.Conveyor then
		p:SetAttribute("Conveyor", props.Conveyor)
	end
	if props.Bounce then
		p:SetAttribute("Bounce", props.Bounce)
	end
	if props.Move then
		p:SetAttribute("MoveFrom", self:w(pos))
		p:SetAttribute("MoveTo", self:w(props.Move))
		p:SetAttribute("Speed", props.Speed or 6)
		p:SetAttribute("Pause", props.Pause or 1)
		p:SetAttribute("Phase", props.Phase or 0)
	end
	if props.Light then
		local L = props.Light
		local light = Instance.new(L.Kind or "PointLight")
		light.Range = L.Range or 16
		light.Brightness = L.Brightness or 1.5
		light.Color = L.Color or C.lamp
		if L.Face and light:IsA("SurfaceLight") then
			light.Face = L.Face
			light.Angle = L.Angle or 120
		end
		light.Shadows = L.Shadows or false
		light.Parent = p
	end
	local parent = props.Parent
	if type(parent) == "string" then
		parent = self:folder(parent)
	end
	p.Parent = parent or self:folder("Structure")
	return p
end

-- Box by min/max corners (local).
function B:span(a, b, props)
	local lo = Vector3.new(math.min(a.X, b.X), math.min(a.Y, b.Y), math.min(a.Z, b.Z))
	local hi = Vector3.new(math.max(a.X, b.X), math.max(a.Y, b.Y), math.max(a.Z, b.Z))
	return self:part((lo + hi) / 2, hi - lo, props)
end

-- Floor slab whose TOP surface sits at height y.
function B:floor(x0, z0, x1, z1, y, props)
	props = props or {}
	local t = props.Thick or 2
	return self:span(Vector3.new(x0, y - t, z0), Vector3.new(x1, y, z1), props)
end

function B:wedge(pos, size, props)
	props = props or {}
	props.Class = "WedgePart"
	return self:part(pos, size, props)
end

function B:ball(pos, d, props)
	props = props or {}
	props.Shape = Enum.PartType.Ball
	return self:part(pos, Vector3.new(d, d, d), props)
end

-- Cylinder along an axis ("X", "Y" or "Z").
function B:cyl(pos, length, d, axis, props)
	props = props or {}
	props.Shape = Enum.PartType.Cylinder
	axis = axis or "Y"
	local rot = props.Rot or Vector3.zero
	if axis == "Y" then
		rot += Vector3.new(0, 0, 90)
	elseif axis == "Z" then
		rot += Vector3.new(0, 90, 0)
	end
	props.Rot = rot
	return self:part(pos, Vector3.new(length, d, d), props)
end

function B:truss(pos, height, props)
	props = props or {}
	props.Class = "TrussPart"
	props.Color = props.Color or C.darkSteel
	props.Material = props.Material or Enum.Material.DiamondPlate
	return self:part(pos + Vector3.new(0, height / 2, 0), Vector3.new(2, height, 2), props)
end

-- A part with text on one face. Returns (part, label).
function B:sign(pos, size, text, props)
	props = props or {}
	props.Color = props.Color or C.black
	props.Parent = props.Parent or "Signs"
	local p = self:part(pos, size, props)
	local gui = Instance.new("SurfaceGui")
	gui.Face = props.Face or Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = props.PPS or 40
	gui.LightInfluence = props.LightInfluence or 0
	gui.Parent = p
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = props.Font or Enum.Font.Highway
	label.TextColor3 = props.TextColor or C.white
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	local pp = UDim.new(0.08, 0)
	pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight = pp, pp, UDim.new(0.04, 0), UDim.new(0.04, 0)
	pad.Parent = label
	return p, label
end

-- Light fixture. Diffusers are plain plastic (not Neon) so the place's Bloom
-- doesn't blow them out; the light itself does the work.
-- props: Color, Range, Brightness, Face (SurfaceLight face; default: point
-- light), Glow (use Neon), Flicker, Parent
function B:lamp(pos, size, props)
	props = props or {}
	local color = props.Color or C.lamp
	local light
	if props.Face then
		light = { Kind = "SurfaceLight", Face = props.Face, Angle = props.Angle or 110, Range = props.Range or 20, Brightness = props.Brightness or 0.9, Color = color }
	else
		light = { Range = props.Range or 20, Brightness = props.Brightness or 0.6, Color = color }
	end
	local p = self:part(pos, size or Vector3.new(4, 0.3, 1), {
		Name = props.Name or "Lamp",
		Color = color,
		Material = props.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic,
		CanCollide = false,
		CastShadow = false,
		Parent = props.Parent or "Decor",
		Light = props.Light or light,
		Attr = props.Flicker and { Flicker = true } or nil,
	})
	return p
end

-- Recessed ceiling fixture: dark housing with a pale diffuser, lighting down.
function B:ceilingLight(pos, len, props)
	props = props or {}
	len = len or 6
	self:part(pos + Vector3.new(0, 0.05, 0), Vector3.new(len + 0.6, 0.3, 1.8), { Color = C.darkSteel, Parent = "Decor", Name = "LampHousing", CanCollide = false, CastShadow = false })
	return self:lamp(pos - Vector3.new(0, 0.12, 0), Vector3.new(len, 0.1, 1.2), {
		Color = props.Color or Color3.fromRGB(235, 230, 214),
		Face = Enum.NormalId.Bottom,
		Angle = 150,
		Range = props.Range or 28,
		Brightness = props.Brightness or 0.55,
		Flicker = props.Flicker,
	})
end

-- Standard level room. Builds floor, walls with a darker lower band, ceiling
-- beams, cable trays, lights and the front wall with a doorway lined up with
-- the station's Metal Door.
-- o: W, D, H, x0, floor, ceiling, bottom, wallColor, wallMat, lowerColor,
-- lowerMat, floorColor, floorMat, ceilColor, lamps, lampColor, lampStep,
-- brightness, flicker, trim (accent colour), band, beams, trays
function B:room(o)
	o = o or {}
	local W, D, H = o.W or 40, o.D or 80, o.H or 18
	local x0 = o.x0 or -W / 2
	local x1 = x0 + W
	local wallColor = o.wallColor or Color3.fromRGB(196, 190, 176)
	local wallMat = o.wallMat or Enum.Material.Concrete
	local lowerColor = o.lowerColor or C.darkConcrete
	local lowerMat = o.lowerMat or Enum.Material.Slate
	local trim = o.trim or o.stripeColor or C.tileBlue
	local function wall(name)
		return { Name = name, Color = wallColor, Material = wallMat }
	end
	-- front wall with a 7x9 doorway at x = 0
	self:span(Vector3.new(x0 - 1, -2, 0), Vector3.new(-3.5, H, 1), wall("FrontWallL"))
	self:span(Vector3.new(3.5, -2, 0), Vector3.new(x1 + 1, H, 1), wall("FrontWallR"))
	self:span(Vector3.new(-3.5, 9, 0), Vector3.new(3.5, H, 1), wall("FrontWallTop"))
	-- door frame, sitting proud of the wall (no overlapping faces)
	for _, x in { -3.85, 3.85 } do
		self:part(Vector3.new(x, 4.5, 1.2), Vector3.new(0.7, 9, 0.4), { Color = C.darkSteel, Material = Enum.Material.Metal, Parent = "Decor", Name = "DoorFrame" })
	end
	self:part(Vector3.new(0, 9.35, 1.2), Vector3.new(8.4, 0.7, 0.4), { Color = C.darkSteel, Material = Enum.Material.Metal, Parent = "Decor", Name = "DoorFrame" })
	self:floor(-3.5, 0, 3.5, 1, 0, { Color = o.floorColor or C.darkConcrete, Material = Enum.Material.Concrete, Name = "Threshold" })
	if o.floor ~= false then
		self:floor(x0, 1, x1, D, 0, {
			Name = "Floor",
			Color = o.floorColor or C.darkConcrete,
			Material = o.floorMat or Enum.Material.Concrete,
			Thick = 4,
		})
	end
	local bottom = o.bottom or -30
	self:span(Vector3.new(x0 - 1, bottom, 0), Vector3.new(x0, H, D + 1), wall("WallLeft"))
	self:span(Vector3.new(x1, bottom, 0), Vector3.new(x1 + 1, H, D + 1), wall("WallRight"))
	self:span(Vector3.new(x0 - 1, bottom, D), Vector3.new(x1 + 1, H, D + 1), wall("WallBack"))
	if o.ceiling ~= false then
		self:span(Vector3.new(x0 - 1, H, 0), Vector3.new(x1 + 1, H + 1, D + 1), {
			Name = "Ceiling",
			Color = o.ceilColor or Color3.fromRGB(70, 68, 66),
			Material = Enum.Material.Concrete,
		})
	end
	if o.floor == false then
		self:floor(x0, 1, x1, D, bottom, { Name = "PitBottom", Color = C.black, Material = Enum.Material.Slate })
	end
	-- darker lower band + trim line on the side and back walls
	if o.band ~= false then
		for _, spec in { { x0, 1 }, { x1, -1 } } do
			self:part(Vector3.new(spec[1] + spec[2] * 0.15, 2, D / 2 + 0.5), Vector3.new(0.3, 4, D - 1), { Color = lowerColor, Material = lowerMat, Parent = "Decor", Name = "WallBand", CanCollide = false })
			self:part(Vector3.new(spec[1] + spec[2] * 0.2, 4.2, D / 2 + 0.5), Vector3.new(0.4, 0.4, D - 1), { Color = trim, Parent = "Decor", Name = "Trim", CanCollide = false })
		end
		self:part(Vector3.new((x0 + x1) / 2, 2, D - 0.15), Vector3.new(W - 0.8, 4, 0.3), { Color = lowerColor, Material = lowerMat, Parent = "Decor", Name = "WallBand", CanCollide = false })
		self:part(Vector3.new((x0 + x1) / 2, 4.2, D - 0.2), Vector3.new(W - 0.8, 0.4, 0.4), { Color = trim, Parent = "Decor", Name = "Trim", CanCollide = false })
	end
	if o.ceiling ~= false then
		if o.beams ~= false then
			for z = 6, D - 2, o.beamStep or 12 do
				self:part(Vector3.new((x0 + x1) / 2, H - 0.5, z), Vector3.new(W, 1, 1), { Color = Color3.fromRGB(58, 56, 56), Material = Enum.Material.Concrete, Parent = "Decor", Name = "Beam", CanCollide = false })
			end
		end
		if o.trays ~= false then
			self:part(Vector3.new(x1 - 2, H - 1.6, D / 2 + 0.5), Vector3.new(1.6, 0.3, D - 1), { Color = C.darkSteel, Material = Enum.Material.DiamondPlate, Parent = "Decor", Name = "CableTray", CanCollide = false })
			self:cyl(Vector3.new(x1 - 2.4, H - 1.25, D / 2 + 0.5), D - 1, 0.35, "Z", { Color = C.black, Parent = "Decor", Name = "Cable", CanCollide = false })
			self:cyl(Vector3.new(x1 - 1.6, H - 1.28, D / 2 + 0.5), D - 1, 0.3, "Z", { Color = Color3.fromRGB(150, 40, 30), Parent = "Decor", Name = "Cable", CanCollide = false })
			self:cyl(Vector3.new(x0 + 1.5, H - 1.9, D / 2 + 0.5), D - 1, 0.9, "Z", { Color = Color3.fromRGB(110, 110, 104), Material = Enum.Material.Metal, Parent = "Decor", Name = "Pipe", CanCollide = false })
		end
		if o.lamps ~= false then
			local step = o.lampStep or 12
			local cols = W > 34 and { x0 + W * 0.3, x0 + W * 0.7 } or { (x0 + x1) / 2 }
			for z = 12, D - 4, step do
				for _, x in cols do
					self:ceilingLight(Vector3.new(x, H - 1.15, z), 6, {
						Color = o.lampColor,
						Brightness = o.brightness,
						Flicker = o.flicker and math.random() < 0.3,
					})
				end
			end
		end
	end
	-- tall rooms: wall lamps so the upper levels aren't pitch black
	if H > 30 and o.lamps ~= false then
		for y = 14, H - 8, 16 do
			for z = 10, D - 6, 20 do
				for _, spec in { { x0, 1 }, { x1, -1 } } do
					self:lamp(Vector3.new(spec[1] + spec[2] * 0.25, y, z), Vector3.new(0.3, 0.8, 3), {
						Color = o.lampColor or C.lamp,
						Range = 24,
						Brightness = 0.7,
					})
				end
			end
		end
	end
	self.bounds = { x0 = x0, x1 = x1, D = D, H = H }
	return self
end

-- Levels used to put their name and a timer on the wall. Players aren't told
-- where they are any more, so this does nothing.
function B:header() end

function B:checkpoint(pos, size)
	self.cp += 1
	local p = self:part(pos, size or Vector3.new(8, 1, 6), {
		Name = tostring(self.cp),
		Color = Color3.fromRGB(70, 190, 110),
		Material = Enum.Material.SmoothPlastic,
		Parent = "Checkpoints",
	})
	return p
end

-- The finish pad. If it's near the back wall, an emergency-exit door is built
-- into that wall behind it, with the EXIT box mounted on the wall above.
function B:finish(pos, size)
	size = size or Vector3.new(12, 0.2, 8)
	local p = self:part(pos, size, {
		Name = "Finish",
		Color = Color3.fromRGB(230, 190, 40),
		Material = Enum.Material.SmoothPlastic,
		Parent = self.model,
	})
	local b = self.bounds
	if b and b.D - (pos.Z + size.Z / 2) < 12 then
		self:exitDoor(pos.X, pos.Y - size.Y / 2, b.D)
	end
	return p
end

-- Green emergency exit door on a wall whose inner face is at z = wallZ.
function B:exitDoor(x, base, wallZ)
	local z = wallZ
	self:part(Vector3.new(x, base + 4, z - 0.1), Vector3.new(5, 8, 0.2), { Color = Color3.fromRGB(40, 90, 60), Material = Enum.Material.Metal, Parent = "Decor", Name = "ExitDoor", CanCollide = false })
	self:part(Vector3.new(x, base + 4.1, z - 0.35), Vector3.new(4.4, 0.25, 0.25), { Color = C.steel, Material = Enum.Material.Metal, Parent = "Decor", Name = "PushBar", CanCollide = false })
	for _, dx in { -2.7, 2.7 } do
		self:part(Vector3.new(x + dx, base + 4.25, z - 0.25), Vector3.new(0.4, 8.5, 0.5), { Color = C.darkSteel, Parent = "Decor", Name = "ExitFrame", CanCollide = false })
	end
	self:part(Vector3.new(x, base + 8.7, z - 0.25), Vector3.new(5.8, 0.4, 0.5), { Color = C.darkSteel, Parent = "Decor", Name = "ExitFrame", CanCollide = false })
	self:sign(Vector3.new(x, base + 9.7, z - 0.3), Vector3.new(3, 1.1, 0.6), "EXIT", {
		Name = "ExitSign",
		Color = Color3.fromRGB(30, 150, 70),
		Face = Enum.NormalId.Front,
		Parent = "Decor",
		CanCollide = false,
		Light = { Range = 8, Brightness = 0.8, Color = Color3.fromRGB(80, 255, 120) },
	})
end

-- Simple subway carriage as a Model (for decor or as a moving hazard).
-- Oriented along X by default; set alongZ = true to run along Z.
function B:carriage(pos, len, props)
	props = props or {}
	local m = Instance.new("Model")
	m.Name = props.Name or "Carriage"
	local along = props.alongZ
	local function v(x, y, z)
		if along then
			return Vector3.new(z, y, x)
		end
		return Vector3.new(x, y, z)
	end
	local body = props.Color or C.steel
	local stripe = props.Stripe or C.red
	local parts = {}
	local function add(p)
		table.insert(parts, p)
		p.Parent = m
		return p
	end
	add(self:part(pos + v(0, 4.5, 0), v(len, 8, 9), { Color = body, Material = Enum.Material.Metal, Name = "Body", Parent = self.model }))
	add(self:part(pos + v(0, 3, 0), v(len + 0.1, 1, 9.1), { Color = stripe, Name = "Stripe", Parent = self.model }))
	add(self:part(pos + v(0, 6, 0), v(len - 2, 2.2, 9.2), { Color = C.black, Material = Enum.Material.Glass, Transparency = 0.2, Name = "Windows", Parent = self.model }))
	add(self:part(pos + v(0, 8.7, 0), v(len, 0.6, 8), { Color = C.darkSteel, Name = "Roof", Parent = self.model }))
	add(self:part(pos + v(len / 2 + 0.05, 5, 0), v(0.2, 1.4, 5), { Color = C.lamp, Material = Enum.Material.Neon, Name = "Headlight", Parent = self.model }))
	add(self:part(pos + v(-len / 2 - 0.05, 5, 0), v(0.2, 1.4, 5), { Color = C.red, Material = Enum.Material.Neon, Name = "Taillight", Parent = self.model }))
	m.PrimaryPart = parts[1]
	if props.Hazard then
		for _, p in parts do
			p:SetAttribute("Hazard", true)
		end
	end
	if props.Deadly then
		for _, p in parts do
			p:SetAttribute("Deadly", true)
		end
	end
	if props.Move then
		-- the pivot is the body's centre, 4.5 studs above the given base point
		m:SetAttribute("MoveFrom", self:w(pos + Vector3.new(0, 4.5, 0)))
		m:SetAttribute("MoveTo", self:w(props.Move + Vector3.new(0, 4.5, 0)))
		m:SetAttribute("Speed", props.Speed or 20)
		m:SetAttribute("Pause", props.Pause or 1)
		m:SetAttribute("Phase", props.Phase or 0)
	end
	m.Parent = type(props.Parent) == "string" and self:folder(props.Parent) or props.Parent or self:folder("Decor")
	return m
end

-- Decor props -------------------------------------------------------------

function B:bench(pos, rotY)
	local r = Vector3.new(0, rotY or 0, 0)
	local seat = self:part(pos + Vector3.new(0, 1.6, 0), Vector3.new(6, 0.4, 2), { Color = C.wood, Material = Enum.Material.Wood, Rot = r, Parent = "Decor", Name = "Bench" })
	local off = CFrame.Angles(0, math.rad(rotY or 0), 0)
	for _, x in { -2.5, 2.5 } do
		local d = off * Vector3.new(x, 0, 0)
		self:part(pos + d + Vector3.new(0, 0.7, 0), Vector3.new(0.4, 1.4, 1.8), { Color = C.darkSteel, Rot = r, Parent = "Decor", Name = "BenchLeg" })
	end
	local back = off * Vector3.new(0, 0, 0.9)
	self:part(pos + back + Vector3.new(0, 2.6, 0), Vector3.new(6, 1.6, 0.3), { Color = C.wood, Material = Enum.Material.Wood, Rot = r, Parent = "Decor", Name = "BenchBack" })
	return seat
end

function B:pillar(pos, h, props)
	props = props or {}
	local d = props.D or 2.5
	local p = self:part(pos + Vector3.new(0, h / 2, 0), Vector3.new(d, h, d), {
		Color = props.Color or C.tile,
		Material = props.Material or Enum.Material.Concrete,
		Parent = props.Parent or "Structure",
		Name = "Pillar",
	})
	self:part(pos + Vector3.new(0, 5, 0), Vector3.new(d + 0.1, 1, d + 0.1), { Color = props.Band or C.tileBlue, Parent = "Decor", Name = "PillarBand", CanCollide = false })
	return p
end

function B:vending(pos, rotY, color)
	local r = Vector3.new(0, rotY or 0, 0)
	local body = self:part(pos + Vector3.new(0, 3.5, 0), Vector3.new(4, 7, 3), { Color = color or C.red, Rot = r, Parent = "Decor", Name = "VendingMachine" })
	local off = CFrame.Angles(0, math.rad(rotY or 0), 0) * Vector3.new(0, 0, -1.55)
	self:part(pos + off + Vector3.new(-0.4, 4.2, 0), Vector3.new(2.6, 4.4, 0.1), { Color = C.lamp, Material = Enum.Material.Neon, Transparency = 0.3, Rot = r, Parent = "Decor", Name = "VendGlass", CanCollide = false })
	return body
end

function B:bin(pos)
	return self:cyl(pos + Vector3.new(0, 1.5, 0), 3, 2, "Y", { Color = C.darkSteel, Material = Enum.Material.Metal, Parent = "Decor", Name = "Bin" })
end

function B:plant(pos)
	self:cyl(pos + Vector3.new(0, 1, 0), 2, 2.4, "Y", { Color = C.darkConcrete, Parent = "Decor", Name = "Pot" })
	self:ball(pos + Vector3.new(0, 3, 0), 3.2, { Color = Color3.fromRGB(60, 130, 60), Material = Enum.Material.Grass, Parent = "Decor", Name = "Leaves" })
end

function B:crate(pos, s, color)
	s = s or 3
	return self:part(pos + Vector3.new(0, s / 2, 0), Vector3.new(s, s, s), { Color = color or C.wood, Material = Enum.Material.WoodPlanks, Name = "Crate" })
end

function B:poster(pos, size, text, face, color)
	return self:sign(pos, size, text, { Color = color or C.tileBlue, Face = face or Enum.NormalId.Back, Font = Enum.Font.GothamBold, Parent = "Decor" })
end

-- Stairs from local point a (bottom front) climbing to height h over run along +Z.
function B:stairs(a, width, h, run, props)
	props = props or {}
	local steps = math.max(2, math.floor(h / 1))
	local dz = run / steps
	for i = 1, steps do
		local top = h * i / steps
		self:span(Vector3.new(a.X - width / 2, a.Y, a.Z + (i - 1) * dz), Vector3.new(a.X + width / 2, a.Y + top, a.Z + i * dz), {
			Color = props.Color or C.darkConcrete,
			Material = props.Material or Enum.Material.Concrete,
			Name = "Step",
		})
	end
end

-- Sloped slab whose top surface runs from local point a to local point b.
function B:ramp(a, b, width, props)
	props = props or {}
	local dir = b - a
	local len = dir.Magnitude
	local wa, wb = self:w(a), self:w(b)
	local mid = (wa + wb) / 2
	local look = CFrame.lookAt(mid, mid + dir.Unit)
	local thick = props.Thick or 1
	local p = self:part(a, Vector3.new(width, thick, len), props)
	p.CFrame = look - look.UpVector * (thick / 2)
	return p
end

-- Station name board in classic roundel style, mounted on a wall face.
function B:roundel(pos, text, face, color)
	local f = face or Enum.NormalId.Back
	self:sign(pos, Vector3.new(18, 3, 0.4), text, { Color = C.white, TextColor = C.black, Face = f, Font = Enum.Font.GothamBold })
	self:part(pos - Vector3.new(0, 0, 0), Vector3.new(20, 1.2, 0.3), { Color = color or C.red, Parent = "Decor", Name = "RoundelBar", CanCollide = false })
end

return B
