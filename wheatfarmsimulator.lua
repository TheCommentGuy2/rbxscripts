local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local PG = plr:WaitForChild("PlayerGui")
local RF = game:GetService("ReplicatedStorage").RemoteFunctions
local TS = game:GetService("TweenService")

local ANCHOR = Vector3.new(97.60, 46.39, -429.05)
local GY = 49.5
local MINX, MAXX = -100.1, 644.9
local MINZ, MAXZ = -352.6, 392.4

local F = {
    running = false, speed = 20, rebirth = false,
    rebirthBusy = false, sold = 0, rebirths = 0,
    collapsed = false, keybind = Enum.KeyCode.LeftControl, unloaded = false,
}
local function getHrp() local c = plr.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function invFull() return plr.Wheat.Value >= ((plr:GetAttribute("InventorySize") or 100) - 1) end
local function params()
    local d = 0.065 - (F.speed - 1) * 0.0006
    local b = F.speed >= 66 and 3 or (F.speed >= 34 and 2 or 1)
    return math.max(0.004, d), b
end

local lastBounds = { MINX, MAXX, MINZ, MAXZ }
local function sweepBounds()
    local minX, maxX, minZ, maxZ, yRef = math.huge, -math.huge, math.huge, -math.huge, nil
    for _, d in ipairs(workspace:GetChildren()) do
        if d:IsA("Model") and d:GetAttribute("Wheat") then
            local v3 = d:FindFirstChildWhichIsA("Vector3Value")
            if v3 then
                local p = v3.Value
                if p.X < minX then minX = p.X end
                if p.X > maxX then maxX = p.X end
                if p.Z < minZ then minZ = p.Z end
                if p.Z > maxZ then maxZ = p.Z end
                if not yRef then yRef = p.Y end
            end
        end
    end
    if yRef then
        GY = yRef + 3
        lastBounds = {
            math.floor(minX / 10) * 10, math.ceil(maxX / 10) * 10,
            math.floor(minZ / 10) * 10, math.ceil(maxZ / 10) * 10,
        }
    end
    return lastBounds[1], lastBounds[2], lastBounds[3], lastBounds[4]
end

local T = {
    window      = Color3.fromRGB(18, 22, 28),
    sidebar     = Color3.fromRGB(15, 19, 24),
    card        = Color3.fromRGB(24, 29, 35),
    raised      = Color3.fromRGB(30, 37, 45),
    border      = Color3.fromRGB(42, 49, 58),
    text        = Color3.fromRGB(255, 255, 255),
    subtext     = Color3.fromRGB(174, 182, 192),
    muted       = Color3.fromRGB(110, 118, 128),
    off         = Color3.fromRGB(43, 49, 56),
    accent      = Color3.fromRGB(45, 212, 224),
    onText      = Color3.fromRGB(11, 28, 32),

    font        = Enum.Font.GothamMedium,
    fontBold    = Enum.Font.GothamBold,

    rWindow     = UDim.new(0, 16),
    rCard       = UDim.new(0, 10),
    rControl    = UDim.new(0, 8),

    winW        = 580,
    winH        = 360,
    collapsed   = 46,
    sideW       = 162,
    pad         = 16,
    rowH        = 34,
    gap         = 10,
    fast        = 0.13,
    med         = 0.16,
}

local conns = {}
local function on(sig, fn)
    local c = sig:Connect(fn)
    table.insert(conns, c)
    return c
