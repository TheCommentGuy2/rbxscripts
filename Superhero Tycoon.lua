local plr = game:GetService("Players").LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local pg = plr:WaitForChild("PlayerGui")
local uis = game:GetService("UserInputService")

if getgenv().STGui then pcall(function() getgenv().STGui:Destroy() end) end

local idx = rs:WaitForChild("SharedPackages"):FindFirstChild("_Index")
local pkg = idx and idx:FindFirstChild("sleitnick_net@0.1.0")
local net = pkg and pkg:FindFirstChild("net")
local RF = net and net:FindFirstChild("RF/HandleTycoonGiverPlayerRequest")
if not RF then warn("[ST] remote missing") return end

local toggleKey = getgenv().STKey or Enum.KeyCode.RightShift

local function isMisc(name)
    return string.find(name, "Island", 1, true) ~= nil or string.sub(name, 1, 6) == "Giver_"
end

local function heroOf(ty)
    local ex = ty:FindFirstChild("Extras")
    if ex then
        local gp = ex:FindFirstChild("Ground")
        local bl = gp and gp:FindFirstChild("Primary")
        bl = bl and bl:FindFirstChild("BillboardGui")
        local hl = bl and bl:FindFirstChild("HeroName")
        if hl and hl.Text ~= "" then return hl.Text end
    end
end

local sg = Instance.new("ScreenGui")
sg.Name = "STGrabber"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.Parent = pg
getgenv().STGui = sg

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(320, 400)
main.Position = getgenv().STPos or UDim2.new(0, 60, 0, 90)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Active = true
main.Parent = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
local st = Instance.new("UIStroke", main)
st.Color = Color3.fromRGB(0, 170, 255)
st.Thickness = 1.5

local mini = Instance.new("TextButton")
mini.Size = UDim2.fromOffset(46, 46)
mini.Position = main.Position
mini.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mini.BorderSizePixel = 0
mini.Text = "ST"
mini.TextColor3 = Color3.fromRGB(120, 210, 255)
mini.Font = Enum.Font.GothamBold
mini.TextSize = 15
mini.Visible = false
mini.Parent = sg
Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 8)
local ms = Instance.new("UIStroke", mini)
ms.Color = Color3.fromRGB(0, 170, 255)
ms.Thickness = 1.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -164, 0, 28)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "Superhero Tycoon GUI"
title.TextColor3 = Color3.fromRGB(120, 210, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local keyBtn = Instance.new("TextButton")
keyBtn.Size = UDim2.fromOffset(56, 24)
keyBtn.Position = UDim2.new(1, -124, 0, 4)
keyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
keyBtn.BorderSizePixel = 0
keyBtn.Text = toggleKey.Name
keyBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
keyBtn.Font = Enum.Font.GothamBold
keyBtn.TextSize = 10
keyBtn.Parent = main
Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(24, 24)
minBtn.Position = UDim2.new(1, -58, 0, 4)
minBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
minBtn.BorderSizePixel = 0
minBtn.Text = "_"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 13
minBtn.Parent = main
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(24, 24)
close.Position = UDim2.new(1, -30, 0, 4)
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.BorderSizePixel = 0
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextSize = 12
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function() sg:Destroy() end)

local capturing = false
keyBtn.MouseButton1Click:Connect(function()
    capturing = true
    keyBtn.Text = "press..."
    keyBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
end)

local function setMinimized(on)
    if on then
        mini.Position = main.Position
        main.Visible = false
        mini.Visible = true
    else
        main.Position = mini.Position
        getgenv().STPos = mini.Position
        mini.Visible = false
        main.Visible = true
    end
end

minBtn.MouseButton1Click:Connect(function() setMinimized(true) end)

local dragging, dragStart, startPos, dragTarget, dragMoved

local function beginDrag(i, target)
    dragging = true
    dragMoved = false
    dragStart = i.Position
    startPos = target.Position
    dragTarget = target
end

title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        beginDrag(i, main)
    end
end)

mini.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        beginDrag(i, mini)
    end
end)

local function endDrag(i)
    if not dragging then return end
    dragging = false
    if dragTarget == mini and not dragMoved then
        setMinimized(false)
    end
    if dragTarget then getgenv().STPos = dragTarget.Position end
    dragTarget = nil
end

title.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then endDrag(i) end
end)
mini.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then endDrag(i) end
end)

