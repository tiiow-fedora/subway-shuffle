-- Live Rails (medium, survive): the substation floor is made of conductor
-- plates. A plate that's about to go live crackles orange with sparks; then it
-- goes electric blue with arcs dancing over it - be anywhere else. Waves sweep
-- across rows and columns as well as random plates. Survive until the train.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 52, 58.4
local CELL = 5.6
local COLS, ROWS = 9, 10
local OX, OZ = -COLS * CELL / 2, 1.4
local IDLE = Color3.fromRGB(96, 100, 108)
local WARN = Color3.fromRGB(255, 150, 30)
local LIVE = Color3.fromRGB(90, 200, 255)

return {
	Order = 12,
	Name = "Live Rails",
	Mode = "survive",
	TimeLimit = 60,
	Ambience = { { "electricBuzz", 0.06 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 20,
			floorColor = Color3.fromRGB(40, 40, 44),
			wallColor = Color3.fromRGB(190, 196, 200),
			lowerColor = Color3.fromRGB(40, 44, 52),
			trim = Color3.fromRGB(240, 190, 40),
			brightness = 1.2,
			exit = false,
		})
		-- conductor plates on insulator feet
		for c = 1, COLS do
			for r = 1, ROWS do
				local x, z = OX + (c - 0.5) * CELL, OZ + (r - 0.5) * CELL
				local plate = B:part(Vector3.new(x, 0.35, z), Vector3.new(CELL - 0.5, 0.3, CELL - 0.5), {
					Name = "Plate",
					Color = IDLE,
					Material = Enum.Material.DiamondPlate,
					Parent = "Plates",
					Attr = { Col = c, Row = r },
				})
				-- arcs: zig-zag bolts above the plate, hidden until it's live
				for k = 1, 3 do
					local arc = B:part(Vector3.new(x + (k - 2) * 1.4, 1.4, z), Vector3.new(0.15, 2, 0.15), {
						Name = "Arc",
						Color = LIVE,
						Material = Enum.Material.Neon,
						Transparency = 1,
						Rot = Vector3.new(0, 0, (k % 2 == 0) and 25 or -25),
						CanCollide = false,
						CastShadow = false,
						Parent = plate,
					})
				end
				local sparks = Instance.new("ParticleEmitter")
				sparks.Name = "Sparks"
				sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				sparks.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80))
				sparks.Rate = 0
				sparks.Speed = NumberRange.new(4, 8)
				sparks.Lifetime = NumberRange.new(0.2, 0.4)
				sparks.SpreadAngle = Vector2.new(60, 60)
				sparks.EmissionDirection = Enum.NormalId.Top
				sparks.Size = NumberSequence.new(0.3, 0)
				sparks.Parent = plate
				local glow = Instance.new("PointLight")
				glow.Name = "Glow"
				glow.Range = 9
				glow.Brightness = 0
				glow.Color = LIVE
				glow.Parent = plate
			end
		end
		-- transformers, insulators and cable runs around the walls
		for _, z in { 14, 34, 54 } do
			for _, side in { -1, 1 } do
				local wx = side * (W / 2 - 0.6)
				B:span(Vector3.new(wx - 0.6, 2.5, z - 3), Vector3.new(wx + 0.6, 9, z + 3), { Color = Color3.fromRGB(70, 90, 80), Material = Enum.Material.Metal, Name = "Cabinet", CanCollide = false })
				for _, dz in { -1.6, 0, 1.6 } do
					B:cyl(Vector3.new(side * (W / 2 - 0.6), 10, z + dz), 2, 0.6, "Y", { Color = Color3.fromRGB(150, 90, 60), Material = Enum.Material.SmoothPlastic, Parent = "Decor", CanCollide = false, Name = "Insulator" })
				end
				B:part(Vector3.new(side * (W / 2 - 1.25), 7, z), Vector3.new(0.1, 0.6, 0.6), { Color = Color3.fromRGB(60, 255, 90), Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false, Name = "StatusLight" })
			end
		end
		for _, y in { 12, 13, 14 } do
			Decor.pipe(B, Vector3.new(-W / 2 + 0.6, y, 2), Vector3.new(-W / 2 + 0.6, y, D - 2), 0.4, y == 13 and Color3.fromRGB(180, 40, 30) or C.black)
		end
		-- hazard chevrons painted round the edge of the plate field
		for _, z in { OZ + ROWS * CELL + 0.4 } do
			for x = OX, OX + COLS * CELL - 2, 2 do
				B:part(Vector3.new(x + 0.5, 0.02, z), Vector3.new(1, 0.04, 0.8), { Color = C.yellow, Parent = "Decor", CanCollide = false })
			end
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local grid = {}
		local all = {}
		for _, p in level.Plates:GetChildren() do
			local c, r = p:GetAttribute("Col"), p:GetAttribute("Row")
			grid[c .. "," .. r] = p
			table.insert(all, p)
		end
		local busy = {}
		local function zap(p)
			if busy[p] then
				return
			end
			busy[p] = true
			-- warning: orange crackle
			p.Material = Enum.Material.Neon
			p.Sparks.Rate = 25
			for k = 1, 6 do
				p.Color = k % 2 == 0 and WARN or WARN:Lerp(IDLE, 0.5)
				task.wait(0.22)
			end
			if ctx.ended then
				return
			end
			-- live
			p.Color = LIVE
			p.Glow.Brightness = 3
			for _, a in p:GetChildren() do
				if a.Name == "Arc" then
					a.Transparency = 0
				end
			end
			ctx:setHazard(p, true)
			Audio.play(p, "spark", 0.35, 50)
			task.wait(1.6)
			ctx:setHazard(p, false)
			for _, a in p:GetChildren() do
				if a.Name == "Arc" then
					a.Transparency = 1
				end
			end
			p.Glow.Brightness = 0
			p.Sparks.Rate = 0
			p.Color = IDLE
			p.Material = Enum.Material.DiamondPlate
			busy[p] = nil
		end
		-- arcs flicker while live
		ctx:every(0.08, function()
			for p in busy do
				for _, a in p:GetChildren() do
					if a.Name == "Arc" and a.Transparency < 1 then
						a.Size = Vector3.new(0.15, 1.2 + math.random() * 1.6, 0.15)
					end
				end
			end
		end)
		ctx:waitForStart()
		task.wait(3)
		local wave = 0
		while not ctx.ended do
			local frac = math.clamp(ctx:elapsed() / ctx.timeLimit, 0, 1)
			wave += 1
			if wave % 4 == 0 then
				-- a whole row or column, with one gap to dodge into
				local alongRow = math.random() < 0.5
				local idx = alongRow and math.random(1, ROWS) or math.random(1, COLS)
				local gap = math.random(1, alongRow and COLS or ROWS)
				for k = 1, alongRow and COLS or ROWS do
					if k ~= gap then
						local p = alongRow and grid[k .. "," .. idx] or grid[idx .. "," .. k]
						task.spawn(zap, p)
					end
				end
			else
				for _ = 1, math.floor(4 + frac * 14) do
					task.spawn(zap, all[math.random(1, #all)])
				end
			end
			task.wait(1.6 - 0.5 * frac)
		end
	end,
}
