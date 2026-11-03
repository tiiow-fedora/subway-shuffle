-- LevelKit: the shared runtime every Subway Shuffle level runs on.
--
-- A level Model (cloned into workspace by levelctrl) contains a LevelScript
-- that calls Kit.start(level, def), where def is the level's module from
-- ServerStorage.SubwayShuffle.Levels. The kit then:
--   * slides the station's Metal Door open
--   * drives attribute-tagged parts: MoveFrom/MoveTo (ping-pong movers),
--     Spin (degrees/sec), Conveyor (Vector3), Bounce (number), Flicker
--   * handles Hazard / Deadly / Checkpoints / Finish / Collectible parts
--   * runs the timer, HUD status and end conditions for the level's Mode:
--       escape  - reach the Finish pad (hazards send you to your checkpoint)
--       survive - last until the timer ends (hazards knock you out of the level)
--       collect - find all the Collectible parts as a team
--       chill   - just hang out until the timer ends
--   * calls def.Run(ctx) (optional) for level-specific logic
--   * fires LevelFinished when the level is over.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local RunState = require(script.Parent.RunState)
local Audio = require(script.Parent.Audio)

local Kit = {}
Kit.__index = Kit

local DEFAULT_ORIGIN = Vector3.new(147.7, 21.4, 100.6)
local WALK_TIME = 25 -- max seconds to wait for someone to walk in before the clock starts

local function gameState()
	return ReplicatedStorage:FindFirstChild("GameState")
end

local function setState(key, value)
	local gs = gameState()
	if gs then
		gs:SetAttribute(key, value)
	end
end

function Kit.notify(player, text, color)
	local ev = ReplicatedStorage:FindFirstChild("Notify")
	if ev then
		ev:FireClient(player, text, color)
	end
end

local function rootOf(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart"), hum
end
Kit.rootOf = rootOf

local function trainReturnCFrame(i)
	local train = workspace:FindFirstChild("SubwayTrain")
	local rp = train and train:FindFirstChild("ReturnPoint")
	if not rp then
		return nil
	end
	local offset = Vector3.new(((i or 0) % 6) * 3 - 7.5, 3, 0)
	return rp.CFrame + offset
end
Kit.trainReturnCFrame = trainReturnCFrame

-- ------------------------------------------------------------------------
-- context methods usable from def.Run

function Kit:w(v)
	return self.origin + v
end

function Kit:participants()
	return RunState.participants()
end

function Kit:onCleanup(fn)
	table.insert(self.cleanups, fn)
end

function Kit:connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self.conns, c)
	return c
end

function Kit:heartbeat(fn)
	return self:connect(RunService.Heartbeat, fn)
end

-- run fn every `interval` seconds until the level ends
function Kit:every(interval, fn)
	task.spawn(function()
		while not self.ended do
			fn()
			task.wait(interval)
		end
	end)
end

function Kit:spawn(fn)
	task.spawn(function()
		if not self.ended then
			fn()
		end
	end)
end

-- The level clock only starts once somebody walks in (or after WALK_TIME),
-- so players have time to get off the train and up the stairs.
function Kit:elapsed()
	if not self.startTime then
		return 0
	end
	return os.clock() - self.startTime
end

function Kit:started()
	return self.startTime ~= nil
end

function Kit:waitForStart()
	while not self.startTime and not self.ended do
		task.wait(0.1)
	end
end

function Kit:timeLeft()
	return math.max(0, self.timeLimit - self:elapsed())
end

function Kit:hint(text)
	setState("LevelHint", text)
end

function Kit:broadcast(text, color)
	for _, p in self:participants() do
		Kit.notify(p, text, color)
	end
end

function Kit:isActive(player)
	return not self.finished[player] and not self.eliminated[player]
end

function Kit:inside(pos)
	local lo, hi = self.boundsMin, self.boundsMax
	return pos.X > lo.X and pos.X < hi.X and pos.Z > lo.Z and pos.Z < hi.Z and pos.Y > lo.Y - 40 and pos.Y < hi.Y + 40
end

-- players currently inside the level area who are still playing
function Kit:activeInside()
	local list = {}
	for _, p in self:participants() do
		local root = rootOf(p)
		if root and self:isActive(p) and self:inside(root.Position) then
			table.insert(list, p)
		end
	end
	return list
end

function Kit:addTrigger(part, kind)
	part:SetAttribute(kind, true)
	self:_track(part)
end

