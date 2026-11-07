local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local ev = RS:WaitForChild("Events"):WaitForChild("Collectible")

local CACHE = getgenv().__jcoinCache or {}
getgenv().__jcoinCache = CACHE
local DONE = getgenv().__jcoinDone or {}
getgenv().__jcoinDone = DONE

local running, stopFlag, finished = false, false, false
local lastId = 1000
local pending = {}

local NoclipParts, Noclipping = {}, nil
local function noclipOn()
	pcall(function() Noclipping:Disconnect() end)
	NoclipParts = {}
	Noclipping = RunService.Stepped:Connect(function()
		local c = lp.Character
		if c then
			for _, ch in ipairs(c:GetDescendants()) do
				if ch:IsA("BasePart") and ch.CanCollide then
					ch.CanCollide = false
					NoclipParts[ch] = true
				end
			end
		end
	end)
end
local function noclipOff()
	pcall(function() Noclipping:Disconnect() end)
	Noclipping = nil
	for ch in pairs(NoclipParts) do
		if typeof(ch) == "Instance" and ch:IsA("BasePart") and ch.Parent then ch.CanCollide = true end
	end
	NoclipParts = {}
end

local FLYING, bv, bg, holdPos = false, nil, nil, nil
local CONTROL = { F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0 }
local FLYSPEED = 1
local flyConns = {}

local function rootOf(c)
	return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
end

local function flyOn()
	local c = lp.Character
	local t = rootOf(c)
	if not t or FLYING then return end
	local hum = c:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = true end

	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.Parent = t

	bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bg.P = 9e4
	bg.CFrame = t.CFrame
	bg.Parent = t

	FLYING = true

	flyConns[#flyConns + 1] = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local tt = rootOf(lp.Character)
		if not tt or not bv or not bg or not bv.Parent then return end
		if holdPos then
			tt.CFrame = CFrame.new(holdPos)
			bv.Velocity = Vector3.new(0, 0, 0)
			bg.CFrame = cam.CFrame
			return
		end
		local move = Vector3.new(0, 0, 0)
		if CONTROL.F + CONTROL.B + CONTROL.L + CONTROL.R + CONTROL.Q + CONTROL.E ~= 0 then
			move = (cam.CFrame.LookVector * (CONTROL.F + CONTROL.B))
				+ (cam.CFrame.RightVector * (CONTROL.L + CONTROL.R))
				+ (cam.CFrame.UpVector * (CONTROL.Q + CONTROL.E))
			move = move * (FLYSPEED * 50)
		end
		bv.Velocity = move
		bg.CFrame = cam.CFrame
	end)

	flyConns[#flyConns + 1] = UIS.InputBegan:Connect(function(i, p)
		if p then return end
		local k = i.KeyCode
		if k == Enum.KeyCode.W then CONTROL.F = 1
		elseif k == Enum.KeyCode.S then CONTROL.B = -1
		elseif k == Enum.KeyCode.A then CONTROL.L = -1
		elseif k == Enum.KeyCode.D then CONTROL.R = 1
		elseif k == Enum.KeyCode.E then CONTROL.Q = 2
		elseif k == Enum.KeyCode.Q then CONTROL.E = -2
		end
	end)

	flyConns[#flyConns + 1] = UIS.InputEnded:Connect(function(i, p)
		if p then return end
		local k = i.KeyCode
		if k == Enum.KeyCode.W then CONTROL.F = 0
		elseif k == Enum.KeyCode.S then CONTROL.B = 0
		elseif k == Enum.KeyCode.A then CONTROL.L = 0
		elseif k == Enum.KeyCode.D then CONTROL.R = 0
		elseif k == Enum.KeyCode.E then CONTROL.Q = 0
		elseif k == Enum.KeyCode.Q then CONTROL.E = 0
		end
	end)
end

local function flyOff()
	FLYING = false
	holdPos = nil
	for _, c in ipairs(flyConns) do pcall(function() c:Disconnect() end) end
	flyConns = {}
	if bv then pcall(function() bv:Destroy() end) bv = nil end
	if bg then pcall(function() bg:Destroy() end) bg = nil end
	local c = lp.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
	pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
	CONTROL = { F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0 }
