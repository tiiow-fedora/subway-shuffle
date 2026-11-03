-- Ticket Inspectors (medium-hard): nobody here has a ticket. Inspectors patrol
-- the concourse with torches - the pool of light on the floor in front of
-- each one is what they can see. Get caught in it (or walk right into one)
-- and you're marched back to your last checkpoint. Use the columns and
-- kiosks as cover and sneak to the exit.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local H = require(root.LevelHelpers)
local Decor = require(root.Decor)
local Kit = require(root.LevelKit)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 84, 136
local BEAM = Color3.fromRGB(255, 230, 140)
local REACH, SPOT_R = 9, 5 -- beam centre distance ahead, and its radius

-- patrol routes (local x, z waypoints), looped
local ROUTES = {
	{ { -30, 24 }, { 30, 24 } },
	{ { 30, 50 }, { 30, 66 }, { -30, 66 }, { -30, 50 } },
	{ { 0, 52 }, { 0, 76 } },
	{ { -32, 92 }, { 32, 92 } },
	{ { 30, 106 }, { 30, 120 }, { -30, 120 }, { -30, 106 } },
}

return {
	Order = 15,
	Name = "Ticket Inspectors",
	Mode = "escape",
	TimeLimit = 120,
	Ambience = { { "stationAmbience", 0.4 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 22,
			floorColor = Color3.fromRGB(150, 146, 138),
			floorMat = Enum.Material.Marble,
			wallColor = Color3.fromRGB(226, 218, 200),
			lowerColor = Color3.fromRGB(40, 60, 110),
			trim = Color3.fromRGB(230, 180, 40),
			brightness = 0.9,
			exit = { x = 0, y = 0 },
		})
		B:checkpoint(Vector3.new(0, 0.1, 6), Vector3.new(7, 0.2, 5))
		-- cover: a grid of thick columns, kiosks and bench rows
		for _, x in { -24, -8, 8, 24 } do
			for _, z in { 34, 56, 84, 110 } do
				B:part(Vector3.new(x, 11, z), Vector3.new(3.4, 22, 3.4), { Color = Color3.fromRGB(226, 218, 200), Material = Enum.Material.Concrete, Name = "Column" })
				B:part(Vector3.new(x, 2, z), Vector3.new(3.6, 4, 3.6), { Color = Color3.fromRGB(40, 60, 110), Material = Enum.Material.Slate, Parent = "Decor", CanCollide = false, Name = "ColumnBase" })
			end
		end
		for _, k in { { -16, 44 }, { 16, 74 }, { -16, 100 } } do
			B:span(Vector3.new(k[1] - 4, 0, k[2] - 3), Vector3.new(k[1] + 4, 4, k[2] + 3), { Color = Color3.fromRGB(150, 60, 40), Material = Enum.Material.Wood, Name = "Kiosk" })
			B:span(Vector3.new(k[1] - 4.4, 4, k[2] - 3.4), Vector3.new(k[1] + 4.4, 4.4, k[2] + 3.4), { Color = Color3.fromRGB(240, 236, 228), Name = "KioskTop" })
		end
		for _, z in { 16, 128 } do
			for _, x in { -30, -18, 18, 30 } do
				Decor.bench(B, Vector3.new(x, 0, z), 0)
			end
		end
		for _, z in { 30, 62, 96, 122 } do
			Decor.advert(B, Vector3.new(-W / 2, 8, z), "+X")
			Decor.advert(B, Vector3.new(W / 2, 8, z), "-X")
		end
		Decor.plant(B, Vector3.new(-9, 0, D - 3))
		Decor.plant(B, Vector3.new(9, 0, D - 3))
		-- the inspectors: classic noobs with a torch and a pool of light ahead
		for i, route in ROUTES do
			local start = route[1]
			local npc = H.npc(B, Vector3.new(start[1], 0, start[2]), "noob", 0, { Name = "Inspector" .. i, Parent = "Inspectors" })
			-- plain classic noobs, with a torch
			local head = npc:FindFirstChild("Head")
			local torch = Instance.new("SpotLight")
			torch.Range = 16
			torch.Angle = 50
			torch.Brightness = 4
			torch.Color = BEAM
			torch.Face = Enum.NormalId.Front
			torch.Parent = head
			npc:SetAttribute("Anim", "walk")
			npc:SetAttribute("AnimSpeed", 0.55)
			npc:SetAttribute("Route", i)
			-- the floor pool (moved by Run)
			B:cyl(Vector3.new(start[1], 0.06, start[2]), 0.06, SPOT_R * 2, "Y", {
				Name = "Beam" .. i,
				Color = BEAM,
				Material = Enum.Material.Neon,
				Transparency = 0.55,
				CanCollide = false,
				CastShadow = false,
				Parent = "Beams",
			})
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		local walls = {}
		for _, d in level:GetDescendants() do
			if d:IsA("BasePart") and (d.Name == "Column" or d.Name == "Kiosk" or d.Name == "KioskTop" or d.Name == "Wall") then
				table.insert(walls, d)
			end
		end
		params.FilterDescendantsInstances = walls
		local guards = {}
		for _, npc in level.Inspectors:GetChildren() do
			local i = npc:GetAttribute("Route")
			local pts = {}
			for _, wp in ROUTES[i] do
				table.insert(pts, ctx:w(Vector3.new(wp[1], 0, wp[2])))
			end
			table.insert(guards, { m = npc, pts = pts, seg = 1, t = 0, beam = level.Beams["Beam" .. i], y = npc:GetPivot().Position.Y, wait = 0, facing = Vector3.new(0, 0, 1) })
		end
		local SPEED = 7
		ctx:heartbeat(function(dt)
			for _, g in guards do
				local a = g.pts[g.seg]
				local b = g.pts[g.seg % #g.pts + 1]
				local seg = b - a
				local len = seg.Magnitude
				local dir = seg.Unit
				if g.wait > 0 then
					-- pausing at a corner: sweep the torch side to side
					g.wait -= dt
					local sweep = math.sin(g.wait * 3) * 0.7
					g.facing = (CFrame.Angles(0, sweep, 0) * dir).Unit
				else
					g.t += SPEED * dt
					g.facing = dir
					if g.t >= len then
						g.t = 0
						g.seg = g.seg % #g.pts + 1
						g.wait = 1.6
					end
				end
				local pos = a + dir * math.min(g.t, len)
				local p = Vector3.new(pos.X, g.y, pos.Z)
				g.m:PivotTo(CFrame.lookAt(p, p + g.facing))
				g.beam.Position = Vector3.new(p.X, ctx.origin.Y + 0.06, p.Z) + g.facing * REACH
			end
		end)
		-- caught?
		ctx:every(0.1, function()
			for _, player in ctx:activeInside() do
				local r = Kit.rootOf(player)
				if r then
					for _, g in guards do
						local gp = g.m:GetPivot().Position
						local flat = Vector3.new(r.Position.X, 0, r.Position.Z)
						local near = (flat - Vector3.new(gp.X, 0, gp.Z)).Magnitude < 3.5
						local inBeam = (flat - Vector3.new(g.beam.Position.X, 0, g.beam.Position.Z)).Magnitude < SPOT_R + 0.5
						if inBeam then
							-- they must actually be able to see you
							local eye = gp + Vector3.new(0, 1.5, 0)
							local hit = workspace:Raycast(eye, r.Position - eye, params)
							inBeam = hit == nil
						end
						if near or inBeam then
							Audio.play(gp, "buzzer", 0.6, 80)
							ctx:sendBack(player, "Caught without a ticket! Back you go.")
							break
						end
					end
				end
			end
		end)
	end,
}