uis.InputChanged:Connect(function(i)
    if dragging and dragTarget then
        local d = i.Position - dragStart
        if math.abs(d.X) > 4 or math.abs(d.Y) > 4 then dragMoved = true end
        dragTarget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

uis.InputBegan:Connect(function(i, gp)
    if gp then return end
    if capturing then
        if i.KeyCode ~= Enum.KeyCode.Unknown then
            toggleKey = i.KeyCode
            getgenv().STKey = i.KeyCode
            keyBtn.Text = i.KeyCode.Name
            keyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            capturing = false
        end
        return
    end
    if i.KeyCode == toggleKey then
        if main.Visible then setMinimized(true) else setMinimized(false) end
    end
end)

local tabs = Instance.new("Frame")
tabs.Size = UDim2.new(1, -20, 0, 26)
tabs.Position = UDim2.fromOffset(10, 34)
tabs.BackgroundTransparency = 1
tabs.Parent = main

local function mkTab(text, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.3333, -4, 1, 0)
    b.Position = UDim2.new(0, x, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(36, 36, 43)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(200, 200, 200)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = tabs
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local toolsTab = mkTab("TOOLS", 0)
local morphTab = mkTab("MORPHS", 0.3333 * 300 + 4)
local miscTab = mkTab("MISC", 0.6666 * 300 + 8)

local function mkScroll()
    local f = Instance.new("ScrollingFrame")
    f.Size = UDim2.new(1, -20, 1, -110)
    f.Position = UDim2.fromOffset(10, 66)
    f.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    f.BorderSizePixel = 0
    f.ScrollBarThickness = 6
    f.CanvasSize = UDim2.new()
    f.Parent = main
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0, 4)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    return f
end

local toolsScroll = mkScroll()
local morphScroll = mkScroll()
local miscScroll = mkScroll()

local grabAll = Instance.new("TextButton")
grabAll.Size = UDim2.new(1, -20, 0, 32)
grabAll.Position = UDim2.new(0, 10, 1, -42)
grabAll.BackgroundColor3 = Color3.fromRGB(0, 120, 190)
grabAll.BorderSizePixel = 0
grabAll.Text = "GRAB ALL"
grabAll.TextColor3 = Color3.new(1, 1, 1)
grabAll.Font = Enum.Font.GothamBold
grabAll.TextSize = 13
grabAll.Parent = main
Instance.new("UICorner", grabAll).CornerRadius = UDim.new(0, 6)

local grabMisc = Instance.new("TextButton")
grabMisc.Size = UDim2.new(1, -20, 0, 32)
grabMisc.Position = UDim2.new(0, 10, 1, -42)
grabMisc.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
grabMisc.BorderSizePixel = 0
grabMisc.Text = "GRAB ALL MISC"
grabMisc.TextColor3 = Color3.new(1, 1, 1)
grabMisc.Font = Enum.Font.GothamBold
grabMisc.TextSize = 13
grabMisc.Visible = false
grabMisc.Parent = main
Instance.new("UICorner", grabMisc).CornerRadius = UDim.new(0, 6)

local function showTab(which)
    toolsScroll.Visible = which == "tools"
    morphScroll.Visible = which == "morph"
    miscScroll.Visible = which == "misc"
    grabAll.Visible = which == "tools"
    grabMisc.Visible = which == "misc"
    toolsTab.BackgroundColor3 = which == "tools" and Color3.fromRGB(0, 120, 190) or Color3.fromRGB(36, 36, 43)
    morphTab.BackgroundColor3 = which == "morph" and Color3.fromRGB(0, 120, 190) or Color3.fromRGB(36, 36, 43)
    miscTab.BackgroundColor3 = which == "misc" and Color3.fromRGB(120, 80, 0) or Color3.fromRGB(36, 36, 43)
end
toolsTab.MouseButton1Click:Connect(function() showTab("tools") end)
morphTab.MouseButton1Click:Connect(function() showTab("morph") end)
miscTab.MouseButton1Click:Connect(function() showTab("misc") end)

local busy = false

local function liveTycoons()
    local out = {}
    for _, ty in ipairs(workspace.Tycoons:GetChildren()) do
        local id = tonumber(ty.Name)
        local con = ty:FindFirstChild("Constructs")
        if id and con then
            local heroSlots = {}
            local pw = con:FindFirstChild("PowerGiver")
            if pw then
                for _, m in ipairs(pw:GetChildren()) do
                    if not isMisc(m.Name) then table.insert(heroSlots, m.Name) end
                end
            end
            table.insert(out, {
                id = id,
                hero = heroOf(ty) or ("Unknown " .. id),
                slots = heroSlots,
                outfit = con:FindFirstChild("OutfitGiver") ~= nil,
            })
        end
    end
    table.sort(out, function(a, b) return a.hero < b.hero end)
    return out
end

local function miscSlots()
    local map = {}
    local order = {}
    for _, ty in ipairs(workspace.Tycoons:GetChildren()) do
        local id = tonumber(ty.Name)
        local con = ty:FindFirstChild("Constructs")
        local pw = con and con:FindFirstChild("PowerGiver")
        if id and pw then
            for _, m in ipairs(pw:GetChildren()) do
                if isMisc(m.Name) and not map[m.Name] then
                    map[m.Name] = { id = id, giver = m.Name }
                    table.insert(order, m.Name)
                end
            end
        end
    end
    table.sort(order)
    return map, order
end

local function grabSlot(id, giver, btn, label)
    local ok, a = pcall(function() return RF:InvokeServer(id, "Power", giver) end)
    if btn then
        btn.Text = "  " .. label .. (ok and a and "   ok" or "   --")
        task.delay(1.2, function()
            if btn and btn.Parent then btn.Text = "  " .. label end
        end)
    end
    return ok and a ~= nil
end

local function grabTycoon(entry, btn)
    local got = 0
    for i, slot in ipairs(entry.slots) do
        if grabSlot(entry.id, slot, nil, slot) then got += 1 end
        if btn then btn.Text = "  " .. entry.hero .. "   " .. got .. "/" .. i end
        task.wait(0.3)
    end
    if btn then btn.Text = "  " .. entry.hero end
end

local function resetChar()
    local ch = plr.Character
    local h = ch and ch:FindFirstChildOfClass("Humanoid")
    if h then h.Health = 0 end
end

local function morph(entry, btn)
    if not entry.outfit then return end
    if btn then btn.Text = "  clearing..." end
    resetChar()
    local ch = plr.CharacterAdded:Wait()
    ch:WaitForChild("HumanoidRootPart")
    task.wait(1.5)
    pcall(function() return RF:InvokeServer(entry.id, "Outfit", "Outfit") end)
    if btn then btn.Text = "  " .. entry.hero end
end

local function row(parent, label, order, cb, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 0, 28)
    b.BackgroundColor3 = color or Color3.fromRGB(42, 50, 60)
    b.BorderSizePixel = 0
    b.Text = "  " .. label
    b.TextColor3 = Color3.fromRGB(225, 225, 230)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.LayoutOrder = order
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function build()
    local keepT = toolsScroll.CanvasPosition
    local keepM = morphScroll.CanvasPosition
    local keepX = miscScroll.CanvasPosition
    for _, f in ipairs({toolsScroll, morphScroll, miscScroll}) do
        for _, c in ipairs(f:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
    end

    local list = liveTycoons()
    for i, e in ipairs(list) do
        row(toolsScroll, e.hero, i, function()
            if busy then return end
            busy = true
            local b = toolsScroll:FindFirstChild("x")
            task.spawn(function() grabTycoon(e, nil) busy = false end)
        end)
        if e.outfit then
            row(morphScroll, e.hero, i, function()
                task.spawn(morph, e, nil)
            end)
        end
    end

    local map, order = miscSlots()
    for i, name in ipairs(order) do
        row(miscScroll, name, i, function()
            local src = map[name]
            if src then grabSlot(src.id, src.giver, nil, name) end
        end, Color3.fromRGB(52, 45, 34))
    end

    toolsScroll.CanvasSize = UDim2.new(0, 0, 0, #list * 32 + 8)
    morphScroll.CanvasSize = UDim2.new(0, 0, 0, #list * 32 + 8)
    miscScroll.CanvasSize = UDim2.new(0, 0, 0, #order * 32 + 8)
    toolsScroll.CanvasPosition = keepT
    morphScroll.CanvasPosition = keepM
    miscScroll.CanvasPosition = keepX
end

grabAll.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    grabAll.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    task.spawn(function()
        local total, got = 0, 0
        local list = liveTycoons()
        for _, e in ipairs(list) do total += #e.slots end
        for _, e in ipairs(list) do
            for _, slot in ipairs(e.slots) do
                if grabSlot(e.id, slot, nil, slot) then got += 1 end
                grabAll.Text = got .. " / " .. total
                task.wait(0.3)
            end
        end
        grabAll.Text = "GRAB ALL"
        grabAll.BackgroundColor3 = Color3.fromRGB(0, 120, 190)
        busy = false
    end)
end)

grabMisc.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    grabMisc.BackgroundColor3 = Color3.fromRGB(70, 60, 40)
    task.spawn(function()
        local map, order = miscSlots()
        local got = 0
        for i, name in ipairs(order) do
            local src = map[name]
            if src and grabSlot(src.id, src.giver, nil, name) then got += 1 end
            grabMisc.Text = "MISC " .. got .. " / " .. i
            task.wait(0.3)
        end
        grabMisc.Text = "GRAB ALL MISC"
        grabMisc.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
        busy = false
    end)
end)

showTab("tools")
build()
task.spawn(function()
    local last = ""
    while sg.Parent do
        task.wait(0.25)
        if not busy then
            local sig = ""
            for _, ty in ipairs(workspace.Tycoons:GetChildren()) do
                sig = sig .. ty.Name .. (heroOf(ty) or "?") .. ","
            end
            if sig ~= last then
                last = sig
                build()
            end
        end
    end
end)
