-- Laser Vault (hard): the station's old bank vault. Four laser sections, each
-- with its emitters on show so you can read it: sweeping curtains, bobbing
-- beams (go under or over), a spinner in a narrow corridor (jump it), and a
-- grid where the gap moves forward one row at a time - follow it. Checkpoints
-- between every section, well clear of the lasers.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 48, 152
local LASER = Color3.fromRGB(255, 30, 40)
local STEEL = Color3.fromRGB(120, 126, 134)
local DARK = Color3.fromRGB(40, 42, 48)
local CURTAINS = { { z = 18, speed = 12, phase = 0 }, { z = 28, speed = 13, phase = 0.45 }, { z = 38, speed = 11, phase = 0.2 } }
local BOBS = { { z = 54, phase = 0 }, { z = 62, phase = 0.35 }, { z = 70, phase = 0.7 } }
local SPIN_Z, SPIN_R = 96, 7.6
local GRID = { 120, 126, 132, 138, 144 }
-- the round vault door over the exit: centre height, radius, how far it rolls
local VAULT_Y, VAULT_R, VAULT_ROLL = 4.4, 5.6, 11.6
local VAULT_Z = D - 2.4 -- in front of the steel collar on the back wall

local function laser(B, pos, size, props)
	props = props or {}
	props.Color = LASER
	props.Material = Enum.Material.Neon
	props.CanCollide = false
	props.CastShadow = false
	props.Hazard = props.Hazard ~= false
	props.Name = props.Name or "Laser"
	props.Parent = props.Parent or "Lasers"
	return B:part(pos, size, props)
end

local function emitter(B, pos, size)
	B:part(pos, size, { Color = DARK, Material = Enum.Material.Metal, Name = "Emitter", Parent = "Decor", CanCollide = false })
end

