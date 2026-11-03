-- Ticket Barrier (easy-medium): the gate line won't let anyone through. The
-- panel above the gates flashes a colour code; stomp the big floor buttons in
-- the same order. Three rounds (3, 4 and 5 colours) and the paddles swing open.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 64, 100
local GATE_Z = 58
local COLORS = { Color3.fromRGB(220, 50, 50), Color3.fromRGB(50, 110, 220), Color3.fromRGB(60, 180, 80), Color3.fromRGB(240, 190, 40) }
local ROUNDS = { 3, 4, 5 }
local STEEL = Color3.fromRGB(150, 156, 162)

return {
	Order = 8,
	Name = "Ticket Barrier",
	Mode = "escape",
	ExitLocked = true,
	TimeLimit = 120,
	Ambience = { { "stationAmbience", 0.35 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 22,
			floorColor = Color3.fromRGB(170, 166, 158),
			floorMat = Enum.Material.Marble,
			wallColor = Color3.fromRGB(226, 220, 206),
			lowerColor = Color3.fromRGB(60, 50, 110),
			trim = Color3.fromRGB(240, 190, 40),
			brightness = 1.3,
			exit = { x = 0, y = 0 },
		})
		B:checkpoint(Vector3.new(0, 0.1, 6), Vector3.new(7, 0.2, 4))
		-- four big floor buttons in a square in front of the gates
		local SPOTS = { Vector3.new(7, 0, 28), Vector3.new(-7, 0, 28), Vector3.new(7, 0, 42), Vector3.new(-7, 0, 42) }
		for i = 1, 4 do
			local x, z = SPOTS[i].X, SPOTS[i].Z
			B:cyl(Vector3.new(x, 0.25, z), 0.5, 10, "Y", { Color = Color3.fromRGB(60, 62, 68), Material = Enum.Material.Metal, Name = "ButtonRing" })
			B:cyl(Vector3.new(x, 0.75, z), 0.5, 8.4, "Y", {
				Name = "Button" .. i,
				Color = COLORS[i],
				Material = Enum.Material.SmoothPlastic,
				Parent = "Buttons",
				Attr = { Trigger = true, Index = i },
			})
		end
		-- the gate line: cabinets with glass paddles, a glass screen above
		local cabinets = {}
		for x = -W / 2 + 2, W / 2 - 2, 5 do
			table.insert(cabinets, x)
		end
		for _, x in cabinets do
			B:span(Vector3.new(x - 0.7, 0, GATE_Z - 2), Vector3.new(x + 0.7, 3.6, GATE_Z + 2), { Color = STEEL, Material = Enum.Material.Metal, Name = "GateCabinet" })
			B:part(Vector3.new(x, 3.62, GATE_Z - 1.4), Vector3.new(1.2, 0.06, 0.8), { Color = Color3.fromRGB(240, 190, 40), Parent = "Decor", CanCollide = false, Name = "Reader" })
			B:part(Vector3.new(x, 3.2, GATE_Z - 2.05), Vector3.new(0.6, 0.4, 0.1), { Color = Color3.fromRGB(220, 60, 50), Material = Enum.Material.Neon, Parent = "GateLights", CanCollide = false, Name = "GateLight" })
			-- glass upstand on the cabinet up to the screen, so you can't climb over
			B:span(Vector3.new(x - 0.6, 3.6, GATE_Z - 0.15), Vector3.new(x + 0.6, 9, GATE_Z + 0.15), { Color = Color3.fromRGB(190, 220, 235), Material = Enum.Material.Glass, Transparency = 0.6, Name = "CabinetGlass", CastShadow = false })
		end
		for k = 1, #cabinets - 1 do
			local x0, x1 = cabinets[k] + 0.7, cabinets[k + 1] - 0.7
			for _, side in { -1, 1 } do
				local w = (x1 - x0) / 2
				local hinge = side < 0 and x0 or x1
				-- tall glass paddles (the gap above them to the screen is too
				-- small to squeeze through)
				B:part(Vector3.new(hinge - side * w / 2, 3.5, GATE_Z), Vector3.new(w, 6, 0.3), {
					Name = "Paddle",
					Color = Color3.fromRGB(190, 220, 235),
					Material = Enum.Material.Glass,
					Transparency = 0.35,
					Parent = "Paddles",
					Attr = { Hinge = B:w(Vector3.new(hinge, 3.5, GATE_Z)), Side = side },
				})
			end
		end
		-- glass screen above head height, from the top of the gates to the ceiling
		B:span(Vector3.new(-W / 2, 9, GATE_Z - 0.2), Vector3.new(W / 2, 22, GATE_Z + 0.2), { Color = Color3.fromRGB(190, 220, 235), Material = Enum.Material.Glass, Transparency = 0.6, Name = "Screen", CastShadow = false })
		B:span(Vector3.new(-W / 2, 8.6, GATE_Z - 0.35), Vector3.new(W / 2, 9, GATE_Z + 0.35), { Color = STEEL, Material = Enum.Material.Metal, Name = "ScreenRail" })
		for x = -W / 2 + 2, W / 2 - 2, 10 do
			B:part(Vector3.new(x, 15.5, GATE_Z), Vector3.new(0.5, 13, 0.6), { Color = STEEL, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "Mullion" })
		end
		-- the display panel above the gates (on the screen)
		B:span(Vector3.new(-12, 11, GATE_Z - 0.7), Vector3.new(12, 17, GATE_Z - 0.2), { Color = Color3.fromRGB(20, 20, 24), Name = "Display" })
		B:part(Vector3.new(0, 14.6, GATE_Z - 0.75), Vector3.new(10, 3.2, 0.1), { Name = "SignalLamp", Color = Color3.fromRGB(30, 30, 34), Parent = B.model, CanCollide = false, Light = { Kind = "SurfaceLight", Face = Enum.NormalId.Front, Range = 22, Brightness = 0, Color = C.white, Angle = 120 } })
		for r = 1, #ROUNDS do
			B:part(Vector3.new(-3 + (r - 1) * 3, 11.9, GATE_Z - 0.75), Vector3.new(1.4, 0.6, 0.1), { Name = "Round" .. r, Color = Color3.fromRGB(60, 60, 64), Parent = "RoundLights", CanCollide = false })
		end
		-- ticket machines and the usual concourse things
		for i, z in { 18, 26 } do
			B:span(Vector3.new(-W / 2, 0, z - 2), Vector3.new(-W / 2 + 2.6, 7, z + 2), { Color = i == 1 and Color3.fromRGB(40, 90, 150) or Color3.fromRGB(60, 62, 66), Material = Enum.Material.Metal, Name = "TicketMachine" })
			B:part(Vector3.new(-W / 2 + 2.65, 4.6, z), Vector3.new(0.1, 1.8, 2.6), { Color = Color3.fromRGB(40, 80, 120), Material = Enum.Material.Glass, Parent = "Decor", CanCollide = false })
		end
		Decor.bench(B, Vector3.new(W / 2 - 2, 0, 20), 90)
		Decor.plant(B, Vector3.new(W / 2 - 3, 0, 8))
		Decor.advert(B, Vector3.new(W / 2, 8, 34), "-X")
		Decor.advert(B, Vector3.new(-W / 2, 8, 40), "+X")
		Decor.clock(B, Vector3.new(16, 15, 1.4), "+Z")
		Decor.plant(B, Vector3.new(-10, 0, D - 3))
		Decor.plant(B, Vector3.new(10, 0, D - 3))
		Decor.bench(B, Vector3.new(-22, 0, D - 3), 0)
	end,
	Run = function(ctx)
		local level = ctx.level
		local lamp = level.SignalLamp
		local light = lamp:FindFirstChildWhichIsA("Light")
		local buttons = {}
		for _, b in level.Buttons:GetChildren() do
			buttons[b:GetAttribute("Index")] = { p = b, home = b.CFrame }
		end
		local state = "wait"
		local seq, idx, round = {}, 1, 1
		local lastSeen = {}

		local function setLamp(color)
			lamp.Color = color or Color3.fromRGB(30, 30, 34)
			lamp.Material = color and Enum.Material.Neon or Enum.Material.SmoothPlastic
			light.Color = color or C.white
			light.Brightness = color and 2 or 0
		end
		local function press(i, flash)
			local b = buttons[i]
			b.p.CFrame = b.home - Vector3.new(0, 0.35, 0)
			b.p.Material = Enum.Material.Neon
			task.delay(flash or 0.35, function()
				b.p.CFrame = b.home
				b.p.Material = Enum.Material.SmoothPlastic
			end)
		end
		local function newSequence(n)
			seq = {}
			for i = 1, n do
				local c
				repeat
					c = math.random(1, 4)
				until i == 1 or c ~= seq[i - 1]
				seq[i] = c
			end
		end
		local function play()
			state = "show"
			task.wait(1)
			for _, c in seq do
				if ctx.ended then
					return
				end
				setLamp(COLORS[c])
				press(c, 0.7)
				Audio.play(lamp, "ding", 0.3, 120)
				task.wait(0.8)
				setLamp(nil)
				task.wait(0.35)
			end
			idx = 1
			state = "input"
		end
		local function openGates()
			state = "done"
			setLamp(COLORS[3])
			for _, l in level.GateLights:GetChildren() do
				l.Color = Color3.fromRGB(60, 220, 90)
			end
			-- the paddles swing open
			for _, p in level.Paddles:GetChildren() do
				local hinge = p:GetAttribute("Hinge")
				local side = p:GetAttribute("Side")
				local start = p.CFrame
				task.spawn(function()
					for k = 1, 20 do
						local a = math.rad(85) * k / 20 * side
						local rel = CFrame.new(hinge):ToObjectSpace(start)
						p.CFrame = CFrame.new(hinge) * CFrame.Angles(0, a, 0) * rel
						task.wait(1 / 30)
					end
					p.CanCollide = false
				end)
			end
			Audio.play(lamp, "doorOpen", 0.8, 150)
			ctx:openExit()
		end

		-- a press is stepping ONTO a button: tracked per player, so somebody
		-- idling on a button never blocks anyone else's press
		ctx.def.OnTrigger = function(_, player, pad)
			local now = os.clock()
			lastSeen[player] = lastSeen[player] or {}
			local seen = lastSeen[player]
			local fresh = not seen[pad] or now - seen[pad] > 0.4
			seen[pad] = now
			if not fresh or state ~= "input" then
				return
			end
			local c = pad:GetAttribute("Index")
			press(c)
			if c == seq[idx] then
				Audio.play(pad, "ding", 0.5)
				idx += 1
				if idx > #seq then
					level.RoundLights["Round" .. round].Color = Color3.fromRGB(60, 220, 90)
					level.RoundLights["Round" .. round].Material = Enum.Material.Neon
					round += 1
					if round > #ROUNDS then
						openGates()
					else
						state = "wait"
						newSequence(ROUNDS[round])
						task.delay(1, play)
					end
				end
			else
				state = "wait"
				Audio.play(pad, "buzzer", 0.7)
				setLamp(Color3.fromRGB(255, 40, 40))
				task.delay(1.2, function()
					setLamp(nil)
					play()
				end)
			end
		end

		newSequence(ROUNDS[1])
		ctx:waitForStart()
		task.wait(2)
		play()
	end,
}