-- turn a part into a hazard (or back) while the level is running
function Kit:setHazard(part, on)
	part:SetAttribute("Hazard", on or nil)
	if on then
		self.hazards[part] = true
	else
		self.hazards[part] = nil
	end
	self.triggerDirty = true
end

function Kit:setCheckpoint(player, index)
	if (self.checkpoint[player] or 1) < index then
		self.checkpoint[player] = index
		local pad = self.checkpoints[index]
		if pad then
			Audio.play(pad, "checkpoint", 0.25, 40)
			-- the pad flashes when you claim it
			task.spawn(function()
				local c = pad.Color
				pad.Material = Enum.Material.Neon
				task.wait(0.4)
				pad.Material = Enum.Material.SmoothPlastic
				pad.Color = c
			end)
		end
	end
end

function Kit:checkpointCFrame(player)
	local pad = self.checkpoints[self.checkpoint[player] or 1]
	local pos
	if pad then
		pos = pad.Position + Vector3.new(0, pad.Size.Y / 2 + 3, 0)
	else
		pos = self.origin + Vector3.new(0, 3, 4)
	end
	local facing = pad and pad:GetAttribute("Facing") or Vector3.new(0, 0, 1)
	return CFrame.lookAt(pos, pos + facing)
end

-- Roblox-style death: the character falls apart (default death sound), and
-- RunCtrl respawns them at RunState.respawnAt[player] (or on the train).
local function kill(player)
	local _, hum = rootOf(player)
	if hum then
		hum.Health = 0
	end
end
Kit.kill = kill

-- Obby-style failure: die, respawn at your last checkpoint.
function Kit:reset(player, why)
	local now = os.clock()
	if self.lastPenalty[player] and now - self.lastPenalty[player] < 1 then
		return
	end
	self.lastPenalty[player] = now
	if not rootOf(player) then
		return
	end
	RunState.respawnAt[player] = self:checkpointCFrame(player)
	kill(player)
end

-- Not a death: fade out and put them back at their checkpoint (e.g. caught).
function Kit:sendBack(player, why)
	local now = os.clock()
	if self.lastPenalty[player] and now - self.lastPenalty[player] < 1.5 then
		return
	end
	self.lastPenalty[player] = now
	local root = rootOf(player)
	if not root then
		return
	end
	Kit.notify(player, "__fade")
	if why then
		Kit.notify(player, why)
	end
	task.delay(0.3, function()
		if player.Character and root.Parent then
			player.Character:PivotTo(self:checkpointCFrame(player))
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end

-- Out of this level: die, respawn on the train.
function Kit:eliminate(player, why)
	if self.eliminated[player] or self.finished[player] then
		return
	end
	self.eliminated[player] = true
	self.entered[player] = true
	RunState.respawnAt[player] = nil
	if why then
		Kit.notify(player, why)
	end
	kill(player)
	if self.def.OnEliminate then
		task.spawn(self.def.OnEliminate, self, player)
	end
end

function Kit:finish(player, why)
	if self.finished[player] or self.eliminated[player] then
		return
	end
	self.finished[player] = true
	self.entered[player] = true
	if self.finishPad then
		Audio.play(self.finishPad, "ding", 0.6)
	end
	Kit.notify(player, why or "You made it!")
end

-- hazard response depends on mode unless the level overrides it
function Kit:penalize(player, part)
	if self.def.OnHazard then
		self.def.OnHazard(self, player, part)
		return
	end
	if part and part:GetAttribute("Deadly") then
		self:eliminate(player)
	elseif self.mode == "survive" or self.mode == "chill" then
		self:eliminate(player)
	else
		self:reset(player)
	end
end

function Kit:collect(player, part)
	if part:GetAttribute("Taken") then
		return
	end
	part:SetAttribute("Taken", true)
	self.collected += 1
	Audio.play(part.Position, "pickup", 0.8)
	for _, d in part:GetDescendants() do
		if d:IsA("BasePart") then
			d.Transparency = 1
		elseif d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			d.Enabled = false
		end
	end
	part.Transparency = 1
	part.CanTouch = false
	part.CanQuery = false
	part.CanCollide = false
	local msg = string.format("%s found one! (%d/%d)", player.DisplayName, self.collected, self.collectTarget)
	self:broadcast(msg)
	-- escape levels with pickups: finding them all opens the exit
	if self.mode == "escape" and self.collected >= self.collectTarget then
		self:broadcast("That's all of them - the exit is open!")
		self:openExit()
	end
	if self.def.OnCollect then
		task.spawn(self.def.OnCollect, self, player, part)
	end
end

-- Slide the exit door open (once). Escape levels open it when someone gets
-- close; puzzle levels set ExitLocked and call this when solved.
function Kit:openExit()
	local door = self.level:FindFirstChild("ExitDoor")
	if not door or self.exitOpen then
		return
	end
	self.exitOpen = true
	-- levels with their own exit door animate it themselves
	if self.def.OpenExit then
		task.spawn(self.def.OpenExit, self, door)
		return
	end
	local start = door:GetPivot()
	local hinge = door:GetAttribute("Hinge")
	local angle = math.rad(door:GetAttribute("OpenAngle") or -90)
	local offset = door:GetAttribute("OpenOffset") or Vector3.new(5, 0, 0)
	Audio.play(door:GetPivot().Position, "doorOpen", 0.5, 60)
	task.spawn(function()
		for i = 1, 40 do
			local a = i / 40
			a = a * a * (3 - 2 * a)
			if hinge then
				-- swing about the hinge edge, away from the level
				local h = CFrame.new(hinge)
				door:PivotTo(h * CFrame.Angles(0, angle * a, 0) * h:Inverse() * start)
			else
				door:PivotTo(start + offset * a)
			end
			task.wait(1 / 40)
		end
	end)
end

-- temporary Lighting changes for this level, restored afterwards
function Kit:applyLighting(t)
	local saved = {}
	for k, v in t do
		saved[k] = Lighting[k]
		Lighting[k] = v
	end
	self:onCleanup(function()
		for k, v in saved do
			Lighting[k] = v
		end
	end)
end

function Kit:setGravity(g)
	local old = workspace.Gravity
	workspace.Gravity = g
	self:onCleanup(function()
		workspace.Gravity = old
	end)
end

function Kit:darken(ambient)
	local saved = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
	}
	Lighting.Ambient = ambient or Color3.new(0, 0, 0)
	Lighting.OutdoorAmbient = ambient or Color3.new(0, 0, 0)
	Lighting.Brightness = 0
	Lighting.ClockTime = 0
	self:onCleanup(function()
		for k, v in saved do
			Lighting[k] = v
		end
	end)
