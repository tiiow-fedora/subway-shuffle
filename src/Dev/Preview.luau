-- Edit-mode QA helper. From the command bar:
--   require(<clone of this>)("L05_Floodwater", 1)
-- puts a copy of the level in workspace at the station door (as levelctrl
-- does) and points the camera at it. Views: 1 = what you see stepping out of
-- the train, 2 = overview from the back corner, 3 = from the exit looking
-- back, 4 = top down. Pass a Vector3 pair {eye, target} (local coords) for a
-- custom view. Name nil removes the preview.
local ServerStorage = game:GetService("ServerStorage")

return function(name, view)
	local cam = workspace.CurrentCamera
	local current = workspace:FindFirstChild("_Preview")
	if name == nil then
		if current then
			current:Destroy()
		end
		return
	end
	-- always re-clone: reusing a same-named preview showed stale builds
	do
		if current then
			current:Destroy()
		end
		local src = ServerStorage.Levels:FindFirstChild(name)
		assert(src, "no level " .. tostring(name))
		current = src:Clone()
		current.Name = "_Preview"
		for _, d in current:GetDescendants() do
			if d:IsA("Script") then
				d.Disabled = true
			end
		end
		current.Parent = workspace
	end
	-- views from above see through the roof
	local open = view == 2 or view == 4 or typeof(view) == "table" and view[3]
	for _, d in current:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Ceiling" or d.Name == "Beam" or d.Name == "CeilingLight" or d.Name == "Lamp" or d.Name == "Roof") then
			d.LocalTransparencyModifier = open and 1 or 0
		end
	end
	local o = Vector3.new(147.7, 21.4, 100.6)
	local D = current:GetAttribute("Depth") or 100
	local eye, at
	if typeof(view) == "table" then
		eye, at = view[1], view[2]
	elseif view == 2 then
		eye, at = Vector3.new(-D * 0.35, D * 0.75, D * 0.1), Vector3.new(0, 0, D * 0.55)
	elseif view == 3 then
		eye, at = Vector3.new(6, 12, D - 4), Vector3.new(0, 2, D * 0.3)
	elseif view == 4 then
		eye, at = Vector3.new(0, D * 1.1, D / 2 + 0.01), Vector3.new(0, 0, D / 2)
	else
		eye, at = Vector3.new(0, 6.5, -2), Vector3.new(0, 4, 30)
	end
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(o + eye, o + at)
	cam.FieldOfView = 70
end
