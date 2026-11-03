-- Blackout (medium): the power's gone in the service corridors. You get a
-- torch; find the glowing green EXIT somewhere at the back of the maze.
local root = script.Parent.Parent
local BuildLib = require(root.BuildLib)
local H = require(root.LevelHelpers)
local Decor = require(root.Decor)

local COLS, ROWS, CELL = 9, 9, 11
local OX, OZ = -COLS * CELL / 2, 9
local D = OZ + ROWS * CELL
local EXIT_COL = 8

return {
	Order = 9,
	Name = "Blackout",
	Mode = "escape",
	TimeLimit = 120,
	Ambience = { { "eerie", 0.4 } },
	Build = function(B)
		local exitX = OX + (EXIT_COL - 0.5) * CELL
		B:room({
			W = COLS * CELL,
			D = D,
			H = 12,
			lamps = false,
			beams = false,
			wallColor = Color3.fromRGB(70, 72, 78),
			lowerColor = Color3.fromRGB(40, 40, 44),
			trim = Color3.fromRGB(200, 160, 40),
			floorColor = Color3.fromRGB(56, 56, 60),
			exit = { x = exitX, y = 0 },
		})
		B:checkpoint(Vector3.new(0, 0.1, 4.5), Vector3.new(6, 0.2, 5))
		local rng = Random.new(9)
		H.maze(COLS, ROWS, CELL, OX, OZ, 5, function(a, b)
			return H.wallBetween(B, a, b, 12, 1, { Color = Color3.fromRGB(84, 86, 92), Material = Enum.Material.Concrete, Name = "MazeWall" })
		end, rng)
		-- dim red emergency lamps, some flickering, and the odd fallen cable
		for _ = 1, 16 do
			local c, r = rng:NextInteger(1, COLS), rng:NextInteger(1, ROWS)
			B:lamp(Vector3.new(OX + (c - 0.5) * CELL, 11.6, OZ + (r - 0.5) * CELL), Vector3.new(1.4, 0.3, 1.4), {
				Color = Color3.fromRGB(200, 30, 30),
				Range = 12,
				Brightness = 0.9,
				Glow = true,
				Flicker = rng:NextNumber() < 0.5,
			})
		end
		for _ = 1, 8 do
			local c, r = rng:NextInteger(1, COLS), rng:NextInteger(2, ROWS)
			B:part(Vector3.new(OX + (c - 0.5) * CELL + rng:NextNumber(-2, 2), 0.15, OZ + (r - 0.5) * CELL), Vector3.new(rng:NextNumber(3, 6), 0.3, 0.3), {
				Color = Color3.fromRGB(20, 20, 20),
				Rot = Vector3.new(0, rng:NextNumber(0, 180), 0),
				Parent = "Decor",
				CanCollide = false,
				Name = "Cable",
			})
		end
		-- the corridor in front of the exit glows green, so you know when you're close
		B:lamp(Vector3.new(exitX, 11.6, D - CELL / 2), Vector3.new(2, 0.3, 2), { Color = Color3.fromRGB(60, 255, 120), Range = 20, Brightness = 1.4, Glow = true })
	end,
	Run = function(ctx)
		ctx:darken(Color3.fromRGB(10, 10, 14))
		ctx:giveLights(48)
	end,
}
