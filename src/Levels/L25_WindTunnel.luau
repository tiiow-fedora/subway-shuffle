-- Wind Tunnel (medium): narrow maintenance beams across the ventilation hall,
-- with huge turbines in the walls that keep kicking on. The lamp on each
-- turbine goes amber, then red when it's blowing - lean into the wind (walk
-- against it) or get blown off the beam.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Kit = require(root.LevelKit)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 56, 152
local KILL = -14
-- turbines: z, side (-1 = left wall blowing toward +X), phase
local FANS = {
	{ z = 24, side = -1, phase = 0 },
	{ z = 46, side = 1, phase = 2 },
	{ z = 78, side = -1, phase = 1 },
	{ z = 100, side = 1, phase = 3 },
	{ z = 124, side = -1, phase = 0.5 },
}
local ON, OFF = 2.6, 3.4
local FORCE = 130 -- sideways acceleration while in the wind
local BEAM = Color3.fromRGB(230, 180, 40)

return {
	Order = 25,
	Name = "Wind Tunnel",
	Mode = "escape",
	TimeLimit = 120,
	KillY = KILL,
	Ambience = { { "fan", 0.35 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 34,
			floor = false,
			bottom = -40,
			wallColor = Color3.fromRGB(96, 100, 108),
			wallMat = Enum.Material.Concrete,
			lowerColor = Color3.fromRGB(56, 60, 68),
			trim = Color3.fromRGB(60, 200, 255),
			trimNeon = true,
			brightness = 0.9,
			exit = { x = 0, y = 0 },
		})
		local beams = {} -- the narrow beams, for the chevrons and trim
		local function slab(x0, z0, x1, z1, props)
			props = props or {}
			if props.Name == "Beam" then
				table.insert(beams, { x0 = x0, z0 = z0, x1 = x1, z1 = z1 })
				-- neon edges along both sides of the beam (the hall's trim colour)
				if z1 - z0 > x1 - x0 then
					for _, x in { x0 + 0.08, x1 - 0.08 } do
						B:part(Vector3.new(x, 0.03, (z0 + z1) / 2), Vector3.new(0.16, 0.06, z1 - z0), { Color = Color3.fromRGB(60, 200, 255), Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false, CastShadow = false, Name = "BeamTrim" })
					end
				end
			end
			props.Thick = 2
			props.Color = props.Color or Color3.fromRGB(80, 84, 92)
			props.Material = props.Material or Enum.Material.DiamondPlate
			props.Name = props.Name or "Platform"
			return B:floor(x0, z0, x1, z1, 0, props)
		end
		slab(-W / 2, 1, W / 2, 10)
		B:checkpoint(Vector3.new(0, 0.1, 5), Vector3.new(7, 0.2, 4))
		-- beams and islands
		slab(-1.6, 10, 1.6, 36, { Color = BEAM, Name = "Beam" })
		slab(-7, 36, 7, 42)
		slab(-1.4, 42, 1.4, 58, { Color = BEAM, Name = "Beam" })
		slab(-8, 58, 8, 66)
		B:checkpoint(Vector3.new(0, 0.1, 62), Vector3.new(7, 0.2, 5))
		-- a dog-leg: the beam steps sideways in the middle of the wind
		slab(-1.4, 66, 1.4, 76, { Color = BEAM, Name = "Beam" })
		slab(-1.4, 76, 7, 79, { Color = BEAM, Name = "Beam" })
		slab(4.2, 79, 7, 92, { Color = BEAM, Name = "Beam" })
		slab(-2, 92, 10, 98)
		slab(-1.3, 98, 1.3, 112, { Color = BEAM, Name = "Beam" })
		slab(-8, 112, 8, 118)
		B:checkpoint(Vector3.new(0, 0.1, 115), Vector3.new(7, 0.2, 4))
		slab(-1.2, 118, 1.2, 134, { Color = BEAM, Name = "Beam" })
		slab(-W / 2, 134, W / 2, D)
		-- the turbines
		for i, f in FANS do
			local wx = f.side * (W / 2)
			local face = f.side < 0 and "+X" or "-X"
			local inward = -f.side
			-- housing: a short wide drum sticking out of the wall, with a cage
			B:cyl(Vector3.new(wx + inward * 1.2, 9, f.z), 2.4, 18, "X", { Color = Color3.fromRGB(70, 74, 82), Material = Enum.Material.Metal, Name = "Housing", CanCollide = false })
			B:cyl(Vector3.new(wx + inward * 2.45, 9, f.z), 0.2, 16.4, "X", { Color = Color3.fromRGB(20, 20, 24), Name = "Throat", Parent = "Decor", CanCollide = false })
			for k = -3, 3 do
				B:part(Vector3.new(wx + inward * 2.9, 9 + k * 2.2, f.z), Vector3.new(0.2, 0.2, 16), { Color = Color3.fromRGB(150, 150, 156), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "Grille" })
				B:part(Vector3.new(wx + inward * 2.9, 9, f.z + k * 2.2), Vector3.new(0.2, 16, 0.2), { Color = Color3.fromRGB(150, 150, 156), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "Grille" })
			end
			-- blades on an upright root so they can spin about X
			local blades = Instance.new("Model")
			blades.Name = "Blades" .. i
			local hub = B:part(Vector3.new(wx + inward * 2.2, 9, f.z), Vector3.new(0.8, 2.4, 2.4), { Name = "Hub", Color = Color3.fromRGB(200, 60, 50), Parent = B.model, CanCollide = false })
			hub.Parent = blades
			for k = 0, 4 do
				local blade = B:part(Vector3.new(wx + inward * 2.2, 9, f.z), Vector3.new(0.3, 7.6, 2.4), { Name = "Blade", Color = Color3.fromRGB(190, 194, 200), Material = Enum.Material.Metal, Rot = Vector3.new(k * 72, 0, 0), Parent = B.model, CanCollide = false })
				blade.CFrame = blade.CFrame * CFrame.new(0, 3.8, 0)
				blade.Parent = blades
			end
			blades.PrimaryPart = hub
			blades.Parent = B:folder("Fans")
			-- status lamp above the turbine
			B:part(Vector3.new(wx + inward * 0.4, 19.5, f.z), Vector3.new(0.4, 1.6, 1.6), { Name = "Lamp" .. i, Color = Color3.fromRGB(60, 220, 90), Material = Enum.Material.Neon, Parent = "FanLamps", CanCollide = false })
			-- the wind: a volume across the hall + visible streaks
			local zone = B:part(Vector3.new(0, 6, f.z), Vector3.new(W - 2, 14, 18), { Name = "Wind" .. i, Transparency = 1, CanCollide = false, CanQuery = false, Parent = "Wind" })
			local streaks = Instance.new("ParticleEmitter")
			streaks.Name = "Streaks"
			streaks.Texture = "rbxasset://textures/particles/smoke_main.dds"
			streaks.Color = ColorSequence.new(Color3.fromRGB(220, 235, 245))
			streaks.EmissionDirection = f.side < 0 and Enum.NormalId.Right or Enum.NormalId.Left
			streaks.Rate = 0
			streaks.Speed = NumberRange.new(40, 50)
			streaks.Lifetime = NumberRange.new(1, 1.3)
			streaks.Size = NumberSequence.new(0.6, 2)
			streaks.Transparency = NumberSequence.new(0.6, 1)
			streaks.SpreadAngle = Vector2.new(20, 20)
			local emitterPart = B:part(Vector3.new(wx + inward * 3, 9, f.z), Vector3.new(0.2, 14, 14), { Name = "Emitter" .. i, Transparency = 1, CanCollide = false, Parent = "Wind" })
			streaks.Parent = emitterPart
			-- warning bars across whichever beam the wind crosses (they follow
			-- the beam, including where it steps sideways)
			for dz = -8, 8, 4 do
				local z = f.z + dz
				for _, b in beams do
					if z >= b.z0 + 0.3 and z <= b.z1 - 0.3 and b.x1 - b.x0 < 4 then
						B:part(Vector3.new((b.x0 + b.x1) / 2, 0.03, z), Vector3.new(b.x1 - b.x0 - 0.4, 0.04, 0.5), { Color = Color3.fromRGB(30, 30, 30), Parent = "Decor", CanCollide = false, Name = "WindBar" })
						break
					end
				end
			end
		end
		Decor.pipe(B, Vector3.new(-W / 2 + 1, 28, 2), Vector3.new(-W / 2 + 1, 28, D - 2), 2, Color3.fromRGB(80, 84, 92))
		Decor.pipe(B, Vector3.new(W / 2 - 1, 30, 2), Vector3.new(W / 2 - 1, 30, D - 2), 1.4, Color3.fromRGB(80, 84, 92))
		-- dim blue glow down in the pit so it reads as a long drop
		for _, z in { 30, 75, 120 } do
			B:lamp(Vector3.new(0, -36, z), Vector3.new(2, 0.3, 2), { Color = Color3.fromRGB(60, 120, 200), Range = 40, Brightness = 0.7, Glow = true })
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local fans = {}
		for i, f in FANS do
			fans[i] = {
				def = f,
				model = level.Fans["Blades" .. i],
				lamp = level.FanLamps["Lamp" .. i],
				zone = level.Wind["Wind" .. i],
				streaks = level.Wind["Emitter" .. i].Streaks,
				angle = 0,
				on = false,
			}
			fans[i].base = fans[i].model:GetPivot()
		end
		ctx:heartbeat(function(dt)
			local t = ctx:elapsed()
			for _, fan in fans do
				local cyc = (t + fan.def.phase) % (ON + OFF)
				local on = cyc >= OFF
				local warn = not on and cyc > OFF - 1
				if on and not fan.on then
					Audio.play(fan.lamp, "whoosh", 0.8, 80)
				end
				fan.on = on
				fan.lamp.Color = on and C.red or warn and C.orange or Color3.fromRGB(60, 220, 90)
				fan.streaks.Rate = on and 40 or 0
				fan.angle += (on and 16 or warn and 5 or 0.8) * dt
				fan.model:PivotTo(fan.base * CFrame.Angles(fan.angle, 0, 0))
			end
		end)
		-- the push is a real force on your character, so walls still stop you
		local forces = {}
		local function forceFor(player, root)
			local f = forces[player]
			if f and f.Parent == root then
				return f
			end
			local att = Instance.new("Attachment")
			att.Name = "WindAttachment"
			att.Parent = root
			f = Instance.new("VectorForce")
			f.Name = "Wind"
			f.Attachment0 = att
			f.RelativeTo = Enum.ActuatorRelativeTo.World
			f.ApplyAtCenterOfMass = true
			f.Force = Vector3.zero
			f.Parent = root
			forces[player] = f
			return f
		end
		ctx:onCleanup(function()
			for _, f in forces do
				if f.Parent then
					f.Attachment0:Destroy()
					f:Destroy()
				end
			end
		end)
		ctx.def.OnPlayerTick = function(_, player, root)
			local push = Vector3.zero
			local z = root.Position.Z
			for _, fan in fans do
				if fan.on and math.abs(z - fan.zone.Position.Z) < 9 then
					push += Vector3.new(-fan.def.side, 0, 0)
				end
			end
			forceFor(player, root).Force = push * root.AssemblyMass * FORCE
		end
	end,
}