end
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = r c.Parent = p return c end
local function stroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col s.Thickness = th or 1 s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = p return s
end
local function tw(o, t, props)
    local a = TS:Create(o, TweenInfo.new(t or T.fast, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    a:Play() return a
end
local function lbl(parent, txt, size, col, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1 l.Text = txt
    l.TextColor3 = col or T.subtext l.Font = font or T.font l.TextSize = size or 12
    l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = parent
    return l
end

local function lineIcon(parent, kind, xoff)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.fromOffset(16, 16)
    holder.AnchorPoint = Vector2.new(0, 0.5)
    holder.Position = UDim2.new(0, xoff or 12, 0.5, 0)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local parts, strokes = {}, {}
    local function ln(w, h, px, py, rot, round)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.Position = UDim2.fromOffset(px, py)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BackgroundColor3 = T.subtext f.BorderSizePixel = 0
        f.Rotation = rot or 0 f.Parent = holder
        if round then corner(f, UDim.new(1, 0)) end
        table.insert(parts, f) return f
    end
    local function ring(w, h, px, py, r)
        local f = ln(w, h, px, py, 0, true)
        f.BackgroundTransparency = 1
        corner(f, UDim.new(r or 1, 0))
        table.insert(strokes, stroke(f, T.subtext, 1.5, 0))
        return f
    end

    if kind == "shield" then
        ring(10, 11, 8, 8, 0.35)
        ln(4, 1.4, 8, 9)
    elseif kind == "info" then
        ring(11, 11, 8, 8, 1)
        ln(1.4, 4, 8, 9)
    end

    return holder, function(col)
        for _, f in ipairs(parts) do f.BackgroundColor3 = col end
        for _, s in ipairs(strokes) do s.Color = col end
    end
end

local function chevron(parent, col)
    local h = Instance.new("Frame")
    h.Size = UDim2.fromOffset(10, 12)
    h.AnchorPoint = Vector2.new(1, 0.5)
    h.Position = UDim2.new(1, -12, 0.5, 0)
    h.BackgroundTransparency = 1 h.Parent = parent
    local a = Instance.new("Frame")
    a.Size = UDim2.fromOffset(1.5, 5) a.Position = UDim2.fromOffset(3, 2)
    a.AnchorPoint = Vector2.new(0.5, 0.5) a.BackgroundColor3 = col
    a.Rotation = 45 a.BorderSizePixel = 0 a.Parent = h
    local b = Instance.new("Frame")
    b.Size = UDim2.fromOffset(1.5, 5) b.Position = UDim2.fromOffset(3, 7)
    b.AnchorPoint = Vector2.new(0.5, 0.5) b.BackgroundColor3 = col
    b.Rotation = -45 b.BorderSizePixel = 0 b.Parent = h
end

local gui = Instance.new("ScreenGui")
gui.Name = "WheatFarm"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.Parent = PG

local main = Instance.new("CanvasGroup")
main.Size = UDim2.fromOffset(T.winW, T.winH)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = T.sidebar
main.BorderSizePixel = 0; main.Active = true; main.Parent = gui
corner(main, T.rWindow)
stroke(main, Color3.fromRGB(255, 255, 255), 1, 0.9)

local sc = Instance.new("UIScale"); sc.Scale = 0.96; sc.Parent = main
main.GroupTransparency = 1
tw(sc, 0.18, { Scale = 1 })
tw(main, 0.18, { GroupTransparency = 0 })

local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, 0)
body.BackgroundTransparency = 1; body.Parent = main

local contentPanel = Instance.new("Frame")
contentPanel.Position = UDim2.fromOffset(T.sideW, 0)
contentPanel.Size = UDim2.new(1, -T.sideW, 1, 0)
contentPanel.BackgroundColor3 = T.window
contentPanel.BorderSizePixel = 0; contentPanel.Parent = body
corner(contentPanel, T.rWindow)
local squarer = Instance.new("Frame")
squarer.Position = UDim2.fromOffset(-8, 0)
squarer.Size = UDim2.new(0, 26, 1, 0)
squarer.BackgroundColor3 = T.window
squarer.BorderSizePixel = 0; squarer.Parent = contentPanel

local panelHeader = lbl(contentPanel, "Main", 15, T.text, T.fontBold)
panelHeader.Position = UDim2.fromOffset(T.pad, 16)
panelHeader.Size = UDim2.new(1, -T.pad * 2, 0, 20)

local actionBar = Instance.new("Frame")
actionBar.Position = UDim2.new(0, 0, 1, -60)
actionBar.Size = UDim2.new(1, 0, 0, 60)
actionBar.BackgroundTransparency = 1; actionBar.Parent = contentPanel
local abLine = Instance.new("Frame")
abLine.Size = UDim2.new(1, -T.pad * 2, 0, 1)
abLine.Position = UDim2.fromOffset(T.pad, 0)
abLine.BackgroundColor3 = T.border
abLine.BackgroundTransparency = 0.45
abLine.BorderSizePixel = 0; abLine.Parent = actionBar

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(T.pad, 48)
scroll.Size = UDim2.new(1, -T.pad * 2, 1, -108)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
scroll.ScrollBarImageTransparency = 0.72
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.Parent = contentPanel

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, T.sideW, 1, 0)
sidebar.BackgroundTransparency = 1; sidebar.Parent = body

local tabs = Instance.new("ScrollingFrame")
tabs.Position = UDim2.fromOffset(10, 48)
tabs.Size = UDim2.new(1, -20, 1, -60)
tabs.BackgroundTransparency = 1
tabs.BorderSizePixel = 0
tabs.ScrollBarThickness = 3
tabs.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
tabs.ScrollBarImageTransparency = 0.8
tabs.CanvasSize = UDim2.new(0, 0, 0, 0)
tabs.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabs.ScrollingDirection = Enum.ScrollingDirection.Y
tabs.Parent = sidebar
local tl = Instance.new("UIListLayout")
tl.Padding = UDim.new(0, 4)
tl.SortOrder = Enum.SortOrder.LayoutOrder
tl.Parent = tabs

local tabButtons, panels = {}, {}
local activeTab = nil

local function refreshTab(n)
    local d = tabButtons[n]
    if not d then return end
    if d.tw then d.tw:Cancel() end
    local active = (activeTab == n)
    d.btn.BackgroundColor3 = active and T.raised or Color3.fromRGB(255, 255, 255)
    d.lab.TextColor3 = active and T.text or T.subtext
    d.ind.Visible = active
    d.tw = tw(d.btn, 0.12, { BackgroundTransparency = active and 0 or (d.hovering and 0.95 or 1) })
end

local function makeTab(name, order)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, T.rowH)
    b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    b.BackgroundTransparency = 1
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.Text = ""
    b.LayoutOrder = order
    b.Parent = tabs
    corner(b, T.rControl)

    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 2, 0, 16)
    ind.Position = UDim2.new(0, 0, 0.5, 0)
    ind.AnchorPoint = Vector2.new(0, 0.5)
    ind.BackgroundColor3 = T.accent
    ind.BorderSizePixel = 0
    ind.Visible = false
    ind.Parent = b
    corner(ind, UDim.new(1, 0))

    local lab = lbl(b, name, 12, T.subtext)
    lab.Position = UDim2.fromOffset(14, 0)
    lab.Size = UDim2.new(1, -22, 1, 0)
    lab.TextYAlignment = Enum.TextYAlignment.Center

    tabButtons[name] = { btn = b, lab = lab, ind = ind, hovering = false, tw = nil }

    on(b.MouseEnter, function()
        tabButtons[name].hovering = true
        refreshTab(name)
    end)
    on(b.MouseLeave, function()
        tabButtons[name].hovering = false
        refreshTab(name)
    end)
    on(b.MouseButton1Click, function() selectTab(name) end)
