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

local function rigOk(rig)
    if not rig or rig.Parent == nil then return false end
    if not rig:IsDescendantOf(workspace) then return false end
    return rig:FindFirstChildOfClass("Humanoid") ~= nil
end

local function headOf(rig)
    return rig:FindFirstChild("Head")
        or rig:FindFirstChild("HumanoidRootPart")
        or rig.PrimaryPart
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

local function ownedElsewhere(rig, pl)
    for p, r in pairs(held) do
        if p ~= pl and r == rig then return true end
    end
    return false
end

local function lock(pl, rig)
    if pl == LP or objs[rig] or not rigOk(rig) or ownedElsewhere(rig, pl) then return end
    local head = headOf(rig)
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

    local o = {hl = hl, bb = bb, lab = lab, pl = pl, rig = rig, hp = 100}
    objs[rig] = o
    held[pl] = rig
    paint(o)
end

local function drop(rig)
    local o = objs[rig]
    if not o then return end
    o.hl:Destroy()
    o.bb:Destroy()
    objs[rig] = nil
    if held[o.pl] == rig then held[o.pl] = nil end
end

local function clearAll()
    local keys = {}
    for r in pairs(objs) do keys[#keys + 1] = r end
    for _, r in ipairs(keys) do drop(r) end
    held = {}
end

local rigs, cacheAt = {}, 0
local function refreshRigs()
    local now = os.clock()
    if now - cacheAt < 0.5 then return end
    cacheAt = now
    table.clear(rigs)
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Humanoid") then
            local m = d.Parent
            if m and m:IsA("Model") then
                local list = rigs[m.Name]
                if not list then list = {}; rigs[m.Name] = list end
                list[#list + 1] = m
            end
        end
    end
end

local function nearestToMe(list)
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return list[1] end
    local best, bestD
    for _, m in ipairs(list) do
        local r = m:FindFirstChild("HumanoidRootPart")
        if r then
            local d = (myRoot.Position - r.Position).Magnitude
            if not bestD or d < bestD then best, bestD = m, d end
        end
    end
    return best
end

local function chooseRig(pl)
    local ch = pl.Character
    if rigOk(ch) then return ch end
    local list = rigs[pl.Name]
    if list and #list > 0 then
        local pick = nearestToMe(list)
        if pick and rigOk(pick) then return pick end
    end
    return nil
end

local function ensure(pl)
    local want = chooseRig(pl)
    local cur  = held[pl]

    if want ~= cur then
        if cur then drop(cur) end
        if want then lock(pl, want) end
        return
    end

    if cur then
        local o = objs[cur]
        if not o then return end
        local h = headOf(cur)
        if h and o.bb.Adornee ~= h then
            o.bb.Adornee = h
            if o.hl.Adornee ~= cur then o.hl.Adornee = cur end
        end
    end
end

local function scan()
    if not espOn then return end
    refreshRigs()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP then pcall(ensure, pl) end
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

local function hook(pl)
    pl.CharacterAdded:Connect(function()
        task.wait(0.05)
        if espOn then pcall(ensure, pl) end
    end)
    pl.CharacterRemoving:Connect(function(ch) drop(ch) end)
    pl:GetPropertyChangedSignal("Team"):Connect(function()
        local o = objs[held[pl]]
        if o then paint(o) end
    end)
end
for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LP then hook(pl) end end
Players.PlayerAdded:Connect(hook)
Players.PlayerRemoving:Connect(function(pl)
    local r = held[pl]
    if r then drop(r) end
    held[pl] = nil
end)

task.spawn(function()
    while SG.Parent do
        pcall(scan)
        task.wait(0.1)
    end
end)

task.spawn(function()
    while SG.Parent do
        local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local keys = {}
        for rig in pairs(objs) do keys[#keys + 1] = rig end
        for _, rig in ipairs(keys) do
            local o = objs[rig]
            if o then
                local root = rig:FindFirstChild("HumanoidRootPart")
                local hum  = rig:FindFirstChildOfClass("Humanoid")
                local d = (myRoot and root) and math.floor((myRoot.Position - root.Position).Magnitude) or -1
                o.hp = hum and math.floor(hum.Health) or 0
                o.lab.Text = string.format("%s  [%dm]  %s", o.pl.DisplayName, d, o.hp > 0 and (o.hp .. "hp") or "DEAD")
                paint(o)
            end
        end
        task.wait(0.2)
    end
end)

scan()
