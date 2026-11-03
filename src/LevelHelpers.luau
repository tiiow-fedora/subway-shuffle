-- Shared bits used by several level builders / runners.
local BuildLib = require(script.Parent.BuildLib)
local C = BuildLib.C

local H = {}

-- Blocky NPC figure as a Model standing on local point pos, facing -Z.
-- opts: Name, Shirt, Pants, Skin, Hat (Color3 or nil), Hazard, Deadly, Parent
function H.figure(B, pos, opts)
	opts = opts or {}
	local m = Instance.new("Model")
	m.Name = opts.Name or "Figure"
	local skin = opts.Skin or Color3.fromRGB(234, 184, 146)
	local shirt = opts.Shirt or C.blue
	local pants = opts.Pants or C.darkSteel
	local s = opts.Scale or 1
	local parts = {}
	local function add(p)
		p.Parent = m
		p.CanCollide = opts.CanCollide == true
		table.insert(parts, p)
		return p
	end
	local torso = add(B:part(pos + Vector3.new(0, 3 * s, 0), Vector3.new(2, 2, 1) * s, { Color = shirt, Name = "Torso", Parent = B.model }))
	add(B:part(pos + Vector3.new(-0.5 * s, 1 * s, 0), Vector3.new(1, 2, 1) * s, { Color = pants, Name = "LeftLeg", Parent = B.model }))
	add(B:part(pos + Vector3.new(0.5 * s, 1 * s, 0), Vector3.new(1, 2, 1) * s, { Color = pants, Name = "RightLeg", Parent = B.model }))
	add(B:part(pos + Vector3.new(-1.5 * s, 3 * s, 0), Vector3.new(1, 2, 1) * s, { Color = shirt, Name = "LeftArm", Parent = B.model }))
	add(B:part(pos + Vector3.new(1.5 * s, 3 * s, 0), Vector3.new(1, 2, 1) * s, { Color = shirt, Name = "RightArm", Parent = B.model }))
	local head = add(B:part(pos + Vector3.new(0, 4.6 * s, 0), Vector3.new(1.2, 1.2, 1.2) * s, { Color = skin, Name = "Head", Parent = B.model }))
	if opts.Face ~= false then
		local face = Instance.new("Decal")
		face.Texture = "rbxasset://textures/face.png"
		face.Face = Enum.NormalId.Front
		face.Parent = head
	end
	if opts.Hat then
		add(B:part(pos + Vector3.new(0, 5.4 * s, 0), Vector3.new(1.4, 0.5, 1.4) * s, { Color = opts.Hat, Name = "Hat", Parent = B.model }))
		add(B:part(pos + Vector3.new(0, 5.2 * s, -0.6 * s), Vector3.new(1.4, 0.15, 0.6) * s, { Color = C.black, Name = "Brim", Parent = B.model }))
	end
	if opts.Material then
		for _, p in parts do
			p.Material = opts.Material
		end
	end
	if opts.Transparency then
		for _, p in parts do
			if p ~= head then
				p.Transparency = opts.Transparency
			end
		end
	end
	for _, p in parts do
		if opts.Hazard then
			p:SetAttribute("Hazard", true)
		end
		if opts.Deadly then
			p:SetAttribute("Deadly", true)
		end
	end
	m.PrimaryPart = torso
	if opts.Avatar then
		-- swapped for the real Roblox avatar at runtime (see FriendAvatars)
		m:SetAttribute("AvatarOf", opts.Avatar)
		m:SetAttribute("FootPos", B:w(pos))
		m:SetAttribute("AvatarScale", s)
		if opts.Label then
			m:SetAttribute("AvatarLabel", opts.Label)
		end
		if opts.CanCollide then
			m:SetAttribute("AvatarCollide", true)
		end
	end
	local parent = opts.Parent
	if type(parent) == "string" then
		parent = B:folder(parent)
	end
	m.Parent = parent or B:folder("Decor")
	return m
end

