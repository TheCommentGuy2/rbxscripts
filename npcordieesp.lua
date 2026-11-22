local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local Tween   = game:GetService("TweenService")
local LP      = Players.LocalPlayer
local PG      = LP:WaitForChild("PlayerGui")

if PG:FindFirstChild("BE_NPC_OR_DIE_ESP") then PG.BE_NPC_OR_DIE_ESP:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "BE_NPC_OR_DIE_ESP"
SG.ResetOnSpawn = false
SG.DisplayOrder = 999
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = PG

local GREEN = Color3.fromRGB(0, 255, 140)
local RED   = Color3.fromRGB(255, 70, 70)
local BLUE  = Color3.fromRGB(70, 140, 255)
local DEAD  = Color3.fromRGB(150, 150, 150)
local OFF   = Color3.fromRGB(60, 66, 76)
local TRACK = Color3.fromRGB(38, 43, 51)
local objs, held, espOn = {}, {}, true

local function gone(rig)
    return rig == nil or rig.Parent == nil or not rig:IsDescendantOf(workspace)
end

local function colorOf(pl)
    local t = pl.Team
    if t then
        local n = t.Name:lower()
        if n:find("sheriff") then return BLUE end
        if n:find("crim") then return RED end
    end
    return GREEN
end

local function paint(o)
    local c = o.hp > 0 and colorOf(o.pl) or DEAD
    o.hl.FillColor = c
    o.hl.OutlineColor = c
    o.hl.FillTransparency = o.hp > 0 and 0.72 or 0.92
    o.lab.TextColor3 = c
end

local function lock(pl, rig)
    if pl == LP or objs[rig] or not rig then return end
    local head = rig:FindFirstChild("Head") or rig:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = rig
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.OutlineTransparency = 0
    hl.Parent = SG

    local bb = Instance.new("BillboardGui")
    bb.Adornee = head
    bb.AlwaysOnTop = true
    bb.MaxDistance = 2000
    bb.Size = UDim2.fromOffset(200, 30)
    bb.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
    bb.Parent = SG

    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.fromScale(1, 1)
    lab.BackgroundTransparency = 1
    lab.Font = Enum.Font.GothamBold
    lab.TextSize = 14
    lab.TextStrokeTransparency = 0.35
    lab.Parent = bb

    local o = {hl = hl, bb = bb, lab = lab, pl = pl, hp = 100}
    objs[rig] = o
    held[pl] = rig
    paint(o)
end

local function drop(rig)
    local o = objs[rig]
    if not o then return end
    o.hl:Destroy(); o.bb:Destroy()
    objs[rig] = nil
    if held[o.pl] == rig then held[o.pl] = nil end
end

local function clearAll()
    for r in pairs(objs) do drop(r) end
    held = {}
end

local function scan()
    if not espOn then return end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP then
            local h = held[pl]
            if h and gone(h) then drop(h) end
        end
    end
    for _, c in ipairs(workspace:GetChildren()) do
        if c:IsA("Model") then
            local hum  = c:FindFirstChildOfClass("Humanoid")
            local root = c:FindFirstChild("HumanoidRootPart")
            if hum and root then
                local pl = Players:FindFirstChild(c.Name)
                if pl and pl ~= LP then
                    local isChar = pl.Character == c
                    local wtd   = (hum.WalkToPoint - root.Position).Magnitude
                    local jumpy = math.abs(hum.JumpPower - 50) > 0.01
                    if isChar then
                        if held[pl] ~= c then
                            local old = held[pl]
                            if old then drop(old) end
                            lock(pl, c)
                        end
                    elseif not held[pl] and wtd > 50 and jumpy then
                        lock(pl, c)
                    end
                end
            end
        end
    end
end

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(206, 74)
panel.Position = UDim2.fromOffset(24, 110)
panel.BackgroundColor3 = Color3.fromRGB(17, 19, 23)
panel.BorderSizePixel = 0
panel.Parent = SG
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(44, 49, 57)

local head = Instance.new("Frame")
head.Size = UDim2.new(1, 0, 0, 34)
head.BackgroundTransparency = 1
head.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.fromOffset(11, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = GREEN
title.Text = "NPC OR DIE ESP"
title.Parent = head

local track = Instance.new("TextButton")
track.Size = UDim2.fromOffset(44, 22)
track.Position = UDim2.fromOffset(11, 42)
track.BackgroundColor3 = GREEN
track.BorderSizePixel = 0
track.AutoButtonColor = false
track.Text = ""
track.Parent = panel
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(16, 16)
knob.Position = UDim2.fromOffset(25, 3)
knob.BackgroundColor3 = Color3.fromRGB(15, 17, 20)
knob.BorderSizePixel = 0
knob.Parent = track
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(120, 22)
label.Position = UDim2.fromOffset(64, 42)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamMedium
label.TextSize = 11
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextColor3 = GREEN
label.Text = "ON"
label.Parent = panel

local function setSwitch(on)
    Tween:Create(track, TweenInfo.new(0.15), {BackgroundColor3 = on and GREEN or TRACK}):Play()
    Tween:Create(knob, TweenInfo.new(0.15), {Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)}):Play()
    label.Text = on and "ON" or "OFF"
    label.TextColor3 = on and GREEN or OFF
end

track.MouseButton1Click:Connect(function()
    espOn = not espOn
    setSwitch(espOn)
    if espOn then scan() else clearAll() end
end)

local dragging, dragStart, startPos
head.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = panel.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                   startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then panel.Visible = not panel.Visible end
end)

task.spawn(function()
    while SG.Parent do
        pcall(scan)
        task.wait(0.15)
    end
end)

task.spawn(function()
    while SG.Parent do
        local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        for rig, o in pairs(objs) do
            local root = rig:FindFirstChild("HumanoidRootPart")
            local hum  = rig:FindFirstChildOfClass("Humanoid")
            local d = (myRoot and root) and math.floor((myRoot.Position - root.Position).Magnitude) or -1
            o.hp = hum and math.floor(hum.Health) or 0
            o.lab.Text = string.format("%s  [%dm]  %s", o.pl.DisplayName, d, o.hp > 0 and (o.hp .. "hp") or "DEAD")
            paint(o)
        end
        task.wait(0.25)
    end
end)

local function hook(pl)
    pl.CharacterAdded:Connect(function(ch)
        task.wait(0.05)
        if espOn and not gone(ch) then
            local old = held[pl]
            if old and old ~= ch then drop(old) end
            lock(pl, ch)
        end
    end)
    pl.CharacterRemoving:Connect(function(ch) drop(ch) end)
end
for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LP then hook(pl) end end
Players.PlayerAdded:Connect(hook)
Players.PlayerRemoving:Connect(function(pl)
    local r = held[pl]
    if r then drop(r) end
    held[pl] = nil
end)

scan()