end

local function makePanel(name, order)
    local p = Instance.new("CanvasGroup")
    p.Size = UDim2.new(1, 0, 0, 0)
    p.AutomaticSize = Enum.AutomaticSize.Y
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.LayoutOrder = order
    p.Visible = false
    p.Parent = scroll
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, T.gap)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = p
    panels[name] = p
    return p
end

function selectTab(name)
    if activeTab == name then return end
    activeTab = name
    panelHeader.Text = name
    for n in pairs(tabButtons) do
        refreshTab(n)
    end
    for n, p in pairs(panels) do
        if n == name then
            p.Visible = true
            p.GroupTransparency = 1
            tw(p, 0.16, { GroupTransparency = 0 })
        else
            p.Visible = false
        end
    end
end

local mainPanel  = makePanel("Main", 1)
local farmPanel  = makePanel("Farming", 2)
local speedPanel = makePanel("Speed", 3)
local setPanel   = makePanel("Settings", 4)

makeTab("Main", 1)
makeTab("Farming", 2)
makeTab("Speed", 3)
makeTab("Settings", 4)

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(T.pad, 16)
title.Size = UDim2.new(0, 240, 0, 20)
title.BackgroundTransparency = 1
title.Text = "WF GUI"
title.TextColor3 = T.text
title.Font = T.fontBold; title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 4
title.Parent = main