end

local function hold(pos) holdPos = pos end

ev.OnClientEvent:Connect(function(msg)
	if type(msg) == "table" and msg.RequestId and pending[msg.RequestId] then
		local f = pending[msg.RequestId]
		pending[msg.RequestId] = nil
		f(msg)
	end
end)

local function request(msgType, payload, timeout)
	lastId += 1
	local id = lastId
	local box = { done = false, ok = false }
	pending[id] = function(msg)
		box.done = true
		box.ok = (msg.Payload and msg.Payload.Data and msg.Payload.Data.Success) == true
	end
	pcall(function() ev:FireServer({ Type = msgType, Payload = payload, RequestId = id }) end)
	local t0 = os.clock()
	while not box.done and os.clock() - t0 < (timeout or 3) do
		if stopFlag then break end
		task.wait(0.08)
	end
	pending[id] = nil
	return box.ok
end

local parent = gethui and gethui() or lp:WaitForChild("PlayerGui")
local old = parent:FindFirstChild("JCoinCollector")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "JCoinCollector"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.Parent = parent

local f = Instance.new("Frame")
f.Size = UDim2.fromOffset(320, 300)
f.Position = UDim2.new(0, 20, 0, 100)
f.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
f.BorderSizePixel = 0
f.Active = true
f.Draggable = true
f.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = f

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 28)
title.Position = UDim2.fromOffset(8, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(0, 220, 130)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "J-Coin Stash Collector"
title.Parent = f

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -16, 0, 16)
status.Position = UDim2.fromOffset(8, 32)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(160, 160, 170)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "idle"
status.Parent = f

local function mkBtn(text, x, w, col, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, 26)
	b.Position = UDim2.fromOffset(x, y or 54)
	b.BackgroundColor3 = col
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Text = text
	b.Parent = f
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b
	return b
end

local btnScan = mkBtn("Scan", 8, 96, Color3.fromRGB(45, 45, 55))
local btnGo = mkBtn("Collect", 112, 96, Color3.fromRGB(0, 150, 90))
local btnStop = mkBtn("Stop", 216, 96, Color3.fromRGB(150, 45, 45))

local cardsOnly = mkBtn("J-Coin only: ON", 8, 150, Color3.fromRGB(35, 35, 42), 88)
cardsOnly.Font = Enum.Font.Gotham
cardsOnly.TextSize = 11
cardsOnly.TextColor3 = Color3.fromRGB(200, 200, 210)

local btnClear = mkBtn("Reset done", 166, 90, Color3.fromRGB(60, 50, 35), 88)
btnClear.Font = Enum.Font.Gotham
btnClear.TextSize = 11
btnClear.TextColor3 = Color3.fromRGB(230, 200, 140)

local log = Instance.new("ScrollingFrame")
log.Size = UDim2.new(1, -16, 1, -150)
log.Position = UDim2.fromOffset(8, 142)
log.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
log.BorderSizePixel = 0
log.ScrollBarThickness = 4
log.CanvasSize = UDim2.new()
log.AutomaticCanvasSize = Enum.AutomaticSize.Y
log.Parent = f

local ll = Instance.new("UIListLayout")
ll.Padding = UDim.new(0, 2)
ll.Parent = log

local function out(msg, col)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -4, 0, 14)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Code
	l.TextSize = 10
	l.TextColor3 = col or Color3.fromRGB(180, 180, 190)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = msg
	l.Parent = log
	task.defer(function() log.CanvasPosition = Vector2.new(0, 1e6) end)
end

local function count(t)
	local n = 0
	for _ in pairs(t) do n += 1 end
	return n
end

local function isCard(id) return id:find("GameCurrencyCard") ~= nil end

local function finish(msg)
	if finished then return end
	finished = true
	stopFlag = true
	holdPos = nil
	pcall(flyOff)
	pcall(noclipOff)
	running = false
	status.Text = msg or "stopped"
end

