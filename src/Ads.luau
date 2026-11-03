-- Ads: the place's own advert decals (the ones already on the train and in
-- the station), shared by every ad board in the game. AdRotator spreads them
-- out so no single ad dominates, and rotates them over time.
local Ads = {}

Ads.POOL = {
	"rbxassetid://10235257903", -- Pizza House
	"rbxassetid://14838954876", -- Witches Brew
	"rbxassetid://7013881912", -- Bloxy Cola: Hit Refresh
	"rbxassetid://3730712400", -- Out for Bloxy Cola
	"rbxassetid://918396276", -- Work at a Pizza Place
	"rbxassetid://13603011609", -- Weezer
	"rbxassetid://14713612531", -- Weezer (blue)
	"rbxassetid://16181087305", -- Weezer (green)
	"rbxassetid://74124660277229", -- Fight Club
	"rbxassetid://5713877164", -- Cobra Kai
	"rbxassetid://18545112125",
	"rbxassetid://602015355", -- Do the Brew
	"rbxassetid://11699391051", -- Witches Brew
	"rbxassetid://16423039715", -- What is bro drinking?
	"rbxassetid://18208780613", -- Freakbob
	"rbxassetid://4632517055",
	"rbxassetid://17371239423",
	"rbxassetid://10652544583",
	"rbxassetid://16422106785",
	"rbxassetid://9605261852",
	"rbxassetid://1931256604",
	"rbxassetid://17438571338",
}

local inPool = {}
for _, id in Ads.POOL do
	inPool[id] = true
end

function Ads.isAd(texture)
	return inPool[texture] == true
end

function Ads.random(rng)
	if rng then
		return Ads.POOL[rng:NextInteger(1, #Ads.POOL)]
	end
	return Ads.POOL[math.random(1, #Ads.POOL)]
end

-- A framed advert board on a wall. `face` is "+X"/"-X"/"+Z"/"-Z" (the way
-- the poster faces); w x h is the poster size.
function Ads.board(B, pos, face, w, h)
	w, h = w or 5, h or 6.5
	local dirs = { ["+Z"] = Vector3.new(0, 0, 1), ["-Z"] = Vector3.new(0, 0, -1), ["+X"] = Vector3.new(1, 0, 0), ["-X"] = Vector3.new(-1, 0, 0) }
	local normals = { ["+Z"] = Enum.NormalId.Back, ["-Z"] = Enum.NormalId.Front, ["+X"] = Enum.NormalId.Right, ["-X"] = Enum.NormalId.Left }
	local dir = dirs[face]
	local function size(a, b, d)
		if face == "+X" or face == "-X" then
			return Vector3.new(d, b, a)
		end
		return Vector3.new(a, b, d)
	end
	B:part(pos + dir * 0.15, size(w + 0.8, h + 0.8, 0.3), { Color = Color3.fromRGB(45, 45, 50), Material = Enum.Material.Metal, Parent = "Decor", Name = "AdFrame", CanCollide = false })
	local poster = B:part(pos + dir * 0.33, size(w, h, 0.06), { Color = Color3.fromRGB(240, 240, 240), Parent = "Decor", Name = "AdBoard", CanCollide = false, CastShadow = false })
	local decal = Instance.new("Decal")
	decal.Face = normals[face]
	decal.Texture = Ads.random()
	decal.Parent = poster
	poster:SetAttribute("AdBoard", true)
	-- a soft light so the poster reads like a backlit panel
	local light = Instance.new("SurfaceLight")
	light.Face = normals[face]
	light.Range = 6
	light.Brightness = 0.6
	light.Angle = 90
	light.Parent = poster
	return poster
end

return Ads