local miniGlyph = Instance.new("Frame")
miniGlyph.Size = UDim2.fromOffset(16, 16)
miniGlyph.Position = UDim2.fromScale(0.5, 0.5)
miniGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
miniGlyph.BackgroundTransparency = 1
miniGlyph.ZIndex = 3
miniGlyph.Visible = false
miniGlyph.Parent = main
local function mline(w, h, px, py, rot)
    local f = Instance.new("Frame")
    f.Size = UDim2.fromOffset(w, h) f.Position = UDim2.fromOffset(px, py)
    f.AnchorPoint = Vector2.new(0.5, 0.5) f.BackgroundColor3 = T.accent
    f.BorderSizePixel = 0 f.Rotation = rot or 0 f.Parent = miniGlyph
    corner(f, UDim.new(1, 0))
end
mline(1.6, 12, 8, 8, -20)
mline(1.6, 7, 5, 5, -55)
mline(1.6, 7, 11, 11, -55)

local function topBtn(txt, xoff, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(24, 24)
    b.Position = UDim2.new(1, xoff, 0, 12)
    b.AnchorPoint = Vector2.new(1, 0)
    b.BackgroundColor3 = col or T.raised
    b.BackgroundTransparency = 0.25
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = T.subtext
    b.Font = T.fontBold; b.TextSize = 13
    b.AutoButtonColor = false
    b.ZIndex = 6
    b.Parent = main
    corner(b, T.rControl)
    on(b.MouseEnter, function() tw(b, 0.12, { BackgroundTransparency = 0, TextColor3 = T.text }) end)
    on(b.MouseLeave, function() tw(b, 0.12, { BackgroundTransparency = 0.25, TextColor3 = T.subtext }) end)
    return b
end
local minBtn = topBtn("_", -46, T.raised)
local closeBtn = topBtn("X", -14, T.raised)

local dragStrip = Instance.new("TextButton")
dragStrip.Size = UDim2.new(1, 0, 0, 48)
dragStrip.BackgroundTransparency = 1
dragStrip.Text = ""
dragStrip.AutoButtonColor = false
dragStrip.ZIndex = 2
dragStrip.Parent = main

local winDrag, winMoved = false, false
local dragOrigin, posOrigin

on(dragStrip.InputBegan, function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        winDrag = true winMoved = false
        dragOrigin = i.Position
        posOrigin = main.Position
    end
end)
on(UIS.InputChanged, function(i)
    if not winDrag then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - dragOrigin
        if math.abs(d.X) > 2 or math.abs(d.Y) > 2 then winMoved = true end
        main.Position = UDim2.new(posOrigin.X.Scale, posOrigin.X.Offset + d.X, posOrigin.Y.Scale, posOrigin.Y.Offset + d.Y)
    end
end)
on(UIS.InputEnded, function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        winDrag = false
    end
end)
on(dragStrip.MouseButton1Click, function()
    if F.collapsed and not winMoved then
        F.collapsed = false
        applyCollapse()
    end
end)

local function mkBtn(txt, y, h, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, h or T.rowH)
    b.BackgroundColor3 = col or T.raised
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = T.text
    b.Font = T.font; b.TextSize = 12
    b.AutoButtonColor = false
    b.Parent = body
    corner(b, T.rControl)
    return b
end

local function hoverBtn(b, base, hoverCol)
    on(b.MouseEnter, function() tw(b, 0.12, { BackgroundColor3 = hoverCol or base:Lerp(Color3.new(1, 1, 1), 0.08) }) end)
    on(b.MouseLeave, function() tw(b, 0.12, { BackgroundColor3 = base }) end)
end

local function card(parent, h)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, h)
    f.BackgroundColor3 = T.card
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, T.rCard)
    stroke(f, T.border, 1, 0.35)
    return f
end