-- Recursive-backtracker maze on a cols x rows grid of `cell`-stud cells whose
-- corner (x = left, z = front) is local (ox, oz). Calls wall(a, b) with local
-- Vector2 endpoints (x, z) for every wall segment that should exist. Returns
-- the grid so callers can pick cells for pickups. Entry is cell (entryCol, 1)
-- and the wall on its front side is left open.
function H.maze(cols, rows, cell, ox, oz, entryCol, wall, rng)
	rng = rng or Random.new()
	local visited = {}
	local openE, openN = {}, {} -- openE[c][r]: passage to c+1; openN[c][r]: passage to r+1
	for c = 1, cols do
		visited[c], openE[c], openN[c] = {}, {}, {}
	end
	local stack = { { entryCol, 1 } }
	visited[entryCol][1] = true
	while #stack > 0 do
		local top = stack[#stack]
		local c, r = top[1], top[2]
		local opts = {}
		if c > 1 and not visited[c - 1][r] then
			table.insert(opts, { c - 1, r, "W" })
		end
		if c < cols and not visited[c + 1][r] then
			table.insert(opts, { c + 1, r, "E" })
		end
		if r > 1 and not visited[c][r - 1] then
			table.insert(opts, { c, r - 1, "S" })
		end
		if r < rows and not visited[c][r + 1] then
			table.insert(opts, { c, r + 1, "N" })
		end
		if #opts == 0 then
			table.remove(stack)
		else
			local pick = opts[rng:NextInteger(1, #opts)]
			local nc, nr, d = pick[1], pick[2], pick[3]
			if d == "E" then
				openE[c][r] = true
			elseif d == "W" then
				openE[nc][nr] = true
			elseif d == "N" then
				openN[c][r] = true
			else
				openN[nc][nr] = true
			end
			visited[nc][nr] = true
			table.insert(stack, { nc, nr })
		end
	end
	-- a few extra openings so it's not a single corridor
	for _ = 1, math.floor(cols * rows / 8) do
		local c, r = rng:NextInteger(1, cols - 1), rng:NextInteger(1, rows - 1)
		if rng:NextNumber() < 0.5 then
			openE[c][r] = true
		else
			openN[c][r] = true
		end
	end
	-- interior walls
	for c = 1, cols do
		for r = 1, rows do
			local x0, z0 = ox + (c - 1) * cell, oz + (r - 1) * cell
			if c < cols and not openE[c][r] then
				wall(Vector2.new(x0 + cell, z0), Vector2.new(x0 + cell, z0 + cell))
			end
			if r < rows and not openN[c][r] then
				wall(Vector2.new(x0, z0 + cell), Vector2.new(x0 + cell, z0 + cell))
			end
		end
	end
	-- outer walls (front wall has the entry gap, back wall is left to the caller)
	for c = 1, cols do
		local x0 = ox + (c - 1) * cell
		if c ~= entryCol then
			wall(Vector2.new(x0, oz), Vector2.new(x0 + cell, oz))
		end
	end
	return { openE = openE, openN = openN }
end

-- Build a wall part between two local Vector2 (x, z) points.
function H.wallBetween(B, a, b, height, thick, props)
	local lo = Vector3.new(math.min(a.X, b.X) - thick / 2, 0, math.min(a.Y, b.Y) - thick / 2)
	local hi = Vector3.new(math.max(a.X, b.X) + thick / 2, height, math.max(a.Y, b.Y) + thick / 2)
	return B:span(lo, hi, props)
end

-- Warning lamps for trains that sweep through the room: each entry is
-- {train = Model, lamp = BasePart}. Lamps go red while the train is within
-- `range` studs (along X) of the room centre.
function H.trainWarnings(ctx, list, range)
	ctx:every(0.1, function()
		for _, e in list do
			if e.train.Parent and e.lamp.Parent then
				local dx = math.abs(e.train:GetPivot().Position.X - ctx.origin.X)
				local danger = dx < range
				e.lamp.Color = danger and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(60, 220, 90)
				local l = e.lamp:FindFirstChildWhichIsA("Light")
				if l then
					l.Color = e.lamp.Color
				end
			end
		end
	end)
end

-- Collect {train, lamp} pairs by matching names "TrainN" / "WarnN".
function H.pairTrains(level)
	local list = {}
	for _, d in level:GetDescendants() do
		local n = d.Name:match("^Train(%d+)$")
		if n and d:IsA("Model") then
			local lamp = level:FindFirstChild("Warn" .. n, true)
			if lamp then
				table.insert(list, { train = d, lamp = lamp })
			end
		end
	end
	return list
end

-- Classic Roblox NPCs: "noob" (yellow/blue/green) or "guest" (black cap),
-- as real R6 rigs. pos = local floor point; rotY = facing (0 = facing -Z).
-- The root is anchored and the limbs hang off it by their joints, so the
-- level can play the walk animation stored in the WalkAnim attribute.
local NOOB = {
	head = Color3.fromRGB(245, 205, 48),
	torso = Color3.fromRGB(13, 105, 172),
	legs = Color3.fromRGB(164, 189, 71),
}
-- the classic Guest. The real model (red ROBLOX cap, shirt, pants) lives at
-- ServerStorage.NPCTemplates.Guest; these colours are only the fallback.
local GUEST = {
	head = Color3.fromRGB(234, 184, 146),
	torso = Color3.fromRGB(27, 27, 30),
	legs = Color3.fromRGB(27, 27, 30),
}
-- default R6 animations (the template has no Animate script)
local R6_IDLE, R6_WALK = "rbxassetid://180435571", "rbxassetid://180426354"

local function fromTemplate(B, pos, kind, rotY, opts)
	local folder = game:GetService("ServerStorage"):FindFirstChild("NPCTemplates")
	local tpl = folder and folder:FindFirstChild(kind == "guest" and "Guest" or "Noob")
	if not tpl then
		return nil
	end
	local m = tpl:Clone()
	m.Name = opts.Name or tpl.Name
	for _, d in m:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	local root = m:FindFirstChild("HumanoidRootPart")
	local hum = m:FindFirstChildOfClass("Humanoid")
	if not root or not hum then
		m:Destroy()
		return nil
	end
	m:SetAttribute("IdleAnim", R6_IDLE)
	m:SetAttribute("WalkAnim", R6_WALK)
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.EvaluateStateMachine = false
	hum.RequiresNeck = false
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = p == root
			p.CanCollide = false
			if opts.Hazard then
				p:SetAttribute("Hazard", true)
			end
		end
	end
	m.PrimaryPart = root
	-- the pivot is the root, so this also straightens the template's own turn;
	-- R6 root sits 3 studs above the floor
	m:PivotTo(CFrame.new(B:w(pos + Vector3.new(0, 3, 0))) * CFrame.Angles(0, math.rad(rotY or 0), 0))
	local parent = opts.Parent
	if type(parent) == "string" then
		parent = B:folder(parent)
	end
	m.Parent = parent or B:folder("Decor")
	return m
end

function H.npc(B, pos, kind, rotY, opts)
	opts = opts or {}
	local fromTpl = fromTemplate(B, pos, kind, rotY, opts)
	if fromTpl then
		return fromTpl
	end
	local look = kind == "guest" and GUEST or NOOB
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = look.head
	desc.LeftArmColor = look.head
	desc.RightArmColor = look.head
	desc.TorsoColor = look.torso
	desc.LeftLegColor = look.legs
	desc.RightLegColor = look.legs
	local ok, m = pcall(function()
		return game:GetService("Players"):CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
	end)
	desc:Destroy()
	if not ok then
		-- fall back to the blocky part figure
		return H.figure(B, pos, { Name = opts.Name or "NPC", Shirt = look.torso, Pants = look.legs, Skin = look.head, Hazard = opts.Hazard, Parent = opts.Parent })
	end
	m.Name = opts.Name or (kind == "guest" and "Guest" or "Noob")
	local animate = m:FindFirstChild("Animate")
	if animate then
		local walk = animate:FindFirstChild("walk")
		local anim = walk and walk:FindFirstChildOfClass("Animation")
		if anim then
			m:SetAttribute("WalkAnim", anim.AnimationId)
		end
		local idle = animate:FindFirstChild("idle")
		anim = idle and idle:FindFirstChildOfClass("Animation")
		if anim then
			m:SetAttribute("IdleAnim", anim.AnimationId)
		end
		animate:Destroy()
	end
	local hum = m:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.EvaluateStateMachine = false
	hum.RequiresNeck = false
	local root = m:FindFirstChild("HumanoidRootPart")
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = p == root
			p.CanCollide = false
			if opts.Hazard then
				p:SetAttribute("Hazard", true)
			end
		end
	end
	if kind == "guest" then
		local head = m:FindFirstChild("Head")
		local torso = m:FindFirstChild("Torso")
		-- black baseball cap with the white R
		local cap = Instance.new("Part")
		cap.Name = "Cap"
		cap.Size = Vector3.new(1.25, 0.5, 1.25)
		cap.Color = Color3.fromRGB(20, 20, 22)
		cap.CanCollide = false
		cap.Massless = true
		cap.CFrame = head.CFrame * CFrame.new(0, 0.5, 0.02)
		cap.Parent = m
		local brim = cap:Clone()
		brim.Name = "Brim"
		brim.Size = Vector3.new(1.15, 0.1, 0.75)
		brim.CFrame = head.CFrame * CFrame.new(0, 0.3, -0.85)
		brim.Parent = m
		local r = Instance.new("SurfaceGui")
		r.Face = Enum.NormalId.Front
		r.Parent = cap
		local rl = Instance.new("TextLabel")
		rl.Size = UDim2.fromScale(1, 1)
		rl.BackgroundTransparency = 1
		rl.Text = "R"
		rl.TextScaled = true
		rl.Font = Enum.Font.ArialBold
		rl.TextColor3 = Color3.new(1, 1, 1)
		rl.Parent = r
		for _, bit in { cap, brim } do
			local w = Instance.new("WeldConstraint")
			w.Part0 = head
			w.Part1 = bit
			w.Parent = bit
			if opts.Hazard then
				bit:SetAttribute("Hazard", true)
			end
		end
		-- the ROBLOX shirt logo
		local shirt = Instance.new("SurfaceGui")
		shirt.Face = Enum.NormalId.Front
		shirt.Parent = torso
		local sl = Instance.new("TextLabel")
		sl.Size = UDim2.fromScale(0.9, 0.3)
		sl.Position = UDim2.fromScale(0.05, 0.3)
		sl.BackgroundTransparency = 1
		sl.Text = "ROBLOX"
		sl.TextScaled = true
		sl.Font = Enum.Font.ArialBold
		sl.TextColor3 = Color3.new(1, 1, 1)
		sl.Parent = shirt
	end
	m.PrimaryPart = root
	-- R6 root sits 3 studs above the floor
	m:PivotTo(CFrame.new(B:w(pos + Vector3.new(0, 3, 0))) * CFrame.Angles(0, math.rad(rotY or 0), 0))
	local parent = opts.Parent
	if type(parent) == "string" then
		parent = B:folder(parent)
	end
	m.Parent = parent or B:folder("Decor")
	return m
end

return H
