-- AdRotator: spreads the advert decals out so every ad gets a turn (the
-- train used to have the same Bloxy Cola ad five times), and rotates them
-- every so often like real digital ad panels.
local ServerStorage = game:GetService("ServerStorage")
local Ads = require(ServerStorage:WaitForChild("SubwayShuffle"):WaitForChild("Ads"))

local train = workspace:WaitForChild("SubwayTrain")

-- the real train and the copy waiting at the lobby platform
local trainAds = {}
local lobby = workspace:FindFirstChild("Lobby")
for _, model in { train, lobby and lobby:FindFirstChild("LobbyTrain") } do
	for _, d in model:GetDescendants() do
		if d:IsA("Decal") and Ads.isAd(d.Texture) then
			table.insert(trainAds, d)
		end
	end
end

local pool = table.clone(Ads.POOL)
local function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
end
shuffle(pool)

local offset = 0
local function assignTrain()
	for i, d in trainAds do
		d.Texture = pool[(i + offset - 1) % #pool + 1]
	end
end
assignTrain()

local function shuffleBoards()
	for _, p in workspace:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("AdBoard") then
			local d = p:FindFirstChildOfClass("Decal")
			if d then
				d.Texture = Ads.random()
			end
		end
	end
end

shuffleBoards()
while true do
	task.wait(30)
	offset += 1
	assignTrain()
	shuffleBoards()
end
