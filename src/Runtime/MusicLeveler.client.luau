-- MusicLeveler: library tracks are mastered at very different loudness
-- (PlaybackLoudness ~20..250 across our level tracks), so some levels' music
-- was hard to hear and others loud. Each client measures every playing
-- LevelMusic sound's PlaybackLoudness and sets its (local) Volume so they all
-- come out equally loud.
-- PlaybackLoudness does NOT change with Volume (tested: same track at 0.2 and
-- 1.0 reads ~140 both times), so it measures the track itself: no feedback.
local TARGET = 62.5 -- Volume * loudness; a typical track (~125) ends up at 0.5
local MIN_VOL, MAX_VOL = 0.12, 1.5
local STEP = 1.5 -- seconds between adjustments

local tracked = {}

local function watch(s)
	if s:IsA("Sound") and s.Name == "LevelMusic" and not tracked[s] then
		tracked[s] = { sum = 0, n = 0 }
	end
end

for _, d in workspace:GetDescendants() do
	watch(d)
end
workspace.DescendantAdded:Connect(watch)
workspace.DescendantRemoving:Connect(function(d)
	tracked[d] = nil
end)

-- sample often, adjust every STEP seconds
task.spawn(function()
	local t = 0
	while true do
		local dt = task.wait(0.1)
		t += dt
		for s, st in tracked do
			if s.IsPlaying then
				local l = s.PlaybackLoudness
				if l > 1 then
					st.sum += l
					st.n += 1
				end
			end
		end
		if t >= STEP then
			t = 0
			for s, st in tracked do
				if st.n >= 5 then
					-- a running average (~15-20 s), so the track's own quiet and loud
					-- passages survive; only its overall level gets matched. The first
					-- reading snaps, later ones glide.
					local window = st.sum / st.n
					local first = st.avg == nil
					st.avg = first and window or (st.avg * 0.88 + window * 0.12)
					local want = math.clamp(TARGET / st.avg, MIN_VOL, MAX_VOL)
					s.Volume = first and want or s.Volume + (want - s.Volume) * 0.35
				end
				st.sum, st.n = 0, 0
			end
		end
	end
end)