local function notice(parent, kind, keyword, rest)
    local f = card(parent, 40)
    local _, tint = lineIcon(f, kind, 12)
    tint(T.accent)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.RichText = true
    l.Text = '<font color="#2DD4E0"><b>' .. keyword .. '</b></font> - ' .. rest
    l.TextColor3 = T.subtext
    l.Font = T.font; l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Position = UDim2.fromOffset(34, 0)
    l.Size = UDim2.new(1, -46, 1, 0)
    l.Parent = f
    return f
end

local function toggleRow(parent, name, desc)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.Parent = parent
    local l = lbl(row, name, 12, T.text)
    l.Position = UDim2.fromOffset(0, 4)
    l.Size = UDim2.new(1, -120, 0, 16)
    local d = lbl(row, desc, 10, T.muted)
    d.Position = UDim2.fromOffset(0, 22)
    d.Size = UDim2.new(1, -120, 0, 14)
    return row
end

local function placePill(btn)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.Size = UDim2.new(0, 0, 0, 24)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.Font = T.fontBold; btn.TextSize = 10
    btn.AutoButtonColor = false
    corner(btn, UDim.new(1, 0))
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 10) p.PaddingRight = UDim.new(0, 10)
    p.Parent = btn
    local c = Instance.new("UISizeConstraint")
    c.MinSize = Vector2.new(52, 24) c.MaxSize = Vector2.new(150, 24)
    c.Parent = btn
end

local function styleToggle(btn, isOn)
    tw(btn, 0.15, {
        BackgroundColor3 = isOn and T.accent or T.off,
        TextColor3 = isOn and T.onText or T.text,
    })
end

local statusCard = card(mainPanel, 82)
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 18); status.Position = UDim2.fromOffset(12, 10)
status.BackgroundTransparency = 1; status.Text = "idle"
status.TextColor3 = T.text; status.Font = T.font
status.TextSize = 12; status.TextXAlignment = Enum.TextXAlignment.Left; status.Parent = statusCard

local stats = Instance.new("TextLabel")
stats.Size = UDim2.new(1, -24, 0, 48); stats.Position = UDim2.fromOffset(12, 30)
stats.BackgroundTransparency = 1; stats.Text = "wheat: 0\nsold: 0\nrebirths: 0"
stats.TextColor3 = T.subtext; stats.Font = T.font
stats.TextSize = 11; stats.TextXAlignment = Enum.TextXAlignment.Left
stats.TextYAlignment = Enum.TextYAlignment.Top; stats.Parent = statusCard

notice(mainPanel, "info", "F2", "unloads the script and closes the menu")

local rbRow = toggleRow(farmPanel, "Auto Rebirth", "Rebirth automatically when gold allows")
local rbBtn = mkBtn("Auto Rebirth: OFF", 112, 24, T.off)
rbBtn.Parent = rbRow
placePill(rbBtn)
rbBtn.TextColor3 = T.text
rbBtn.BackgroundColor3 = T.off

local rbLbl = lbl(farmPanel, "cost: ?", 10, T.muted)
rbLbl.Size = UDim2.new(1, 0, 0, 14)

local speedLbl = lbl(speedPanel, "speed " .. F.speed, 12, T.subtext)
speedLbl.Size = UDim2.new(1, 0, 0, 16)

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 24)
bar.BackgroundTransparency = 1; bar.Parent = speedPanel

local track = Instance.new("Frame")
track.Size = UDim2.new(1, 0, 0, 4)
track.Position = UDim2.new(0, 0, 0.5, -2)
track.BackgroundColor3 = T.off
track.BorderSizePixel = 0; track.Parent = bar
corner(track, UDim.new(1, 0))

local fill = Instance.new("Frame")
fill.Size = UDim2.new((F.speed - 1) / 99, 0, 1, 0); fill.BackgroundColor3 = T.accent
fill.BorderSizePixel = 0; fill.Parent = track
corner(fill, UDim.new(1, 0))

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(14, 14)
knob.Position = UDim2.new(1, 0, 0.5, 0)
knob.AnchorPoint = Vector2.new(1, 0.5)
knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
knob.BorderSizePixel = 0; knob.Parent = fill
corner(knob, UDim.new(1, 0))
stroke(knob, Color3.fromRGB(0, 0, 0), 1, 0.8)