end

-- attach a light to every participant (torch levels)
function Kit:giveLights(range, color)
	local made = {}
	local function give(player)
		local root = rootOf(player)
		if root and not root:FindFirstChild("LevelTorch") then
			local l = Instance.new("SpotLight")
			l.Name = "LevelTorch"
			l.Range = range or 40
			l.Angle = 70
			l.Brightness = 3
			l.Color = color or Color3.fromRGB(255, 240, 200)
			l.Face = Enum.NormalId.Front
			l.Shadows = true
			l.Parent = root
			local glow = Instance.new("PointLight")
			glow.Name = "LevelTorch"
			glow.Range = 10
			glow.Brightness = 0.6
			glow.Parent = root
			table.insert(made, l)
			table.insert(made, glow)
		end
	end
	for _, p in self:participants() do
		give(p)
	end
	self:every(1, function()
		for _, p in self:participants() do
			give(p)
		end
	end)
	self:onCleanup(function()
		for _, l in made do
			l:Destroy()
		end
	end)
end

-- temporarily change humanoid stats for everyone in the level
function Kit:setHumanoid(prop, value)
	local saved = {}
	self:every(0.5, function()
		for _, p in self:participants() do
			local _, hum = rootOf(p)
			if hum and saved[hum] == nil then
				saved[hum] = hum[prop]
				if prop == "JumpPower" then
					hum.UseJumpPower = true
				end
				hum[prop] = value
			end
		end
	end)
	self:onCleanup(function()
		for hum, v in saved do
			if hum.Parent then
				hum[prop] = v
			end
		end
	end)
end

function Kit:endLevel(reason)
	if self.ended then
		return
	end
	self.ended = true
	self.endReason = reason
end

-- ------------------------------------------------------------------------
-- internals

function Kit:_track(obj)
	if not obj:IsA("BasePart") then
		return
	end
	local changed = false
	if obj:GetAttribute("Hazard") or obj:GetAttribute("Deadly") then
		self.hazards[obj] = true
		changed = true
	end
	if obj:GetAttribute("Bounce") then
		self.bouncers[obj] = true
		changed = true
	end
	if obj:GetAttribute("Collectible") then
		self.collectibles[obj] = true
		changed = true
	end
	if obj:GetAttribute("Trigger") then
		self.triggers[obj] = true
		changed = true
	end
	if changed then
		self.triggerDirty = true
	end
