-- Verity's Ball Pit (easy): someone filled this platform with ball-pit balls.
-- Verity - the big yellow one with the smiley face - has a train to catch,
-- and it's waiting with its doors open. Find her in the pit and roll her
-- through the doors onto the train.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local TrainKit = require(root.TrainKit)
local Audio = require(root.Audio)
local PhysicsService = game:GetService("PhysicsService")
local C = BuildLib.C

local W, D = 90, 96
local TRACK_Z = 75
local TRAIN_X = -30
local BALL_COLORS = { Color3.fromRGB(230, 60, 60), Color3.fromRGB(50, 120, 230), Color3.fromRGB(60, 190, 90), Color3.fromRGB(240, 130, 40), Color3.fromRGB(170, 80, 220), Color3.fromRGB(240, 110, 170), Color3.fromRGB(40, 200, 210) }
local VERITY = Color3.fromRGB(255, 220, 40)

return {
	Order = 28,
	Name = "Verity's Ball Pit",
	Mode = "escape",
	TimeLimit = 100,
	Build = function(B)
		local RAIL = -TrainKit.floorAboveTrack() -- track level: train floor = platform
		local doors = TrainKit.doorOffsets(true)
		B:room({
			W = W,
			D = D,
			H = 26,
			wallColor = Color3.fromRGB(226, 220, 204),
			lowerColor = Color3.fromRGB(50, 110, 170),
			trim = Color3.fromRGB(240, 200, 40),
			floorColor = Color3.fromRGB(176, 170, 160),
			floorMat = Enum.Material.Marble,
			brightness = 1.4,
			sideHoles = { { side = -1, TRACK_Z - 11, TRACK_Z + 11, -8.01, 18 }, { side = 1, TRACK_Z - 11, TRACK_Z + 11, -8.01, 18 } },
			exit = false,
		})
		-- the track bed along the back, and the train waiting at the platform
		local floor = B:folder("Structure"):FindFirstChild("Floor")
		floor.Size = Vector3.new(floor.Size.X, floor.Size.Y, 63)
		floor.Position = B:w(Vector3.new(0, -floor.Size.Y / 2, 1 + 63 / 2))
		B:span(Vector3.new(-W / 2, RAIL - 2, 64), Vector3.new(W / 2, RAIL, D), { Name = "TrackBed", Color = Color3.fromRGB(70, 66, 60), Material = Enum.Material.Pebble })
		B:span(Vector3.new(-W / 2, RAIL, 63.4), Vector3.new(W / 2, 0, 64), { Name = "PlatformEdge", Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Concrete })
		B:span(Vector3.new(-W / 2, RAIL, 86), Vector3.new(W / 2, 0, D), { Name = "BackWalkway", Color = Color3.fromRGB(150, 146, 136), Material = Enum.Material.Concrete })
		Decor.track(B, Vector3.new(-W / 2 - 20, RAIL, TRACK_Z), Vector3.new(W / 2 + 20, RAIL, TRACK_Z), false)
		for _, side in { -1, 1 } do
			B:recess(side, TRACK_Z, 22, 24, 70, RAIL)
		end
		TrainKit.place(B, Vector3.new(TRAIN_X, RAIL, TRACK_Z - 1.6), { Name = "Train", Parent = "Structure", flip = true })
		-- the open doors glow yellow, with Verity's smiley on the floor in front
		for _, dx in doors do
			local x = TRAIN_X + dx
			B:part(Vector3.new(x, 0.03, 61.5), Vector3.new(6, 0.06, 4), { Color = VERITY, Material = Enum.Material.Neon, Transparency = 0.3, Parent = "Decor", CanCollide = false, Name = "DoorGlow", Light = { Range = 14, Brightness = 1.2, Color = VERITY } })
		end
		B:sign(Vector3.new(TRAIN_X + (doors[1] + doors[2]) / 2, 0.05, 56), Vector3.new(8, 0.04, 8), ":)", { Color = VERITY, TextColor = C.black, Face = Enum.NormalId.Top, Parent = "Decor", CanCollide = false, Font = Enum.Font.FredokaOne })
		-- low walls make the ball pit
		for _, spec in { { -W / 2, -W / 2 + 1, 1, 62 }, { W / 2 - 1, W / 2, 1, 62 }, { -W / 2, W / 2, 1, 2 } } do
			B:span(Vector3.new(spec[1], 0, spec[3]), Vector3.new(spec[2], 2.6, spec[4]), { Color = Color3.fromRGB(240, 110, 170), Name = "PitWall" })
		end
		-- an invisible fence along the platform edge that only Verity hits, with
		-- gaps at the two open doors, so she can't roll onto the tracks
		local gaps = {}
		for _, dx in doors do
			table.insert(gaps, TRAIN_X + dx)
		end
		table.sort(gaps)
		local x = -W / 2
		for _, gx in gaps do
			B:span(Vector3.new(x, 0, 62.6), Vector3.new(gx - 3.4, 8, 63.4), { Name = "VerityFence", Transparency = 1, CastShadow = false })
			x = gx + 3.4
		end
		B:span(Vector3.new(x, 0, 62.6), Vector3.new(W / 2, 8, 63.4), { Name = "VerityFence", Transparency = 1, CastShadow = false })
		-- the balls
		local rng = Random.new(28)
		for i = 1, 170 do
			local ball = B:ball(Vector3.new(rng:NextNumber(-42, 42), 1.5 + (i % 3) * 2.6, rng:NextNumber(5, 58)), 2.6, {
				Name = "Ball",
				Color = BALL_COLORS[rng:NextInteger(1, #BALL_COLORS)],
				Material = Enum.Material.SmoothPlastic,
				Parent = "Balls",
			})
			ball.Anchored = false
			ball.CustomPhysicalProperties = PhysicalProperties.new(0.4, 0.4, 0.5)
		end
		-- Verity
		local verity = B:ball(Vector3.new(30, 3, 46), 4.4, { Name = "Verity", Color = VERITY, Material = Enum.Material.SmoothPlastic, Parent = B.model })
		verity.Anchored = false
		verity.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.5, 0.4)
		local face = Instance.new("Decal")
		face.Texture = "rbxasset://textures/face.png"
		face.Face = Enum.NormalId.Front
		face.Parent = verity
		local glow = Instance.new("PointLight")
		glow.Color = VERITY
		glow.Range = 8
		glow.Brightness = 0.6
		glow.Parent = verity
		-- benches, a clock, ads
		for _, z in { 20, 44 } do
			Decor.advert(B, Vector3.new(-W / 2, 9, z), "+X")
			Decor.advert(B, Vector3.new(W / 2, 9, z), "-X")
		end
	end,
	Run = function(ctx)
		local level = ctx.level
		local verity = level.Verity
		local train = level.Structure.Train
		local cf, size = train:GetBoundingBox()
		-- collision groups: players walk through the pit walls and Verity's fence,
		-- balls stay in the pit, Verity stays in the pit or on the train
		for _, g in { "SS_Ball", "SS_Verity", "SS_PitWall", "SS_VerityFence" } do
			if not PhysicsService:IsCollisionGroupRegistered(g) then
				PhysicsService:RegisterCollisionGroup(g)
			end
		end
		PhysicsService:CollisionGroupSetCollidable("SS_PitWall", "Default", false)
		PhysicsService:CollisionGroupSetCollidable("SS_VerityFence", "Default", false)
		PhysicsService:CollisionGroupSetCollidable("SS_VerityFence", "SS_Ball", false)
		PhysicsService:CollisionGroupSetCollidable("SS_VerityFence", "SS_PitWall", false)
		for _, p in level.Structure:GetChildren() do
			if p.Name == "PitWall" then
				p.CollisionGroup = "SS_PitWall"
			elseif p.Name == "VerityFence" then
				p.CollisionGroup = "SS_VerityFence"
				p.CanQuery = false
				p.CanTouch = false
			end
		end
		for _, b in level.Balls:GetChildren() do
			b.CollisionGroup = "SS_Ball"
		end
		verity.CollisionGroup = "SS_Verity"
		local home = ctx:w(Vector3.new(0, 4, 30))
		local function reset()
			verity.CFrame = CFrame.new(home)
			verity.AssemblyLinearVelocity = Vector3.zero
			verity.AssemblyAngularVelocity = Vector3.zero
		end
		ctx:waitForStart()
		ctx:broadcast("Verity has a train to catch! Find her and roll her aboard.")
		-- she hops now and then so you can spot her
		ctx:every(4, function()
			if verity.Parent then
				verity.AssemblyLinearVelocity += Vector3.new(0, 30, 0)
			end
		end)
		ctx.def.Check = function()
			local rel = cf:PointToObjectSpace(verity.Position)
			local inside = math.abs(rel.X) < size.X / 2 - 2 and math.abs(rel.Z) < size.Z / 2 - 3 and rel.Y > -size.Y / 2
			if inside then
				Audio.play(verity, "ding", 1, 200)
				for _, p in ctx:participants() do
					ctx:finish(p, "Verity made her train!")
				end
				return "VERITY IS ABOARD"
			end
			-- if she ever leaves the pit / platform area, put her back
			local lp = verity.Position - ctx.origin
			local nearTrain = math.abs(rel.X) < size.X / 2 and math.abs(rel.Z) < size.Z / 2 + 3 and rel.Y > -size.Y / 2 - 3
			if not nearTrain and (lp.Y < -3 or lp.Y > 30 or math.abs(lp.X) > W / 2 or lp.Z < 0 or lp.Z > 64) then
				reset()
			end
			return nil
		end
	end,
}
