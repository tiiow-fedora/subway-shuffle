-- Sewer Slide: climb the old storm-overflow tunnel while barrels come rolling
-- out of the outfall pipe at the top. Duck behind the concrete blocks.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 32, 142
local BRICK = Color3.fromRGB(96, 92, 78)
local SLIME = Color3.fromRGB(90, 120, 50)
local PIPE_X, PIPE_Y, PIPE_R = 4, 36, 5

return {
	Order = 24,
	Name = "Sewer Slide",
	Mode = "escape",
	TimeLimit = 100,
	Ambience = { { "waterRush", 0.25 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 48,
			wallColor = BRICK,
			wallMat = Enum.Material.Brick,
			floorColor = Color3.fromRGB(64, 66, 56),
			lowerColor = Color3.fromRGB(56, 60, 44),
			lowerMat = Enum.Material.Slate,
			trim = SLIME,
			lampColor = Color3.fromRGB(210, 230, 170),
			brightness = 0.9,
			lampStep = 18,
			flicker = true,
			exit = { x = -10, y = 30 },
		})
		B:checkpoint(Vector3.new(0, 0.1, 5), Vector3.new(7, 0.2, 5))
		local segs = {
			{ a = Vector3.new(0, 0, 12), b = Vector3.new(0, 15, 62) },
			{ a = Vector3.new(0, 15, 72), b = Vector3.new(0, 30, 122) },
		}
		for i, s in ipairs(segs) do
			B:ramp(s.a, s.b, W, { Name = "Slope", Color = Color3.fromRGB(78, 80, 68), Material = Enum.Material.Slate, Thick = 2 })
			-- a shallow gutter of green water down the middle
			B:ramp(s.a + Vector3.new(0, 0.04, 0), s.b + Vector3.new(0, 0.04, 0), 3, { Color = SLIME, Material = Enum.Material.Glass, Transparency = 0.35, Parent = "Decor", CanCollide = false, Thick = 0.05, Name = "Gutter" })
			-- two staggered concrete blocks per slope to hide behind
			for k, t in ipairs({ 0.35, 0.72 }) do
				local p = s.a:Lerp(s.b, t)
				local x = ((k + i) % 2 == 0) and -8 or 8
				B:part(p + Vector3.new(x, 1.8, 0), Vector3.new(7, 3.4, 2), { Name = "Cover", Color = Color3.fromRGB(120, 118, 110), Material = Enum.Material.Concrete })
			end
		end
		B:span(Vector3.new(-W / 2, 0, 62), Vector3.new(W / 2, 15, 72), { Name = "Landing", Color = Color3.fromRGB(70, 72, 60), Material = Enum.Material.Concrete })
		B:checkpoint(Vector3.new(0, 15.1, 67), Vector3.new(8, 0.2, 5))
		B:span(Vector3.new(-W / 2, 0, 122), Vector3.new(W / 2, 30, D), { Name = "Top", Color = Color3.fromRGB(70, 72, 60), Material = Enum.Material.Concrete })
		-- the outfall pipe: a big concrete pipe mouth in the back wall
		B:cyl(Vector3.new(PIPE_X, PIPE_Y, D - 3), 6, PIPE_R * 2 + 2, "Z", { Name = "PipeRing", Color = Color3.fromRGB(110, 108, 100), Material = Enum.Material.Concrete, CanCollide = false })
		B:cyl(Vector3.new(PIPE_X, PIPE_Y, D - 6.08), 0.1, PIPE_R * 2 - 0.4, "Z", { Name = "PipeDark", Color = Color3.fromRGB(8, 10, 6), Parent = "Decor", CanCollide = false })
		for x = PIPE_X - 4, PIPE_X + 4, 2 do
			B:part(Vector3.new(x, PIPE_Y + 0.5, D - 6.3), Vector3.new(0.3, PIPE_R * 2 - 1, 0.3), { Color = C.rust, Material = Enum.Material.CorrodedMetal, Parent = "Decor", CanCollide = false, Name = "BrokenGrate" })
		end
		-- slime trickling out of the pipe
		B:part(Vector3.new(PIPE_X, 30.04, D - 10), Vector3.new(3, 0.05, 8), { Color = SLIME, Material = Enum.Material.Glass, Transparency = 0.3, Parent = "Decor", CanCollide = false })
		-- exit to the side of the outfall
		-- old pipes and cables along the walls
		Decor.pipe(B, Vector3.new(-W / 2 + 0.8, 8, 2), Vector3.new(-W / 2 + 0.8, 8, D - 2), 1.2, C.rust)
		Decor.pipe(B, Vector3.new(W / 2 - 0.8, 10, 2), Vector3.new(W / 2 - 0.8, 10, D - 2), 0.8, Color3.fromRGB(90, 90, 86))
		Decor.pipe(B, Vector3.new(W / 2 - 0.8, 34, 2), Vector3.new(W / 2 - 0.8, 34, D - 2), 1.4, Color3.fromRGB(70, 72, 66))
		for _, z in { 40, 96 } do
			Decor.vent(B, Vector3.new(-W / 2 + 0.1, 24, z), "+X", 4, 3)
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local barrels = {}
		local function spawnBarrel()
			-- an oil drum: steel body, rolled rims and a painted band
			local colors = { Color3.fromRGB(40, 90, 160), Color3.fromRGB(170, 40, 30), Color3.fromRGB(50, 120, 60), Color3.fromRGB(220, 160, 30) }
			local col = colors[math.random(1, #colors)]
			local b = Instance.new("Part")
			b.Name = "Drum"
			b.Shape = Enum.PartType.Cylinder
			b.Size = Vector3.new(3.4, 2.8, 2.8)
			b.Color = col
			b.Material = Enum.Material.Metal
			b.CFrame = CFrame.new(ctx:w(Vector3.new(PIPE_X + math.random(-2, 2), PIPE_Y - 2.6, D - 7)))
			-- low friction so it rolls instead of snagging
			b.CustomPhysicalProperties = PhysicalProperties.new(2.5, 0.15, 0.25, 1, 1)
			b:SetAttribute("Hazard", true)
			for _, dx in { -1.55, 0, 1.55 } do
				local ring = Instance.new("Part")
				ring.Name = "Rim"
				ring.Shape = Enum.PartType.Cylinder
				ring.Size = Vector3.new(dx == 0 and 0.5 or 0.25, 2.95, 2.95)
				ring.Color = dx == 0 and Color3.fromRGB(240, 240, 240) or col:Lerp(Color3.new(0, 0, 0), 0.35)
				ring.Material = Enum.Material.Metal
				ring.CanCollide = false
				ring.Massless = true
				ring.CFrame = b.CFrame * CFrame.new(dx, 0, 0)
				ring:SetAttribute("Hazard", true)
				local w = Instance.new("WeldConstraint")
				w.Part0 = b
				w.Part1 = ring
				w.Parent = ring
				ring.Parent = b
			end
			b.Parent = level
			Audio.play(b.Position, "drum", 0.6, 100)
			b.AssemblyLinearVelocity = Vector3.new(math.random(-4, 4), 0, -20)
			b.AssemblyAngularVelocity = Vector3.new(-8, 0, 0)
			barrels[b] = os.clock()
		end
		ctx:every(0.25, function()
			for b, t in barrels do
				local stuck = b.Parent and b.AssemblyLinearVelocity.Magnitude < 1 and os.clock() - t > 3
				if not b.Parent or stuck or os.clock() - t > 14 or b.Position.Y < ctx.origin.Y - 10 or b.Position.Z < ctx.origin.Z + 6 then
					barrels[b] = nil
					b:Destroy()
				end
			end
		end)
		ctx:waitForStart()
		while not ctx.ended do
			local frac = math.clamp(ctx:elapsed() / ctx.timeLimit, 0, 1)
			spawnBarrel()
			task.wait(1.5 - 0.6 * frac)
		end
	end,
}
