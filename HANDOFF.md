# Subway Shuffle — handoff (2026-09-30)

## Status (end of session 2026-09-30, evening)
Everything from the second QA spec is now written, synced, built (BUILD true, 33 levels + lobby) and
smoke-tested in Play (Dev/Smoke: 0 script errors across all 33 levels). What is still NOT done is listed
under "Still to do" at the bottom.

## Project
- Roblox game "Subway Shuffle" (Normal Elevator but a subway). Rojo project `C:\Users\user\subway-shuffle`,
  syncs only `ServerStorage.SubwayShuffle` (src/). `rojo serve --port 34872` (start it if not running).
- Memory files hold the architecture and the user's design rules: `project_roblox_subway_game.md`,
  `feedback_subway_shuffle_design.md` (in `~/.claude/projects/C--Users-user/memory/`). Read them first.
- Tools: `tools/luau-compile.exe --text f` (syntax), `tools/luau-analyze.exe f` (unknown globals; ignore Roblox globals).
- Rebuild (Studio command bar, multi-line; click the Run button, Enter adds a line):
  `local t = game.ServerStorage.SubwayShuffle:Clone() t.Name='_SSBuild' t.Parent=game.ServerStorage local ok,e=pcall(function() require(t.BuildAll)() end) t:Destroy() print('BUILD',ok,e)`
  Single level: `require(t.BuildAll)({only="L05_Floodwater"})`. Takes ~2 min for all. "Dangerous command" dialog → Always Continue.
- The Rojo plugin keeps dropping with "Number of requests exceeded limit". Okay → Connect → Accept, and it resyncs.
- Edit-mode preview: `_G.pv(levelName, view)` (Dev/Preview; view 1 = player's first view, 2 = overview with roof
  hidden, 3 = from the exit, or `{eyeLocal, targetLocal, hideRoof}`). Redefine `_G.pv` after a Studio restart:
  `_G.pv = function(n,v) local t=game.ServerStorage.SubwayShuffle.Dev.Preview:Clone() t.Parent=game.ServerStorage pcall(function() require(t)(n,v) end) t:Destroy() end`
