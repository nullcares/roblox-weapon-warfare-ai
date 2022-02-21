-- // Written by: @
-- // Info: 
-- // Creation date: 02/21/22

local pfs = game:GetService('PathfindingService')
local plrs = game:GetService('Players')
local cam = game.Workspace.CurrentCamera
local lp = plrs.LocalPlayer
local target = nil

local con = getgenv()
con.enabled = true
con.aimpart = 'Torso'
con.aimbotsharpness = 0.25
con.randompart = true
con.weapon = 'G-17'
con.team_check = false
con.ff_filter = true
con.range = 1000

local function navigate_target()
	if lp.Character and target then
		local c = lp.Character:WaitForChild('HumanoidRootPart')
		local h = lp.Character:WaitForChild('Humanoid')
	
		local path = pfs:CreatePath()
		path:ComputeAsync(c.Position, target[con.aimpart].Position)
		if path.Status == Enum.PathStatus.NoPath then
			warn('Path doesnt exist')
			h:MoveTo(c.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)))
			
			local start = tick()
			local pass = false
			h.MoveToFinished:Connect(function()
				pass = true
			end)
			repeat wait() until pass == true or tick()-start > 5
		else
			local wps = path:GetWaypoints()
			for _, v in pairs(wps) do
				h:MoveTo(v.Position)
				if v.Action == Enum.PathWaypointAction.Jump then
					h.Jump = true
				end
				
				local start = tick()
				local pass = false
				h.MoveToFinished:Connect(function()
					pass = true
				end)
				repeat wait() until pass == true or tick()-start > 2
			end
		end
	end
end

local function vis_check(s, t)
	local bl = RaycastParams.new()
	bl.FilterDescendantsInstances = {s.Parent}
	bl.FilterType = Enum.RaycastFilterType.Blacklist
	local r = game:GetService('Workspace'):Raycast(s.Position, (t.Position - s.Position).Unit*con.range, bl)
	if r and (r.Instance == t or r.Instance:IsDescendantOf(t.Parent)) then
		return true
	end
	return false
end

local function visible_cam(t)
	local bl = RaycastParams.new()
	bl.FilterDescendantsInstances = {lp.Character}
	bl.FilterType = Enum.RaycastFilterType.Blacklist
	local r = game:GetService('Workspace'):Raycast(cam.CFrame.Position, (t.Position - cam.CFrame.Position).Unit*con.range, bl)
	if r and (r.Instance == t or r.Instance:IsDescendantOf(t.Parent)) then
		return true
	end
	return false
end

local function get_closest()
	if not lp.Character then return nil end
	
	local Closest = {math.huge, nil}
	
	for _, v in pairs(game:GetService('Workspace'):GetChildren()) do
		local t = v:FindFirstChild(con.aimpart)
		local h = v:FindFirstChildWhichIsA('Humanoid')
		if t and h and h:GetState() ~= Enum.HumanoidStateType.Dead then
			local p = plrs:GetPlayerFromCharacter(v)
			if p then
				if p.Name == lp.Name then continue end
				if con.team_check and p.Team == lp.Team then continue end
				p = v
			end
		if con.ff_filter and v:FindFirstChildWhichIsA('ForceField') then continue end
			local ch = lp.Character:WaitForChild(con.aimpart)
			local d = (ch.Position - t.Position).Magnitude
			if d < Closest[1] and vis_check(ch, t) then
				Closest[1] = d
				Closest[2] = v
			end
		end
	end
	
	return Closest[2]
end

local function get_weapon(str)
    for _, v in pairs(game:GetService('Workspace'):GetDescendants()) do
		if v.Name == str and v:IsA('MeshPart') and v:FindFirstChild('GrabTime') then
			return v
		end
    end
end

local function grab_wep()
    local c = lp.Character
    local h = c:WaitForChild('Humanoid')
	local g = get_weapon(con.weapon)
	if g == nil then
		return
	end
    local save = c.HumanoidRootPart.Position
    
    c:MoveTo(g.Position)
    task.wait(g.GrabTime.Value*2)
    local A_1 = c.HumanoidRootPart
    local A_2 = g
    local A_3 = 10
    local Event = game:GetService("ReplicatedStorage").Remotes.GrabItem
    Event:FireServer(A_1, A_2, A_3)
    c:MoveTo(save)
    task.wait(0.5)
    
    h:EquipTool(lp.Backpack:WaitForChild(con.weapon))
end

task.spawn(function()
	while true do
		if target ~= nil and visible_cam(target[con.aimpart])  then
	       	mouse1click()
		  	cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target[con.aimpart].Position), con.aimbotsharpness)
            if target.Humanoid:GetState() == Enum.HumanoidStateType.Dead then
                target = nil
            end
		end
        task.wait()
    end
end)

--[[
lp.Backpack.ChildAdded:Connect(function(c)
	if lp.Character and c:IsA('Tool') and c.Name == con.weapon then
		lp.Character.Humanoid:EquipTool(c)
	end
end)]]

lp.CharacterAdded:Connect(function(c)
	task.wait()
	grab_wep()
	
    for i = 1, 15 do
        mousescroll(100)
        task.wait()
    end
	local h = c:WaitForChild('Humanoid')
	task.wait(1)
	while h:GetState() ~= Enum.HumanoidStateType.Dead do
		local f = get_closest()
		if f ~= nil then
			print('New target: '..f:GetFullName())
			target = f
			navigate_target()
		else
			print('No target available')
			c.Humanoid:MoveTo(c.HumanoidRootPart.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)))
            keypress(0x52)
            task.wait()
            keyrelease(0x52)			

			local start = tick()
			local pass = false
			h.MoveToFinished:Connect(function()
				pass = true
			end)
			repeat wait() until pass == true or tick()-start > 3
		end
	end
	print('Im dead!')
	target = nil
	-- wait until the respawn button appears
	task.wait(6)
    local Viewport = workspace.CurrentCamera.ViewportSize
    mousemoveabs(Viewport.X / 2, Viewport.Y / 2) -- Moves your cursor to the center of the window
	mouse1click()
end)