return {
	Order = 31,
	Name = "Laser Vault",
	Mode = "escape",
	TimeLimit = 130,
	Ambience = { { "laserHum", 0.3 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 22,
			wallColor = Color3.fromRGB(150, 156, 164),
			wallMat = Enum.Material.DiamondPlate,
			lowerColor = Color3.fromRGB(60, 64, 72),
			trim = Color3.fromRGB(255, 60, 60),
			trimNeon = true,
			floorColor = Color3.fromRGB(70, 74, 82),
			floorMat = Enum.Material.Metal,
			brightness = 1,
			exit = { x = 0, y = 0 },
		})
		local cps = { 6, 46, 80, 112 }
		for _, z in cps do
			B:checkpoint(Vector3.new(0, 0.1, z), Vector3.new(8, 0.2, 5))
		end
		-- 1: sweeping curtains - a vertical beam between an emitter head on a
		-- ceiling rail and one on a floor rail, sliding across the room
		for i, c in ipairs(CURTAINS) do
			B:part(Vector3.new(0, 21.4, c.z), Vector3.new(W - 2, 0.6, 0.8), { Color = DARK, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "Rail" })
			B:part(Vector3.new(0, 0.1, c.z), Vector3.new(W - 2, 0.2, 0.8), { Color = DARK, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "FloorRail" })
			-- four beams on the rail, sliding together left and right
			local m = Instance.new("Model")
			m.Name = "Curtain" .. i
			local root = B:part(Vector3.new(0, 10.8, c.z), Vector3.new(0.5, 0.5, 0.5), { Name = "Root", Transparency = 1, CanCollide = false, Parent = B.model })
			root.Parent = m
			for k = -1.5, 1.5 do
				local x = k * 11
				local beam = laser(B, Vector3.new(x, 10.8, c.z), Vector3.new(0.35, 20.6, 0.35), { Parent = B.model })
				beam.Parent = m
				for _, y in { 21, 0.5 } do
					local head = B:part(Vector3.new(x, y, c.z), Vector3.new(1.2, 0.8, 1.2), { Color = DARK, Material = Enum.Material.Metal, Parent = B.model, CanCollide = false, Name = "Head" })
					head.Parent = m
				end
			end
			m.PrimaryPart = root
			local dir = i % 2 == 0 and 1 or -1
			m:SetAttribute("MoveFrom", B:w(Vector3.new(-dir * 5.5, 10.8, c.z)))
			m:SetAttribute("MoveTo", B:w(Vector3.new(dir * 5.5, 10.8, c.z)))
			m:SetAttribute("Speed", c.speed * 0.6)
			m:SetAttribute("Pause", 0.5)
			m:SetAttribute("Phase", c.phase)
			m.Parent = B:folder("Structure")
		end
		-- 2: bobbing beams between emitters riding up and down wall rails
		for i, b in ipairs(BOBS) do
			for _, x in { -W / 2 + 0.4, W / 2 - 0.4 } do
				B:part(Vector3.new(x, 5, b.z), Vector3.new(0.4, 10, 0.8), { Color = DARK, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "WallRail" })
			end
			local m = Instance.new("Model")
			m.Name = "Bob" .. i
			local beam = laser(B, Vector3.new(0, 1, b.z), Vector3.new(W - 2, 0.3, 0.3), { Parent = B.model })
			beam.Parent = m
			for _, x in { -W / 2 + 1, W / 2 - 1 } do
				local head = B:part(Vector3.new(x, 1, b.z), Vector3.new(1, 1, 1.2), { Color = DARK, Material = Enum.Material.Metal, Parent = B.model, CanCollide = false, Name = "Head" })
				head.Parent = m
			end
			m.PrimaryPart = beam
			m:SetAttribute("MoveFrom", B:w(Vector3.new(0, 1, b.z)))
			m:SetAttribute("MoveTo", B:w(Vector3.new(0, 8.6, b.z)))
			m:SetAttribute("Speed", 4)
			m:SetAttribute("Pause", 1.4)
			m:SetAttribute("Phase", b.phase)
			m.Parent = B:folder("Structure")
		end
		-- 3: the narrow corridor with the spinner
		for _, side in { -1, 1 } do
			B:span(Vector3.new(side * 8, 0, 86), Vector3.new(side * W / 2, 22, 106), { Color = Color3.fromRGB(150, 156, 164), Material = Enum.Material.DiamondPlate, Name = "CorridorWall" })
		end
		B:cyl(Vector3.new(0, 1.2, SPIN_Z), 2.4, 1.6, "Y", { Name = "SpinPost", Color = DARK, Material = Enum.Material.Metal })
		local spin = laser(B, Vector3.new(0, 1.5, SPIN_Z), Vector3.new(SPIN_R * 2, 0.35, 0.35), { Name = "SpinLaser", Parent = "Structure" })
		spin:SetAttribute("Spin", 45)
		-- 4: the grid - full-height laser walls between wall emitters
		for r, z in ipairs(GRID) do
			laser(B, Vector3.new(0, 6, z), Vector3.new(W - 2, 12, 0.25), { Name = "Grid" .. r, Parent = "Grid", Hazard = false, Transparency = 0.45 })
			for _, x in { -W / 2 + 0.5, W / 2 - 0.5 } do
				B:part(Vector3.new(x, 6, z), Vector3.new(1, 12.4, 1.2), { Name = "GridEmitter" .. r, Color = DARK, Material = Enum.Material.Metal, Parent = "GridEmitters", CanCollide = false })
			end
		end
		-- the vault: gold behind glass in the corners, clear of the door's path
		for _, sx in { -1, 1 } do
			local xa, xb = sx * 17.8, sx * (W / 2)
			B:span(Vector3.new(math.min(xa, xb), 0, D - 4), Vector3.new(math.max(xa, xb), 6, D), { Color = DARK, Material = Enum.Material.Metal, Name = "GoldShelf" })
			for k = 0, 5 do
				B:part(Vector3.new(sx * (18.9 + (k % 3) * 1.9), 6.5 + (k // 3) * 0.9, D - 2), Vector3.new(1.7, 0.8, 1), { Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Foil, Parent = "Decor", Name = "GoldBar" })
			end
			B:span(Vector3.new(math.min(xa, xb), 6, D - 4.2), Vector3.new(math.max(xa, xb), 10, D - 4), { Color = Color3.fromRGB(200, 225, 235), Material = Enum.Material.Glass, Transparency = 0.6, Name = "Glass" })
		end
		-- THE VAULT DOOR replaces the standard exit door: a steel collar round
		-- the doorway, and a great round door in front of it that rolls aside
		-- along a rail when you get close
		local old = B.model:FindFirstChild("ExitDoor")
		if old then
			old:Destroy()
		end
		local backZ = B:w(Vector3.new(0, 0, D - 3)).Z
		for _, d in B.model:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "DoorFrame" and d.Position.Z > backZ then
				d:Destroy()
			elseif d:IsA("BasePart") and d.Name == "ExitSign" then
				d.Position += Vector3.new(0, VAULT_Y + VAULT_R + 2.4 - d.Position.Y + B:w(Vector3.zero).Y, 0)
			end
		end
		local STEEL_LT = Color3.fromRGB(176, 182, 190)
		local n = 24
		for k = 0, n - 1 do
			local a = (k + 0.5) / n * math.pi * 2
			local r = VAULT_R + 0.9
			local y = VAULT_Y + math.sin(a) * r
			if y > -0.5 then
				B:part(Vector3.new(math.cos(a) * r, y, D - 0.7), Vector3.new(1.6, 2 * r * math.sin(math.pi / n) + 0.12, 1.4), { Color = Color3.fromRGB(78, 82, 92), Material = Enum.Material.DiamondPlate, Name = "VaultCollar", Rot = Vector3.new(0, 0, math.deg(a)) })
			end
		end
		-- a top guide rail and a slot in the floor for it to roll along
		B:part(Vector3.new(VAULT_ROLL / 2, VAULT_Y + VAULT_R + 0.35, VAULT_Z), Vector3.new(VAULT_ROLL + 2 * VAULT_R + 1, 0.5, 2), { Color = DARK, Material = Enum.Material.Metal, Name = "VaultRail" })
		B:part(Vector3.new(VAULT_ROLL / 2, 0.02, VAULT_Z), Vector3.new(VAULT_ROLL + 2 * VAULT_R, 0.05, 1.9), { Color = Color3.fromRGB(14, 14, 16), Parent = "Decor", CanCollide = false, Name = "VaultSlot" })
		local door = Instance.new("Model")
		door.Name = "ExitDoor"
		local function add(p)
			p.Parent = door
			return p
		end
		local c = Vector3.new(0, VAULT_Y, VAULT_Z)
		local disc = add(B:cyl(c, 1.6, VAULT_R * 2, "Z", { Name = "Disc", Color = STEEL_LT, Material = Enum.Material.Metal, Parent = B.model }))
		add(B:cyl(c - Vector3.new(0, 0, 0.82), 0.1, VAULT_R * 2 - 1.6, "Z", { Name = "Face", Color = STEEL, Material = Enum.Material.DiamondPlate, Parent = B.model, CanCollide = false }))
		-- rivets round the face
		for k = 0, 15 do
			local a = k / 16 * math.pi * 2
			add(B:cyl(c + Vector3.new(math.cos(a) * (VAULT_R - 0.45), math.sin(a) * (VAULT_R - 0.45), -0.85), 0.2, 0.35, "Z", { Name = "Rivet", Color = DARK, Material = Enum.Material.Metal, Parent = B.model, CanCollide = false }))
		end
		-- the wheel: hub and three spokes, spun before the door rolls
		add(B:cyl(c - Vector3.new(0, 0, 1.2), 0.6, 1.2, "Z", { Name = "WheelHub", Color = Color3.fromRGB(200, 170, 60), Material = Enum.Material.Metal, Parent = B.model, CanCollide = false }))
		for k = 0, 2 do
			add(B:part(c - Vector3.new(0, 0, 1.25), Vector3.new(4.6, 0.3, 0.3), { Name = "WheelSpoke", Color = Color3.fromRGB(200, 170, 60), Material = Enum.Material.Metal, Parent = B.model, CanCollide = false, Rot = Vector3.new(0, 0, k * 60) }))
		end
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			add(B:ball(c + Vector3.new(math.cos(a) * 2.3, math.sin(a) * 2.3, -1.25), 0.5, { Name = "WheelKnob", Color = Color3.fromRGB(200, 170, 60), Material = Enum.Material.Metal, Parent = B.model, CanCollide = false }))
		end
		door.PrimaryPart = disc
		door.Parent = B.model
		Decor.cctv(B, Vector3.new(W / 2 - 0.2, 18, 50), "-X")
		Decor.cctv(B, Vector3.new(-W / 2 + 0.2, 18, 116), "+X")
	end,
	-- spin the wheel, clunk, then roll the door aside along its rail
	OpenExit = function(ctx, door)
		local disc = door.PrimaryPart
		local c0 = CFrame.new(disc.Position)
		local rel, wheel = {}, {}
		for _, p in door:GetChildren() do
			if p:IsA("BasePart") then
				rel[p] = c0:ToObjectSpace(p.CFrame)
				wheel[p] = p.Name:sub(1, 5) == "Wheel"
			end
		end
		local function pose(roll, spin)
			local c = c0 * CFrame.new(roll, 0, 0) * CFrame.Angles(0, 0, -roll / VAULT_R)
			for p, r in rel do
				p.CFrame = wheel[p] and c * CFrame.Angles(0, 0, spin) * r or c * r
			end
		end
		local function run(time, f)
			local t0 = os.clock()
			while true do
				local a = math.min(1, (os.clock() - t0) / time)
				f(a * a * (3 - 2 * a))
				if a >= 1 then
					break
				end
				task.wait()
			end
		end
		Audio.play(disc, "lever", 0.8, 80)
		run(1.2, function(a)
			pose(0, a * math.pi * 3)
		end)
		Audio.play(disc, "drum", 0.7, 80)
		task.wait(0.35)
		Audio.play(disc, "doorOpen", 0.8, 90)
		run(2.4, function(a)
			pose(a * VAULT_ROLL, math.pi * 3)
		end)
		Audio.play(disc, "drum", 0.5, 80)
	end,
	Run = function(ctx)
		local level = ctx.level
		local grid, emitters = {}, {}
		for _, g in level.Grid:GetChildren() do
			grid[tonumber(g.Name:match("%d+"))] = g
		end
		for _, e in level.GridEmitters:GetChildren() do
			local r = tonumber(e.Name:match("%d+"))
			emitters[r] = emitters[r] or {}
			table.insert(emitters[r], e)
		end
		-- the gap travels forward one row every 1.2 seconds
		local STEP = 1.2
		local state = {}
		ctx:heartbeat(function()
			local k = math.floor(os.clock() / STEP)
			for r, g in grid do
				local on = (k - r) % 3 ~= 0
				if state[r] ~= on then
					state[r] = on
					g.Transparency = on and 0.4 or 1
					ctx:setHazard(g, on)
					for _, e in emitters[r] do
						e.Color = on and LASER or DARK
						e.Material = on and Enum.Material.Neon or Enum.Material.Metal
					end
				end
			end
		end)
	end,
}
