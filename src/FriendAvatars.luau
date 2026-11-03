-- FriendAvatars: swaps placeholder NPC figures for real Roblox avatars.
-- A builder marks a figure Model with the attribute AvatarOf = "<name>". At
-- runtime swapAll(container) resolves each name - first against the owner's
-- friends list (matching username OR display name, ignoring spaces/case), then
-- as a plain username - and replaces the blocky figure with that avatar.
-- If anything fails the blocky figure simply stays.
local Players = game:GetService("Players")

local FriendAvatars = {}

-- the game owner; friends are looked up from this account
FriendAvatars.OWNER = "tiiow"

local idCache = {} -- normalized name -> userId | false
local descCache = {} -- userId -> HumanoidDescription
local friendsLoaded = false
local friendIndex = {} -- normalized username/displayname -> {id, display}

local function norm(s)
	return (string.lower(s):gsub("[%s_%-%.]", ""))
end

local function ownerId()
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId > 0 then
		return game.CreatorId
	end
	local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, FriendAvatars.OWNER)
	return ok and id or nil
end

local function loadFriends()
	if friendsLoaded then
		return
	end
	friendsLoaded = true
	local id = ownerId()
	if not id then
		return
	end
	friendIndex[norm(FriendAvatars.OWNER)] = { id = id, display = FriendAvatars.OWNER }
	local ok, pages = pcall(Players.GetFriendsAsync, Players, id)
	if not ok then
		warn("FriendAvatars: couldn't read friends list:", pages)
		return
	end
	while true do
		for _, f in pages:GetCurrentPage() do
			local entry = { id = f.Id, display = f.DisplayName or f.Username }
			friendIndex[norm(f.Username)] = entry
			if f.DisplayName then
				friendIndex[norm(f.DisplayName)] = friendIndex[norm(f.DisplayName)] or entry
			end
		end
		if pages.IsFinished then
			break
		end
		local okNext = pcall(pages.AdvanceToNextPageAsync, pages)
		if not okNext then
			break
		end
	end
end

function FriendAvatars.resolve(name)
	local key = norm(name)
	if idCache[key] ~= nil then
		return idCache[key] or nil
	end
	loadFriends()
	local entry = friendIndex[key]
	if entry then
		idCache[key] = entry
		return entry
	end
	local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, (name:gsub("%s", "")))
	if ok and id then
		idCache[key] = { id = id, display = name }
	else
		idCache[key] = false
	end
	return idCache[key] or nil
end

local function makeAvatar(entry)
	local desc = descCache[entry.id]
	if not desc then
		local ok, d = pcall(Players.GetHumanoidDescriptionFromUserId, Players, entry.id)
		if not ok then
			return nil
		end
		desc = d
		descCache[entry.id] = d
	end
	local ok, model = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, Enum.HumanoidRigType.R15)
	if not ok then
		return nil
	end
	return model
end

-- Replace one placeholder figure. Returns the new model or nil.
function FriendAvatars.swap(fig)
	local name = fig:GetAttribute("AvatarOf")
	if not name then
		return nil
	end
	local entry = FriendAvatars.resolve(name)
	if not entry then
		return nil
	end
	local avatar = makeAvatar(entry)
	if not avatar then
		return nil
	end
	local scale = fig:GetAttribute("AvatarScale") or 1
	avatar.Name = fig.Name
	local hum = avatar:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayName = fig:GetAttribute("AvatarLabel") or entry.display
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
		hum.NameDisplayDistance = 50
		hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	end
	-- only the root is anchored; the body hangs off it by its joints so the
	-- idle animation can play (and nothing ends up crushed into the torso)
	-- keep the avatar's own animations (idle, walk, dances, wave, cheer) as
	-- attributes so levels can make friends walk about or dance (Kit.playAnim)
	local idleId
	local animate = avatar:FindFirstChild("Animate")
	local anims = {}
	if animate then
		for _, kind in { "idle", "walk", "run", "wave", "cheer", "dance", "dance2", "dance3", "point", "toolnone" } do
			local folder = animate:FindFirstChild(kind)
			local anim = folder and folder:FindFirstChildOfClass("Animation")
			if anim then
				anims[kind] = anim.AnimationId
			end
		end
		idleId = anims.idle
		animate:Destroy()
	end
	local rootPart = avatar:FindFirstChild("HumanoidRootPart")
	for _, p in avatar:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = p == rootPart
			p.CanCollide = false
		end
	end
	if hum then
		hum.EvaluateStateMachine = false
	end
	if scale ~= 1 then
		pcall(avatar.ScaleTo, avatar, scale)
	end
	-- stand exactly on the placeholder's floor spot, facing the same way.
	-- A humanoid's root sits HipHeight + half its height above the ground.
	local figCf = fig:GetPivot()
	local foot = fig:GetAttribute("FootPos")
	if not foot then
		local c, sz = fig:GetBoundingBox()
		foot = Vector3.new(figCf.Position.X, c.Position.Y - sz.Y / 2, figCf.Position.Z)
	end
	local root = avatar:FindFirstChild("HumanoidRootPart")
	local lift
	if hum and root then
		if hum.RigType == Enum.HumanoidRigType.R15 then
			lift = hum.HipHeight + root.Size.Y / 2
		else
			lift = 3 * scale
		end
		avatar.PrimaryPart = root
	else
		local c, sz = avatar:GetBoundingBox()
		lift = avatar:GetPivot().Position.Y - (c.Position.Y - sz.Y / 2)
	end
	avatar:PivotTo(CFrame.new(foot + Vector3.new(0, lift, 0)) * figCf.Rotation)
	-- some body types don't match HipHeight: snap the actual feet to the floor
	local lowest = math.huge
	for _, p in avatar:GetChildren() do
		if p:IsA("BasePart") and (p.Name:find("Foot") or p.Name:find("Leg")) then
			-- vertical half-extent of a (possibly rotated) box
			local ext = 0
			for _, axis in { p.CFrame.RightVector * p.Size.X, p.CFrame.UpVector * p.Size.Y, p.CFrame.LookVector * p.Size.Z } do
				ext += math.abs(axis.Y) / 2
			end
			lowest = math.min(lowest, p.Position.Y - ext)
		end
	end
	if lowest < math.huge then
		avatar:PivotTo(avatar:GetPivot() + Vector3.new(0, foot.Y - lowest, 0))
	end
	for k, v in fig:GetAttributes() do
		avatar:SetAttribute(k, v)
	end
	for kind, id in anims do
		avatar:SetAttribute("Anim_" .. kind, id)
	end
	avatar:SetAttribute("Swapped", true)
	avatar.Parent = fig.Parent
	fig:Destroy()
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if animator and idleId then
		local a = Instance.new("Animation")
		a.AnimationId = idleId
		local ok, track = pcall(animator.LoadAnimation, animator, a)
		if ok then
			track.Looped = true
			track:Play()
		end
	end
	return avatar
end

-- Swap every AvatarOf figure under a container (yields; call in a task).
function FriendAvatars.swapAll(container)
	for _, d in container:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("AvatarOf") and d.Parent then
			local ok, err = pcall(FriendAvatars.swap, d)
			if not ok then
				warn("FriendAvatars: swap failed for", d:GetAttribute("AvatarOf"), err)
			end
		end
	end
end

return FriendAvatars