end

function Kit:_untrack(obj)
	if self.hazards[obj] or self.bouncers[obj] or self.collectibles[obj] or self.triggers[obj] then
		self.hazards[obj] = nil
		self.bouncers[obj] = nil
		self.collectibles[obj] = nil
		self.triggers[obj] = nil
		self.triggerDirty = true
	end
end

function Kit:_openDoor()
	local tunnel = workspace:FindFirstChild("TunnelSystem")
	local target = self.level:GetAttribute("DoorPos") or (self.origin + Vector3.new(0, 3, -1.2))
	if not tunnel then
		return
	end
	local door, bestDist = nil, 15
	for _, d in tunnel:GetDescendants() do
		if d:IsA("Model") and d.Name == "Metal Door" then
			local dist = (d:GetPivot().Position - target).Magnitude
			if dist < bestDist then
				door, bestDist = d, dist
			end
		end
	end
	if not door or door:GetAttribute("Opened") then
		return
	end
	door:SetAttribute("Opened", true)
	-- a plug door: step out toward the platform first, then slide. Sliding
	-- straight along X parked it half inside the station wall (its middle on
	-- the wall face) and flush with the floor, and both Z-fought
	local start = door:GetPivot()
	local out = Vector3.new(0, 0.02, -0.6)
	for i = 1, 6 do
		door:PivotTo(start + out * (i / 6))
		task.wait(1 / 30)
	end
	for i = 1, 30 do
		door:PivotTo(start + out + Vector3.new(4.6 * i / 30, 0, 0))
		task.wait(1 / 30)
	end
end

function Kit:_setupMovers()
	local movers, spinners = {}, {}
	for _, obj in self.level:GetDescendants() do
		if not (obj:IsA("BasePart") or obj:IsA("Model")) then
			continue
		end
		local parts = {}
		if obj:IsA("BasePart") then
			parts = { obj }
		else
			for _, p in obj:GetDescendants() do
				if p:IsA("BasePart") then
					table.insert(parts, p)
				end
			end
		end
		local a, b = obj:GetAttribute("MoveFrom"), obj:GetAttribute("MoveTo")
		if a and b then
			table.insert(movers, {
				obj = obj,
				a = a,
				b = b,
				parts = parts,
				last = a,
				rot = obj:GetPivot().Rotation,
				speed = obj:GetAttribute("Speed") or 6,
				pause = obj:GetAttribute("Pause") or 1,
				phase = obj:GetAttribute("Phase") or 0,
			})
		end
		local spin = obj:GetAttribute("Spin")
		if spin then
			local axisName = obj:GetAttribute("SpinAxis") or "Y"
			local axis = axisName == "X" and Vector3.xAxis or axisName == "Z" and Vector3.zAxis or Vector3.yAxis
			table.insert(spinners, {
				obj = obj,
				base = obj:GetPivot(),
				axis = axis,
				speed = math.rad(spin),
				parts = parts,
			})
		end
		local conv = obj:GetAttribute("Conveyor")
		if conv and obj:IsA("BasePart") then
			obj.AssemblyLinearVelocity = conv
		end
	end

	local clock = 0
	self:heartbeat(function(dt)
		clock += dt
		for _, m in movers do
			if not m.obj.Parent then
				continue
			end
			local travel = (m.b - m.a).Magnitude / m.speed
			local cycle = 2 * (travel + m.pause)
			local t = (clock + m.phase * cycle) % cycle
			local alpha
			if t < m.pause then
				alpha = 0
			elseif t < m.pause + travel then
				alpha = (t - m.pause) / travel
			elseif t < 2 * m.pause + travel then
				alpha = 1
			else
				alpha = 1 - (t - 2 * m.pause - travel) / travel
			end
			local pos = m.a:Lerp(m.b, alpha)
			local vel = dt > 0 and (pos - m.last) / dt or Vector3.zero
			-- never more than the mover's real speed: a big jump (first frame,
			-- server hitch) would otherwise launch anyone standing on it
			if vel.Magnitude > m.speed * 1.5 then
				vel = vel.Unit * m.speed
			end
			if not m.started then
				m.started = true
				vel = Vector3.zero
			end
			m.last = pos
			m.obj:PivotTo(CFrame.new(pos) * m.rot)
			for _, p in m.parts do
				p.AssemblyLinearVelocity = vel
			end
		end
		for _, s in spinners do
			if not s.obj.Parent then
				continue
			end
			local cf = s.base * CFrame.fromAxisAngle(s.axis, clock * s.speed)
			s.obj:PivotTo(cf)
			local worldAxis = s.base:VectorToWorldSpace(s.axis)
			for _, p in s.parts do
				p.AssemblyAngularVelocity = worldAxis * s.speed
			end
		end
	end)
