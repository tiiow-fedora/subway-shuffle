-- Frozen Platform (medium, survive): you step out onto a frozen lake and get
-- put on the big ice floe in the middle. Slabs of ice crack (they flash white)
-- and sink - random ones, at random moments, faster as time goes on, so there's
-- no pattern to learn - and giant snowballs roll across the floe. Stay out of
-- the water until the train comes back.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Kit = require(root.LevelKit)
local Audio = require(root.Audio)
local C = BuildLib.C

local CENTER = Vector3.new(0, 0, 70)
local RINGS = { 6, 11, 16, 21, 26 } -- outer radius of the centre disc and each ring
local ICE = Color3.fromRGB(190, 225, 245)
local SNOW = Color3.fromRGB(240, 244, 248)

local function pine(B, pos, s)
	B:cyl(pos + Vector3.new(0, 2 * s, 0), 4 * s, 1.2 * s, "Y", { Color = Color3.fromRGB(100, 70, 45), Material = Enum.Material.Wood, Parent = "Scenery", Name = "Trunk" })
	for k = 0, 3 do
		local w = (7 - k * 1.5) * s
		B:part(pos + Vector3.new(0, (4 + k * 2.4) * s, 0), Vector3.new(w, 2.4 * s, w), { Color = k == 3 and SNOW or Color3.fromRGB(50, 100, 70):Lerp(SNOW, 0.25), Material = Enum.Material.Grass, Parent = "Scenery", Name = "Needles", Rot = Vector3.new(0, k * 25, 0) })
	end
end

