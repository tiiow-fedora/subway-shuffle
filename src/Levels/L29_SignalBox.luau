-- Signal Box (medium): a country junction. The barrier across the path to the
-- exit stays down until every signal shows green. Cross the two live tracks,
-- climb up into the signal box and pull the four red levers - each one turns
-- a signal outside (and a lamp on the diagram) from red to green.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local TrainKit = require(root.TrainKit)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 130, 150
local TRACKS = { 32, 56 }
local BOX = { x0 = -36, x1 = -18, z0 = 74, z1 = 92, ground = 8, top = 16 }
local GATE_Z = 104
local WOOD = Color3.fromRGB(120, 84, 52)
local CREAM = Color3.fromRGB(236, 226, 196)
local GREEN = Color3.fromRGB(40, 110, 70)
local RED_SIG, GREEN_SIG = Color3.fromRGB(230, 40, 30), Color3.fromRGB(40, 230, 80)

return {
	Order = 29,
	Name = "Signal Box",
	Mode = "escape",
	ExitLocked = true,
	TimeLimit = 130,
	Ambience = { { "birds", 0.35 } },
	Build = function(B)
		B:room({ W = W, D = D, outdoor = true, clearZ = { { 22, 66 } }, exit = { x = 4, z = 120 } })
		B:checkpoint(Vector3.new(0, 0.1, 7), Vector3.new(7, 0.2, 5))
		B:checkpoint(Vector3.new(-8, 0.1, 70), Vector3.new(6, 0.2, 5))
		-- the two running lines
		for i, z in TRACKS do
			Decor.track(B, Vector3.new(-W / 2 - 200, 0.3, z), Vector3.new(W / 2 + 200, 0.3, z), false)
			local dir = i == 1 and 1 or -1
			local train = TrainKit.shell(B, Vector3.new(-dir * (W / 2 + 120), 0.3, z), { Name = "Train" .. i, Hazard = true, Parent = "Trains", flip = dir < 0 })
			if train then
				train:SetAttribute("MoveFrom", train:GetPivot().Position)
				train:SetAttribute("MoveTo", B:w(Vector3.new(dir * (W / 2 + 120), 0.3, z)))
				train:SetAttribute("Speed", 50 + i * 6)
				train:SetAttribute("Pause", 3)
				train:SetAttribute("Phase", i * 0.3)
			end
		end
		-- THE SIGNAL BOX. Brick base, a glazed operating floor on top, reached by
		-- an open wooden staircase on its east side.
		local bx0, bx1, bz0, bz1, G, T = BOX.x0, BOX.x1, BOX.z0, BOX.z1, BOX.ground, BOX.top
		local zc = (bz0 + bz1) / 2
		local GLASS = Color3.fromRGB(200, 225, 235)
		local TRIM = Color3.fromRGB(245, 240, 225)
		local DARKWOOD = Color3.fromRGB(90, 62, 40)
		B:span(Vector3.new(bx0, 0, bz0), Vector3.new(bx1, G, bz1), { Color = Color3.fromRGB(150, 80, 60), Material = Enum.Material.Brick, Name = "BoxBase" })
		-- plinth and a stone string course just under the operating floor
		B:span(Vector3.new(bx0 - 0.3, 0, bz0 - 0.3), Vector3.new(bx1 + 0.3, 0.8, bz1 + 0.3), { Color = Color3.fromRGB(90, 86, 82), Material = Enum.Material.Slate, Name = "Plinth" })
		B:span(Vector3.new(bx0 - 0.25, G - 0.9, bz0 - 0.25), Vector3.new(bx1 + 0.25, G - 0.5, bz1 + 0.25), { Color = Color3.fromRGB(200, 194, 180), Material = Enum.Material.Concrete, Name = "StringCourse" })
		-- locking-room door and small windows in the base (decor)
		B:part(Vector3.new(bx1 - 4, 3.5, bz0 - 0.05), Vector3.new(3, 7, 0.1), { Color = GREEN, Parent = "Decor", CanCollide = false, Name = "BaseDoor" })
		for _, x in { bx0 + 4, bx0 + 9 } do
			B:part(Vector3.new(x, 4.5, bz0 - 0.05), Vector3.new(2.4, 2.6, 0.1), { Color = Color3.fromRGB(60, 70, 80), Material = Enum.Material.Glass, Parent = "Decor", CanCollide = false })
			B:part(Vector3.new(x, 3.1, bz0 - 0.15), Vector3.new(2.8, 0.25, 0.3), { Color = Color3.fromRGB(200, 194, 180), Parent = "Decor", CanCollide = false, Name = "Sill" })
		end
		-- operating floor: floor, cream panels to waist height, glazing above
		B:span(Vector3.new(bx0 - 0.5, G, bz0 - 0.5), Vector3.new(bx1 + 0.5, G + 0.4, bz1 + 0.5), { Color = WOOD, Material = Enum.Material.WoodPlanks, Name = "OpFloor" })
		local panel = { Color = CREAM, Material = Enum.Material.WoodPlanks, Name = "Panel" }
		local fy = G + 0.4
		local sillY = fy + 3
		local headY = T - 0.6
		local function glass(a, b)
			B:span(Vector3.new(a.X, sillY, a.Z), Vector3.new(b.X, headY, b.Z), { Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.6, Name = "Window", CastShadow = false })
		end
		local function bar(pos, size)
			B:part(pos, size, { Color = TRIM, Material = Enum.Material.Wood, Parent = "Decor", Name = "GlazingBar", CanCollide = false })
		end
		-- front (south) and back (north)
		for _, z in { bz0, bz1 } do
			B:span(Vector3.new(bx0, fy, z - 0.3), Vector3.new(bx1, sillY, z + 0.3), panel)
			B:part(Vector3.new((bx0 + bx1) / 2, sillY + 0.1, z), Vector3.new(bx1 - bx0 + 0.4, 0.2, 0.9), { Color = WOOD, Material = Enum.Material.Wood, Name = "Sill" })
			glass(Vector3.new(bx0, 0, z - 0.1), Vector3.new(bx1, 0, z + 0.1))
			for x = bx0 + 3, bx1 - 1, 3 do
				bar(Vector3.new(x, (sillY + headY) / 2, z), Vector3.new(0.25, headY - sillY, 0.35))
			end
			bar(Vector3.new((bx0 + bx1) / 2, sillY + 3.4, z), Vector3.new(bx1 - bx0, 0.2, 0.3))
		end
		-- west (the diagram wall)
		B:span(Vector3.new(bx0 - 0.3, fy, bz0), Vector3.new(bx0 + 0.3, sillY, bz1), panel)
		B:part(Vector3.new(bx0, sillY + 0.1, zc), Vector3.new(0.9, 0.2, bz1 - bz0 + 0.4), { Color = WOOD, Material = Enum.Material.Wood, Name = "Sill" })
		glass(Vector3.new(bx0 - 0.1, 0, bz0), Vector3.new(bx0 + 0.1, 0, bz1))
		for z = bz0 + 3, bz1 - 1, 3 do
			bar(Vector3.new(bx0, (sillY + headY) / 2, z), Vector3.new(0.35, headY - sillY, 0.25))
		end
		bar(Vector3.new(bx0, sillY + 3.4, zc), Vector3.new(0.3, 0.2, bz1 - bz0))
		-- east wall: solid, with the doorway (z 79..84) onto the landing
		B:wallX(bx1 - 0.3, bx1 + 0.3, bz0, bz1, fy, T, { { 79, 84, fy - 0.01, fy + 7 } }, panel)
		B:part(Vector3.new(bx1 + 0.35, fy + 3.5, 84.4), Vector3.new(0.1, 7, 0.8), { Color = GREEN, Parent = "Decor", CanCollide = false, Name = "DoorLeaf" })
		-- corner posts and the head beams
		for _, x in { bx0, bx1 } do
			for _, z in { bz0, bz1 } do
				B:part(Vector3.new(x, (fy + T) / 2, z), Vector3.new(0.7, T - fy, 0.7), { Color = WOOD, Material = Enum.Material.Wood, Name = "Post" })
			end
		end
		for _, z in { bz0, bz1 } do
			B:part(Vector3.new((bx0 + bx1) / 2, T - 0.3, z), Vector3.new(bx1 - bx0 + 0.7, 0.6, 0.7), { Color = WOOD, Material = Enum.Material.Wood, Name = "HeadBeam" })
		end
		B:part(Vector3.new(bx0, T - 0.3, zc), Vector3.new(0.7, 0.6, bz1 - bz0), { Color = WOOD, Material = Enum.Material.Wood, Name = "HeadBeam" })
		-- pitched roof with deep eaves, bargeboards on the gable ends, a stove pipe
		local midX = (bx0 + bx1) / 2
		local span = (bx1 - bx0) / 2 + 2
		for _, sx in { -1, 1 } do
			B:ramp(Vector3.new(midX + sx * span, T - 1, zc), Vector3.new(midX, T + 4, zc), bz1 - bz0 + 3, { Color = Color3.fromRGB(70, 60, 60), Material = Enum.Material.Slate, Name = "Roof", Thick = 0.6 })
			for _, z in { bz0 - 1.6, bz1 + 1.6 } do
				B:ramp(Vector3.new(midX + sx * span, T - 1.2, z), Vector3.new(midX, T + 3.8, z), 0.3, { Color = TRIM, Material = Enum.Material.Wood, Name = "Bargeboard", Thick = 0.8, Parent = "Decor", CanCollide = false })
			end
		end
		B:part(Vector3.new(midX, T + 0.2, zc), Vector3.new(bx1 - bx0, 0.3, bz1 - bz0), { Color = Color3.fromRGB(220, 214, 196), Name = "Ceiling", Parent = "Decor", CanCollide = false })
		B:cyl(Vector3.new(bx0 + 3, T + 3.5, bz0 + 4), 4, 0.8, "Y", { Color = C.black, Material = Enum.Material.Metal, Parent = "Decor", Name = "StovePipe" })
		-- open wooden staircase up the east side: 12 treads, stringers, handrails
		local SX, SW, SZ0, SZ1 = -12, 4, 66, 79
		local n = 12
		for i = 1, n do
			local top = fy * i / n
			local z0 = SZ0 + (SZ1 - SZ0) * (i - 1) / n
			local z1 = SZ0 + (SZ1 - SZ0) * i / n
			B:span(Vector3.new(SX - SW / 2, top - 0.35, z0), Vector3.new(SX + SW / 2, top, z1 + 0.05), { Color = WOOD, Material = Enum.Material.WoodPlanks, Name = "Step" })
		end
		for _, side in { -1, 1 } do
			local x = SX + side * (SW / 2 + 0.2)
			B:ramp(Vector3.new(x, 0.4, SZ0), Vector3.new(x, fy + 0.4, SZ1), 0.35, { Color = DARKWOOD, Material = Enum.Material.Wood, Name = "Stringer", Thick = 1.4, Parent = "Decor" })
			B:ramp(Vector3.new(x, 3.4, SZ0), Vector3.new(x, fy + 3.4, SZ1), 0.3, { Color = WOOD, Material = Enum.Material.Wood, Name = "Handrail", Thick = 0.3 })
			for _, z in { SZ0 + 0.3, SZ1 - 0.2 } do
				local y0 = fy * (z - SZ0) / (SZ1 - SZ0)
				B:part(Vector3.new(x, y0 + 1.7, z), Vector3.new(0.35, 3.4, 0.35), { Color = WOOD, Material = Enum.Material.Wood, Name = "NewelPost" })
			end
			for k = 1, 5 do
				local z = SZ0 + (SZ1 - SZ0) * k / 6
				local y0 = fy * (z - SZ0) / (SZ1 - SZ0)
				B:part(Vector3.new(x, y0 + 1.7, z), Vector3.new(0.15, 3.4, 0.15), { Color = WOOD, Material = Enum.Material.Wood, Name = "Baluster", Parent = "Decor", CanCollide = false })
			end
		end
		-- landing at the top, round to the door, railed on its open sides
		B:span(Vector3.new(bx1, G, 79), Vector3.new(SX + SW / 2, fy, 84), { Color = WOOD, Material = Enum.Material.WoodPlanks, Name = "Landing" })
		for _, x in { SX - SW / 2 + 0.3, SX + SW / 2 - 0.3 } do
			B:part(Vector3.new(x, G / 2, 83.6), Vector3.new(0.5, G, 0.5), { Color = DARKWOOD, Material = Enum.Material.Wood, Name = "LandingPost" })
		end
		local function railRun(a, b)
			local mid = (a + b) / 2
			local len = (b - a).Magnitude
			local along = math.abs(b.X - a.X) > 0.01 and Vector3.new(len, 0, 0) or Vector3.new(0, 0, len)
			B:part(mid + Vector3.new(0, 3.2, 0), Vector3.new(0.3, 0.3, 0.3) + along, { Color = WOOD, Material = Enum.Material.Wood, Name = "Handrail" })
			B:part(mid + Vector3.new(0, 1.6, 0), Vector3.new(0.1, 3, 0.1) + along, { Color = Color3.fromRGB(220, 210, 190), Material = Enum.Material.Wood, Name = "RailInfill", Parent = "Decor", CanCollide = false })
			-- invisible guard so nobody slips off the landing edge
			B:part(mid + Vector3.new(0, 1.8, 0), Vector3.new(0.3, 3.6, 0.3) + along, { Transparency = 1, CastShadow = false, Name = "RailGuard" })
		end
		railRun(Vector3.new(bx1 + 0.3, fy, 83.85), Vector3.new(SX + SW / 2, fy, 83.85))
		railRun(Vector3.new(SX + SW / 2 - 0.15, fy, 79), Vector3.new(SX + SW / 2 - 0.15, fy, 83.7))
		railRun(Vector3.new(bx1 + 0.3, fy, 79.15), Vector3.new(SX - SW / 2, fy, 79.15))
		-- a little canopy over the door
		B:span(Vector3.new(bx1 + 0.3, fy + 7.4, 78.4), Vector3.new(bx1 + 2.8, fy + 7.7, 84.6), { Color = Color3.fromRGB(70, 60, 60), Material = Enum.Material.Slate, Name = "Canopy" })

		-- inside: the lever frame along the north wall. The four live levers are
		-- red, lit and outlined; spare levers are dull. Levers stand "normal",
		-- leaning away from you, and get pulled back toward you.
		local levers = { { col = C.red, active = 1 }, { col = C.black }, { col = C.red, active = 2 }, { col = C.blue }, { col = C.red, active = 3 }, { col = Color3.fromRGB(230, 200, 40) }, { col = C.red, active = 4 }, { col = C.black } }
		B:span(Vector3.new(bx0 + 1, fy, bz1 - 3.2), Vector3.new(bx1 - 1, fy + 0.8, bz1 - 1.4), { Color = Color3.fromRGB(50, 50, 54), Material = Enum.Material.Metal, Name = "LeverFrame" })
		B:part(Vector3.new((bx0 + bx1) / 2, fy + 0.82, bz1 - 2.3), Vector3.new(bx1 - bx0 - 3, 0.04, 0.3), { Color = Color3.fromRGB(20, 20, 22), Parent = "Decor", CanCollide = false, Name = "Slot" })
		for i, l in levers do
			local x = bx0 + 2.8 + (i - 1) * 1.8
			local base = Vector3.new(x, fy + 0.8, bz1 - 2.3)
			local m = Instance.new("Model")
			m.Name = "Lever" .. i
			local pivot = B:part(base, Vector3.new(0.6, 0.5, 0.6), { Name = "Pivot", Color = Color3.fromRGB(30, 30, 30), Parent = B.model })
			pivot.Parent = m
			local parts = {
				B:part(base + Vector3.new(0, 2.4, 0), Vector3.new(0.32, 4.8, 0.32), { Name = "Handle", Color = l.col, Material = Enum.Material.SmoothPlastic, Parent = B.model, CanCollide = false }),
				B:part(base + Vector3.new(0, 4.9, 0), Vector3.new(0.4, 0.7, 0.4), { Name = "Grip", Color = Color3.fromRGB(215, 215, 220), Material = Enum.Material.Metal, Reflectance = 0.2, Parent = B.model, CanCollide = false }),
				B:part(base + Vector3.new(0, 3.9, -0.3), Vector3.new(0.22, 0.9, 0.3), { Name = "Catch", Color = Color3.fromRGB(190, 190, 196), Material = Enum.Material.Metal, Parent = B.model, CanCollide = false }),
			}
			-- lean the lever 20 degrees away from the operator, about its pivot
			local pcf = pivot.CFrame
			local lean = pcf * CFrame.Angles(math.rad(20), 0, 0)
			for _, p in parts do
				p.CFrame = lean * pcf:ToObjectSpace(p.CFrame)
				p.Parent = m
			end
			m.PrimaryPart = pivot
			m.Parent = B:folder("Levers")
			if l.active then
				m:SetAttribute("Active", l.active)
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Pull"
				prompt.ObjectText = "Signal lever " .. l.active
				prompt.HoldDuration = 0
				prompt.MaxActivationDistance = 10
				prompt.RequiresLineOfSight = false
				prompt.Parent = parts[2]
				-- lit, so they glow through the windows from the ground
				local glow = Instance.new("PointLight")
				glow.Name = "LeverGlow"
				glow.Color = RED_SIG
				glow.Range = 4.5
				glow.Brightness = 0.7
				glow.Parent = parts[2]
				local hl = Instance.new("Highlight")
				hl.Name = "LeverHighlight"
				hl.FillColor = RED_SIG
				hl.FillTransparency = 0.55
				hl.OutlineColor = Color3.fromRGB(255, 230, 120)
				hl.DepthMode = Enum.HighlightDepthMode.Occluded
				hl.Parent = m
				-- number plate on the front of the frame
				B:sign(Vector3.new(x, fy + 0.45, bz1 - 3.25), Vector3.new(1, 0.6, 0.05), tostring(l.active), { Color = C.white, TextColor = C.black, Face = Enum.NormalId.Front, Parent = "Decor", CanCollide = false })
			end
		end
		-- a lamp over the frame
		B:part(Vector3.new((bx0 + bx1) / 2, T - 1.2, bz1 - 2.6), Vector3.new(bx1 - bx0 - 4, 0.3, 0.8), { Name = "FrameLamp", Color = Color3.fromRGB(255, 240, 210), Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false, Light = { Kind = "SpotLight", Face = Enum.NormalId.Bottom, Range = 12, Brightness = 2, Angle = 90, Color = Color3.fromRGB(255, 236, 200) } })
		-- the diagram board on the west wall, with one lamp per signal
		B:part(Vector3.new(bx0 + 0.5, fy + 5.5, zc), Vector3.new(0.2, 3, 10), { Color = Color3.fromRGB(20, 24, 30), Name = "Diagram" })
		for _, y in { fy + 5, fy + 6 } do
			B:part(Vector3.new(bx0 + 0.65, y, zc), Vector3.new(0.05, 0.12, 9), { Color = C.white, Parent = "Decor", CanCollide = false })
		end
		for k = 1, 4 do
			B:part(Vector3.new(bx0 + 0.7, fy + 6.5, bz0 + 3 + (k - 1) * 3.4), Vector3.new(0.1, 0.5, 0.5), { Name = "DiagLamp" .. k, Color = RED_SIG, Material = Enum.Material.Neon, Parent = "DiagLamps", CanCollide = false })
		end
		-- desk and phone
		B:span(Vector3.new(bx1 - 5, fy, bz0 + 1), Vector3.new(bx1 - 1, fy + 2.6, bz0 + 3), { Color = WOOD, Material = Enum.Material.Wood, Name = "Desk" })
		B:part(Vector3.new(bx1 - 3, fy + 2.9, bz0 + 2), Vector3.new(0.8, 0.5, 0.6), { Color = C.black, Parent = "Decor", Name = "Phone" })
		-- the four signals outside (by the gate), red until their lever is pulled
		for k = 1, 4 do
			local x = -20 + (k - 1) * 9
			B:part(Vector3.new(x, 3.5, GATE_Z - 3), Vector3.new(0.5, 7, 0.5), { Color = C.darkSteel, Material = Enum.Material.Metal, Parent = "Decor", Name = "SignalPost" })
			B:part(Vector3.new(x, 7.6, GATE_Z - 3), Vector3.new(1.4, 1.8, 1), { Color = C.black, Parent = "Decor", Name = "SignalHead" })
			B:part(Vector3.new(x, 7.6, GATE_Z - 3.55), Vector3.new(0.8, 0.8, 0.1), { Name = "Signal" .. k, Color = RED_SIG, Material = Enum.Material.Neon, Parent = "Signals", CanCollide = false, Light = { Range = 10, Brightness = 1, Color = RED_SIG } })
		end
		-- the fence and the barrier across the path to the exit
		B:span(Vector3.new(-W / 2, 0, GATE_Z), Vector3.new(-2, 4, GATE_Z + 0.4), { Color = Color3.fromRGB(200, 196, 186), Material = Enum.Material.WoodPlanks, Name = "Fence" })
		B:span(Vector3.new(10, 0, GATE_Z), Vector3.new(W / 2, 4, GATE_Z + 0.4), { Color = Color3.fromRGB(200, 196, 186), Material = Enum.Material.WoodPlanks, Name = "Fence" })
		-- invisible above the fence so it can't be jumped (but not over the gate)
		B:span(Vector3.new(-W / 2, 4, GATE_Z), Vector3.new(-2, 40, GATE_Z + 0.4), { Transparency = 1, Name = "FenceBounds", CastShadow = false })
		B:span(Vector3.new(10, 4, GATE_Z), Vector3.new(W / 2, 40, GATE_Z + 0.4), { Transparency = 1, Name = "FenceBounds", CastShadow = false })
		B:part(Vector3.new(-2, 2, GATE_Z + 0.2), Vector3.new(0.8, 4, 0.8), { Color = C.darkSteel, Name = "GatePost" })
		local arm = Instance.new("Model")
		arm.Name = "BarrierArm"
		local hinge = B:part(Vector3.new(-2, 3, GATE_Z + 0.2), Vector3.new(0.6, 0.6, 0.6), { Name = "Hinge", Transparency = 1, Parent = B.model, CanCollide = false })
		hinge.Parent = arm
		for k = 0, 5 do
			local seg = B:part(Vector3.new(-1 + k * 2 + 1, 3, GATE_Z + 0.2), Vector3.new(2, 0.6, 0.4), { Color = k % 2 == 0 and C.red or C.white, Parent = B.model, Name = "ArmSeg" })
			seg.Parent = arm
		end
		local block = B:part(Vector3.new(4, 20, GATE_Z + 0.2), Vector3.new(12, 40, 1), { Name = "GateBlock", Transparency = 1, Parent = B.model, CastShadow = false })
		block.Parent = arm
		arm.PrimaryPart = hinge
		arm.Parent = B.model
	end,
	Run = function(ctx)
		local level = ctx.level
		local pulled = 0
		local signals, lamps = {}, {}
		for k = 1, 4 do
			signals[k] = level.Signals["Signal" .. k]
			lamps[k] = level.DiagLamps["DiagLamp" .. k]
		end
		local function setGreen(k)
			signals[k].Color = GREEN_SIG
			signals[k]:FindFirstChildWhichIsA("Light").Color = GREEN_SIG
			lamps[k].Color = GREEN_SIG
		end
		local function openGate()
			local arm = level.BarrierArm
			local hinge = arm.PrimaryPart
			local start = arm:GetPivot()
			arm.GateBlock.CanCollide = false
			Audio.play(hinge, "lever", 0.8)
			task.spawn(function()
				for i = 1, 30 do
					arm:PivotTo(start * CFrame.Angles(0, 0, math.rad(80 * i / 30)))
					task.wait(1 / 30)
				end
			end)
			ctx:broadcast("All signals green - the barrier's up!")
			ctx:openExit()
		end
		-- the live levers pulse until they're pulled
		ctx:every(0.05, function()
			local t = 0.45 + 0.35 * math.sin(os.clock() * 4)
			for _, m in level.Levers:GetChildren() do
				local hl = m:FindFirstChild("LeverHighlight")
				if hl then
					hl.FillTransparency = t
				end
			end
		end)
		local function ease(a)
			return a < 0.5 and 4 * a * a * a or 1 - (-2 * a + 2) ^ 3 / 2
		end
		for _, m in level.Levers:GetChildren() do
			local k = m:GetAttribute("Active")
			if k then
				local grip = m:FindFirstChild("Grip")
				local prompt = grip:FindFirstChildOfClass("ProximityPrompt")
				ctx:connect(prompt.Triggered, function(player)
					prompt.Enabled = false
					local hl = m:FindFirstChild("LeverHighlight")
					if hl then
						hl:Destroy()
					end
					local glow = grip:FindFirstChild("LeverGlow")
					if glow then
						glow.Color = GREEN_SIG
					end
					-- swing from "normal" (+20, leaning away) to "reversed" (-25,
					-- toward you) about the pivot, eased, then settle on the stop
					local base = m.PrimaryPart.CFrame
					local rest = base * CFrame.Angles(math.rad(20), 0, 0)
					local rel = {}
					for _, p in m:GetChildren() do
						if p:IsA("BasePart") and p ~= m.PrimaryPart then
							rel[p] = rest:ToObjectSpace(p.CFrame)
						end
					end
					local function pose(deg)
						local cf = base * CFrame.Angles(math.rad(deg), 0, 0)
						for p, r in rel do
							p.CFrame = cf * r
						end
					end
					Audio.play(m.PrimaryPart, "lever", 0.9)
					task.spawn(function()
						local t0 = os.clock()
						while true do
							local a = math.min(1, (os.clock() - t0) / 0.55)
							pose(20 - 47 * ease(a))
							if a >= 1 then
								break
							end
							task.wait()
						end
						for i = 1, 6 do
							pose(-27 + 2 * i / 6)
							task.wait(1 / 60)
						end
						pose(-25)
					end)
					setGreen(k)
					pulled += 1
					ctx:broadcast(string.format("%s pulled lever %d (%d/4)", player.DisplayName, k, pulled))
					if pulled >= 4 then
						openGate()
					end
				end)
			end
		end
	end,
}
