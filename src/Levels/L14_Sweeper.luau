-- The Sweeper (hard-ish, survive): everyone gets their own podium in a ring
-- around the sweeper, inside a glass tube - you can jump, but you can't walk
-- off. Two bars sweep round - a low one to jump and a second one later on -
-- and they speed up. Get hit and you're out: straight to the spectator
-- balcony. Last one standing wins (or survive the clock if you're alone).
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local H = require(root.LevelHelpers)
local Kit = require(root.LevelKit)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 90, 100
local CENTER = Vector3.new(0, 0, 54)
local RING = 18
local PODIUMS = 16 -- one each for a full server
local ARM_LEN = 21 -- reaches from the hub (r = 4) past the ring
local TUBE_R = 2.9

return {
	Order = 14,
	Name = "The Sweeper",
	Mode = "survive",
	TimeLimit = 60,
	KillY = -12,
	Ambience = { { "crowd", 0.5 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 34,
			floor = false,
			bottom = -40,
			wallColor = Color3.fromRGB(60, 70, 110),
			wallMat = Enum.Material.SmoothPlastic,
			lowerColor = Color3.fromRGB(30, 34, 60),
			trim = Color3.fromRGB(255, 200, 40),
			trimNeon = true,
			brightness = 1.4,
			exit = false,
		})
		-- entry balcony (you get teleported to the arena from here)
		B:span(Vector3.new(-12, -4, 1), Vector3.new(12, 0, 14), { Name = "Balcony", Color = Color3.fromRGB(80, 84, 96), Material = Enum.Material.DiamondPlate })
		for _, x in { -12, 12 } do
			B:part(Vector3.new(x, 1.5, 7.5), Vector3.new(0.4, 3, 13), { Color = C.yellow, Name = "BalconyRail" })
		end
		B:part(Vector3.new(0, 1.5, 14), Vector3.new(24, 3, 0.4), { Color = C.yellow, Name = "BalconyRail" })
		-- the hub
		B:cyl(CENTER + Vector3.new(0, -10, 0), 24, 8, "Y", { Name = "Hub", Color = Color3.fromRGB(220, 60, 50), Material = Enum.Material.SmoothPlastic })
		B:cyl(CENTER + Vector3.new(0, 2.3, 0), 0.6, 8.6, "Y", { Name = "HubCap", Color = C.yellow, Material = Enum.Material.Neon, Parent = "Decor" })
		-- podiums on columns, each inside a glass tube (eight panes) that the
		-- bars pass straight through but players can't leave
		for i = 1, PODIUMS do
			local a = (i - 1) / PODIUMS * math.pi * 2
			local pos = CENTER + Vector3.new(math.cos(a) * RING, 0, math.sin(a) * RING)
			B:cyl(pos + Vector3.new(0, -0.5, 0), 1, 5.6, "Y", { Name = "Podium" .. i, Color = ({ C.blue, C.green, C.orange, C.purple })[i % 4 + 1], Material = Enum.Material.SmoothPlastic, Parent = "Podiums", Attr = { Angle = a } })
			B:cyl(pos + Vector3.new(0, -16, 0), 30, 2.6, "Y", { Name = "Column", Color = Color3.fromRGB(200, 200, 210), Material = Enum.Material.Metal })
			for k = 0, 7 do
				local pa = k / 8 * math.pi * 2
				local pane = B:part(pos + Vector3.new(math.cos(pa) * TUBE_R, 7, math.sin(pa) * TUBE_R), Vector3.new(0.2, 14, TUBE_R * 0.83), {
					Name = "Tube",
					Color = Color3.fromRGB(190, 220, 240),
					Material = Enum.Material.Glass,
					Transparency = 0.82,
					CastShadow = false,
					Parent = "Tubes",
					Rot = Vector3.new(0, -math.deg(pa), 0),
				})
				pane.CanQuery = false
			end
			B:cyl(pos + Vector3.new(0, 14.1, 0), 0.2, TUBE_R * 2 + 0.4, "Y", { Name = "TubeRim", Color = C.yellow, Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false })
		end
		-- the spectator balcony label lights: where you go when you're out
		for _, x in { -11, 11 } do
			B:part(Vector3.new(x, 0.05, 8), Vector3.new(1, 0.06, 11), { Color = C.yellow, Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false, Name = "BalconyStrip" })
		end
		-- the two sweeper arms (positioned by Run)
		B:part(CENTER + Vector3.new(ARM_LEN / 2 + 4, 1.1, 0), Vector3.new(ARM_LEN, 1.2, 1.2), { Name = "ArmLow", Color = C.yellow, Material = Enum.Material.SmoothPlastic, Parent = B.model, CanCollide = false })
		B:part(CENTER + Vector3.new(ARM_LEN / 2 + 4, 1.1, 0), Vector3.new(ARM_LEN, 1.2, 1.2), { Name = "ArmTwo", Color = C.red, Material = Enum.Material.SmoothPlastic, Parent = B.model, CanCollide = false, Transparency = 1 })
		-- the stands: tiered seating all round with a crowd watching
		local rng = Random.new(14)
		for _, spec in { { -1, -W / 2 }, { 1, W / 2 } } do
			for tier = 0, 3 do
				local x = spec[2] - spec[1] * (3 + (3 - tier) * 3)
				B:span(Vector3.new(math.min(x, x - spec[1] * 3), -4, 20), Vector3.new(math.max(x, x - spec[1] * 3), 2 + tier * 2.5, D - 6), { Color = Color3.fromRGB(70, 74, 90), Material = Enum.Material.Concrete, Name = "Tier" })
				for z = 24, D - 10, 7 do
					if rng:NextNumber() < 0.55 then
						local npc = H.npc(B, Vector3.new(x - spec[1] * 1.5, 2 + tier * 2.5, z + rng:NextNumber(-1, 1)), rng:NextNumber() < 0.5 and "noob" or "guest", spec[1] < 0 and -90 or 90, { Name = "Fan", Parent = "Crowd" })
						npc:SetAttribute("Anim", "idle")
					end
				end
			end
		end
		-- spotlights on the ceiling pointing at the arena
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			B:part(CENTER + Vector3.new(math.cos(a) * 24, 32, math.sin(a) * 24), Vector3.new(1.6, 1.6, 1.6), {
				Name = "Spot",
				Color = C.black,
				Parent = "Decor",
				CanCollide = false,
				Light = { Kind = "SpotLight", Range = 50, Brightness = 4, Color = ({ C.yellow, C.cyan, C.pink })[k % 3 + 1], Face = Enum.NormalId.Bottom, Angle = 45 },
			})
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local center = ctx:w(CENTER + Vector3.new(0, 1.1, 0))
		local low, two = level.ArmLow, level.ArmTwo
		local podiums = {}
		for _, p in level.Podiums:GetChildren() do
			table.insert(podiums, p)
		end
		table.sort(podiums, function(a, b)
			return a:GetAttribute("Angle") < b:GetAttribute("Angle")
		end)
		-- the bars start (and park) halfway between two podiums
		local a1, a2 = math.pi / PODIUMS, math.pi + math.pi / PODIUMS
		local function placeArms()
			low.CFrame = CFrame.new(center) * CFrame.Angles(0, a1, 0) * CFrame.new(ARM_LEN / 2 + 4, 0, 0)
			two.CFrame = CFrame.new(center) * CFrame.Angles(0, a2, 0) * CFrame.new(ARM_LEN / 2 + 4, 0, 0)
		end
		placeArms()
		local balcony = ctx:w(Vector3.new(0, 3, 8))
		local started = false
		local seat = {} -- player -> podium
		local taken = {}
		local count = 0
		-- the angle between a podium and a bar (on the XZ plane, 0..pi)
		local function gap(p, armAngle)
			-- CFrame.Angles(0, a, 0) points the arm along (cos a, 0, -sin a)
			local d = (p.Position - center) * Vector3.new(1, 0, 1)
			local pa = math.atan2(-d.Z, d.X)
			local diff = (pa - armAngle) % (math.pi * 2)
			return math.min(diff, math.pi * 2 - diff)
		end
		local function toBalcony(player, why)
			ctx.eliminated[player] = true
			Kit.notify(player, "__fade")
			if why then
				Kit.notify(player, why)
			end
			task.delay(0.25, function()
				if player.Character then
					player.Character:PivotTo(CFrame.lookAt(balcony + Vector3.new(math.random(-8, 8), 0, math.random(-3, 3)), center))
				end
			end)
		end
		-- everyone who walks in gets their own podium (never one a bar is near);
		-- anyone arriving once the bars are going watches from the balcony
		ctx.def.OnEnter = function(_, player)
			if seat[player] or ctx.eliminated[player] then
				return
			end
			if started then
				toBalcony(player, "The round's already started - watch from the balcony!")
				return
			end
			local best
			for _, p in podiums do
				if not taken[p] and gap(p, a1) > 0.3 and (two.Transparency > 0 or gap(p, a2) > 0.3) then
					best = p
					break
				end
			end
			if not best then
				toBalcony(player, "All podiums are taken - watch from the balcony!")
				return
			end
			taken[best] = player
			seat[player] = best
			count += 1
			Kit.notify(player, "__fade")
			task.wait(0.3)
			-- put them on it, and keep them there until the round starts: a
			-- respawn or a late teleport (e.g. the level browser) could leave a
			-- player standing at the door instead of on their podium
			while not started and not ctx.ended and player.Parent and seat[player] == best do
				local root = Kit.rootOf(player)
				if root then
					local flat = (root.Position - best.Position) * Vector3.new(1, 0, 1)
					if flat.Magnitude > TUBE_R + 0.5 or root.Position.Y < best.Position.Y - 2 then
						player.Character:PivotTo(CFrame.lookAt(best.Position + Vector3.new(0, 3.6, 0), center))
					end
				end
				task.wait(0.5)
			end
		end
		-- a hit takes you out: straight to the spectator balcony
		ctx.def.OnHazard = function(_, player)
			if ctx.eliminated[player] then
				return
			end
			Audio.play(center, "buzzer", 0.4, 120)
			toBalcony(player, "Swept! You're out - watch from the balcony.")
		end
		-- last one standing
		ctx.def.Check = function()
			if not started or count < 2 then
				return nil
			end
			local left = {}
			for player in seat do
				if player.Parent and not ctx.eliminated[player] then
					table.insert(left, player)
				end
			end
			if #left <= 1 then
				if left[1] then
					ctx:broadcast(left[1].DisplayName .. " is the last one standing!")
					Kit.notify(left[1], "You win!", Color3.fromRGB(255, 220, 60))
				end
				return "WINNER"
			end
			return nil
		end
		ctx:waitForStart()
		task.wait(5)
		started = true
		ctx:setHazard(low, true)
		ctx:broadcast("Here it comes - jump!")
		ctx:heartbeat(function(dt)
			local frac = math.clamp(ctx:elapsed() / ctx.timeLimit, 0, 1)
			a1 += math.rad(50 + 80 * frac) * dt
			if frac > 0.4 then
				if two.Transparency > 0 then
					two.Transparency = 0
					ctx:setHazard(two, true)
					ctx:broadcast("A second sweeper!")
				end
				a2 -= math.rad(35 + 50 * frac) * dt
			end
			placeArms()
		end)
	end,
}
