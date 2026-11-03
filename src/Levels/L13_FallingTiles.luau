-- Crumbling Platform (medium, survive): an old platform floor over a deep
-- void. Every tile you step on turns amber, red, shakes and drops. There's a
-- second floor below - after that, the drop. Keep moving and survive.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 56, 62
local TILE = 4.6
local LAYERS = {
	{ y = 0, top = Color3.fromRGB(226, 220, 204), base = Color3.fromRGB(150, 146, 136) },
	{ y = -18, top = Color3.fromRGB(110, 170, 210), base = Color3.fromRGB(60, 100, 130) },
}

return {
	Order = 13,
	Name = "Crumbling Platform",
	Mode = "survive",
	TimeLimit = 55,
	KillY = -46,
	Ambience = { { "eerie", 0.3 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 22,
			floor = false,
			bottom = -60,
			wallColor = Color3.fromRGB(214, 206, 188),
			lowerColor = Color3.fromRGB(150, 60, 50),
			trim = Color3.fromRGB(240, 190, 40),
			brightness = 1.3,
			exit = false,
		})
		-- tiled floors
		for li, layer in LAYERS do
			local folder = "Layer" .. li
			local x = -W / 2 + TILE / 2 + 0.4
			while x < W / 2 - TILE / 2 do
				local z = 1 + TILE / 2 + 0.2
				while z < D - TILE / 2 do
					local tile = B:part(Vector3.new(x, layer.y - 0.35, z), Vector3.new(TILE - 0.3, 0.7, TILE - 0.3), {
						Name = "Tile",
						Color = layer.top,
						Material = Enum.Material.Marble,
						Parent = folder,
					})
					local base = B:part(Vector3.new(x, layer.y - 1.0, z), Vector3.new(TILE, 0.6, TILE), {
						Name = "Grout",
						Color = layer.base,
						Material = Enum.Material.Concrete,
						Parent = tile,
					})
					z += TILE
				end
				x += TILE
			end
		end
		-- far below: a lake of lava (same build as the Boiler Room's), with a
		-- drifting crust, glowing cracks and embers rising off it
		local LAVA_Y = -41
		B:part(Vector3.new(0, LAVA_Y - 1, D / 2), Vector3.new(W, 2, D), {
			Name = "Lava",
			Color = Color3.fromRGB(255, 100, 20),
			Material = Enum.Material.Neon,
			Hazard = true,
			Parent = B.model,
		})
		B:part(Vector3.new(0, LAVA_Y + 0.05, D / 2), Vector3.new(W, 0.1, D), { Name = "Crust", Color = Color3.fromRGB(200, 70, 20), Material = Enum.Material.CrackedLava, Transparency = 0.45, CanCollide = false, CastShadow = false, Parent = "Decor" })
		-- rocky banks along the walls, so the lava meets something solid
		for _, side in { -1, 1 } do
			B:span(Vector3.new(side * W / 2 - side * 2.5, LAVA_Y - 2, 1), Vector3.new(side * W / 2, LAVA_Y + 1.2, D), { Name = "Bank", Color = Color3.fromRGB(46, 40, 38), Material = Enum.Material.Basalt })
		end
		local rng = Random.new(13)
		for _ = 1, 9 do
			local x, z = rng:NextNumber(-W / 2 + 6, W / 2 - 6), rng:NextNumber(8, D - 8)
			local rock = B:part(Vector3.new(x, LAVA_Y + 0.15, z), Vector3.new(rng:NextNumber(3, 6), 0.9, rng:NextNumber(3, 6)), { Name = "CrustRock", Color = Color3.fromRGB(52, 44, 40), Material = Enum.Material.Basalt, CanCollide = false, Parent = "Decor", Rot = Vector3.new(0, rng:NextNumber(0, 90), 0) })
			rock.CastShadow = false
		end
		for _, p in { Vector3.new(-14, 0, 18), Vector3.new(12, 0, 44), Vector3.new(0, 0, 31) } do
			local glow = B:part(Vector3.new(p.X, LAVA_Y + 0.2, p.Z), Vector3.new(2, 0.1, 2), { Name = "LavaGlow", Transparency = 1, CanCollide = false, Parent = "Decor", Light = { Range = 60, Brightness = 1.4, Color = Color3.fromRGB(255, 110, 40) } })
			local embers = Instance.new("ParticleEmitter")
			embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			embers.Color = ColorSequence.new(Color3.fromRGB(255, 160, 60))
			embers.LightEmission = 1
			embers.Rate = 8
			embers.Speed = NumberRange.new(3, 6)
			embers.Lifetime = NumberRange.new(2, 4)
			embers.Size = NumberSequence.new(0.35, 0.05)
			embers.SpreadAngle = Vector2.new(25, 25)
			embers.EmissionDirection = Enum.NormalId.Top
			embers.Parent = glow
			glow.Size = Vector3.new(18, 0.1, 18)
		end
		-- lights under the top floor so the lower one is readable
		for _, z in { 14, 32, 50 } do
			for _, x in { -W / 2 + 0.6, W / 2 - 0.6 } do
				B:lamp(Vector3.new(x, -9, z), Vector3.new(0.4, 1.2, 4), { Color = Color3.fromRGB(180, 220, 255), Range = 30, Brightness = 0.6 })
			end
		end
		-- station dressing on the walls
		for _, z in { 18, 44 } do
			Decor.advert(B, Vector3.new(-W / 2, 8, z), "+X")
			Decor.advert(B, Vector3.new(W / 2, 8, z), "-X")
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local tiles = {}
		for _, name in { "Layer1", "Layer2" } do
			for _, t in level[name]:GetChildren() do
				table.insert(tiles, t)
			end
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = tiles
		local doomed = {}
		local function crumble(t)
			doomed[t] = true
			local home = t.CFrame
			t.Color = Color3.fromRGB(240, 170, 40)
			task.wait(0.25)
			t.Color = Color3.fromRGB(220, 60, 40)
			Audio.play(t, "iceCrack", 0.35, 60)
			for k = 1, 4 do
				t.CFrame = home * CFrame.new(math.random(-10, 10) / 100, 0, math.random(-10, 10) / 100)
				task.wait(0.05)
			end
			t.CFrame = home
			-- drop it (tile and grout together)
			for _, p in { t, t:FindFirstChild("Grout") } do
				if p then
					p.CanCollide = false
					p.Anchored = false
				end
			end
			task.wait(3)
			t:Destroy()
		end
		ctx.def.OnPlayerTick = function(_, _, rootPart)
			local hit = workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0), params)
			local t = hit and hit.Instance
			if t and t.Name == "Grout" then
				t = t.Parent
			end
			if t and not doomed[t] then
				task.spawn(crumble, t)
			end
		end
	end,
}