end

-- Play one of an NPC's animations by kind ("idle", "walk", "dance", ...),
-- stopping whatever it was playing. Friend avatars carry Anim_<kind>
-- attributes (FriendAvatars); noob/guest rigs carry IdleAnim / WalkAnim.
local npcTracks = setmetatable({}, { __mode = "k" })
-- NPC rigs (the Guest template, some avatars) can come without an Animator,
-- and then nothing would ever play on them
local function animatorOf(hum)
	if not hum then
		return nil
	end
	local a = hum:FindFirstChildOfClass("Animator")
	if not a then
		a = Instance.new("Animator")
		a.Parent = hum
	end
	return a
end
function Kit.playAnim(model, kind, speed)
	local hum = model and model:FindFirstChildOfClass("Humanoid")
	local animator = animatorOf(hum)
	if not animator then
		return nil
	end
	local id = model:GetAttribute("Anim_" .. kind)
		or (kind == "walk" and model:GetAttribute("WalkAnim"))
		or (kind == "idle" and model:GetAttribute("IdleAnim"))
	if not id then
		return nil
	end
	local cache = npcTracks[model]
	if not cache then
		cache = {}
		npcTracks[model] = cache
		-- stop anything started elsewhere (the idle loop from the swap)
		for _, t in animator:GetPlayingAnimationTracks() do
			t:Stop(0.2)
		end
	end
	local track = cache[kind]
	if not track then
		local a = Instance.new("Animation")
		a.AnimationId = id
		local ok, t = pcall(animator.LoadAnimation, animator, a)
		if not ok then
			return nil
		end
		track = t
		track.Looped = true
		cache[kind] = track
	end
	for k, t in cache do
		if k ~= kind and t.IsPlaying then
			t:Stop(0.2)
		end
	end
	if not track.IsPlaying then
		track:Play(0.2)
	end
	track:AdjustSpeed(speed or 1)
	return track
end

-- Make a player dance one of their own /e dances (on = true) or stop it.
-- The track belongs to the character, so a respawn clears it by itself.
local playerDances = setmetatable({}, { __mode = "k" })
function Kit.forceDance(player, on)
	local char = player.Character
	local cur = playerDances[player]
	if cur and (not on or cur.char ~= char) then
		pcall(cur.track.Stop, cur.track, 0.2)
		playerDances[player] = nil
		cur = nil
	end
	if not on or cur then
		return
	end
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local animate = char and char:FindFirstChild("Animate")
	if not animator or not animate then
		return
	end
	local holder = animate:FindFirstChild(({ "dance", "dance2", "dance3" })[math.random(1, 3)])
	local anim = holder and holder:FindFirstChildOfClass("Animation")
	if anim then
		local ok, track = pcall(animator.LoadAnimation, animator, anim)
		if ok then
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = true
			track:Play(0.2)
			playerDances[player] = { track = track, char = char }
		end
	end
end

-- NPC rigs built by LevelHelpers.npc carry their animation ids; play the one
-- named by their Anim attribute ("walk" or "idle", default idle).
function Kit.animateNpcs(container)
	for _, m in container:GetDescendants() do
		if m:IsA("Model") and (m:GetAttribute("WalkAnim") or m:GetAttribute("IdleAnim")) then
			local animator = animatorOf(m:FindFirstChildOfClass("Humanoid"))
			local which = m:GetAttribute("Anim") == "walk" and "WalkAnim" or "IdleAnim"
			local id = m:GetAttribute(which)
			if animator and id then
				local anim = Instance.new("Animation")
				anim.AnimationId = id
				local ok, track = pcall(animator.LoadAnimation, animator, anim)
				if ok then
					track.Looped = true
					track:Play(0.1, 1, m:GetAttribute("AnimSpeed") or 1)
				end
			end
		end
	end
end

