-- Commuter Cafe (chill): a breather stop. Grab an espresso from the counter
-- (10 seconds of extra speed), sit down, watch the commuters go past the
-- window, and wait for the train.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local H = require(root.LevelHelpers)
local Decor = require(root.Decor)
local Kit = require(root.LevelKit)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 56, 64
local WOOD = Color3.fromRGB(120, 80, 50)
local DARKWOOD = Color3.fromRGB(80, 52, 34)
local WARM = Color3.fromRGB(255, 196, 130)
local BOOST_TIME = 10
local WINDOWS = { { 14, 26 }, { 32, 44 } } -- z ranges of the big windows (right wall)

local function chair(B, pos, rotY)
	local rot = CFrame.Angles(0, math.rad(rotY), 0)
	local function at(v)
		return pos + rot * v
	end
	for _, dx in { -0.8, 0.8 } do
		for _, dz in { -0.8, 0.8 } do
			B:part(at(Vector3.new(dx, 0.9, dz)), Vector3.new(0.25, 1.8, 0.25), { Color = DARKWOOD, Parent = "Decor", Name = "ChairLeg" })
		end
	end
	local seat = Instance.new("Seat")
	seat.Anchored = true
	seat.Size = Vector3.new(2, 0.3, 2)
	seat.CFrame = CFrame.new(B:w(at(Vector3.new(0, 1.95, 0)))) * rot
	seat.Color = Color3.fromRGB(150, 50, 40)
	seat.Material = Enum.Material.Fabric
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.Parent = B:folder("Decor")
	B:part(at(Vector3.new(0, 3.1, 0.9)), Vector3.new(2, 2, 0.25), { Color = DARKWOOD, Rot = Vector3.new(0, rotY, 0), Parent = "Decor", Name = "ChairBack" })
end

local function cafeTable(B, pos)
	B:cyl(pos + Vector3.new(0, 3, 0), 0.25, 4.6, "Y", { Color = WOOD, Material = Enum.Material.Wood, Name = "TableTop" })
	B:cyl(pos + Vector3.new(0, 1.5, 0), 3, 0.5, "Y", { Color = C.darkSteel, Material = Enum.Material.Metal, Name = "TableLeg" })
	B:cyl(pos + Vector3.new(0, 0.1, 0), 0.2, 2.2, "Y", { Color = C.darkSteel, Material = Enum.Material.Metal, Parent = "Decor", Name = "TableFoot" })
	B:cyl(pos + Vector3.new(0.8, 3.45, 0.4), 0.7, 0.6, "Y", { Color = C.white, Parent = "Decor", CanCollide = false, Name = "Mug" })
	-- pendant lamp over the table
	B:part(pos + Vector3.new(0, 12.5, 0), Vector3.new(0.1, 7, 0.1), { Color = C.black, Parent = "Decor", CanCollide = false, Name = "Cord" })
	B:cyl(pos + Vector3.new(0, 8.8, 0), 0.8, 2.2, "Y", { Color = DARKWOOD, Parent = "Decor", CanCollide = false, Name = "Shade" })
	B:ball(pos + Vector3.new(0, 8.3, 0), 0.8, { Color = WARM, Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false, Name = "Bulb", Light = { Range = 20, Brightness = 0.7, Color = WARM } })
end

