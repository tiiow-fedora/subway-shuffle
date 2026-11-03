-- Aura Farming (chill): a sunny canal-side park. The golden rings with light
-- rising out of them are aura spots: stand in one and you glow and your aura
-- goes up (your total floats over your head). The ring on the front of the
-- boat - where United7378 is busy aura farming - is worth five times as much.
-- Whoever has the most aura when the train comes is crowned Aura King.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local H = require(root.LevelHelpers)
local Decor = require(root.Decor)
local Kit = require(root.LevelKit)
local Audio = require(root.Audio)
local C = BuildLib.C

local W, D = 110, 124
local CANAL = { 54, 76 }
local GOLD = Color3.fromRGB(255, 205, 60)
local SPOTS = { Vector3.new(-30, 0, 20), Vector3.new(26, 0, 30), Vector3.new(-8, 0, 40), Vector3.new(34, 0, 92), Vector3.new(-36, 0, 100), Vector3.new(4, 0, 108) }

local function auraRing(B, pos, value, parent)
	local ring = B:cyl(pos + Vector3.new(0, 0.06, 0), 0.12, 7, "Y", { Name = "AuraSpot", Color = GOLD, Material = Enum.Material.Neon, Transparency = 0.15, CanCollide = false, Parent = parent, Attr = { Aura = value } })
	B:cyl(pos + Vector3.new(0, 0.08, 0), 0.12, 5.6, "Y", { Color = Color3.fromRGB(255, 240, 180), Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, Parent = ring, Name = "Inner" })
	local beam = Instance.new("ParticleEmitter")
	beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	beam.Color = ColorSequence.new(GOLD)
	beam.EmissionDirection = Enum.NormalId.Top
	beam.Rate = 25
	beam.Speed = NumberRange.new(4, 7)
	beam.Lifetime = NumberRange.new(1.2, 1.8)
	beam.Size = NumberSequence.new(0.4, 0.1)
	beam.SpreadAngle = Vector2.new(10, 10)
	beam.LightEmission = 1
	beam.Parent = ring
	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 10
	light.Brightness = 1
	light.Parent = ring
	return ring
end