return {
	Order = 19,
	Name = "Frozen Platform",
	Mode = "survive",
	TimeLimit = 70,
	KillY = -4,
	Ambience = { { "windLoop", 0.07 } },
	Lighting = { ClockTime = 12, FogStart = 60, FogEnd = 360, FogColor = Color3.fromRGB(210, 220, 232) },
	Build = function(B)
		B.model:SetAttribute("Outdoor", true) -- open sky: outdoor base lighting
		-- the station building behind you and the snowy shore
		B:wallZ(0, 1, -150, 150, -10, 22, { { -B.DOOR_W / 2, B.DOOR_W / 2, -1, B.DOOR_H } }, { Color = Color3.fromRGB(150, 86, 66), Material = Enum.Material.Brick, Name = "StationWall" })
		B:span(Vector3.new(-150, 22, -6), Vector3.new(150, 23, 1.6), { Color = SNOW, Material = Enum.Material.Snow, Name = "SnowyEaves" })
		B:doorFrame(0, 0, 1, 1, Color3.fromRGB(200, 196, 186))
		B:span(Vector3.new(-150, -10, 1), Vector3.new(150, 0, 30), { Color = SNOW, Material = Enum.Material.Snow, Name = "Shore" })
		B:span(Vector3.new(-150, -10, 110), Vector3.new(150, 0, 220), { Color = SNOW, Material = Enum.Material.Snow, Name = "FarShore" })
		for _, spec in { { -150, -40 }, { 40, 150 } } do
			B:span(Vector3.new(spec[1], -10, 30), Vector3.new(spec[2], 0, 110), { Color = SNOW, Material = Enum.Material.Snow, Name = "SideShore" })
		end
		-- the lake
		B:span(Vector3.new(-40, -8, 30), Vector3.new(40, -2.5, 110), { Name = "Lake", Color = Color3.fromRGB(34, 66, 86), Material = Enum.Material.SmoothPlastic })
		B:span(Vector3.new(-40, -2.6, 30), Vector3.new(40, -2.5, 110), { Name = "Water", Color = Color3.fromRGB(52, 92, 112), Material = Enum.Material.SmoothPlastic, Transparency = 0.35, CanCollide = false, Deadly = true })
		-- the ice floe: a centre disc and rings of slabs
		local seg = 14
		for ri, outer in RINGS do
			local inner = ri == 1 and 0 or RINGS[ri - 1]
			if ri == 1 then
				B:cyl(CENTER + Vector3.new(0, -0.6, 0), 1.2, outer * 2, "Y", { Name = "Disc", Color = ICE, Material = Enum.Material.Ice, Parent = "Ring1" })
			else
				local mid = (inner + outer) / 2
				local width = outer - inner - 0.3
				local arc = 2 * math.pi * outer / seg + 0.6
				for k = 0, seg - 1 do
					local a = (k + 0.5) / seg * math.pi * 2
					-- neighbouring slabs overlap (so the outer edge has no gaps);
					-- every other one sits a hair lower so their tops don't Z-fight
					local pos = CENTER + Vector3.new(math.cos(a) * mid, -0.6 - (k % 2) * 0.05, math.sin(a) * mid)
					B:part(pos, Vector3.new(width, 1.2, arc), {
						Name = "Slab",
						Color = ICE,
						Material = Enum.Material.Ice,
						Rot = Vector3.new(0, -math.deg(a), 0),
						Parent = "Ring" .. ri,
					})
				end
			end
		end
		-- pine forest all round
		local rng = Random.new(19)
		for _ = 1, 60 do
			local x = rng:NextNumber(-120, 120)
			local z = rng:NextNumber(10, 200)
			if math.abs(x) > 46 or z > 116 or z < 24 then
				if not (math.abs(x) < 10 and z < 24) then
					pine(B, Vector3.new(x, 0, z), rng:NextNumber(1, 1.6))
				end
			end
		end
		-- falling snow
		local cloud = B:part(CENTER + Vector3.new(0, 40, 0), Vector3.new(120, 1, 120), { Name = "SnowCloud", Transparency = 1, CanCollide = false, Parent = "Decor" })
		local snow = Instance.new("ParticleEmitter")
		snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
		snow.EmissionDirection = Enum.NormalId.Bottom
		snow.Rate = 120
		snow.Speed = NumberRange.new(6, 9)
		snow.Lifetime = NumberRange.new(6, 8)
		snow.Size = NumberSequence.new(0.35)
		snow.Parent = cloud
		-- invisible bounds
		local inv = { Transparency = 1, CastShadow = false, Name = "Bounds" }
		for _, b in { { -48, -47, 1, 120 }, { 47, 48, 1, 120 } } do
			B:span(Vector3.new(b[1], -10, b[3]), Vector3.new(b[2], 60, b[4]), inv)
		end
		B:span(Vector3.new(-48, -10, 119), Vector3.new(48, 60, 120), inv)
	end,
	Run = function(ctx)
		local level = ctx.level
		local center = ctx:w(CENTER)
		-- step out of the door and you're taken out onto the floe
		local placed = {}
		ctx.def.OnEnter = function(_, player)
			if placed[player] then
				return
			end
			placed[player] = true
			Kit.notify(player, "__fade")
			task.wait(0.3)
			local a = math.random() * math.pi * 2
			local spot = center + Vector3.new(math.cos(a) * 12, 3.5, math.sin(a) * 12)
			if player.Character then
				player.Character:PivotTo(CFrame.lookAt(spot, center + Vector3.new(0, 3.5, 0)))
			end
			Kit.notify(player, "You're on thin ice!")
		end
		-- one slab: flashes white and cracks, then sinks
		local function sinkSlab(p)
			local home = p.CFrame
			Audio.play(p, "iceCrack", 0.5, 80)
			for k = 1, 8 do
				p.Color = k % 2 == 0 and SNOW or ICE:Lerp(SNOW, 0.6)
				p.CFrame = home * CFrame.new(math.random(-6, 6) / 100, 0, math.random(-6, 6) / 100)
				task.wait(0.22)
			end
			p.CFrame = home
			Audio.play(p, "splash", 0.45, 80)
			p.CanCollide = false
			for k = 1, 30 do
				p.CFrame = home - Vector3.new(0, k * 0.25, 0)
				p.Transparency = k / 30
				task.wait(1 / 30)
			end
			p:Destroy()
		end
		local slabs = {}
		for ri = 2, #RINGS do
			local ring = level:FindFirstChild("Ring" .. ri)
			for _, p in ring and ring:GetChildren() or {} do
				table.insert(slabs, p)
			end
		end
		local function snowball(radius)
			local a = math.random() * math.pi * 2
			local from = center + Vector3.new(math.cos(a) * radius, 4, math.sin(a) * radius)
			local ball = Instance.new("Part")
			ball.Name = "Snowball"
			ball.Shape = Enum.PartType.Ball
			ball.Size = Vector3.new(6, 6, 6)
			ball.Color = SNOW
			ball.Material = Enum.Material.Snow
			ball.CFrame = CFrame.new(from)
			ball.CustomPhysicalProperties = PhysicalProperties.new(3, 0.3, 0.3)
			ball.Parent = level
			local dir = (center - from) * Vector3.new(1, 0, 1)
			ball.AssemblyLinearVelocity = dir.Unit * 24 + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
			task.delay(8, function()
				if ball.Parent then
					ball:Destroy()
				end
			end)
		end
		ctx:waitForStart()
		task.wait(6)
		-- random slabs at random moments, more often as time runs out; the
		-- centre disc never goes and a dozen slabs are always left
		local t0 = os.clock()
		local lastBall = 0
		while not ctx.ended do
			local frac = math.clamp((os.clock() - t0) / (ctx.timeLimit - 6), 0, 1)
			task.wait((2.4 - 1.5 * frac) * (0.6 + math.random() * 0.8))
			if #slabs > 12 then
				for _ = 1, (math.random() < 0.3 + frac * 0.4) and 2 or 1 do
					if #slabs > 12 then
						local p = table.remove(slabs, math.random(1, #slabs))
						task.spawn(sinkSlab, p)
					end
				end
			end
			if os.clock() - lastBall > 3.5 + math.random() * 2 then
				lastBall = os.clock()
				snowball(RINGS[#RINGS] - 3)
			end
		end
	end,
}
