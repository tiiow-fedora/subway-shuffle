-- Pick a Door (easy): five rooms, each ending in three doors. Walk up to a
-- door: the right one slides open (green light) and stays open for everyone;
-- a wrong one lights red and the trapdoor in front of it drops you back to
-- the start of that room.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local Decor = require(root.Decor)
local Audio = require(root.Audio)
local C = BuildLib.C

local W = 44
local ROOMS = 5
local DEPTH = 26
local D = ROOMS * DEPTH + 10
local DOOR_X = { -12, 0, 12 }
local THEMES = {
	{ wall = Color3.fromRGB(220, 200, 200), lower = Color3.fromRGB(160, 50, 50) },
	{ wall = Color3.fromRGB(200, 210, 230), lower = Color3.fromRGB(50, 80, 160) },
	{ wall = Color3.fromRGB(205, 225, 205), lower = Color3.fromRGB(50, 130, 70) },
	{ wall = Color3.fromRGB(225, 215, 195), lower = Color3.fromRGB(190, 130, 40) },
	{ wall = Color3.fromRGB(215, 205, 230), lower = Color3.fromRGB(110, 60, 160) },
}

return {
	Order = 22,
	Name = "Pick a Door",
	Mode = "escape",
	TimeLimit = 110,
	KillY = -6,
	FallEliminates = false,
	Ambience = { { "stationAmbience", 0.25 } },
	Build = function(B)
		B:room({
			W = W,
			D = D,
			H = 18,
			floor = false,
			bottom = -14,
			wallColor = Color3.fromRGB(226, 220, 206),
			lowerColor = Color3.fromRGB(60, 60, 66),
			trim = Color3.fromRGB(230, 180, 40),
			brightness = 1.3,
			exit = { x = 0, y = 0 },
		})
		local DW = B.DOOR_W
		for k = 1, ROOMS do
			local z0 = (k - 1) * DEPTH + 1
			local wz = k * DEPTH -- the door wall
			local th = THEMES[k]
			-- floor of this room, with a trapdoor hole in front of each door
			local holes = {}
			for _, x in DOOR_X do
				table.insert(holes, { x - 3, x + 3 })
			end
			table.sort(holes, function(a, b)
				return a[1] < b[1]
			end)
			local floorProps = { Color = th.lower:Lerp(Color3.new(1, 1, 1), 0.55), Material = Enum.Material.Marble, Name = "Floor", Thick = 2 }
			B:floor(-W / 2, z0, W / 2, wz - 6, 0, floorProps)
			local x = -W / 2
			for _, h in holes do
				B:floor(x, wz - 6, h[1], wz, 0, floorProps)
				x = h[2]
			end
			B:floor(x, wz - 6, W / 2, wz, 0, floorProps)
			-- the wall with three doorways
			local wallHoles = {}
			for _, dx in DOOR_X do
				table.insert(wallHoles, { dx - DW / 2, dx + DW / 2, -0.01, B.DOOR_H })
			end
			if k < ROOMS then
				B:wallZ(wz, wz + 1, -W / 2, W / 2, -14, 18, wallHoles, { Color = th.wall, Material = Enum.Material.Concrete, Name = "DoorWall" })
				-- the coloured band along the wall stops at each doorway (and its frame)
				local bx = -W / 2
				for _, dx in DOOR_X do
					B:span(Vector3.new(bx, 0, wz - 0.3), Vector3.new(dx - DW / 2 - 0.6, 4, wz), { Color = th.lower, Material = Enum.Material.Slate, Parent = "Decor", CanCollide = false, Name = "Band" })
					bx = dx + DW / 2 + 0.6
				end
				B:span(Vector3.new(bx, 0, wz - 0.3), Vector3.new(W / 2, 4, wz), { Color = th.lower, Material = Enum.Material.Slate, Parent = "Decor", CanCollide = false, Name = "Band" })
			end
			for i, dx in DOOR_X do
				-- trapdoor (hinged at the room side)
				local trap = B:part(Vector3.new(dx, -0.5, wz - 3), Vector3.new(6, 1, 6), {
					Name = "Trap" .. k .. "_" .. i,
					Color = th.lower,
					Material = Enum.Material.DiamondPlate,
					Parent = "Traps",
				})
				if k < ROOMS then
					local door = B:metalDoor(Vector3.new(dx, 0, wz + 0.5), "Door" .. k .. "_" .. i, B:folder("Doors"))
					door:SetAttribute("Room", k)
					door:SetAttribute("Slot", i)
					B:doorFrame(dx, 0, wz, -1, Color3.fromRGB(60, 62, 68))
					-- the number above the door and a little lamp
					B:sign(Vector3.new(dx, B.DOOR_H + 2.2, wz - 0.3), Vector3.new(2.2, 2.2, 0.4), tostring(4 - i), { -- 1 on the left as you face the doors (+X is screen-left)
						Color = th.lower,
						Face = Enum.NormalId.Front,
						Parent = "Decor",
						CanCollide = false,
					})
					B:part(Vector3.new(dx - 2.2, B.DOOR_H + 2.2, wz - 0.3), Vector3.new(0.7, 0.7, 0.4), { Name = "Lamp" .. k .. "_" .. i, Color = Color3.fromRGB(240, 220, 160), Material = Enum.Material.Neon, Parent = "Lamps", CanCollide = false })
					-- an invisible plate in front of the door that "knocks"
					B:part(Vector3.new(dx, 3, wz - 1.2), Vector3.new(DW, 6, 1), { Name = "Knock" .. k .. "_" .. i, Transparency = 1, CanCollide = false, Parent = "Knocks", Attr = { Trigger = true, Room = k, Slot = i } })
				end
			end
			if k == ROOMS then
				-- the last room has no door wall; its traps stay shut
				for _, t in B:folder("Traps"):GetChildren() do
					if t.Name:match("^Trap" .. k .. "_") then
						t.Color = Color3.fromRGB(150, 146, 140)
					end
				end
			end
			-- checkpoint in the middle of the room, well clear of the doors
			B:checkpoint(Vector3.new(0, 0.1, z0 + 10), Vector3.new(6, 0.2, 5))
			-- a bit of furniture so each room has its own character
			Decor.bench(B, Vector3.new(-W / 2 + 2.2, 0, z0 + 10), 90)
			Decor.plant(B, Vector3.new(W / 2 - 3, 0, z0 + 4))
			Decor.advert(B, Vector3.new(W / 2, 8, z0 + 12), "-X")
		end
		-- the hall beyond the last room, up to the exit
		B:floor(-W / 2, ROOMS * DEPTH, W / 2, D, 0, { Color = Color3.fromRGB(190, 186, 176), Material = Enum.Material.Marble, Name = "Floor", Thick = 2 })
	end,
	Run = function(ctx)
		local level = ctx.level
		local answer, solved = {}, {}
		for k = 1, ROOMS - 1 do
			answer[k] = math.random(1, 3)
		end
		local busy = {}
		local function find(folder, name)
			return level[folder]:FindFirstChild(name)
		end
		ctx.def.OnTrigger = function(_, player, plate)
			local k, slot = plate:GetAttribute("Room"), plate:GetAttribute("Slot")
			if solved[k] or (busy[player] and os.clock() - busy[player] < 2) then
				return
			end
			busy[player] = os.clock()
			local door = find("Doors", "Door" .. k .. "_" .. slot)
			local lamp = find("Lamps", "Lamp" .. k .. "_" .. slot)
			if slot == answer[k] then
				solved[k] = true
				lamp.Color = Color3.fromRGB(60, 230, 90)
				plate.CanTouch = false
				plate:SetAttribute("Trigger", nil)
				Audio.play(plate, "doorOpen", 0.8)
				-- swings open on its hinge into the next room
				local start = door:GetPivot()
				local h = CFrame.new(door:GetAttribute("Hinge"))
				local angle = math.rad(door:GetAttribute("OpenAngle") or -90)
				task.spawn(function()
					for i = 1, 30 do
						local a = i / 30
						a = a * a * (3 - 2 * a)
						door:PivotTo(h * CFrame.Angles(0, angle * a, 0) * h:Inverse() * start)
						task.wait(1 / 30)
					end
				end)
				ctx:broadcast(player.DisplayName .. " found the right door!")
			else
				lamp.Color = Color3.fromRGB(230, 50, 40)
				Audio.play(plate, "buzzer", 0.6)
				-- the trapdoor swings open under them
				local trap = find("Traps", "Trap" .. k .. "_" .. slot)
				local home = trap.CFrame
				local hinge = home * CFrame.new(0, 0, -3)
				task.spawn(function()
					for i = 1, 10 do
						trap.CFrame = hinge * CFrame.Angles(math.rad(9 * i), 0, 0) * CFrame.new(0, 0, 3) -- free edge swings down
						task.wait(1 / 30)
					end
					trap.CanCollide = false
					task.wait(1.6)
					trap.CanCollide = true
					trap.CFrame = home
				end)
			end
		end
		-- fell through a trapdoor: back to the start of the room
		ctx.def.OnPlayerTick = function(_, player, rootPart)
			if rootPart.Position.Y < ctx.origin.Y - 4 then
				ctx:sendBack(player, "Wrong door!")
			end
		end
	end,
}
