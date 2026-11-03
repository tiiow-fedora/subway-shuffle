-- Audio: every sound the game uses, by name, plus helpers.
-- Library audio is from Roblox's licensed partners (ProSoundEffects, APM)
-- or Studio's built-in content, so it plays in any experience.
local Audio = {}

-- Mix: every sound goes in one of three SoundGroups, so the balance between
-- music, ambience and effects is set in one place (effects were drowning the
-- music). Music loudness itself is evened out per track on each client by
-- Runtime/MusicLeveler, which reads PlaybackLoudness.
local SoundService = game:GetService("SoundService")
local MIX = { Music = 1, Ambience = 0.7, SFX = 0.45 }
local function group(name)
	local g = SoundService:FindFirstChild("SS_" .. name)
	if not g then
		g = Instance.new("SoundGroup")
		g.Name = "SS_" .. name
		g.Volume = MIX[name]
		g.Parent = SoundService
	end
	return g
end
Audio.group = group

Audio.ID = {
	-- train + stations
	trainInterior = "rbxassetid://9112835656", -- NYC Subway Interior
	trainPass = "rbxassetid://9116330641", -- L Train pass-by
	trainRumble = "rbxassetid://9117092499", -- NYC Subway
	doorOpen = "rbxassetid://9114153584", -- door slide
	doorChime = "rbxassetid://6983350215", -- doors closing chime
	stationAmbience = "rbxassetid://5870205466",
	elevatorMusic = "rbxassetid://1841647093", -- "Life in an Elevator" (APM)
	crowd = "rbxassetid://9112879470",
	-- machines, weather, nature
	boiler = "rbxassetid://9112839913",
	lavaBubbles = "rbxassetid://9112752570",
	steam = "rbxassetid://108173766941619",
	windLoop = "rbxassetid://6544555787",
	fan = "rbxassetid://9114185166",
	electricBuzz = "rbxassetid://220954198",
	spark = "rbxassetid://624552683",
	laserHum = "rbxassetid://126321934365548",
	explosion = "rbxasset://sounds/impact_explosion_03.mp3",
	splash = "rbxasset://sounds/impact_water.mp3",
	propeller = "rbxassetid://6476278928",
	iceCrack = "rbxassetid://9114858583",
	drum = "rbxassetid://9116621926",
	drumRoll = "rbxassetid://9116624009",
	escalator = "rbxassetid://5357108289",
	waterRush = "rbxassetid://9114437912",
	carWash = "rbxassetid://9112742807",
	birds = "rbxassetid://9113444290",
	crickets = "rbxassetid://9112764546",
	eerie = "rbxassetid://9112775624",
	refinery = "rbxassetid://9112838943",
	-- music
	cafeMusic = "rbxassetid://97316511727172",
	discoMusic = "rbxassetid://9038367768", -- Funky Disco Beats (APM)
	-- feedback
	pickup = "rbxassetid://4612375051",
	ding = "rbxassetid://6947264041",
	buzzer = "rbxassetid://13666317273",
	lever = "rbxassetid://9116260154",
	checkpoint = "rbxassetid://1301186018",
	whoosh = "rbxassetid://9120698415",
	trainHorn = "rbxassetid://9120250368", -- ProSoundEffects "Train Horn 2"
}