function Kit:_setupFlicker()
	for _, lamp in self.level:GetDescendants() do
		if lamp:IsA("BasePart") and lamp:GetAttribute("Flicker") then
			task.spawn(function()
				local bulb = lamp:FindFirstChildWhichIsA("Light")
				while not self.ended and lamp.Parent do
					task.wait(math.random(10, 40) / 10)
					for _ = 1, math.random(2, 5) do
						lamp.Material = Enum.Material.SmoothPlastic
						if bulb then
							bulb.Enabled = false
						end
						task.wait(0.05 + math.random() * 0.1)
						lamp.Material = Enum.Material.Neon
						if bulb then
							bulb.Enabled = true
						end
						task.wait(0.05 + math.random() * 0.1)
					end
				end
			end)
		end
	end
end

function Kit:_statusText()
	local parts = self:participants()
	local total = #parts
	if self.def.Status then
		return self.def.Status(self)
	end
	if self.mode == "escape" then
		local n = 0
		for _, p in parts do
			if self.finished[p] then
				n += 1
			end
		end
		return string.format("%d / %d escaped", n, total)
	elseif self.mode == "survive" then
		local n = 0
		for _, p in parts do
			if not self.eliminated[p] then
				n += 1
			end
		end
		return string.format("%d / %d still standing", n, total)
	elseif self.mode == "collect" then
		return string.format("%d / %d found", self.collected, self.collectTarget)
	end
	return "Relax..."
end

function Kit:_checkEnd()
	local parts = self:participants()
	local elapsed = self:elapsed()
	if self.def.Check then
		local reason = self.def.Check(self)
		if reason then
			return reason
		end
	end
	if self.mode == "collect" and self.collectTarget > 0 and self.collected >= self.collectTarget then
		return "ALL FOUND!"
	end
	if self.mode == "escape" or self.mode == "collect" then
		local all = #parts > 0
		local anyFinished = false
		for _, p in parts do
			if self.finished[p] then
				anyFinished = true
			end
			if not self.finished[p] and not self.eliminated[p] then
				all = false
			end
		end
		if all and self.mode == "escape" then
			return "ALL ESCAPED!"
		end
		if elapsed > 30 and anyFinished and #self:activeInside() == 0 then
			return "EVERYONE'S THROUGH!"
		end
	elseif self.mode == "survive" then
		local anyEntered = false
		for _, p in parts do
			if self.entered[p] then
				anyEntered = true
			end
		end
		if elapsed > 15 and anyEntered and #self:activeInside() == 0 then
			return "EVERYONE'S OUT!"
		end
	end
	return nil
end

function Kit:_rebuildTriggerParams()
	local list = {}
	for p in self.hazards do
		table.insert(list, p)
	end
	for p in self.bouncers do
		table.insert(list, p)
	end
	for p in self.collectibles do
		table.insert(list, p)
	end
	for p in self.triggers do
		table.insert(list, p)
	end
	for _, p in self.checkpoints do
		table.insert(list, p)
	end
	if self.finishPad then
		table.insert(list, self.finishPad)
	end
	self.overlap.FilterDescendantsInstances = list
	self.triggerDirty = false
end

function Kit:_tick()
	local lo = self.origin.Y + (self.def.KillY or -10)
	for _, player in self:participants() do
		local root, hum = rootOf(player)
		if not root then
			if self.entered[player] and self:isActive(player) and self.mode == "survive" then
				self.eliminated[player] = true
			end
			continue
		end
		local pos = root.Position
		local inside = self:inside(pos)
		if inside and not self.entered[player] then
			self.entered[player] = true
			-- keep the camera close: zoomed right out you could see the outside
			-- of the station and the tunnel around the level
			if not self.zoomSaved then
				self.zoomSaved = {}
				self:onCleanup(function()
					for p, z in self.zoomSaved do
						if p.Parent then
							p.CameraMaxZoomDistance = z
						end
					end
				end)
			end
			if self.zoomSaved[player] == nil then
				self.zoomSaved[player] = player.CameraMaxZoomDistance
				player.CameraMaxZoomDistance = math.min(player.CameraMaxZoomDistance, self.def.MaxZoom or 24)
			end
			if self.def.OnEnter then
				task.spawn(self.def.OnEnter, self, player)
			end
		end
		if not inside or not self:isActive(player) then
			continue
		end
		-- touching things
		local hits = workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0, -0.7, 0), Vector3.new(3, 5.6, 3), self.overlap)
		local penalized = false
		for _, part in hits do
			if self.hazards[part] and not penalized then
				penalized = true
				self:penalize(player, part)
			elseif self.bouncers[part] then
				local v = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(v.X, part:GetAttribute("Bounce"), v.Z)
			elseif self.collectibles[part] then
				self:collect(player, part)
			elseif self.triggers[part] and self.def.OnTrigger then
				self.def.OnTrigger(self, player, part)
			elseif part == self.finishPad then
				self:finish(player)
			else
				local idx = self.checkpointIndex[part]
				if idx then
					self:setCheckpoint(player, idx)
				end
			end
		end
		if pos.Y < lo and self:isActive(player) then
			if self.mode == "survive" or self.def.FallEliminates then
				self:eliminate(player)
			else
				self:reset(player)
			end
		end
		if hum and self.def.OnPlayerTick then
			self.def.OnPlayerTick(self, player, root, hum)
		end
	end