local function begin()
	stopFlag = false
	finished = false
	running = true
	noclipOn()
	flyOn()
end

local function scan()
	if running then return end
	begin()
	local ok, err = pcall(function()
		local pp = workspace.World.Gameplay.Nodes.PlacePoints
		local pts = pp:GetChildren()
		local found = 0
		for i, a in ipairs(pts) do
			if stopFlag then break end
			if a:IsA("BasePart") then
				hold(a.Position + Vector3.new(0, 14, 0))
				task.wait(1.3)
				for _, d in ipairs(workspace:GetDescendants()) do
					local id = d:GetAttribute("CollectibleId")
					if id and not CACHE[id] and not DONE[id] then
						CACHE[id] = d:GetPivot().Position
						found += 1
						if isCard(id) then out("+ "..id, Color3.fromRGB(0, 220, 130)) end
					end
				end
				status.Text = "scan "..i.."/"..#pts.."  cached "..count(CACHE)
			end
		end
		out("scan complete: +"..found.."  cached "..count(CACHE).."  done "..count(DONE), Color3.fromRGB(0, 220, 130))
	end)
	if not ok then out("scan error: "..tostring(err), Color3.fromRGB(220, 120, 120)) end
	finish("scan done")
end

local function collect()
	if running then return end
	begin()
	local ok_n, bad_n = 0, 0
	local ok, err = pcall(function()
		local list = {}
		for id, p in pairs(CACHE) do
			if not DONE[id] then
				if cardsOnly:GetAttribute("off") or isCard(id) then
					table.insert(list, { id = id, p = p })
				end
			end
		end
		table.sort(list, function(a, b) return a.id < b.id end)
		status.Text = "collecting "..#list

		for i, e in ipairs(list) do
			if stopFlag then break end
			status.Text = "("..i.."/"..#list..") "..e.id
			out("> "..e.id)
			local done = false
			for _ = 1, 10 do
				if stopFlag then break end
				hold(e.p + Vector3.new(0, 2.5, 0))
				task.wait(0.45)
				if request("RequestClaimCollectible", { CollectibleId = e.id }, 3) then
					done = true
					break
				end
				task.wait(0.35)
			end
			if done then
				ok_n += 1
				DONE[e.id] = true
				CACHE[e.id] = nil
				out("  claimed", Color3.fromRGB(0, 220, 130))
			else
				bad_n += 1
				out("  failed (kept for retry)", Color3.fromRGB(220, 120, 120))
			end
			task.wait(0.3)
		end
	end)
	if not ok then out("collect error: "..tostring(err), Color3.fromRGB(220, 120, 120)) end
	finish("done  ok "..ok_n.."  fail "..bad_n.."  done total "..count(DONE))
	out("finished: "..ok_n.." claimed, "..bad_n.." failed", Color3.fromRGB(0, 220, 130))
end

cardsOnly:SetAttribute("off", false)
cardsOnly.MouseButton1Click:Connect(function()
	local off = not cardsOnly:GetAttribute("off")
	cardsOnly:SetAttribute("off", off)
	cardsOnly.Text = "J-Coin only: "..(off and "OFF" or "ON")
end)

btnClear.MouseButton1Click:Connect(function()
	getgenv().__jcoinDone = {}
	DONE = getgenv().__jcoinDone
	out("done list cleared")
end)

btnScan.MouseButton1Click:Connect(function()
	if running then finish("stopped") task.wait(0.2) end
	task.spawn(scan)
end)

btnGo.MouseButton1Click:Connect(function()
	if running then finish("stopped") task.wait(0.2) end
	if count(CACHE) == 0 then
		out("cache empty, scanning first")
		task.spawn(function()
			scan()
			task.wait(0.5)
			collect()
		end)
	else
		task.spawn(collect)
	end
end)

btnStop.MouseButton1Click:Connect(function()
	status.Text = "stopping..."
	finish("stopped")
	out("stopped", Color3.fromRGB(220, 200, 120))
end)

out("loaded  cached "..count(CACHE).."  done "..count(DONE))
status.Text = "ready"