-- One music track per level (APM / DistroKid library music, licensed for
-- every experience), picked to suit the place. LevelKit plays the level's
-- track across the whole level and stops it when the level ends.
Audio.MUSIC = {
	L01_MaintenanceTunnel = 114710204840609, -- Electric Tension
	L02_RushHour = 1837599596, -- Busy City
	L03_MindTheGap = 1842602330, -- Field Day
	L04_TrackCrossing = 1848360371, -- Stop Go
	L05_Floodwater = 1847683499, -- Running Faster A
	L06_LostProperty = 119168063156350, -- Investigative Marimba
	L07_Escalators = 1836284597, -- Tomorrows Transport
	L08_TicketBarrier = 1839997360, -- Solve It Tension Bed
	L09_Blackout = 1842063441, -- Infiltrator (a)
	L10_CommuterCafe = 140331368291861, -- Cozy Autumn Cafe Vibes with Smooth Jazz
	L11_TrainWash = 1837465056, -- Marimba Paradise
	L12_LiveRails = 1847693202, -- Electronic Tension
	L13_FallingTiles = 1840489593, -- Time's Running Out
	L14_Sweeper = 1842174239, -- Game Show
	L15_TicketInspectors = 1839629773, -- Spying
	L16_BoilerRoom = 1841714817, -- Extremities f (industrial rock)
	L17_RooftopRun = 1842949232, -- High Octane
	L18_MoonBase = 1837472332, -- Deep Space
	L19_FrozenPlatform = 1836280952, -- Four Seasons: Winter
	L20_Bombardiro = 103046874465690, -- Bombardiro Crocodilo
	L21_VentShaft = 9044545570, -- Night Run
	L22_PickADoor = 1845013659, -- Game Show
	L23_CarriageHop = 1837560230, -- Classic Chase
	L24_SewerSlide = 1841647421, -- Cartoon Capers
	L25_WindTunnel = 1842601594, -- Chasing The Sun
	L26_GhostStation = 140033496825661, -- Chilling Fog
	L27_RunawayTrain = 1848090337, -- Intense Chase
	L28_VerityBallPit = 97927847298766, -- "verity theme" (DistroKid); alt: 79667847475202 Verity Song, 112929059262260 Verity Phonk
	L29_SignalBox = 1844740845, -- Railway Junction (APM)
	L30_MusicalBenches = 1847785418, -- I Like To Disco B
	L31_LaserVault = 9047964393, -- Last Chance Mission
	L32_AuraFarming = 95131770144654, -- "AURA = ∞" phonk (DistroKid); alt: 138294124783082 AURA FARMING BOAT, 99979837873059 +100k AURA PHONK
	L33_BaggageCarousel = 1837913244, -- Future Mall
	Lobby = 9046862941, -- Sunset Chill (Bed Version) (APM); the train speaker already plays Life in an Elevator
}

-- Level music: even across the level (full volume out to `range`, fading
-- beyond it) rather than a point source in the middle of the room.
function Audio.music(part, id, volume, range)
	local s = Instance.new("Sound")
	s.Name = "LevelMusic"
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Looped = true
	s.Volume = volume or 0.5
	s.SoundGroup = group("Music")
	-- the client leveller scales around this
	s:SetAttribute("BaseVolume", s.Volume)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = range
	s.RollOffMaxDistance = range * 1.6
	s.Parent = part
	s:Play()
	return s
end

local function make(id, props)
	local s = Instance.new("Sound")
	s.SoundId = Audio.ID[id] or id
	for k, v in props or {} do
		s[k] = v
	end
	return s
end
Audio.make = make

-- Looping 3D ambience emitted from a part (audible within `range` studs).
function Audio.loop(part, id, volume, range)
	local s = make(id, {
		Name = "Ambience_" .. tostring(id),
		Looped = true,
		Volume = volume or 0.5,
		RollOffMode = Enum.RollOffMode.Linear,
		RollOffMinDistance = (range or 80) * 0.4,
		RollOffMaxDistance = range or 80,
		SoundGroup = group("Ambience"),
	})
	s.Parent = part
	s:Play()
	return s
end

-- One-shot sound from a part (or a position, via a temporary attachment).
function Audio.play(where, id, volume, range)
	local parent = where
	local temp
	if typeof(where) == "Vector3" then
		temp = Instance.new("Attachment")
		temp.WorldPosition = where
		temp.Parent = workspace.Terrain
		parent = temp
	end
	local s = make(id, {
		Volume = volume or 0.7,
		RollOffMode = Enum.RollOffMode.InverseTapered,
		RollOffMinDistance = 10,
		RollOffMaxDistance = range or 120,
		SoundGroup = group("SFX"),
	})
	s.Parent = parent
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
		if temp then
			temp:Destroy()
		end
	end)
	task.delay(15, function()
		if s.Parent then
			s:Destroy()
		end
		if temp and temp.Parent then
			temp:Destroy()
		end
	end)
	return s
end

return Audio