local function setSpeed(v)
    F.speed = math.clamp(math.floor(v + 0.5), 1, 100)
    fill.Size = UDim2.new((F.speed - 1) / 99, 0, 1, 0)
    speedLbl.Text = "speed " .. F.speed
end
setSpeed(F.speed)
local sliderDrag = false
local function fromX(x)
    local rel = (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
    setSpeed(math.clamp(rel, 0, 1) * 99 + 1)
end
on(bar.InputBegan, function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        sliderDrag = true; fromX(i.Position.X)
    end
end)
on(UIS.InputChanged, function(i)
    if sliderDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        fromX(i.Position.X)
    end
end)
on(UIS.InputEnded, function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        sliderDrag = false
    end
end)

local keyLbl = lbl(setPanel, "MINIMISE KEY", 10, T.muted)
keyLbl.Size = UDim2.new(1, 0, 0, 14)

local keyBtn = mkBtn("Minimise key: LeftControl", 160, 34, T.card)
keyBtn.Parent = setPanel
keyBtn.BackgroundColor3 = T.card
keyBtn.TextColor3 = T.text
keyBtn.TextXAlignment = Enum.TextXAlignment.Left
keyBtn.Font = T.font; keyBtn.TextSize = 12
stroke(keyBtn, T.border, 1, 0.4)
local kp = Instance.new("UIPadding"); kp.PaddingLeft = UDim.new(0, 12); kp.Parent = keyBtn
chevron(keyBtn, T.muted)
hoverBtn(keyBtn, T.card, T.raised)

local startBtn = mkBtn("START", 190, 34, T.accent)
startBtn.Size = UDim2.new(0.5, -21, 0, 34)
startBtn.Position = UDim2.fromOffset(T.pad, 12)
startBtn.TextColor3 = T.onText
startBtn.Font = T.fontBold; startBtn.TextSize = 12
startBtn.Parent = actionBar

local stopBtn = mkBtn("STOP", 226, 34, T.raised)
stopBtn.Size = UDim2.new(0.5, -21, 0, 34)
stopBtn.Position = UDim2.new(0.5, 5, 0, 12)
stopBtn.Font = T.fontBold; stopBtn.TextSize = 12
stopBtn.Parent = actionBar

local function syncButtons()
    if F.running then
        tw(startBtn, 0.15, { BackgroundColor3 = T.raised, TextColor3 = T.subtext })
        tw(stopBtn, 0.15, { BackgroundColor3 = T.accent, TextColor3 = T.onText })
    else
        tw(startBtn, 0.15, { BackgroundColor3 = T.accent, TextColor3 = T.onText })
        tw(stopBtn, 0.15, { BackgroundColor3 = T.raised, TextColor3 = T.text })
    end
end
on(startBtn.MouseEnter, function() tw(startBtn, 0.12, { BackgroundColor3 = startBtn.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.12) }) end)
on(startBtn.MouseLeave, syncButtons)
on(stopBtn.MouseEnter, function() tw(stopBtn, 0.12, { BackgroundColor3 = stopBtn.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.12) }) end)
on(stopBtn.MouseLeave, syncButtons)

local function applyCollapse()
    body.Visible = not F.collapsed
    title.Visible = not F.collapsed
    minBtn.Visible = not F.collapsed
    closeBtn.Visible = not F.collapsed
    miniGlyph.Visible = F.collapsed
    main.Size = F.collapsed and UDim2.fromOffset(T.collapsed, T.collapsed) or UDim2.fromOffset(T.winW, T.winH)
end
on(minBtn.MouseButton1Click, function() F.collapsed = not F.collapsed applyCollapse() end)
on(closeBtn.MouseButton1Click, function() gui.Enabled = false end)

local function getCost()
    local ok, h = pcall(require, plr.PlayerScripts.LocalManager.Client)
    if ok and h and h.GetRebirthCost then
        local ok2, c = pcall(h.GetRebirthCost)
        if ok2 and type(c) == "number" then return c end
    end
    return 100000000
