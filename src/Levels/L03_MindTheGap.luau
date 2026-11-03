-- Mind the Gap (medium): an open-air station with four track cuttings to
-- cross. Each cutting has two bridges. When a train is coming the signal goes
-- amber, then red, and each bridge's two halves swing down against the walls
-- of the cutting so the train can pass. Cross while the light is green - if
-- you're on a bridge when it drops, you fall in.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local TrainKit = require(root.TrainKit)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 96, 172
local PITS = { { 22, 44 }, { 56, 78 }, { 90, 112 }, { 124, 146 } }
local PIT_DEPTH = 16
local BRIDGE_X = { -18, 18 }
local PLATFORM = Color3.fromRGB(176, 172, 164)

return {
	Order = 3,
	Name = "Mind the Gap",
	Mode = "escape",
	TimeLimit = 110,
	KillY = -10,
	Ambience = { { "birds", 0.35 } },
	Build = function(B)
		local pits = {}
		for _, p in PITS do
			table.insert(pits, { p[1], p[2], PIT_DEPTH })
		end
		B:room({ W = W, D = D, outdoor = true, pitsZ = pits, exit = { x = 0, z = D - 12, y = 0.4 } })
		-- paved platforms between the cuttings
		local edges = { 1, 22, 44, 56, 78, 90, 112, 124, 146, D }
		for i = 1, #edges - 1, 2 do
			local z0, z1 = edges[i], edges[i + 1]
			B:span(Vector3.new(-W / 2, -0.2, z0), Vector3.new(W / 2, 0.4, z1), { Name = "Platform", Color = PLATFORM, Material = Enum.Material.Concrete })
			if i > 1 then
				B:part(Vector3.new(0, 0.42, z0 + 0.7), Vector3.new(W, 0.04, 1.2), { Color = C.yellow, Parent = "Decor", CanCollide = false, Name = "EdgeLine" })
			end
			if z1 ~= D then
				B:part(Vector3.new(0, 0.42, z1 - 0.7), Vector3.new(W, 0.04, 1.2), { Color = C.yellow, Parent = "Decor", CanCollide = false, Name = "EdgeLine" })
			end
		end
		B:checkpoint(Vector3.new(0, 0.5, 8), Vector3.new(7, 0.2, 5))
		B:checkpoint(Vector3.new(0, 0.5, 84), Vector3.new(7, 0.2, 5))
		-- canopies and benches on the platforms
		for _, zc in { 11, 50, 84, 118 } do
			for _, x in { -36, 36 } do
				for _, dz in { -3, 3 } do
					B:part(Vector3.new(x, 4.6, zc + dz), Vector3.new(0.5, 8.4, 0.5), { Color = Color3.fromRGB(50, 90, 140), Material = Enum.Material.Metal, Name = "CanopyPost" })
				end
				B:span(Vector3.new(x - 8, 8.8, zc - 4.5), Vector3.new(x + 8, 9.3, zc + 4.5), { Color = Color3.fromRGB(50, 90, 140), Material = Enum.Material.Metal, Name = "Canopy" })
				Decor.bench(B, Vector3.new(x, 0.4, zc), 0)
			end
		end
		-- each cutting: rails, a train, two bridges and signals
		for i, p in PITS do
			local zc = (p[1] + p[2]) / 2
			Decor.track(B, Vector3.new(-W / 2 - 200, -PIT_DEPTH, zc), Vector3.new(W / 2 + 200, -PIT_DEPTH, zc), false)
			local dir = i % 2 == 0 and 1 or -1
			local train = TrainKit.shell(B, Vector3.new(-dir * (W / 2 + 140), -PIT_DEPTH, zc), { Name = "Train" .. i, Hazard = true, Parent = "Trains", flip = dir < 0 })
			if train then
				train:SetAttribute("Dir", dir)
				train:SetAttribute("Lane", i)
			end
			for b, x in BRIDGE_X do
				-- two leaves, each hinged at its platform edge (yellow deck, rails)
				local half = (p[2] - p[1]) / 2
				for leaf, spec in { { p[1], 1 }, { p[2], -1 } } do
					local hz, toward = spec[1], spec[2]
					local m = Instance.new("Model")
					m.Name = "Leaf" .. i .. "_" .. b .. "_" .. leaf
					local mid = hz + toward * half / 2
					local deck = B:part(Vector3.new(x, 0, mid), Vector3.new(6, 0.8, half - 0.05), { Name = "Deck", Color = Color3.fromRGB(200, 160, 40), Material = Enum.Material.DiamondPlate, Parent = B.model })
					deck.Parent = m
					for _, sx in { -1, 1 } do
						-- low rails, so a dropped leaf stays clear of the passing train
						local rail = B:part(Vector3.new(x + sx * 2.8, 0.75, mid), Vector3.new(0.3, 0.7, half - 0.3), { Name = "Rail", Color = Color3.fromRGB(230, 230, 230), Material = Enum.Material.Metal, Parent = B.model })
						rail.Parent = m
					end
					m.PrimaryPart = deck
					m:SetAttribute("Lane", i)
					-- hinge on the platform edge at deck level; swing down 90 degrees
					m:SetAttribute("Hinge", B:w(Vector3.new(x, -0.4, hz)))
					m:SetAttribute("Swing", toward)
					m.Parent = B:folder("Bridges")
					-- hinge housing on the platform edge
					B:part(Vector3.new(x, 0.43, hz - toward * 0.4), Vector3.new(6.4, 0.06, 0.8), { Color = C.black, Parent = "Decor", CanCollide = false, Name = "HingePlate" })
				end
				-- a signal next to the bridge
				local sigZ = p[1] - 1.5
				B:part(Vector3.new(x + 4.5, 2.9, sigZ), Vector3.new(0.5, 5, 0.5), { Color = C.darkSteel, Parent = "Decor", Name = "SignalPost" })
				B:part(Vector3.new(x + 4.5, 5.9, sigZ), Vector3.new(1.3, 2.4, 1), { Color = C.black, Parent = "Decor", Name = "SignalHead" })
				B:part(Vector3.new(x + 4.5, 5.9, sigZ - 0.55), Vector3.new(0.8, 0.8, 0.1), {
					Name = "Signal" .. i,
					Color = C.green,
					Material = Enum.Material.Neon,
					Parent = "Signals",
					CanCollide = false,
					Light = { Range = 8, Brightness = 1, Color = C.green },
				})
			end
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local trains, bridges, signals = {}, {}, {}
		for _, t in level.Trains:GetChildren() do
			trains[t:GetAttribute("Lane")] = t
		end
		for _, b in level.Bridges:GetChildren() do
			local lane = b:GetAttribute("Lane")
			bridges[lane] = bridges[lane] or {}
			table.insert(bridges[lane], { m = b, home = b:GetPivot() })
		end
		for _, s in level.Signals:GetChildren() do
			local lane = tonumber(s.Name:match("%d+"))
			signals[lane] = signals[lane] or {}
			table.insert(signals[lane], s)
		end
		local function setSignal(lane, color)
			for _, s in signals[lane] or {} do
				s.Color = color
				local l = s:FindFirstChildWhichIsA("Light")
				if l then
					l.Color = color
				end
			end
		end
		-- drop (out = false) or raise (out = true) a lane's bridge leaves
		local function slide(lane, out)
			for _, b in bridges[lane] or {} do
				task.spawn(function()
					local hinge = CFrame.new(b.m:GetAttribute("Hinge"))
					local swing = b.m:GetAttribute("Swing")
					for k = 1, 18 do
						local a = k / 18
						a = a * a * (3 - 2 * a)
						local f = out and (1 - a) or a
						local angle = math.rad(90) * swing * f
						-- ease off the wall as it drops: hanging on the hinge line put the
						-- deck inside the pit wall, and its face Z-fought with the wall's
						local away = Vector3.new(0, 0, swing * 0.45 * f)
						b.m:PivotTo(CFrame.new(away) * hinge * CFrame.Angles(angle, 0, 0) * hinge:Inverse() * b.home)
						task.wait(1 / 30)
					end
				end)
			end
		end
		-- each cutting runs its own cycle: bridges out (green) -> amber ->
		-- bridges back (red) -> train passes -> bridges out again
		for lane, train in trains do
			task.spawn(function()
				local dir = train:GetAttribute("Dir")
				local base = train:GetPivot()
				local startX = base.Position.X
				-- get going almost straight away (lanes staggered a little)
				task.wait(0.4 + lane * 0.7)
				local first = true
				while not ctx.ended do
					setSignal(lane, C.green)
					task.wait(first and 1 or 4.5 + (lane % 2) * 1.5)
					first = false
					setSignal(lane, C.orange)
					task.wait(1.4)
					setSignal(lane, C.red)
					slide(lane, false)
					task.wait(0.8)
					Audio.play(ctx:w(Vector3.new(0, -4, (PITS[lane][1] + PITS[lane][2]) / 2)), "trainPass", 0.9, 160)
					local dist = 2 * (W / 2 + 140)
					local speed = 95
					local t = 0
					while t < dist and not ctx.ended do
						t += speed * task.wait()
						train:PivotTo(CFrame.new(startX + dir * t, base.Position.Y, base.Position.Z) * base.Rotation)
					end
					train:PivotTo(base)
					slide(lane, true)
					task.wait(0.8)
				end
			end)
		end
	end,
}
