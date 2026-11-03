-- TrainKit: every train you see in a level or the lobby is a copy of the real
-- workspace.SubwayTrain, so they all match the subway you ride.
--   TrainKit.place(B, pos, opts)  - full copy (interior and all), static,
--                                   with its own collisions (you can walk in)
--   TrainKit.shell(B, pos, opts)  - just the outside, welded to one anchored
--                                   root so it can be moved cheaply. Every
--                                   visible part is non-solid; one plain
--                                   invisible box is the train's collision, so
--                                   standing or walking on it is smooth.
-- pos is the local point under the middle of the train at TRACK level (the
-- same y you pass to Decor.track); the wheels sit on the rail heads.
-- opts: alongZ (bool), Name, Parent, Hazard, Deadly, flip (bool, turn 180),
-- bogies (place: default false; shell: default true)
local TrainKit = {}

local STRIP = { ReturnPoint = true, stoppoint = true, CamPos = true, ShuffleDoors = true }
local RAIL_TOP = 0.6 -- Decor.track rail heads sit this far above track level
local WHEEL = 2.6 -- bogie + wheel height under the body

local function source()
	return workspace:FindFirstChild("SubwayTrain")
end

-- A clean copy of the real train: no scripts, sounds, seats-that-sit, marker
-- parts or the invisible walls (those hang 5 studs below the body and made
-- every copy float); everything anchored.
local function cleanCopy()
	local src = source()
	if not src then
		return nil
	end
	local m = src:Clone()
	for _, d in m:GetDescendants() do
		if STRIP[d.Name] or d:IsA("LuaSourceContainer") or d:IsA("Sound") then
			d:Destroy()
		elseif d:IsA("BasePart") and d.Transparency >= 1 then
			d:Destroy()
		end
	end
	for _, d in m:GetDescendants() do
		if d:IsA("Seat") then
			-- keep the look, but nobody gets stuck sitting in level trains
			d.Disabled = true
		end
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	return m
end

-- floor of the real train above the bottom of its visible body
local FLOOR_Y = 12.36

local function extents(m)
	local cf, size = m:GetBoundingBox()
	return cf.Position, size
end

-- How far the train's floor is above track level (for platforms: put the
-- track this far below the platform top).
function TrainKit.floorAboveTrack()
	local m = cleanCopy()
	if not m then
		return 4.4
	end
	local c, size = extents(m)
	m:Destroy()
	return (FLOOR_Y - (c.Y - size.Y / 2)) + WHEEL + RAIL_TOP
end

-- Height of the train's roof above track level.
function TrainKit.roofAboveTrack()
	local m = cleanCopy()
	if not m then
		return 17
	end
	local _, size = extents(m)
	m:Destroy()
	return size.Y + WHEEL + RAIL_TOP
end

-- Centres of the train's two door openings, as offsets along the train from
-- its middle (the real train's doors are at world x 117-123.5 and 135-141 on
-- its +Z side). With flip = true the doors face -Z and the offsets mirror.
function TrainKit.doorOffsets(flip)
	local m = cleanCopy()
	if not m then
		return { -50, -32.2 }
	end
	local c = extents(m)
	m:Destroy()
	local t = { 120.25 - c.X, 138 - c.X }
	if flip then
		t = { -t[1], -t[2] }
	end
	return t
end

local function bogies(m, center, size)
	local bottom = center.Y - size.Y / 2
	for _, sx in { -1, 1 } do
		local bx = center.X + sx * (size.X / 2 - 12)
		local frame = Instance.new("Part")
		frame.Name = "Bogie"
		frame.Anchored = true
		frame.Size = Vector3.new(9, 1.2, size.Z - 4)
		frame.Color = Color3.fromRGB(40, 40, 44)
		frame.Material = Enum.Material.Metal
		frame.CFrame = CFrame.new(bx, bottom - 0.6, center.Z)
		frame.Parent = m
		for _, wx in { -2.8, 2.8 } do
			for _, wz in { -1, 1 } do
				local w = Instance.new("Part")
				w.Name = "Wheel"
				w.Shape = Enum.PartType.Cylinder
				w.Anchored = true
				-- wheels run on the rails (2.4 either side of the track centre)
				w.Size = Vector3.new(0.6, WHEEL, WHEEL)
				w.Color = Color3.fromRGB(30, 30, 32)
				w.Material = Enum.Material.Metal
				w.CFrame = CFrame.new(bx + wx, bottom - WHEEL / 2, center.Z + wz * 2.4) * CFrame.Angles(0, math.rad(90), 0)
				w.Parent = m
			end
		end
	end
	-- a dark skirt between the bogies so you never see daylight under the body
	local skirt = Instance.new("Part")
	skirt.Name = "Skirt"
	skirt.Anchored = true
	skirt.Size = Vector3.new(size.X - 30, 1.4, size.Z - 3)
	skirt.Color = Color3.fromRGB(34, 34, 38)
	skirt.Material = Enum.Material.Metal
	skirt.CFrame = CFrame.new(center.X, bottom - 0.7, center.Z)
	skirt.Parent = m
end

local function finish(m, B_, pos, opts, center, size)
	local rot = (opts.alongZ and 90 or 0) + (opts.flip and 180 or 0)
	m:PivotTo(CFrame.new(B_:w(pos + Vector3.new(0, RAIL_TOP, 0))) * CFrame.Angles(0, math.rad(rot), 0))
	local parent = opts.Parent
	if type(parent) == "string" then
		parent = B_:folder(parent)
	end
	m.Parent = parent or B_:folder("Structure")
	m:SetAttribute("TrainLength", size.X)
	m:SetAttribute("TrainWidth", size.Z)
	m:SetAttribute("TrainHeight", size.Y + WHEEL)
	return m, size
end