return {
	Order = 10,
	Name = "Commuter Cafe",
	Mode = "chill",
	TimeLimit = 45,
	Ambience = { { "crowd", 0.1 } },
	Lighting = { ClockTime = 17.5, Ambient = Color3.fromRGB(120, 100, 84), OutdoorAmbient = Color3.fromRGB(120, 100, 84) },
	Build = function(B)
		local holes = {}
		for _, w in WINDOWS do
			table.insert(holes, { side = 1, w[1], w[2], 3, 12 })
		end
		B:room({
			W = W,
			D = D,
			H = 16,
			floorColor = Color3.fromRGB(150, 104, 66),
			floorMat = Enum.Material.WoodPlanks,
			wallColor = Color3.fromRGB(232, 214, 184),
			lowerColor = WOOD,
			lowerMat = Enum.Material.WoodPlanks,
			trim = DARKWOOD,
			lamps = false,
			beams = false,
			trays = false,
			sideHoles = holes,
			exit = false,
		})
		-- the windows: glass panes, frames, and a lit corridor outside them
		for _, w in WINDOWS do
			local zc = (w[1] + w[2]) / 2
			B:part(Vector3.new(W / 2 + 0.5, 7.5, zc), Vector3.new(0.2, 9, w[2] - w[1]), { Color = Color3.fromRGB(200, 225, 235), Material = Enum.Material.Glass, Transparency = 0.7, Name = "WindowGlass", CastShadow = false })
			for _, z in { w[1], zc, w[2] } do
				B:part(Vector3.new(W / 2 - 0.1, 7.5, z), Vector3.new(0.4, 9, 0.4), { Color = DARKWOOD, Parent = "Decor", CanCollide = false, Name = "WindowFrame" })
			end
			B:part(Vector3.new(W / 2 - 0.4, 2.9, zc), Vector3.new(1, 0.3, w[2] - w[1] + 0.6), { Color = DARKWOOD, Parent = "Decor", Name = "Sill" })
		end
		-- the corridor outside the windows
		local cx0, cx1 = W / 2 + 1, W / 2 + 13
		B:span(Vector3.new(cx0, -1, 4), Vector3.new(cx1, 0, 56), { Color = Color3.fromRGB(176, 170, 160), Material = Enum.Material.Marble, Name = "CorridorFloor" })
		B:span(Vector3.new(cx1, -1, 4), Vector3.new(cx1 + 1, 16, 56), { Color = Color3.fromRGB(226, 218, 200), Material = Enum.Material.Concrete, Name = "CorridorWall" })
		B:span(Vector3.new(cx0, 16, 4), Vector3.new(cx1 + 1, 17, 56), { Color = Color3.fromRGB(86, 84, 82), Name = "CorridorCeiling" })
		for _, z in { 4, 56 } do
			B:span(Vector3.new(cx0, -1, z - 1), Vector3.new(cx1 + 1, 17, z), { Color = Color3.fromRGB(20, 20, 22), Name = "CorridorEnd" })
		end
		for z = 10, 50, 10 do
			B:lamp(Vector3.new((cx0 + cx1) / 2, 15.7, z), Vector3.new(4, 0.2, 1.2), { Color = Color3.fromRGB(240, 240, 230), Glow = true, Range = 18, Brightness = 1 })
		end
		Decor.advert(B, Vector3.new(cx1, 7, 20), "-X")
		Decor.advert(B, Vector3.new(cx1, 7, 40), "-X")
		for k = 1, 4 do
			local npc = H.npc(B, Vector3.new((cx0 + cx1) / 2 + (k % 2 == 0 and 2 or -2), 0, 6 + k * 11), k % 2 == 0 and "guest" or "noob", k % 2 == 0 and 0 or 180, { Name = "Passer", Parent = "Passers" })
			npc:SetAttribute("Anim", "walk")
			npc:SetAttribute("AnimSpeed", 0.7)
			npc:SetAttribute("Dir", k % 2 == 0 and -1 or 1)
		end
		-- counter along the back, display case, coffee machine, register
		B:span(Vector3.new(-18, 0, D - 13), Vector3.new(14, 3.6, D - 10), { Color = DARKWOOD, Material = Enum.Material.WoodPlanks, Name = "Counter" })
		B:span(Vector3.new(-18.2, 3.6, D - 13.2), Vector3.new(14.2, 3.9, D - 9.8), { Color = Color3.fromRGB(236, 232, 222), Material = Enum.Material.Marble, Name = "CounterTop" })
		B:span(Vector3.new(4, 3.9, D - 13), Vector3.new(13, 6.2, D - 10.2), { Color = Color3.fromRGB(210, 230, 240), Material = Enum.Material.Glass, Transparency = 0.6, Name = "DisplayCase" })
		for k = 0, 3 do
			B:part(Vector3.new(5.2 + k * 2.2, 4.3, D - 11.6), Vector3.new(1.4, 0.6, 1.2), { Color = ({ Color3.fromRGB(220, 170, 90), Color3.fromRGB(120, 70, 40), Color3.fromRGB(240, 200, 120), Color3.fromRGB(200, 90, 110) })[k + 1], Parent = "Decor", CanCollide = false, Name = "Pastry" })
		end
		B:span(Vector3.new(-16, 3.9, D - 12.6), Vector3.new(-11, 7.6, D - 10.4), { Color = Color3.fromRGB(70, 72, 78), Material = Enum.Material.Metal, Name = "CoffeeMachine" })
		B:part(Vector3.new(-13.5, 7.7, D - 11.5), Vector3.new(3.6, 0.2, 1.6), { Color = Color3.fromRGB(190, 190, 195), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false })
		for _, x in { -15, -12 } do
			B:part(Vector3.new(x, 5.4, D - 12.75), Vector3.new(0.5, 0.8, 0.3), { Color = C.black, Parent = "Decor", CanCollide = false, Name = "Group" })
		end
		B:span(Vector3.new(-6, 3.9, D - 12.4), Vector3.new(-3, 5.4, D - 10.6), { Color = Color3.fromRGB(40, 40, 44), Name = "Register" })
		B:part(Vector3.new(-4.5, 4.2, D - 10.3), Vector3.new(2.4, 0.5, 0.6), { Color = Color3.fromRGB(60, 60, 66), Material = Enum.Material.Metal, Parent = B.model, CanCollide = false, Name = "RegisterDrawer" })
		-- the plate the barista serves pastries onto
		B:cyl(Vector3.new(1, 3.95, D - 12.4), 0.1, 1.8, "Y", { Color = C.white, Parent = "Decor", CanCollide = false, Name = "ServePlate" })
		-- espresso cups on the counter front, with a prompt each
		for i = 1, 5 do
			local x = -9 + (i - 1) * 2.2
			local cup = B:cyl(Vector3.new(x, 4.4, D - 12.6), 1, 0.9, "Y", { Name = "Espresso" .. i, Color = C.white, Material = Enum.Material.SmoothPlastic, Parent = "Cups" })
			B:cyl(Vector3.new(x, 4.95, D - 12.6), 0.06, 0.75, "Y", { Color = Color3.fromRGB(70, 40, 20), Parent = cup, CanCollide = false, Name = "Coffee" })
			local steam = Instance.new("ParticleEmitter")
			steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
			steam.Rate = 3
			steam.Speed = NumberRange.new(1, 2)
			steam.Lifetime = NumberRange.new(1, 1.5)
			steam.Size = NumberSequence.new(0.3, 0.8)
			steam.Transparency = NumberSequence.new(0.5, 1)
			steam.Parent = cup
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Drink"
			prompt.ObjectText = "Espresso"
			prompt.HoldDuration = 0.3
			prompt.MaxActivationDistance = 8
			prompt.RequiresLineOfSight = false
			prompt.Parent = cup
		end
		-- warm pendants over the counter and a lit back bar
		for _, x in { -12, -4, 6 } do
			B:part(Vector3.new(x, 13.25, D - 11.5), Vector3.new(0.1, 5.5, 0.1), { Color = C.black, Parent = "Decor", CanCollide = false, Name = "Cord" })
			B:cyl(Vector3.new(x, 10.2, D - 11.5), 1, 2.4, "Y", { Color = Color3.fromRGB(40, 70, 60), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "Shade" })
			B:lamp(Vector3.new(x, 9.6, D - 11.5), Vector3.new(1.6, 0.2, 1.6), { Color = WARM, Range = 16, Brightness = 0.8, Face = Enum.NormalId.Bottom, Angle = 130 })
		end
		B:part(Vector3.new(11, 7.85, D - 0.9), Vector3.new(9.6, 0.15, 0.3), { Color = WARM, Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false, Name = "ShelfLight", Light = { Kind = "SurfaceLight", Face = Enum.NormalId.Bottom, Range = 9, Brightness = 0.9, Color = WARM, Angle = 150 } })
		B:part(Vector3.new(-7, 15.2, D - 1.2), Vector3.new(20, 0.3, 0.6), { Color = DARKWOOD, Parent = "Decor", CanCollide = false, Name = "MenuLightBar", Light = { Kind = "SurfaceLight", Face = Enum.NormalId.Bottom, Range = 8, Brightness = 0.7, Color = WARM, Angle = 120 } })
		-- the barista and the menu board behind the counter
		local barista = H.figure(B, Vector3.new(-4, 0, D - 6), { Name = "Barista", Shirt = Color3.fromRGB(40, 90, 60), Avatar = "Enclave2009", Label = "Enclave" })
		barista.Parent = B.model
		B:span(Vector3.new(-18, 8, D - 0.4), Vector3.new(4, 14, D), { Color = Color3.fromRGB(30, 34, 30), Name = "MenuBoard" })
		B:sign(Vector3.new(-7, 11, D - 0.45), Vector3.new(21, 5.6, 0.05), "Espresso  2.20      Latte  2.90\nHot Chocolate  2.70    Croissant  1.80\nTung Tung Tea  2.50", {
			Color = Color3.fromRGB(30, 34, 30),
			Face = Enum.NormalId.Front,
			Font = Enum.Font.Cartoon,
			TextColor = Color3.fromRGB(240, 236, 220),
			Parent = "Decor",
			CanCollide = false,
			LightInfluence = 1,
		})
		B:span(Vector3.new(-18, 14.5, D - 0.6), Vector3.new(4, 15, D), { Color = DARKWOOD, Name = "MenuFrame" })
		-- shelves of cups and bags of coffee beans
		B:span(Vector3.new(6, 8, D - 1.2), Vector3.new(16, 8.3, D), { Color = DARKWOOD, Name = "Shelf" })
		for k = 0, 5 do
			B:cyl(Vector3.new(7 + k * 1.6, 8.85, D - 0.6), 1, 0.9, "Y", { Color = ({ C.white, Color3.fromRGB(200, 90, 60), C.white, Color3.fromRGB(60, 110, 160), C.white, Color3.fromRGB(230, 190, 60) })[k + 1], Parent = "Decor", CanCollide = false, Name = "CupOnShelf" })
		end
		-- tables, chairs, a sofa corner and a rug
		-- tables in a tidy grid, centred on the rug
		B:part(Vector3.new(2, 0.03, 28), Vector3.new(38, 0.06, 26), { Color = Color3.fromRGB(150, 60, 50), Material = Enum.Material.Fabric, Parent = "Decor", CanCollide = false, Name = "Rug" })
		B:part(Vector3.new(2, 0.05, 28), Vector3.new(36, 0.06, 24), { Color = Color3.fromRGB(176, 120, 70), Material = Enum.Material.Fabric, Parent = "Decor", CanCollide = false, Name = "RugBorder" })
		B:part(Vector3.new(2, 0.07, 28), Vector3.new(34.6, 0.06, 22.6), { Color = Color3.fromRGB(150, 60, 50), Material = Enum.Material.Fabric, Parent = "Decor", CanCollide = false, Name = "RugCentre" })
		for _, pos in { Vector3.new(-10, 0, 20), Vector3.new(2, 0, 20), Vector3.new(14, 0, 20), Vector3.new(-10, 0, 36), Vector3.new(2, 0, 36), Vector3.new(14, 0, 36) } do
			cafeTable(B, pos)
			chair(B, pos + Vector3.new(-3.2, 0, 0), -90)
			chair(B, pos + Vector3.new(3.2, 0, 0), 90)
		end
		-- sofa corner
		local SOFA = Color3.fromRGB(70, 90, 130)
		B:span(Vector3.new(-W / 2, 0, 8), Vector3.new(-W / 2 + 4, 1.4, 20), { Color = SOFA:Lerp(Color3.new(0, 0, 0), 0.3), Material = Enum.Material.Fabric, Name = "SofaBase" })
		B:span(Vector3.new(-W / 2, 0, 8), Vector3.new(-W / 2 + 1.4, 4.6, 20), { Color = SOFA, Material = Enum.Material.Fabric, Name = "SofaBack" })
		for _, z in { 7.4, 20.6 } do
			B:span(Vector3.new(-W / 2, 0, z - 0.6), Vector3.new(-W / 2 + 4.2, 3, z + 0.6), { Color = SOFA, Material = Enum.Material.Fabric, Name = "SofaArm" })
		end
		-- three cushions you can actually sit on (facing into the room)
		for k = 0, 2 do
			local seat = Instance.new("Seat")
			seat.Name = "SofaSeat"
			seat.Anchored = true
			seat.Size = Vector3.new(3.8, 0.8, 2.6)
			seat.CFrame = CFrame.new(B:w(Vector3.new(-W / 2 + 2.6, 1.8, 10 + k * 4))) * CFrame.Angles(0, math.rad(-90), 0)
			seat.Color = SOFA
			seat.Material = Enum.Material.Fabric
			seat.TopSurface = Enum.SurfaceType.Smooth
			seat.Parent = B:folder("Decor")
		end
		B:span(Vector3.new(-W / 2 + 7, 0, 11), Vector3.new(-W / 2 + 11, 1.8, 17), { Color = WOOD, Material = Enum.Material.Wood, Name = "CoffeeTable" })
		-- bookshelf
		B:span(Vector3.new(-W / 2, 0, 30), Vector3.new(-W / 2 + 2, 10, 42), { Color = DARKWOOD, Material = Enum.Material.Wood, Name = "Bookshelf" })
		local rng = Random.new(10)
		for y = 1.2, 8, 2.4 do
			local z = 30.6
			while z < 41.2 do
				local w = rng:NextNumber(0.4, 0.8)
				B:part(Vector3.new(-W / 2 + 2.15, y + 0.8, z + w / 2), Vector3.new(0.3, rng:NextNumber(1.2, 1.9), w), { Color = Color3.fromHSV(rng:NextNumber(), 0.5, 0.6), Parent = "Decor", CanCollide = false, Name = "Book" })
				z += w + 0.05
			end
		end
		-- wall sconces
		for z = 12, 52, 20 do
			B:lamp(Vector3.new(-W / 2 + 0.6, 9, z), Vector3.new(0.6, 1, 1), { Color = WARM, Glow = true, Range = 18, Brightness = 1 })
		end
		Decor.plant(B, Vector3.new(-24, 0, D - 4), 1.1)
		Decor.plant(B, Vector3.new(24, 0, 6), 1.1)
		Decor.plant(B, Vector3.new(-24, 0, 4), 1.1)
	end,
	Run = function(ctx)
		local level = ctx.level
		-- people walking past the windows
		local passers = {}
		for _, npc in level.Passers:GetChildren() do
			table.insert(passers, { m = npc, base = npc:GetPivot(), dir = npc:GetAttribute("Dir"), off = math.random() * 50 })
		end
		local t0 = os.clock()
		ctx:heartbeat(function()
			local t = os.clock() - t0
			for _, p in passers do
				local z = ((p.off + t * 6) % 52)
				local zz = p.dir > 0 and (ctx.origin.Z + 4 + z) or (ctx.origin.Z + 56 - z)
				p.m:PivotTo(CFrame.new(p.base.Position.X, p.base.Position.Y, zz) * p.base.Rotation)
			end
		end)
		-- Enclave the barista works the counter, really handling things: takes a
		-- cup to the machine and fills it (steam, hiss), sets it out in an empty
		-- spot on the counter (or drinks it himself if none are empty), rings
		-- the register (drawer slides out), and serves a pastry from the case
		-- onto the plate. Things in his hand follow his right hand.
		local machine = level.Structure:FindFirstChild("CoffeeMachine")
		local drawer = level:FindFirstChild("RegisterDrawer")
		local drawerHome = drawer and drawer.CFrame
		local plate = level.Decor:FindFirstChild("ServePlate")
		local pastries = {}
		for _, p in level.Decor:GetChildren() do
			if p.Name == "Pastry" then
				table.insert(pastries, { part = p, home = p.CFrame })
			end
		end
		local function barista()
			return level:FindFirstChild("Barista")
		end
		local held -- the part in his hand
		local holdTrack
		local function hand(b)
			return b:FindFirstChild("RightHand") or b:FindFirstChild("Right Arm")
		end
		ctx:heartbeat(function()
			local b = barista()
			local h = b and hand(b)
			if held and h then
				local down = h.Name == "RightHand" and 0.35 or 1.1
				held.CFrame = CFrame.new((h.CFrame * CFrame.new(0, -down, -0.25)).Position) * b:GetPivot().Rotation
			end
		end)
		local function setHold(b, part)
			held = part
			-- arm out while carrying (Action priority, so the walk keeps the legs)
			if part and not holdTrack then
				local id = b:GetAttribute("Anim_toolnone")
				local hum = b:FindFirstChildOfClass("Humanoid")
				local animator = hum and hum:FindFirstChildOfClass("Animator")
				if id and animator then
					local a = Instance.new("Animation")
					a.AnimationId = id
					local ok, t = pcall(animator.LoadAnimation, animator, a)
					if ok then
						holdTrack = t
						t.Priority = Enum.AnimationPriority.Action
						t.Looped = true
						t:Play(0.2)
					end
				end
			elseif not part and holdTrack then
				holdTrack:Stop(0.2)
				holdTrack = nil
			end
		end
		local function newCup()
			local cup = Instance.new("Part")
			cup.Name = "HeldCup"
			cup.Shape = Enum.PartType.Cylinder
			cup.Size = Vector3.new(1, 0.9, 0.9)
			cup.Color = C.white
			cup.Anchored = true
			cup.CanCollide = false
			cup.CanQuery = false
			cup.CanTouch = false
			cup.Parent = level
			return cup
		end
		local function walkTo(b, x)
			local from = b:GetPivot()
			local target = Vector3.new(ctx.origin.X + x, from.Position.Y, from.Position.Z)
			local dist = (target - from.Position).Magnitude
			if dist > 0.2 then
				local walkRot = CFrame.lookAt(Vector3.zero, (target - from.Position).Unit).Rotation
				Kit.playAnim(b, "walk", 0.8)
				local t, dur = 0, dist / 6
				while t < dur and not ctx.ended and barista() == b do
					t += task.wait()
					b:PivotTo(CFrame.new(from.Position:Lerp(target, math.min(t / dur, 1))) * walkRot)
				end
			end
			-- face the counter (-Z) to work
			b:PivotTo(CFrame.new(target))
			Kit.playAnim(b, "idle")
		end
		local function emptyCup()
			for _, cup in level.Cups:GetChildren() do
				local prompt = cup:FindFirstChildOfClass("ProximityPrompt")
				if prompt and not prompt.Enabled then
					return cup, prompt
				end
			end
			return nil
		end
		local served -- the pastry sitting on the plate
		ctx:spawn(function()
			while not ctx.ended do
				local b = barista()
				if not b then
					task.wait(0.5)
					continue
				end
				-- 1: the coffee machine
				walkTo(b, -13.5)
				local cup = newCup()
				setHold(b, cup)
				task.wait(0.5)
				if machine then
					local puff = Instance.new("ParticleEmitter")
					puff.Texture = "rbxasset://textures/particles/smoke_main.dds"
					puff.Rate = 12
					puff.Speed = NumberRange.new(2, 3)
					puff.Lifetime = NumberRange.new(0.8, 1.2)
					puff.Size = NumberSequence.new(0.6, 1.6)
					puff.Transparency = NumberSequence.new(0.4, 1)
					puff.EmissionDirection = Enum.NormalId.Top
					puff.Parent = machine
					Audio.play(machine, "steam", 0.3, 40)
					task.wait(2.5)
					puff:Destroy()
				end
				cup.Color = Color3.fromRGB(110, 70, 40) -- full
				task.wait(0.4)
				-- 2: set it out where a cup's been drunk, or drink it himself
				walkTo(b, -6)
				local slot, prompt = emptyCup()
				task.wait(0.4)
				setHold(b, nil)
				cup:Destroy()
				if slot then
					slot.Transparency = 0
					slot.Coffee.Transparency = 0
					prompt.Enabled = true
					Audio.play(slot, "pickup", 0.25, 30)
				else
					Kit.playAnim(b, "cheer")
					Audio.play(b:GetPivot().Position, "pickup", 0.2, 30)
				end
				task.wait(1)
				-- 3: ring something up
				walkTo(b, -4.5)
				Kit.playAnim(b, "point")
				Audio.play(b:GetPivot().Position, "ding", 0.25, 30)
				if drawer then
					for i = 1, 8 do
						drawer.CFrame = drawerHome * CFrame.new(0, 0, 0.9 * i / 8)
						task.wait(1 / 30)
					end
					task.wait(0.8)
					for i = 8, 0, -1 do
						drawer.CFrame = drawerHome * CFrame.new(0, 0, 0.9 * i / 8)
						task.wait(1 / 30)
					end
				end
				Kit.playAnim(b, "idle")
				task.wait(0.6)
				-- 4: a pastry from the case onto the plate (the last one goes back)
				if served then
					served.part.CFrame = served.home
					served = nil
				end
				walkTo(b, 7)
				local p = pastries[math.random(1, math.max(1, #pastries))]
				if p and plate then
					task.wait(0.4)
					setHold(b, p.part)
					task.wait(0.4)
					walkTo(b, 1)
					task.wait(0.3)
					setHold(b, nil)
					p.part.CFrame = CFrame.new(plate.Position + Vector3.new(0, 0.35, 0))
					served = p
				end
				task.wait(1.5)
			end
		end)
		ctx:onCleanup(function()
			if held and held.Name == "HeldCup" then
				held:Destroy()
			end
			held = nil
		end)
		-- espresso: drink it for 10 seconds of speed; the barista refills the cup
		local boosted = {}
		for _, cup in level.Cups:GetChildren() do
			local prompt = cup:FindFirstChildOfClass("ProximityPrompt")
			ctx:connect(prompt.Triggered, function(player)
				local root, hum = Kit.rootOf(player)
				if not hum or boosted[player] then
					return
				end
				boosted[player] = true
				prompt.Enabled = false
				cup.Transparency = 1
				cup.Coffee.Transparency = 1
				Audio.play(cup, "pickup", 0.6)
				Kit.notify(player, "Espresso! You're faster for " .. BOOST_TIME .. " seconds.")
				local old = hum.WalkSpeed
				hum.WalkSpeed = 26
				local trail = Instance.new("ParticleEmitter")
				trail.Name = "EspressoSteam"
				trail.Texture = "rbxasset://textures/particles/smoke_main.dds"
				trail.Color = ColorSequence.new(Color3.fromRGB(230, 200, 160))
				trail.Rate = 20
				trail.Lifetime = NumberRange.new(0.5, 0.8)
				trail.Speed = NumberRange.new(0.5, 1)
				trail.Size = NumberSequence.new(0.6, 1.4)
				trail.Transparency = NumberSequence.new(0.3, 1)
				trail.Parent = root
				task.delay(BOOST_TIME, function()
					if hum.Parent then
						hum.WalkSpeed = old
					end
					trail:Destroy()
					boosted[player] = nil
					Kit.notify(player, "The espresso wore off.")
				end)
				-- the barista makes a fresh one on their next round (see above)
			end)
			ctx:onCleanup(function()
				for p in boosted do
					local _, hum = Kit.rootOf(p)
					if hum then
						hum.WalkSpeed = 16
					end
				end
			end)
		end
	end,
}