end

local function sell()
    local hrp = getHrp(); if not hrp then return end
    local had = plr.Wheat.Value
    hrp.CFrame = CFrame.new(ANCHOR + Vector3.new(0, 3, 0))
    local t = 0
    while plr.Wheat.Value > 2 and t < 2 and F.running do task.wait(0.1) t = t + 0.1 end
    F.sold = F.sold + math.max(0, had - plr.Wheat.Value)
    task.wait(0.12)
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if F.unloaded then break end
        if F.running then
            pcall(function()
                local n = PG:FindFirstChild("UI") and PG.UI:FindFirstChild("Notif")
                if n and n.Visible then n.Visible = false end
                plr:SetAttribute("FullInv", true)
            end)
            stats.Text = "wheat: " .. plr.Wheat.Value .. "\nsold: " .. F.sold .. "\nrebirths: " .. F.rebirths
            local cost = getCost()
            rbLbl.Text = "cost: " .. string.format("%.3g", cost)
            if F.rebirth and not F.rebirthBusy then
                local gold = plr.leaderstats and plr.leaderstats.Gold.Value or 0
                if gold >= cost then
                    F.rebirthBusy = true
                    status.Text = "rebirthing..."
                    local ok, data, err = pcall(function() return RF.Rebirth:InvokeServer() end)
                    if ok and data then
                        F.rebirths = F.rebirths + 1
                        status.Text = "rebirthed"
                    else
                        status.Text = "rebirth failed"
                        if not ok then warn("[WF] " .. tostring(data)) end
                    end
                    task.wait(1.5)
                    F.rebirthBusy = false
                end
            end
        end
    end
end)

local function patrol()
    while F.running do
        local delay, batch = params()
        local cols = math.floor((MAXX - MINX) / 10)
        local rows = math.floor((MAXZ - MINZ) / 10)
        for r = 0, rows do
            if not F.running then break end
            local z = MINZ + r * 10
            local flip = (r % 2 == 1)
            local i = 0
            while i <= cols do
                if not F.running then break end
                while F.rebirthBusy do task.wait(0.01) end
                local hrp = getHrp()
                if not hrp then task.wait(0.2) else
                    delay, batch = params()
                    for k = 0, batch - 1 do
                        local idx = i + k
                        if idx > cols then break end
                        local x = MINX + (flip and (cols - idx) or idx) * 10
                        hrp.CFrame = CFrame.new(x, GY, z)
                    end
                    i = i + batch
                    task.wait(delay)
                    if invFull() then sell() end
                end
            end
        end
    end
end

on(startBtn.MouseButton1Click, function()
    if F.running then return end
    if not getHrp() then status.Text = "no character" return end
    F.running = true; F.rebirthBusy = false
    status.Text = "running"
    syncButtons()
    task.spawn(patrol)
end)
on(stopBtn.MouseButton1Click, function()
    F.running = false
    status.Text = "stopped"
    syncButtons()
end)

on(rbBtn.MouseButton1Click, function()
    F.rebirth = not F.rebirth
    rbBtn.Text = "Auto Rebirth: " .. (F.rebirth and "ON" or "OFF")
    styleToggle(rbBtn, F.rebirth)
end)

local captureKey = false
on(keyBtn.MouseButton1Click, function()
    captureKey = true; keyBtn.Text = "press a key..."
end)

local function unload()
    if F.unloaded then return end
    F.unloaded = true
    F.running = false
    F.rebirthBusy = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    table.clear(conns)
    gui:Destroy()
end

on(UIS.InputBegan, function(i, gp)
    if gp then return end
    if captureKey then
        captureKey = false
        F.keybind = i.KeyCode
        keyBtn.Text = "Minimise key: " .. i.KeyCode.Name
        return
    end
    if i.KeyCode == F.keybind then
        if not gui.Enabled then
            gui.Enabled = true
        else
            F.collapsed = not F.collapsed
            applyCollapse()
        end
    elseif i.KeyCode == Enum.KeyCode.F2 then
        unload()
    end
end)

selectTab("Main")
syncButtons()

print("[WF GUI] loaded.")