end

-- ------------------------------------------------------------------------

function Kit.start(level, def)
	local self = setmetatable({}, Kit)
	self.level = level
	self.def = def
	self.mode = def.Mode or "escape"
	self.origin = level:GetAttribute("Origin") or DEFAULT_ORIGIN
	self.timeLimit = level:GetAttribute("TimeLimit") or def.TimeLimit or 90
	self.conns, self.cleanups = {}, {}
	self.finished, self.eliminated, self.entered = {}, {}, {}
	self.checkpoint, self.lastPenalty = {}, {}
	self.hazards, self.bouncers, self.collectibles, self.triggers = {}, {}, {}, {}
	self.collected = 0
	self.warned = {}
	self.ended = false
	self.startTime = nil
	self.loadTime = os.clock()

	local cf, size = level:GetBoundingBox()
	self.boundsMin = cf.Position - size / 2
	self.boundsMax = cf.Position + size / 2
	self.boundsMin = Vector3.new(self.boundsMin.X, self.boundsMin.Y, math.max(self.boundsMin.Z, self.origin.Z + 0.5))

	self.checkpoints, self.checkpointIndex = {}, {}
	local cpFolder = level:FindFirstChild("Checkpoints")
	if cpFolder then
		for _, pad in cpFolder:GetChildren() do
			local i = tonumber(pad.Name)
			if i then
				self.checkpoints[i] = pad
				self.checkpointIndex[pad] = i
			end
		end
	end
	self.finishPad = level:FindFirstChild("Finish")
	-- build the touch list on the first tick even if the level has no hazards
	-- (otherwise the finish pad and checkpoints are never detected)
	self.triggerDirty = true

	self.overlap = OverlapParams.new()
	self.overlap.FilterType = Enum.RaycastFilterType.Include

	for _, d in level:GetDescendants() do
		self:_track(d)
	end
	self:connect(level.DescendantAdded, function(d)
		self:_track(d)
	end)
	self:connect(level.DescendantRemoving, function(d)
		self:_untrack(d)
	end)

	local n = 0
	for _ in self.collectibles do
		n += 1
	end
	self.collectTarget = def.CollectTarget or n

	print("LEVEL STARTED:", def.Name or level.Name)

	task.spawn(function()
		self:_openDoor()
	end)
	task.spawn(function()
		require(script.Parent.FriendAvatars).swapAll(level)
	end)
	self:_setupMovers()
	self:_setupFlicker()
	Kit.animateNpcs(level)
	-- base lighting: even and readable (the place itself is tuned for the
	-- station). Indoors gets a raised ambient so rooms aren't bright pools with
	-- black gaps; darker rooms (low RoomBrightness) keep some mood. The level's
	-- own Lighting table wins over these.
	local base
	if level:GetAttribute("Outdoor") then
		base = {
			Ambient = Color3.fromRGB(118, 118, 124),
			OutdoorAmbient = Color3.fromRGB(140, 140, 146),
			Brightness = 2.4,
			ClockTime = 14,
			EnvironmentDiffuseScale = 0.8,
			EnvironmentSpecularScale = 0.35,
		}
	else
		local rb = level:GetAttribute("RoomBrightness") or 1.2
		local amb = rb <= 0.9 and Color3.fromRGB(78, 78, 86) or Color3.fromRGB(112, 108, 104)
		base = {
			Ambient = amb,
			OutdoorAmbient = amb,
			EnvironmentDiffuseScale = 0.5,
			EnvironmentSpecularScale = 0.25,
		}
	end
	for k, v in def.Lighting or {} do
		base[k] = v
	end
	self:applyLighting(base)
	-- level ambience / music, from an emitter in the middle of the level
	local depth = level:GetAttribute("Depth") or 80
	local emitter = Instance.new("Part")
	emitter.Name = "SoundEmitter"
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.CanTouch = false
	emitter.Transparency = 1
	emitter.Size = Vector3.new(1, 1, 1)
	emitter.Position = self.origin + Vector3.new(0, 10, depth / 2)
	emitter.Parent = level
	self.emitter = emitter
	local range = math.max(90, depth * 0.9)
	for _, a in def.Ambience or {} do
		Audio.loop(emitter, a[1], a[2] or 0.4, a[3] or range)
	end
	-- the level's own track (Audio.MUSIC), even across the whole level
	local musicId = def.Music ~= false and Audio.MUSIC[level:GetAttribute("LevelModule") or ""]
	if musicId then
		local span = math.max(self.boundsMax.X - self.boundsMin.X, depth)
		local musicRange = math.clamp(span * 0.6 + 20, 80, 220)
		self.music = Audio.music(emitter, musicId, def.MusicVolume or 0.5, musicRange)
	end
	-- nothing keeps playing once the level is over
	self:onCleanup(function()
		for _, snd in emitter:GetDescendants() do
			if snd:IsA("Sound") then
				snd:Stop()
			end
		end
	end)
	self.exitDoor = level:FindFirstChild("ExitDoor")

	if def.Run then
		task.spawn(def.Run, self)
	end

	while not self.ended do
		-- the Studio level browser asks a level to stop early (cleanups still run)
		if level:GetAttribute("Abort") then
			self:endLevel("SKIPPED")
			break
		end
		if self.triggerDirty then
			self:_rebuildTriggerParams()
		end
		if not self.startTime then
			local anyone = next(self.entered) ~= nil
			if anyone or os.clock() - self.loadTime > WALK_TIME then
				self.startTime = os.clock()
			end
		end
		local remaining = self:timeLeft()
		for _, mark in { 30, 10 } do
			if self.startTime and remaining <= mark and not self.warned[mark] and self.timeLimit > mark + 5 then
				self.warned[mark] = true
				local text = self.mode == "survive" and (mark .. " seconds to survive!") or (mark .. " seconds until the train leaves!")
				self:broadcast(text)
			end
		end
		self:_tick()
		-- escape levels: the exit door slides open as someone approaches it
		if self.exitDoor and not self.exitOpen and not def.ExitLocked and self.mode == "escape" then
			local doorPos = self.exitDoor:GetPivot().Position
			for _, p in self:activeInside() do
				local r = rootOf(p)
				if r and (r.Position - doorPos).Magnitude < 40 then
					self:openExit()
					break
				end
			end
		end
		local reason = self:_checkEnd()
		if reason then
			self:endLevel(reason)
		elseif self.startTime and remaining <= 0 then
			if self.mode == "survive" then
				for _, p in self:participants() do
					if not self.eliminated[p] then
						Kit.notify(p, "You survived!", Color3.fromRGB(255, 220, 60))
					end
				end
				self:endLevel("SURVIVED!")
			elseif self.mode == "chill" then
				self:endLevel("ALL ABOARD!")
			else
				self:endLevel("TIME'S UP!")
			end
		end
		task.wait(0.05)
	end

	-- who cleared this stop (levelctrl turns this into Wins)
	local completed = {}
	for _, p in self:participants() do
		local ok
		if self.mode == "escape" then
			ok = self.finished[p]
		elseif self.mode == "collect" then
			ok = self.collected >= self.collectTarget and self.entered[p] and not self.eliminated[p]
		elseif self.mode == "survive" then
			ok = self.entered[p] and not self.eliminated[p]
		else
			ok = true
		end
		if ok then
			completed[p] = true
		end
	end
	RunState.completed = completed
	for _, p in self:participants() do
		RunState.respawnAt[p] = nil
	end
	for _, c in self.conns do
		c:Disconnect()
	end
	for _, fn in self.cleanups do
		local ok, err = pcall(fn)
		if not ok then
			warn("level cleanup failed:", err)
		end
	end
	if def.Finale and self.endReason ~= "SKIPPED" then
		pcall(def.Finale, self)
	end
	if level:GetAttribute("DevLevel") then
		-- loaded by the Studio level browser, not the train: report back to it
		level:SetAttribute("Ended", self.endReason or "ENDED")
		return
	end
	task.wait(1.5)
	print("LEVEL FINISHED:", def.Name or level.Name, self.endReason)
	game.ServerScriptService.LevelFinished:Fire()
end

return Kit