return {
	Order = 32,
	Name = "Aura Farming",
	Mode = "chill",
	TimeLimit = 50,
	Ambience = { { "birds", 0.4 } },
	Lighting = { ClockTime = 15 },
	Build = function(B)
		B:room({ W = W, D = D, outdoor = true, pitsZ = { { CANAL[1], CANAL[2], 5, Color3.fromRGB(60, 70, 60) } }, exit = false })
		-- canal water
		B:span(Vector3.new(-W / 2 - 220, -5, CANAL[1] + 0.8), Vector3.new(W / 2 + 220, -1.6, CANAL[2] - 0.8), { Name = "CanalWater", Color = Color3.fromRGB(50, 120, 140), Material = Enum.Material.Glass, Transparency = 0.25, CanCollide = false, Attr = { Trigger = true } })
		-- a stone edge, jetties, a footbridge
		for _, z in { CANAL[1] - 0.6, CANAL[2] + 0.6 } do
			B:span(Vector3.new(-W / 2, -0.2, z - 0.6), Vector3.new(W / 2, 0.3, z + 0.6), { Color = Color3.fromRGB(190, 186, 176), Material = Enum.Material.Concrete, Name = "Coping" })
		end
		for _, x in { -24, 24 } do
			B:span(Vector3.new(x - 3, -0.2, CANAL[1] - 1), Vector3.new(x + 3, 0.2, CANAL[1] + 4), { Color = Color3.fromRGB(140, 100, 60), Material = Enum.Material.WoodPlanks, Name = "Jetty" })
		end
		B:span(Vector3.new(-42, 0, CANAL[1] - 1), Vector3.new(-36, 1, CANAL[2] + 1), { Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.WoodPlanks, Name = "Footbridge" })
		for _, x in { -42, -36 } do
			B:span(Vector3.new(x - 0.2, 1, CANAL[1] - 1), Vector3.new(x + 0.2, 3.4, CANAL[2] + 1), { Color = Color3.fromRGB(110, 80, 50), Material = Enum.Material.Wood, Name = "BridgeRail" })
		end
		-- paths
		B:span(Vector3.new(-3, -0.02, 1), Vector3.new(3, 0.06, CANAL[1] - 1.2), { Color = Color3.fromRGB(210, 196, 160), Material = Enum.Material.Sand, Name = "Path" })
		B:span(Vector3.new(-W / 2 + 4, -0.02, CANAL[1] - 6), Vector3.new(W / 2 - 4, 0.06, CANAL[1] - 2), { Color = Color3.fromRGB(210, 196, 160), Material = Enum.Material.Sand, Name = "Towpath" })
		-- the racing boat, drifting up and down the canal
		local boat = Instance.new("Model")
		boat.Name = "Boat"
		local zc = (CANAL[1] + CANAL[2]) / 2
		local hull = B:part(Vector3.new(0, -1.4, zc), Vector3.new(36, 1.6, 5), { Name = "Hull", Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.Wood, Parent = B.model })
		hull.Parent = boat
		for _, dz in { -2.4, 2.4 } do
			local rail = B:part(Vector3.new(0, -0.3, zc + dz), Vector3.new(36, 0.8, 0.3), { Color = C.red, Parent = B.model, Name = "Rail" })
			rail.Parent = boat
		end
		local ring = auraRing(B, Vector3.new(13, -0.6, zc), 5, B.model)
		ring.Parent = boat
		boat.PrimaryPart = hull
		boat:SetAttribute("MoveFrom", B:w(Vector3.new(-20, -1.4, zc)))
		boat:SetAttribute("MoveTo", B:w(Vector3.new(20, -1.4, zc)))
		boat:SetAttribute("Speed", 3)
		boat:SetAttribute("Pause", 2)
		boat.Parent = B:folder("Structure")
		local farmer = H.figure(B, Vector3.new(16.5, -0.6, zc), { Name = "AuraFarmer", Shirt = C.black, Pants = C.black, Avatar = "United7378", Label = "United7378" })
		farmer:PivotTo(farmer:GetPivot() * CFrame.Angles(0, math.rad(-90), 0))
		farmer:SetAttribute("RideBoat", true)
		-- where his feet go, relative to the hull (Run keeps him there)
		farmer:SetAttribute("HullFoot", Vector3.new(16.5, 0.8, 0))
		-- aura spots round the park
		for _, pos in SPOTS do
			auraRing(B, pos, 1, "Spots")
		end
		-- the leaderboard, across the canal just off the footbridge, facing the
		-- water so you can read it from either bank
		B:part(Vector3.new(-33, 3, 80), Vector3.new(0.6, 6, 0.6), { Color = Color3.fromRGB(110, 80, 50), Material = Enum.Material.Wood, Name = "BoardPost" })
		B:part(Vector3.new(-21, 3, 80), Vector3.new(0.6, 6, 0.6), { Color = Color3.fromRGB(110, 80, 50), Material = Enum.Material.Wood, Name = "BoardPost" })
		B:sign(Vector3.new(-27, 7.5, 80), Vector3.new(12, 6, 0.5), "AURA", { Name = "AuraBoard", Color = Color3.fromRGB(110, 80, 50), TextColor = Color3.fromRGB(255, 240, 200), Face = Enum.NormalId.Front, Font = Enum.Font.FredokaOne })
		-- trees, flowerbeds, benches and lamps
		local rng = Random.new(32)
		for _, pos in { Vector3.new(-44, 0, 14), Vector3.new(44, 0, 18), Vector3.new(-16, 0, 30), Vector3.new(40, 0, 44), Vector3.new(-48, 0, 88), Vector3.new(18, 0, 100), Vector3.new(-20, 0, 116), Vector3.new(46, 0, 112) } do
			B:tree(pos, rng:NextNumber(1, 1.3))
		end
		for _, pos in { Vector3.new(14, 0, 14), Vector3.new(-22, 0, 86), Vector3.new(22, 0, 82) } do
			B:cyl(pos + Vector3.new(0, 0.4, 0), 0.8, 7, "Y", { Color = Color3.fromRGB(120, 90, 60), Material = Enum.Material.Ground, Name = "Flowerbed" })
			for k = 0, 7 do
				local a = k / 8 * math.pi * 2
				B:ball(pos + Vector3.new(math.cos(a) * 2.3, 1.1, math.sin(a) * 2.3), 0.9, { Color = ({ C.red, C.yellow, C.pink, C.purple })[k % 4 + 1], Parent = "Decor", CanCollide = false, Name = "Flower" })
			end
		end
		for _, pos in { Vector3.new(-12, 0, 48), Vector3.new(12, 0, 48), Vector3.new(-10, 0, 84), Vector3.new(10, 0, 84) } do
			Decor.bench(B, pos, pos.Z < 60 and 180 or 0)
		end
		for _, pos in { Vector3.new(-6, 0, 48), Vector3.new(6, 0, 82) } do
			B:part(pos + Vector3.new(0, 4.5, 0), Vector3.new(0.4, 9, 0.4), { Color = Color3.fromRGB(40, 50, 40), Material = Enum.Material.Metal, Name = "LampPost" })
			B:ball(pos + Vector3.new(0, 9.3, 0), 1.2, { Color = Color3.fromRGB(255, 240, 210), Material = Enum.Material.Neon, Parent = "Decor", CanCollide = false, Name = "Globe" })
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local aura = {}
		local tags, glows = {}, {}
		local board = level.Signs.AuraBoard:FindFirstChild("Label", true)
		local spots = {}
		for _, d in level:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "AuraSpot" then
				table.insert(spots, d)
			end
		end
		-- the farmer rides on the boat. The real avatar is swapped in at the
		-- build-time FootPos, but the boat has moved since, so pin his feet to
		-- a hull-relative spot every frame (and get him dancing once he's real)
		local hull = level.Structure.Boat.Hull
		local rider, foot, dancing -- the instance we're carrying (the swap replaces it)
		ctx:heartbeat(function()
			local farmer = level.Decor:FindFirstChild("AuraFarmer")
			if not farmer then
				return
			end
			if farmer ~= rider then
				rider, foot, dancing = farmer, farmer:GetAttribute("FootPos"), false
			end
			local rel = farmer:GetAttribute("HullFoot")
			if not rel or not foot then
				return
			end
			local want = hull.CFrame:PointToWorldSpace(rel)
			if (want - foot).Magnitude > 0.001 then
				farmer:PivotTo(farmer:GetPivot() + (want - foot))
				foot = want
			end
			if not dancing and farmer:FindFirstChildOfClass("Humanoid") then
				dancing = Kit.playAnim(farmer, "dance") ~= nil
			end
		end)
		local function tagFor(player, rootPart)
			local t = tags[player]
			if t and t.Parent == rootPart then
				return t
			end
			t = Instance.new("BillboardGui")
			t.Name = "AuraTag"
			t.Size = UDim2.fromOffset(160, 40)
			t.StudsOffset = Vector3.new(0, 4.2, 0)
			t.AlwaysOnTop = true
			local l = Instance.new("TextLabel")
			l.Size = UDim2.fromScale(1, 1)
			l.BackgroundTransparency = 1
			l.Font = Enum.Font.FredokaOne
			l.TextScaled = true
			l.TextColor3 = GOLD
			l.TextStrokeTransparency = 0.3
			l.Text = "0 aura"
			l.Parent = t
			t.Parent = rootPart
			tags[player] = t
			return t
		end
		local function glow(player, rootPart, on)
			local g = glows[player]
			if not g or g.Parent ~= rootPart then
				g = Instance.new("ParticleEmitter")
				g.Name = "Aura"
				g.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				g.Color = ColorSequence.new(GOLD)
				g.LightEmission = 1
				g.Rate = 0
				g.Speed = NumberRange.new(2, 4)
				g.Lifetime = NumberRange.new(0.8, 1.2)
				g.Size = NumberSequence.new(0.5, 0.1)
				g.SpreadAngle = Vector2.new(180, 180)
				g.Parent = rootPart
				glows[player] = g
			end
			g.Rate = on and 40 or 0
		end
		ctx:onCleanup(function()
			for _, t in tags do
				t:Destroy()
			end
			for _, g in glows do
				g:Destroy()
			end
			for p in tags do
				Kit.forceDance(p, false)
			end
		end)
		-- fell in the canal: out you come, minus a lot of aura
		ctx.def.OnTrigger = function(_, player)
			aura[player] = (aura[player] or 0) - 500
			Kit.notify(player, "-500 aura")
			Audio.play(ctx:w(Vector3.new(0, 0, 60)), "splash", 0.6, 100)
			player.Character:PivotTo(CFrame.new(ctx:w(Vector3.new(math.random(-10, 10), 3, 44))))
		end
		ctx:every(0.5, function()
			for _, p in ctx:participants() do
				local r = Kit.rootOf(p)
				if r then
					local gain = 0
					for _, s in spots do
						local flat = Vector3.new(r.Position.X - s.Position.X, 0, r.Position.Z - s.Position.Z)
						if flat.Magnitude < 3.6 and math.abs(r.Position.Y - s.Position.Y) < 6 then
							gain += 25 * s:GetAttribute("Aura")
						end
					end
					glow(p, r, gain > 0)
					Kit.forceDance(p, gain > 0)
					if gain > 0 then
						aura[p] = (aura[p] or 0) + gain
						Audio.play(r, "pickup", 0.2, 30)
					end
					tagFor(p, r).TextLabel.Text = (aura[p] or 0) .. " aura"
				end
			end
			local rows = {}
			for p, v in aura do
				table.insert(rows, { p.DisplayName, v })
			end
			table.sort(rows, function(a, b)
				return a[2] > b[2]
			end)
			local lines = { "AURA" }
			for i = 1, math.min(4, #rows) do
				table.insert(lines, string.format("%d. %s  %d", i, rows[i][1], rows[i][2]))
			end
			board.Text = table.concat(lines, "\n")
		end)
		ctx.def.Finale = function()
			local best, who = -math.huge, nil
			for p, v in aura do
				if v > best then
					best, who = v, p
				end
			end
			if who then
				ctx:broadcast(who.DisplayName .. " is the AURA KING with " .. best .. " aura!")
			end
		end
	end,
}
