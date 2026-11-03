-- Runs a Subway Shuffle level. The level's logic lives in
-- ServerStorage.SubwayShuffle.Levels[<LevelModule attribute>]; this just hands
-- the cloned level Model to the shared LevelKit.
local root = game:GetService("ServerStorage"):WaitForChild("SubwayShuffle")
local level = script.Parent
local def = require(root.Levels[level:GetAttribute("LevelModule")])
require(root.LevelKit).start(level, def)
