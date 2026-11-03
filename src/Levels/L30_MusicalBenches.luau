-- Deadly Dance Floor: an underground club. While the music plays everybody
-- dances (you can still move). When it stops, raised podiums rise out of the
-- floor - one fewer than there are players - and then the floor turns into
-- lasers. Be on a podium.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local H = require(root.LevelHelpers)
local Kit = require(root.LevelKit)
local C = BuildLib.C

local W, D = 60, 66
local STAGE_Z = 50
local FLOOR_TILE = 5
local PODIUM_H = 5
local LASER_TOP = 4.3 -- the laser zone covers everything below this height

local PARTY = { Color3.fromRGB(255, 60, 140), Color3.fromRGB(60, 200, 255), Color3.fromRGB(140, 70, 255), Color3.fromRGB(255, 200, 40), Color3.fromRGB(60, 255, 140) }

return {
	Order = 30,
	Name = "Deadly Dance Floor",
	Mode = "survive",
	TimeLimit = 50,
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 24,
			floorColor = Color3.fromRGB(18, 18, 22),
			floorMat = Enum.Material.SmoothPlastic,
			wallColor = Color3.fromRGB(34, 26, 46),
			wallMat = Enum.Material.Fabric,
			lowerColor = Color3.fromRGB(20, 18, 26),
			trim = Color3.fromRGB(140, 70, 255),
			lampColor = Color3.fromRGB(200, 170, 255),
			brightness = 1.1,
			lampStep = 14,
			beams = false,
			exit = false,
		})
		-- dance floor tiles
		for x = -W / 2 + FLOOR_TILE / 2 + 2, W / 2 - FLOOR_TILE / 2 - 2, FLOOR_TILE do
			for z = 8, STAGE_Z - 4, FLOOR_TILE do
				B:part(Vector3.new(x, 0.03, z), Vector3.new(FLOOR_TILE - 0.3, 0.06, FLOOR_TILE - 0.3), {
					Color = Color3.fromRGB(40, 30, 60),
					Material = Enum.Material.Glass,
					Parent = "DanceFloor",
					CanCollide = false,
					CastShadow = false,
					Name = "Tile",
				})
			end
		end
		-- stage, DJ booth, speaker stacks (all behind the rail)
		B:span(Vector3.new(-W / 2, 0, STAGE_Z), Vector3.new(W / 2, 2, D), { Name = "Stage", Color = Color3.fromRGB(28, 26, 30), Material = Enum.Material.WoodPlanks })
		B:span(Vector3.new(-8, 2, STAGE_Z + 5), Vector3.new(8, 5.5, STAGE_Z + 8), { Name = "DJBooth", Color = Color3.fromRGB(20, 20, 24), Material = Enum.Material.Metal })
		B:part(Vector3.new(0, 4, STAGE_Z + 4.95), Vector3.new(15, 2.5, 0.1), { Name = "BoothFront", Color = Color3.fromRGB(140, 70, 255), Material = Enum.Material.Neon, Transparency = 0.4, Parent = "Decor", CanCollide = false })
		-- the decks: two turntables with spinning platters and a mixer between
		for _, x in { -1.75, 1.75 } do
			B:span(Vector3.new(x - 1.4, 5.5, STAGE_Z + 5.3), Vector3.new(x + 1.4, 5.8, STAGE_Z + 7.7), { Color = Color3.fromRGB(34, 34, 38), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "Turntable" })
			local platter = B:cyl(Vector3.new(x, 5.86, STAGE_Z + 6.5), 0.12, 2.1, "Y", { Color = Color3.fromRGB(14, 14, 16), Material = Enum.Material.SmoothPlastic, Parent = "Decor", CanCollide = false, Name = "Platter", Attr = { Spin = 200, SpinAxis = "X" } }) -- a Y cylinder's own axis is its local X
			local label = B:cyl(Vector3.new(x, 5.93, STAGE_Z + 6.5), 0.02, 0.7, "Y", { Color = Color3.fromRGB(255, 60, 140), Material = Enum.Material.Neon, Parent = platter, CanCollide = false, Name = "Label" })
			label.Parent = platter
			-- the tone arm
			B:part(Vector3.new(x + 1.05, 5.95, STAGE_Z + 6.2), Vector3.new(0.12, 0.12, 1.4), { Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "ToneArm", Rot = Vector3.new(0, 20, 0) })
		end
		B:span(Vector3.new(-0.45, 5.5, STAGE_Z + 5.4), Vector3.new(0.45, 6, STAGE_Z + 7.6), { Color = Color3.fromRGB(26, 26, 30), Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "Mixer" })
		for k = 0, 2 do
			B:part(Vector3.new(-0.25 + k * 0.25, 6.03, STAGE_Z + 6.3), Vector3.new(0.12, 0.06, 0.5), { Color = PARTY[k + 1], Material = Enum.Material.Neon, Parent = "MixerLights", CanCollide = false, Name = "Fader" })
		end
		-- a riser behind the booth so the DJ stands over his decks
		B:span(Vector3.new(-3, 2, STAGE_Z + 8), Vector3.new(3, 3.5, STAGE_Z + 11), { Color = Color3.fromRGB(26, 26, 30), Material = Enum.Material.Metal, Name = "Riser" })
		H.figure(B, Vector3.new(0, 3.5, STAGE_Z + 9), { Name = "DJ", Shirt = C.purple, Hat = C.black, Avatar = "tiiow", Label = "DJ tiiow", Parent = B.model })
		for _, x in { -20, -13, 13, 20 } do
			B:span(Vector3.new(x - 3, 2, STAGE_Z + 6), Vector3.new(x + 3, 12, STAGE_Z + 10), { Name = "Speaker", Color = Color3.fromRGB(16, 16, 18) })
			for _, y in { 5, 9.5 } do
				B:cyl(Vector3.new(x, y, STAGE_Z + 5.95), 0.1, y > 6 and 2.4 or 4, "Z", { Color = Color3.fromRGB(40, 40, 44), Parent = "Decor", CanCollide = false, Name = "Cone" })
			end
		end
		B:part(Vector3.new(0, 10, STAGE_Z + 0.2), Vector3.new(W, 20, 0.2), { Name = "StageBarrier", Transparency = 1, CastShadow = false })
		B:part(Vector3.new(0, 3, STAGE_Z - 0.2), Vector3.new(W, 0.2, 0.2), { Color = C.steel, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "Rail" })
		for x = -W / 2 + 2, W / 2 - 2, 4 do
			B:part(Vector3.new(x, 1.5, STAGE_Z - 0.2), Vector3.new(0.2, 3, 0.2), { Color = C.steel, Material = Enum.Material.Metal, Parent = "Decor", CanCollide = false, Name = "RailPost" })
		end
		-- lighting truss with moving heads
		for _, z in { 18, 36 } do
			B:part(Vector3.new(0, 19, z), Vector3.new(W - 4, 1.2, 1.2), { Color = C.darkSteel, Material = Enum.Material.DiamondPlate, Parent = "Decor", CanCollide = false, Name = "Truss" })
			for x = -20, 20, 10 do
				B:part(Vector3.new(x, 18, z), Vector3.new(1.4, 1.2, 1.4), {
					Name = "MovingHead",
					Color = C.black,
					Parent = "PartyLights",
					CanCollide = false,
					Light = { Kind = "SpotLight", Range = 40, Brightness = 6, Color = PARTY[1], Face = Enum.NormalId.Bottom, Angle = 40 },
				})
			end
		end
		for _, x in { -W / 2 + 2, W / 2 - 2 } do
			for _, z in { 18, 36 } do
				B:part(Vector3.new(x, 9.5, z), Vector3.new(1, 19, 1), { Color = C.darkSteel, Material = Enum.Material.Metal, Parent = "Decor", Name = "TrussLeg" })
			end
		end
		-- a mirror ball over the dance floor, with its own spotlights on it
		local ball = B:ball(Vector3.new(0, 17, 26), 3.6, { Name = "MirrorBall", Color = Color3.fromRGB(220, 220, 230), Material = Enum.Material.Foil, Reflectance = 0.6, Parent = B.model, CanCollide = false, Attr = { Spin = 40 } })
		B:part(Vector3.new(0, 20.5, 26), Vector3.new(0.1, 5, 0.1), { Color = C.black, Parent = "Decor", CanCollide = false, Name = "BallCord" })
		local glint = Instance.new("PointLight")
		glint.Range = 30
		glint.Brightness = 1.5
		glint.Color = Color3.fromRGB(230, 230, 255)
		glint.Parent = ball
		-- stage wash lights on the front of the stage
		for x = -20, 20, 10 do
			B:part(Vector3.new(x, 2.4, STAGE_Z + 0.5), Vector3.new(1.4, 0.8, 0.8), { Name = "StageWash", Color = C.black, Parent = "Decor", CanCollide = false, Light = { Kind = "SpotLight", Face = Enum.NormalId.Front, Range = 30, Brightness = 3, Angle = 60, Color = Color3.fromRGB(255, 120, 200) } })
		end
		-- low couches along the sides (still below the laser line)
		for _, spec in { { -W / 2, 1 }, { W / 2, -1 } } do
			for _, z in { 10, 27, 44 } do
				local x = spec[1] + spec[2] * 2
				B:span(Vector3.new(x - 1.5, 0, z - 4), Vector3.new(x + 1.5, 1.6, z + 4), { Name = "Couch", Color = Color3.fromRGB(90, 30, 50), Material = Enum.Material.Fabric })
				B:span(Vector3.new(spec[1] + spec[2] * 0.4 - 0.4, 0, z - 4), Vector3.new(spec[1] + spec[2] * 0.4 + 0.4, 3.4, z + 4), { Name = "CouchBack", Color = Color3.fromRGB(90, 30, 50), Material = Enum.Material.Fabric })
			end
		end
		-- neon strip along the ceiling edges
		for _, x in { -W / 2 + 0.3, W / 2 - 0.3 } do
			B:part(Vector3.new(x, 22.5, D / 2), Vector3.new(0.2, 0.3, D - 2), { Color = Color3.fromRGB(140, 70, 255), Material = Enum.Material.Neon, Transparency = 0.3, Parent = "Decor", CanCollide = false })
		end
		-- the laser floor (hazard only while active) and its visible beams
		B:part(Vector3.new(0, LASER_TOP / 2, (1 + STAGE_Z) / 2), Vector3.new(W, LASER_TOP, STAGE_Z - 1), { Name = "LaserZone", Transparency = 1, CanCollide = false, CastShadow = false, Parent = B.model })
		for z = 4, STAGE_Z - 2, 4 do
			B:part(Vector3.new(0, 0.5, z), Vector3.new(W - 1, 0.15, 0.15), { Name = "Beam", Color = C.red, Material = Enum.Material.Neon, Transparency = 1, CanCollide = false, CastShadow = false, Parent = "Lasers" })
		end
		for x = -W / 2 + 3, W / 2 - 3, 4 do
			B:part(Vector3.new(x, 0.5, (1 + STAGE_Z) / 2), Vector3.new(0.15, 0.15, STAGE_Z - 3), { Name = "Beam", Color = C.red, Material = Enum.Material.Neon, Transparency = 1, CanCollide = false, CastShadow = false, Parent = "Lasers" })
		end
		-- podiums wait under the floor
		for i = 1, 12 do
			local pod = B:cyl(Vector3.new(0, -PODIUM_H - 1, 25), PODIUM_H, 5, "Y", { Name = "Podium" .. i, Color = Color3.fromRGB(230, 225, 215), Material = Enum.Material.Marble, Parent = "Podiums" })
			pod.CanCollide = false
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local tiles = level.DanceFloor:GetChildren()
		local heads = level.PartyLights:GetChildren()
		local beams = level.Lasers:GetChildren()
		local zone = level.LaserZone
		local podiums = level.Podiums:GetChildren()
		local phase = "music"

		-- lights
		ctx:every(0.35, function()
			for _, t in tiles do
				t.Color = phase == "music" and PARTY[math.random(1, #PARTY)] or (phase == "lasers" and Color3.fromRGB(80, 10, 10) or Color3.fromRGB(40, 30, 60))
			end
			for _, h in heads do
				local l = h:FindFirstChildWhichIsA("Light")
				l.Color = phase == "music" and PARTY[math.random(1, #PARTY)] or C.red
				h.CFrame = CFrame.new(h.Position) * CFrame.Angles(math.rad(math.random(-35, 35)), 0, math.rad(math.random(-35, 35)))
			end
		end)

		-- forced dancing: one of the player's own /e dances while the music's on
		local dancing = {}
		local function startDance(player)
			dancing[player] = true
			Kit.forceDance(player, true)
		end
		local function stopDances()
			for p in dancing do
				Kit.forceDance(p, false)
				dancing[p] = nil
			end
		end
		ctx:onCleanup(stopDances)

		local function tween(part, target, time)
			local start = part.CFrame
			local t = 0
			while t < time do
				t += task.wait()
				part.CFrame = start:Lerp(target, math.min(1, t / time))
			end
		end

		-- DJ tiiow works the decks while the music plays: right hand
		-- scratching, left hand on the mixer, head nodding, bobbing to the beat.
		-- His arms are posed through the shoulder joints' C0 (in torso space, so
		-- R6 and R15 both work) on top of a quiet idle. When it cuts, he cheers.
		local BPM = 124
		local cones, front, faders = {}, level.Decor:FindFirstChild("BoothFront"), level:FindFirstChild("MixerLights")
		for _, p in level.Decor:GetChildren() do
			if p.Name == "Cone" then
				table.insert(cones, { part = p, cf = p.CFrame, size = p.Size })
			end
		end
		local djState = {} -- per avatar instance: joints and their rest offsets
		-- a joint we can pose: Motor6D (C0) or the newer AnimationConstraint
		-- avatar joints (its Attachment0 on the torso side plays the C0 role)
		local function jointOf(d)
			if d:IsA("Motor6D") then
				return { get = function()
					return d.C0
				end, set = function(cf)
					d.C0 = cf
				end }
			elseif d:IsA("AnimationConstraint") and d.Attachment0 then
				local att = d.Attachment0
				return { get = function()
					return att.CFrame
				end, set = function(cf)
					att.CFrame = cf
				end }
			end
			return nil
		end
		local function joints(dj)
			local st = djState[dj]
			if st then
				return st
			end
			st = {}
			for _, d in dj:GetDescendants() do
				local key = (d.Name == "RightShoulder" or d.Name == "Right Shoulder") and "r"
					or (d.Name == "LeftShoulder" or d.Name == "Left Shoulder") and "l"
					or d.Name == "Neck" and "n"
				local j = key and not st[key] and jointOf(d)
				if j then
					j.rest = j.get()
					st[key] = j
				end
			end
			st.base = dj:GetPivot()
			djState[dj] = st
			return st
		end
		local function pose(j, rot)
			if j then
				j.set(CFrame.new(j.rest.Position) * rot * j.rest.Rotation)
			end
		end
		local mode -- what the DJ is currently doing
		ctx:heartbeat(function()
			local beat = (os.clock() * BPM / 60) % 1
			local on = phase == "music"
			local pump = on and (1 - beat) ^ 3 or 0
			for _, c in cones do
				c.part.CFrame = CFrame.new(0, 0, -0.3 * pump) * c.cf
				c.part.Size = Vector3.new(c.size.X, c.size.Y * (1 + 0.08 * pump), c.size.Z * (1 + 0.08 * pump))
			end
			if front then
				local k = math.floor(os.clock() * BPM / 60) % #PARTY + 1
				front.Color = on and PARTY[k] or C.red
				front.Transparency = on and 0.15 + 0.4 * beat or 0.3
			end
			if faders then
				for i, f in faders:GetChildren() do
					f.Transparency = on and (math.sin(os.clock() * (3 + i)) > 0 and 0 or 0.7) or 0.8
				end
			end
			local dj = level:FindFirstChild("DJ")
			if not dj or not dj:FindFirstChildOfClass("Humanoid") then
				return
			end
			local st = joints(dj)
			if on then
				if mode ~= "decks" then
					mode = "decks"
					Kit.playAnim(dj, "idle")
				end
				local t = os.clock()
				-- right hand on the right-hand platter, scratching back and forth
				local scratch = math.sin(t * 13) * 0.28 + math.sin(t * 5.3) * 0.08
				pose(st.r, CFrame.Angles(math.rad(72), scratch, 0))
				-- left hand on the mixer, riding a fader
				pose(st.l, CFrame.Angles(math.rad(68 + math.sin(t * 2.1) * 5), -0.32, 0))
				-- nod on the beat, and bob the whole body
				pose(st.n, CFrame.Angles(-math.rad(14) * pump, 0, 0))
				dj:PivotTo(st.base * CFrame.new(0, -0.18 * pump, 0))
			elseif mode ~= "cheer" then
				mode = "cheer"
				pose(st.r, CFrame.identity)
				pose(st.l, CFrame.identity)
				pose(st.n, CFrame.identity)
				dj:PivotTo(st.base)
				Kit.playAnim(dj, "cheer")
			end
		end)
		-- the level's track plays only during the music phase
		local function music(on)
			local m = ctx.music
			if not m then
				return
			end
			if on then
				if m.IsPaused then
					m:Resume()
				elseif not m.IsPlaying then
					m:Play()
				end
			else
				m:Pause()
			end
		end

		ctx:waitForStart()
		while not ctx.ended do
			-- music
			phase = "music"
			music(true)
			local musicTime = math.random(50, 75) / 10
			local t0 = os.clock()
			while os.clock() - t0 < musicTime and not ctx.ended do
				for _, p in ctx:activeInside() do
					startDance(p)
				end
				task.wait(0.4)
			end
			if ctx.ended then
				break
			end
			stopDances()
			music(false)
			-- music stops: podiums rise
			phase = "seats"
			local n = math.max(1, #ctx:activeInside() - 1)
			local used = {}
			local risen = {}
			for i = 1, math.min(n, #podiums) do
				local pos
				repeat
					pos = Vector3.new(math.random(-3, 3) * 6, 0, 4 + math.random(1, 6) * 6)
				until not used[pos.X .. "," .. pos.Z]
				used[pos.X .. "," .. pos.Z] = true
				local pod = podiums[i]
				local rot = CFrame.Angles(0, 0, math.rad(90))
				pod.CFrame = CFrame.new(ctx:w(pos + Vector3.new(0, -PODIUM_H / 2 - 0.2, 0))) * rot
				pod.CanCollide = true
				task.spawn(tween, pod, CFrame.new(ctx:w(pos + Vector3.new(0, PODIUM_H / 2, 0))) * rot, 0.6)
				table.insert(risen, pod)
			end
			ctx:broadcast("The music stopped! Get on a podium!")
			task.wait(3.5)
			if ctx.ended then
				break
			end
			-- lasers
			phase = "lasers"
			for _, b in beams do
				b.Transparency = 0.1
			end
			ctx:setHazard(zone, true)
			task.wait(2.5)
			ctx:setHazard(zone, false)
			for _, b in beams do
				b.Transparency = 1
			end
			-- podiums sink back down
			phase = "reset"
			for _, pod in risen do
				task.spawn(function()
					tween(pod, pod.CFrame - Vector3.new(0, PODIUM_H + 0.4, 0), 0.6)
					pod.CanCollide = false
				end)
			end
			task.wait(1)
		end
	end,
}