- Play-mode smoke test (server command bar): Dev/Smoke runs every level ~10 s and lists errors.
- Play-mode level browser (Studio only): bottom panel (Lobby, <, >, Retry, # box; keys `[` `]` `\`).
- Reading Studio output: click Output, Ctrl+A, Ctrl+C, then `powershell Get-Clipboard | grep ...`.

## State: second QA pass (the user's long "SECOND playtest pass" spec)
Built and smoke-tested. Items marked VERIFIED were checked in Studio this session; the rest only passed the
smoke test (no errors) and still want an eyes-on playthrough.

### Done in code (needs verification in Studio)
- TrainKit rewrite:
  - Strips the invisible parts (they were the cause of the floating).
  - `pos` is now TRACK level (the y you pass to Decor.track); wheels sit on the rail heads (+0.6).
  - Shells: visual parts are non-collidable, with one invisible welded `Collider` box (gets Hazard/Deadly) and a dark `Interior` core.
  - New helpers: `place` (with bogies), `floorAboveTrack()`, `roofAboveTrack()`, `doorOffsets(flip)`.
  - Lobby, L28, L23 updated to use the helpers; L26 track at -4 already matches.
- Kit movers: no first-frame velocity spike, and velocity is clamped.
- Doors: `B:metalDoor` is procedural and exactly fills the DOOR_W × DOOR_H opening, with Hinge/OpenAngle attributes.
  `Kit:openExit` swings it (falls back to OpenOffset). Pick a Door swings its correct door the same way.
- Lighting:
  - Kit applies base lighting from the level attributes `Outdoor` / `RoomBrightness` (set by Arch room; L17 and L19 set Outdoor manually), merged under `def.Lighting`.
  - Arch ceiling lights are dimmer and wider (×0.5 brightness, SurfaceLight angle 150); wall lamps toned down.
- Music: `Audio.MUSIC[LevelModule]` holds 33 APM/DistroKid tracks, played by `Audio.music` (even across the level), stored as `ctx.music`.
  All emitter sounds stop on cleanup. Removed the old `def.Music` fields.
  Verify every ID loads (Sound.TimeLength > 0) in Studio.
- Ambience volumes lowered (L01, L12, L19, L24); checkpoint sound now 0.25.
- Decor:
  - Real extinguisher model; extinguishers removed from L01 and L09.
  - Functional clocks (ClockHand attributes + the `Runtime/Clocks.client` script, installed by BuildAll); decorative clocks removed from L06/07/13/15/28/33.
  - `D.advert` keeps posters above y 8.4 (clear of the trim); track ballast raised 0.04 to stop Z-fighting.
- Arch outdoors: side tree rows skip cuttings and `o.clearZ` ranges (L04 tracks, L29 z 22..66).
- FriendAvatars stores `Anim_<kind>` attributes (idle/walk/dance...); `Kit.playAnim(model, kind, speed)` plays them.
- NPC Guests clone `ServerStorage.NPCTemplates.Guest` (the user's model; BuildAll files any workspace.Guest/Noob there).
  An Animator is added. The user reported Guests still don't animate: test why.
- DevLevels / DevLevelsUI level browser; LevelKit honours the `Abort` and `DevLevel` attributes.
- Per level:
  - L01: pendulum cables on ceiling reels.
  - L03: drop-leaf bridges (hinged, swing down 90°) replace the broken sliding ones.
  - L04: trees cleared and floodlights dimmed.
  - L05: matte water, pump Z-fighting fixed, pendant lamps added.
  - L07: understructure under the escalators, dimmer lights.
  - L08: screen starts above head height (it was impassable), tall paddles plus cabinet glass, 2×2 buttons, per-player presses.
  - L10:
    - Barista Enclave walks the counter loop (machine, register, cups refill, case).
    - Pendants and a lit back bar.
    - Centred table grid and rug; sofa Seats; crowd ambience.
  - L11: puddles moved off the track.
  - L13: real lava (as in Boiler), timer 55 s, KillY -46.
  - L14 Sweeper:
    - 16 podiums in glass tubes; bars start between podiums.
    - A hit sends you to the balcony (eliminated); late joiners spectate.
    - Last one standing wins.
  - L15: plain noobs, removed the mid checkpoint.
  - L17: cradle on an I-beam gantry with a trolley and ropes, and no rails; sloped plank; Outdoor.
  - L18: lander legs fixed.
  - L19: random slab sinking; matte lake; Outdoor.
  - L20: footbridge/stairs removed.
  - L21:
    - Ledges run back to the wall; sliding ledges on wall rails.
    - Neon edge trim and chevrons; floor path from the door.
  - L22: band split at the doors, checkpoint at z0+10, hinge-swing door.
  - L23: depth and rails derived from `roofAboveTrack`, embankments, dimmer floodlights.
  - L25: wind bars follow the beam; neon beam edges.
  - L26: generic graffiti, booth moved back (z 26), fallen can.
  - L27: crate-wall and narrow-gap obstacles.

### Done this session (session 3)
- Missing train wall (VERIFIED): `TrainKit.shell` culled with `p.Size` and ignored rotation; now uses world-space
  extents. Both sides of a shell train checked end to end.
- Black `Interior` core poked out at the tapered cab ends / roof corners (user report, VERIFIED): core is now
  `size - (14, 6, 6)`. You can see into the empty cab through the windscreens, which reads fine.
- Dev/Preview reused a same-named `_Preview` and showed STALE builds after a rebuild. It now always re-clones.
- L27: "Train Horn 2" (`Audio.ID.trainHorn`) plays at launch.
- L28 (VERIFIED on the server): collision groups SS_Ball / SS_Verity / SS_PitWall / SS_VerityFence. Players walk
  through the pit walls; balls and Verity don't. An invisible Verity-only fence on the platform edge with gaps at
  the two train doors. She resets to (0,4,30) if she leaves the pit/platform (the train's bbox counts as inside).
- L29: cabin redesigned (glazing bars, sills, head beams, deep eaves, bargeboards, stove pipe, door canopy,
  plinth, string course). Open wooden stairs: 12 treads, stringers, sloped handrails, balusters, railed landing
  with invisible guards. Live levers: red, pulsing Highlight plus a small red lamp, numbered plates, lamp over the
  frame. Levers stand "normal" leaning away and swing eased to "reversed" with a settle. No sign.
  Edit preview VERIFIED; the pull animation has not been seen in play yet.
- L30: display name "Deadly Dance Floor" (module still L30_MusicalBenches, which keys Audio.MUSIC). ctx.music
  pauses when the podiums rise and resumes for the music phase (VERIFIED by sampling). DJ dances (VERIFIED: track
  507771019 playing).
- `Kit.forceDance(player, on)` (LevelKit) = the shared /e-dance code; used by L30 and L32.
- L31: custom vault exit. The ExitDoor is a 11.2-stud round door with a wheel; `def.OpenExit` (new hook in
  `Kit:openExit`) spins the wheel, clunks, then rolls it 11.6 studs along a top rail / floor slot. Steel collar
  round the doorway; gold shelves moved to the corners so it clears them; EXIT sign raised.
  VERIFIED it ends open and clear; the animation was only half seen.
- L32 (VERIFIED): the farmer was swapped in at build-time FootPos while the boat had already moved (so he ended
  up in the canal). His feet are now pinned to hull-relative `HullFoot` each frame and he dances. The player dances
  on aura spots and stops off them. Leaderboard moved across the canal at (-27, 80) beside the footbridge.
- L33: belt cases in separate lanes (z +/-1.5) since ping-pong movers on one line pass through each other.
  Rear columns stop under the landing slab. Carousel cases moved past the bumper ends.
- Guest NPCs not animating (VERIFIED fixed, 26/26 animating in L02): nothing created an Animator, so
  `animateNpcs`/`playAnim` skipped silently. LevelKit `animatorOf` now creates one.
- Station Metal Door Z-fight (every stop, reported on L13): sliding along X parked its middle plane on the
  station wall face (z 99.39) with its bottom flush with the floor. It now steps out 0.6 toward the platform,
  rises 0.02, then slides. Not yet seen in play.
- Cafe chairs: could NOT reproduce. Seats work (teleported onto one: Sit = true, facing the table). Ask the
  user what exactly fails.
- The red "experience doesn't have access permission to use asset id 122193759333439" spam is
  `tiiow.Animate.mood` (the user's own avatar's mood animation in Studio). Not ours; ignore it in smoke logs.

### Third playtest round (session 3, later) - user played all 33 levels
User verdicts: most levels good (Cafe, Train Wash, Live Rails, Crumbling Platform, Sweeper, Ticket Inspectors,
Boiler Room, Moon Base, Carriage Hop, Sewer Slide, Wind Tunnel, Runaway Train, Laser Vault, Aura Farming,
Baggage Carousel, lobby). Cafe chairs DO work. Deadly Dance Floor is a favourite. Fixed this round:
- The "tunnel pieces / station wall Z-fighting through the level walls" was a Dev/Preview `_Preview` left in the
  workspace (it gets copied into Play). levelctrl now deletes any `_Preview` at startup. ALWAYS `_G.pv(nil)`
  before Play.
- Shell trains: windows (Transparency 0..1 parts: 14 glass @0.4, 2 plastic @0.5) become opaque dark tinted
  glass, so the hollow inside never shows (the core box can't fill the octagonal body). VERIFIED.
- L03: trains start almost at once (0.4 + lane*0.7 s, first green 1 s). Dropped bridge leaves ease 0.45 off the
  pit wall (they sat inside the wall and Z-fought); rails 0.7 tall so they still clear the train.
- L05: too bright: walls (150,160,154), RoomBrightness 0.85, Lighting.ExposureCompensation -0.5.
- AUDIO: SoundGroups SS_Music 1 / SS_Ambience 0.7 / SS_SFX 0.45 (Audio.group), music base volume 0.5, and
  Runtime/MusicLeveler.client: per-client auto-gain on LevelMusic using PlaybackLoudness (slow running average,
  TARGET 140, clamp 0.35x..2.5x base). Measured per-unit loudness 42..489 across tracks. Lobby music
  (Audio.MUSIC.Lobby = "Life in an Elevator") from RunCtrl. L28 music "verity theme" 97927847298766 (alts in the
  comment), L29 "Railway Junction" 1844740845. Track search: toolbox API
  `apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType=Audio&query=...` from a create.roblox.com
  page (javascript fetch with credentials).
- L10: Enclave really works: cup in hand to the machine (fills brown), sets it in an empty spot (or drinks it),
  points at the register (drawer slides), takes a pastry from the case to the ServePlate. Held items follow the
  right hand; "toolnone" (arm out) is now captured by FriendAvatars. VERIFIED.
- L14: a seated player is re-put on their podium until the round starts (respawn / late teleport race).
- L17: gantry post/arm/beam butt instead of overlapping (Z-fight). L19: alternate ice slabs 0.05 lower.
- Kit: CameraMaxZoomDistance capped at 24 (def.MaxZoom) while in a level, restored on cleanup.
- L20: two Deadly express trains (TrainKit.shell movers) on the tracks + rumble.
- L21: real fan (shroud with hazard bands, 5 pitched steel blades + yellow tips, hub, struts, red glow, black pit)
  under a bar grille, plus a big upward air blast (stretched streaks + haze).
- L22: trapdoors now swing DOWN (+angle about X). L26: can 3 lies on its side under the bench plank.
- L29: rail infill no longer semi-transparent.
- L30: DJ is now tiiow ("DJ tiiow") on a riser; turntables with platters (SpinAxis X: a Y cylinder's axis is its
  local X), mixer with faders; cones pump on the beat, booth front cycles colour. During music the DJ's arms are
  posed on the decks (scratching) through the joints, else he cheers. Avatars use AnimationConstraint joints
  (not Motor6D) - pose via the constraint's Attachment0 CFrame. VERIFIED.

### Round 4 fixes (same day)
- MusicLeveler was wrong: PlaybackLoudness does NOT scale with Volume (tested), so dividing by Volume made it
  bang-bang to the clamps. Now Volume = 62.5 / runningAvg(loudness), clamped 0.12..1.5, first reading snaps.
- Lobby had "two musics": lobby track was the same "Life in an Elevator" the train speaker plays. The lobby now
  plays "Sunset Chill (Bed Version)" 9046862941 (the train speaker is 310 studs away, inaudible there).
- Shell trains get closed door leaves in both doorways (TrainDoors builds the real doors at runtime, so copies
  had open holes); interior core back to (X-5, Y-7.5, Z-6.5) so cab windows aren't see-through. VERIFIED.
- L30: riser 3.5, arms 72/68 deg so DJ tiiow's hands rest on the decks. VERIFIED.
- L32 music: "AURA = inf" phonk 95131770144654 (alts in Audio.luau comment).

### Still to do
- Multiplayer test with Test > Local Server (2-4 players): L06, L08, L14, L22, L28, L29, L30.
- Eyes-on playthrough of every changed level from the player's view (Z-fighting, floating, flinging, audio,
  lighting). In particular the L29 lever pull, the L31 vault roll and the station door plug-slide.
- Verify in play: L03 bridges/early trains, L21 air blast, L22 trapdoors, L20 express trains, music levels
  feel even (MusicLeveler), L14 podium seating with 2+ players.
