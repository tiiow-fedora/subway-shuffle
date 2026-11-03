-- Clocks: turns the hands of every station clock (parts with a ClockHand
-- attribute, built by Decor.clock) to the player's own local time. Purely
-- visual and client-side, so it costs the server nothing.
local FACE_DIR = {
	["+Z"] = Vector3.new(0, 0, 1),
	["-Z"] = Vector3.new(0, 0, -1),
	["+X"] = Vector3.new(1, 0, 0),
	["-X"] = Vector3.new(-1, 0, 0),
}
local UP = Vector3.new(0, 1, 0)

local hands = {}
local function scan()
	hands = {}
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("ClockHand") then
			table.insert(hands, d)
		end
	end
end

local function place(hand, turns)
	local n = FACE_DIR[hand:GetAttribute("ClockFace") or "+Z"]
	local center = hand:GetAttribute("ClockCenter")
	local len = hand:GetAttribute("Len") or 1
	if not (n and center) then
		return
	end
	local a = turns * math.pi * 2
	local d = UP * math.cos(a) + UP:Cross(n) * math.sin(a)
	hand.CFrame = CFrame.fromMatrix(center + d * len / 2, d:Cross(n), d)
end

workspace.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") and d:GetAttribute("ClockHand") then
		table.insert(hands, d)
	end
end)
scan()

while true do
	local t = os.date("*t")
	local minutes = t.min + t.sec / 60
	local hours = (t.hour % 12) + minutes / 60
	for i = #hands, 1, -1 do
		local h = hands[i]
		if not h.Parent then
			table.remove(hands, i)
		elseif h:GetAttribute("ClockHand") == "hour" then
			place(h, hours / 12)
		else
			place(h, minutes / 60)
		end
	end
	task.wait(1)
end