-- an anchored invisible part at rail level under the middle: the pivot
local function rootAt(m, center, size)
	local root = Instance.new("Part")
	root.Name = "TrainRoot"
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Anchored = true
	root.Size = Vector3.new(1, 1, 1)
	root.CFrame = CFrame.new(center.X, center.Y - size.Y / 2 - WHEEL, center.Z)
	root.Parent = m
	m.PrimaryPart = root
	return root
end

function TrainKit.place(B_, pos, opts)
	opts = opts or {}
	local m = cleanCopy()
	if not m then
		return nil
	end
	m.Name = opts.Name or "Train"
	local center, size = extents(m)
	bogies(m, center, size)
	rootAt(m, center, size)
	return finish(m, B_, pos, opts, center, size)
end

function TrainKit.shell(B_, pos, opts)
	opts = opts or {}
	local m = cleanCopy()
	if not m then
		return nil
	end
	local center, size = extents(m)
	-- drop what sits well inside the body (seats, poles, interior trim)
	local inset = 1.6
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			local rel = p.Position - center
			-- world-space half extents, so rotated panels aren't mistaken for interior
			local c, s = p.CFrame, p.Size / 2
			local half = Vector3.new(
				math.abs(c.RightVector.X) * s.X + math.abs(c.UpVector.X) * s.Y + math.abs(c.LookVector.X) * s.Z,
				math.abs(c.RightVector.Y) * s.X + math.abs(c.UpVector.Y) * s.Y + math.abs(c.LookVector.Y) * s.Z,
				math.abs(c.RightVector.Z) * s.X + math.abs(c.UpVector.Z) * s.Y + math.abs(c.LookVector.Z) * s.Z
			)
			local nearOutside = math.abs(rel.Z) + half.Z > size.Z / 2 - inset
				or rel.Y + half.Y > size.Y / 2 - inset
				or rel.Y - half.Y < -size.Y / 2 + inset
				or math.abs(rel.X) + half.X > size.X / 2 - inset
			if not nearOutside then
				p:Destroy()
			end
		end
	end
	for _, d in m:GetDescendants() do
		if d:IsA("Model") and not d:FindFirstChildWhichIsA("BasePart", true) then
			d:Destroy()
		end
	end
	-- the windows (see-through glass/plastic panes) become dark tinted glass:
	-- no box fits the octagonal body, so the empty inside showed round its edges
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency > 0 and p.Transparency < 1 then
			p.Transparency = 0
			p.Color = Color3.fromRGB(22, 26, 32)
			p.Material = Enum.Material.Glass
			p.Reflectance = 0.25
		end
	end
	-- closed doors in the two doorways (the real train's doors are built at
	-- runtime by TrainDoors, so a copy had open holes you could see through).
	-- Same geometry as TrainDoors, in the source train's coordinates.
	for _, o in { { 117, 123.5 }, { 135, 141 } } do
		local x0, x1 = o[1], o[2]
		local w = (x1 - x0) / 2
		local fy, ty, lz = 12.36, 21.3, 38.45
		local h = ty - fy
		for _, cx in { x0 + w / 2, x1 - w / 2 } do
			local leaf = Instance.new("Part")
			leaf.Name = "DoorLeaf"
			leaf.Anchored = true
			leaf.Size = Vector3.new(w - 0.04, h, 0.3)
			leaf.CFrame = CFrame.new(cx, fy + h / 2, lz)
			leaf.Color = Color3.fromRGB(150, 155, 160)
			leaf.Material = Enum.Material.Metal
			leaf.Parent = m
			local win = Instance.new("Part")
			win.Name = "DoorWindow"
			win.Anchored = true
			win.Size = Vector3.new(w - 0.8, h * 0.4, 0.34)
			win.CFrame = leaf.CFrame + Vector3.new(0, h * 0.12, 0)
			win.Color = Color3.fromRGB(22, 26, 32)
			win.Material = Enum.Material.Glass
			win.Reflectance = 0.25
			win.Parent = m
		end
	end
	-- and a dark core behind the door openings
	local core = Instance.new("Part")
	core.Name = "Interior"
	core.Anchored = true
	-- kept well inside: the body tapers at the cab ends and rounds over at the
	-- roof, and a bigger box poked out through those corners
	core.Size = Vector3.new(size.X - 5, size.Y - 7.5, size.Z - 6.5)
	core.Color = Color3.fromRGB(28, 30, 36)
	core.Material = Enum.Material.SmoothPlastic
	core.CFrame = CFrame.new(center)
	core.Parent = m
	if opts.bogies ~= false then
		bogies(m, center, size)
	end
	local root = rootAt(m, center, size)
	-- the one solid part: a plain box around the body
	local box = Instance.new("Part")
	box.Name = "Collider"
	box.Transparency = 1
	box.Anchored = false
	box.Size = Vector3.new(size.X, size.Y + WHEEL - 0.4, size.Z)
	box.CFrame = CFrame.new(center.X, center.Y - (WHEEL - 0.4) / 2, center.Z)
	box.CastShadow = false
	box.Parent = m
	if opts.Hazard then
		box:SetAttribute("Hazard", true)
	end
	if opts.Deadly then
		box:SetAttribute("Deadly", true)
	end
	box.CanCollide = opts.CanCollide ~= false
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p ~= root then
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = p
			w.Parent = p
			p.Anchored = false
			p.Massless = true
			if p ~= box then
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
			end
		end
	end
	m.Name = opts.Name or "Train"
	return finish(m, B_, pos, opts, center, size)
end

-- size of the real train (length along its axis, width, height)
function TrainKit.size()
	local src = source()
	if not src then
		return Vector3.new(120, 13, 16)
	end
	local _, size = src:GetBoundingBox()
	return size
end

return TrainKit
