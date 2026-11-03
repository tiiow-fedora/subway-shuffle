-- Shared run state. Every server Script requires this same table, so RunCtrl,
-- levelctrl and the level scripts all see the same riders/stop count.
local RunState = {
	active = false, -- a run is in progress (players are on the train)
	stop = 0, -- how many stations this run has visited
	riders = {}, -- [Player] = true for everyone on this run
	endRun = nil, -- unused (the ride loops forever)
	respawnAt = {}, -- [Player] = CFrame: where to put them next time they spawn
	completed = nil, -- set by LevelKit when a level ends: [Player] = true
}

-- The players a level should care about. Outside a run (e.g. a Studio test of a
-- single level) that's simply everyone in the server.
function RunState.participants()
	local list = {}
	if RunState.active then
		for player in RunState.riders do
			if player.Parent then
				table.insert(list, player)
			end
		end
	else
		list = game:GetService("Players"):GetPlayers()
	end
	return list
end

return RunState
