local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local lp = Players.LocalPlayer

if _G.FSR_UNLOAD then pcall(_G.FSR_UNLOAD) end

local THEME = {
	Font       = Enum.Font.Gotham,
	FontMedium = Enum.Font.GothamMedium,
	FontBold   = Enum.Font.GothamBold,

	Window     = Color3.fromRGB(18, 22, 28),
	Sidebar    = Color3.fromRGB(15, 19, 24),
	Surface    = Color3.fromRGB(24, 29, 35),
	Raised     = Color3.fromRGB(30, 37, 45),
	Stroke     = Color3.fromRGB(42, 49, 58),
	HoverBg    = Color3.fromRGB(30, 35, 42),
	Off        = Color3.fromRGB(43, 49, 56),
	Text       = Color3.fromRGB(255, 255, 255),
	TextDim    = Color3.fromRGB(174, 182, 192),
	TextFaint  = Color3.fromRGB(122, 130, 140),
	Accent     = Color3.fromRGB(45, 212, 224),
	AccentDeep = Color3.fromRGB(21, 47, 53),

	W          = 580,
	H          = 400,
	SidebarW   = 162,
	Pad        = 18,

	RWindow    = 16,
	RCard      = 10,
	RControl   = 8,
	RRow       = 8,
	RowH       = 34,
	PillW      = 52,
	PillH      = 24,

	Tween      = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	TweenSlow  = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

local Z_BASE    = 10
local Z_HEAD    = 12
local Z_HEADBTN = 13
local Z_SIDE    = 11
local Z_SIDECHLD = 12
local Z_EMBLEM  = 30
local Z_MAIN    = 2
local Z_SHADOW  = 1
local Z_ICON    = 20

local S = { screen = true, ragdoll = true, move = true, tp = true, mute = true,
	recover = false, float = UIS.TouchEnabled }
local api = {
	running = false, standoff = 9, retreat = 30, escapeH = 60,
	allow = {}, resume = true,
	kills = 0, dmg = 0, t0 = 0, preferName = nil,
	toggleKey = Enum.KeyCode.RightShift,
}
local conns = {}
local function addC(c) table.insert(conns, c) return c end

local char, hum, hrp, enemies, Input
local lastGood = Vector3.zero
local prevPos = Vector3.zero
local armedAt = 0
local armedUntil = 0
local restores = 0
local stats = { flops = 0, yanks = 0, manual = 0, releases = 0 }
local savedVol = nil
local escaping = false
local target
local filterText = ""
local known = {}
local seen = {}
local lastTravel = 0
local tick = 0

local ok, err = pcall(function()

local alive = true
local baseWalk = 16
local floatGui, fbtn

local function corner(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = o
	return c
end

local function pillCorner(o)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = o
	return c
end

local function strokeOf(o, col, tr)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = 1
	s.Transparency = tr or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end

local function tw(o, props)
	TweenService:Create(o, THEME.Tween, props):Play()
end

local function deathScreen()
	return lp.PlayerGui and lp.PlayerGui:FindFirstChild("Death Screen")
end

local function parentGui()
	local o, h = pcall(function() return gethui() end)
	if o and h then return h end
	local o2, cg = pcall(function() return game:GetService("CoreGui") end)
	if o2 and cg then return cg end
	return lp:WaitForChild("PlayerGui")
end

local sg = Instance.new("ScreenGui")
sg.Name = "FSR"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999
sg.Parent = parentGui()

local icon = Instance.new("TextButton")
icon.Size = UDim2.fromOffset(44, 44)
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.new(0.5, 0, 0.5, 0)
icon.BackgroundColor3 = THEME.Window
icon.BorderSizePixel = 0
icon.Font = THEME.FontBold
icon.TextSize = 12
icon.TextColor3 = THEME.Accent
icon.Text = "FSR"
icon.Visible = false
icon.ZIndex = Z_ICON
icon.Parent = sg
corner(icon, 12)
strokeOf(icon, THEME.Accent, 0.35)

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(THEME.W, THEME.H)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = THEME.Window
main.BackgroundTransparency = 0.04
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.ZIndex = Z_MAIN
main.Parent = sg
corner(main, THEME.RWindow)
strokeOf(main, Color3.fromRGB(255, 255, 255), 0.94)

local openScale = Instance.new("UIScale")
openScale.Scale = 0.96
openScale.Parent = main
tw(openScale, { Scale = 1 })

local head = Instance.new("Frame")
head.Size = UDim2.new(1, 0, 0, 34)
head.BackgroundTransparency = 1
head.BorderSizePixel = 0
head.ZIndex = Z_HEAD
head.Parent = main

local function headBtn(txt, x, col, txtcol)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(22, 22)
	b.Position = UDim2.new(1, x, 0, 6)
	b.BackgroundColor3 = col
	b.BackgroundTransparency = 1
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Font = THEME.FontMedium
	b.TextSize = 12
	b.TextColor3 = txtcol
	b.Text = txt
	b.ZIndex = Z_HEADBTN
	b.Parent = head
	corner(b, 7)
	b.MouseEnter:Connect(function()
		b.BackgroundColor3 = THEME.Raised
		b.BackgroundTransparency = 0
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundTransparency = 1
	end)
	return b
end

local minBtn = headBtn("–", -62, THEME.Raised, THEME.TextDim)
local closeBtn = headBtn("×", -34, THEME.Raised, THEME.TextDim)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.fromOffset(THEME.SidebarW, THEME.H)
sidebar.BackgroundColor3 = THEME.Sidebar
sidebar.BorderSizePixel = 0
sidebar.ZIndex = Z_SIDE
sidebar.Parent = main
corner(sidebar, THEME.RWindow)

local title = Instance.new("TextLabel")
title.Size = UDim2.fromOffset(THEME.SidebarW - 32, 20)
title.Position = UDim2.fromOffset(16, 16)
title.BackgroundTransparency = 1
title.Font = THEME.FontBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
title.TextColor3 = THEME.Text
title.Text = "FS:R HUB"
title.ZIndex = Z_SIDECHLD
title.Parent = sidebar

local function makeTab(txt, y, glyph)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -24, 0, THEME.RowH)
	b.Position = UDim2.fromOffset(12, y)
	b.BackgroundColor3 = THEME.HoverBg
	b.BackgroundTransparency = 1
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = ""
	b.ZIndex = Z_SIDECHLD
	b.Parent = sidebar
	corner(b, THEME.RRow)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromOffset(3, 16)
	bar.Position = UDim2.new(0, 0, 0.5, -8)
	bar.BackgroundColor3 = THEME.Accent
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.ZIndex = Z_SIDECHLD + 1
	bar.Parent = b
	corner(bar, 2)

	local ic = Instance.new("TextLabel")
	ic.Size = UDim2.fromOffset(16, 16)
	ic.Position = UDim2.fromOffset(13, 9)
	ic.BackgroundTransparency = 1
	ic.Font = THEME.Font
	ic.TextSize = 14
	ic.TextColor3 = THEME.TextDim
	ic.Text = glyph
	ic.ZIndex = Z_SIDECHLD + 1
	ic.Parent = b

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -40, 1, 0)
	l.Position = UDim2.fromOffset(37, 0)
	l.BackgroundTransparency = 1
	l.Font = THEME.FontMedium
	l.TextSize = 12
	l.TextColor3 = THEME.TextDim
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = txt
	l.ZIndex = Z_SIDECHLD + 1
	l.Parent = b

	b.MouseEnter:Connect(function()
		if bar.Visible == false then
			b.BackgroundTransparency = 0.95
		end
	end)
	b.MouseLeave:Connect(function()
		if bar.Visible == false then
			b.BackgroundTransparency = 1
		end
	end)

	return b, l, ic, bar
end

local tabMain, tabMainLbl, tabMainIc, tabMainBar = makeTab("Main", 62, "≡")
local tabSet, tabSetLbl, tabSetIc, tabSetBar = makeTab("Settings", 104, "⚙")

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.fromOffset(THEME.W - THEME.SidebarW, THEME.H)
content.Position = UDim2.fromOffset(THEME.SidebarW, 0)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = THEME.TextFaint
content.ScrollBarImageTransparency = 0.35
content.CanvasSize = UDim2.new()
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.ZIndex = Z_BASE
content.Parent = main

local pageMain = Instance.new("Frame")
pageMain.Size = UDim2.fromOffset(382, 248)
pageMain.Position = UDim2.fromOffset(THEME.Pad, 34)
pageMain.BackgroundTransparency = 1
pageMain.ZIndex = Z_BASE
pageMain.Parent = content

local pageSet = Instance.new("Frame")
pageSet.Size = UDim2.fromOffset(382, 360)
pageSet.Position = UDim2.fromOffset(THEME.Pad, 34)
pageSet.BackgroundTransparency = 1
pageSet.Visible = false
pageSet.ZIndex = Z_BASE
pageSet.Parent = content

local function sectionHeader(par, txt, x, y, w)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromOffset(w or 176, 16)
	l.Position = UDim2.fromOffset(x or 0, y or 0)
	l.BackgroundTransparency = 1
	l.Font = THEME.FontMedium
	l.TextSize = 13
	l.TextColor3 = THEME.Text
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = txt
	l.ZIndex = Z_BASE
	l.Parent = par
	return l
end

local function setTab(which)
	local m = which == "main"
	pageMain.Visible = m
	pageSet.Visible = not m

	local function st(on, b, l, ic, bar)
		if on then
			b.BackgroundColor3 = THEME.Raised
			b.BackgroundTransparency = 0
			l.TextColor3 = THEME.Text
			ic.TextColor3 = THEME.Accent
			bar.Visible = true
		else
			b.BackgroundColor3 = THEME.HoverBg
			b.BackgroundTransparency = 1
			l.TextColor3 = THEME.TextDim
			ic.TextColor3 = THEME.TextDim
			bar.Visible = false
		end
	end
	st(m, tabMain, tabMainLbl, tabMainIc, tabMainBar)
	st(not m, tabSet, tabSetLbl, tabSetIc, tabSetBar)

	local shown = m and pageMain or pageSet
	shown.Position = UDim2.fromOffset(THEME.Pad, 38)
	TweenService:Create(shown, THEME.TweenSlow, { Position = UDim2.fromOffset(THEME.Pad, 34) }):Play()
end

tabMain.MouseButton1Click:Connect(function() setTab("main") end)
tabSet.MouseButton1Click:Connect(function() setTab("set") end)
setTab("main")

local function descBar(par, y, w)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(w or 194, 26)
	card.Position = UDim2.fromOffset(0, y)
	card.BackgroundColor3 = THEME.Surface
	card.BorderSizePixel = 0
	card.ZIndex = Z_BASE
	card.Parent = par
	corner(card, THEME.RCard)
	strokeOf(card, THEME.Stroke, 0.4)

	local icHolder = Instance.new("Frame")
	icHolder.Size = UDim2.fromOffset(16, 16)
	icHolder.Position = UDim2.fromOffset(11, 11)
	icHolder.BackgroundTransparency = 1
	icHolder.ZIndex = Z_BASE + 1
	icHolder.Parent = card

	local icRing = Instance.new("Frame")
	icRing.Size = UDim2.fromScale(1, 1)
	icRing.BackgroundTransparency = 1
	icRing.ZIndex = Z_BASE + 1
	icRing.Parent = icHolder
	pillCorner(icRing)
	strokeOf(icRing, THEME.Accent, 0.15)

	local icTxt = Instance.new("TextLabel")
	icTxt.Size = UDim2.fromScale(1, 1)
	icTxt.BackgroundTransparency = 1
	icTxt.Font = THEME.FontBold
	icTxt.TextSize = 10
	icTxt.TextColor3 = THEME.Accent
	icTxt.Text = "i"
	icTxt.ZIndex = Z_BASE + 2
	icTxt.Parent = icHolder

	local kw = Instance.new("TextLabel")
	kw.Size = UDim2.fromOffset(140, 12)
	kw.Position = UDim2.fromOffset(34, 9)
	kw.BackgroundTransparency = 1
	kw.Font = THEME.FontBold
	kw.TextSize = 10
	kw.TextColor3 = THEME.Accent
	kw.TextXAlignment = Enum.TextXAlignment.Left
	kw.Text = "INFO"
	kw.ZIndex = Z_BASE + 1
	kw.Parent = card

	local d = Instance.new("TextLabel")
	d.Size = UDim2.fromOffset(w or 194, 26)
	d.Position = UDim2.fromOffset(0, y)
	d.BackgroundTransparency = 1
	d.Font = THEME.Font
	d.TextSize = 12
	d.TextWrapped = true
	d.TextColor3 = THEME.TextDim
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.TextYAlignment = Enum.TextYAlignment.Top
	d.Text = ""
	d.ZIndex = Z_BASE + 3
	d.Parent = par
	local pad = Instance.new("UIPadding", d)
	pad.PaddingLeft = UDim.new(0, 34)
	pad.PaddingTop = UDim.new(0, 24)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 8)

	card.Position = d.Position
	card.Size = d.Size
	d:GetPropertyChangedSignal("Position"):Connect(function() card.Position = d.Position end)
	d:GetPropertyChangedSignal("Size"):Connect(function() card.Size = d.Size end)

	return d
end

local function hookDesc(btn, bar, text)
	btn.MouseEnter:Connect(function()
		bar.Text = text
	end)
	btn.MouseLeave:Connect(function()
		if bar.Text == text then
			bar.Text = ""
		end
	end)
end

local function toggleRow(par, label, tbl, key, desc, bar)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, THEME.RowH)
	b.BackgroundColor3 = THEME.HoverBg
	b.BackgroundTransparency = 1
	b.BorderSizePixel = 0
	b.Text = ""
	b.AutoButtonColor = false
	b.ZIndex = Z_BASE
	b.Parent = par
	corner(b, THEME.RRow)

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -76, 1, 0)
	l.Position = UDim2.fromOffset(10, 0)
	l.BackgroundTransparency = 1
	l.Font = THEME.Font
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Text = label
	l.ZIndex = Z_BASE + 1
	l.Parent = b

	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromOffset(THEME.PillW, THEME.PillH)
	pill.Position = UDim2.new(1, -THEME.PillW - 8, 0.5, -THEME.PillH / 2)
	pill.BackgroundColor3 = THEME.Off
	pill.BorderSizePixel = 0
	pill.ZIndex = Z_BASE + 1
	pill.Parent = b
	pillCorner(pill)

	local pt = Instance.new("TextLabel")
	pt.Size = UDim2.fromScale(1, 1)
	pt.BackgroundTransparency = 1
	pt.Font = THEME.FontBold
	pt.TextSize = 10
	pt.Text = "OFF"
	pt.TextColor3 = THEME.Text
	pt.ZIndex = Z_BASE + 2
	pt.Parent = pill

	local function paint()
		if tbl[key] then
			tw(pill, { BackgroundColor3 = THEME.Accent })
			pt.Text = "ON"
			pt.TextColor3 = THEME.Window
			l.TextColor3 = THEME.Text
		else
			tw(pill, { BackgroundColor3 = THEME.Off })
			pt.Text = "OFF"
			pt.TextColor3 = THEME.Text
			l.TextColor3 = THEME.TextDim
		end
	end

	b.MouseEnter:Connect(function()
		b.BackgroundTransparency = 0.95
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundTransparency = 1
	end)

	b.MouseButton1Click:Connect(function()
		tbl[key] = not tbl[key]
		if key == "screen" then
			if not S.screen then
				local d = deathScreen()
				if d then
					d.Enabled = true
				end
			end
		end
		if key == "mute" then
			if not S.mute then
				local d = deathScreen()
				local s = d and d:FindFirstChild("DeathSound")
				if s and savedVol then
					s.Volume = savedVol
				end
			end
		end
		if key == "recover" and not S.recover then
			escaping = false
		end
		if key == "float" and floatGui then
			floatGui.Enabled = S.float
		end
		paint()
	end)
	if desc and bar then
		hookDesc(b, bar, desc)
	end
	paint()
	return b
end

local function numRow(par, label, def, key, minV, maxV, y)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.Position = UDim2.fromOffset(0, y)
	row.BackgroundTransparency = 1
	row.ZIndex = Z_BASE
	row.Parent = par

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -78, 1, 0)
	l.BackgroundTransparency = 1
	l.Font = THEME.Font
	l.TextSize = 12
	l.TextColor3 = THEME.TextDim
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = label
	l.ZIndex = Z_BASE + 1
	l.Parent = row

	local b = Instance.new("TextBox")
	b.Size = UDim2.fromOffset(66, 30)
	b.Position = UDim2.new(1, -66, 0.5, -15)
	b.BackgroundColor3 = THEME.Surface
	b.BorderSizePixel = 0
	b.Font = THEME.Font
	b.TextSize = 12
	b.TextColor3 = THEME.Text
	b.Text = def
	b.ZIndex = Z_BASE + 1
	b.Parent = row
	corner(b, THEME.RControl)
	local bs = strokeOf(b, THEME.Stroke, 0.3)

	b.Focused:Connect(function()
		tw(bs, { Color = THEME.Accent })
	end)
	b.FocusLost:Connect(function()
		tw(bs, { Color = THEME.Stroke })
		local n = tonumber(b.Text)
		if n then
			api[key] = math.clamp(n, minV, maxV)
		end
		b.Text = tostring(api[key])
	end)
	return row
end

sectionHeader(pageMain, "Targets", 0, 0, 176)

local search = Instance.new("TextBox")
search.Size = UDim2.fromOffset(176, 32)
search.Position = UDim2.fromOffset(0, 22)
search.BackgroundColor3 = THEME.Surface
search.BorderSizePixel = 0
search.Font = THEME.Font
search.TextSize = 12
search.TextColor3 = THEME.Text
search.PlaceholderText = "filter mobs..."
search.PlaceholderColor3 = THEME.TextFaint
search.Text = ""
search.ZIndex = Z_BASE
search.Parent = pageMain
corner(search, THEME.RControl)
local searchStroke = strokeOf(search, THEME.Stroke, 0.3)
search.Focused:Connect(function()
	tw(searchStroke, { Color = THEME.Accent })
end)
search.FocusLost:Connect(function()
	tw(searchStroke, { Color = THEME.Stroke })
end)

local targetLbl = Instance.new("TextLabel")
targetLbl.Size = UDim2.fromOffset(176, 14)
targetLbl.Position = UDim2.fromOffset(0, 60)
targetLbl.BackgroundTransparency = 1
targetLbl.Font = THEME.Font
targetLbl.TextSize = 11
targetLbl.TextColor3 = THEME.TextFaint
targetLbl.TextXAlignment = Enum.TextXAlignment.Left
targetLbl.Text = "nothing selected = nearest"
targetLbl.ZIndex = Z_BASE
targetLbl.Parent = pageMain

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.fromOffset(176, 170)
list.Position = UDim2.fromOffset(0, 78)
list.BackgroundColor3 = THEME.Surface
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = THEME.TextFaint
list.ScrollBarImageTransparency = 0.4
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ZIndex = Z_BASE
list.Parent = pageMain
corner(list, THEME.RCard)
strokeOf(list, THEME.Stroke, 0.5)
local llay = Instance.new("UIListLayout", list)
llay.Padding = UDim.new(0, 3)
local lpad = Instance.new("UIPadding", list)
lpad.PaddingTop = UDim.new(0, 6)
lpad.PaddingLeft = UDim.new(0, 6)
lpad.PaddingRight = UDim.new(0, 6)
lpad.PaddingBottom = UDim.new(0, 6)

local runBtn = Instance.new("TextButton")
runBtn.Size = UDim2.fromOffset(194, 34)
runBtn.Position = UDim2.fromOffset(188, 0)
runBtn.BackgroundColor3 = THEME.Raised
runBtn.BorderSizePixel = 0
runBtn.Font = THEME.FontBold
runBtn.TextSize = 12
runBtn.TextColor3 = THEME.TextDim
runBtn.Text = "START"
runBtn.AutoButtonColor = false
runBtn.ZIndex = Z_BASE
runBtn.Parent = pageMain
corner(runBtn, THEME.RControl)
runBtn.MouseEnter:Connect(function()
	if not api.running then runBtn.BackgroundColor3 = THEME.HoverBg end
end)
runBtn.MouseLeave:Connect(function()
	if not api.running then runBtn.BackgroundColor3 = THEME.Raised end
end)

local status = Instance.new("TextLabel")
status.Size = UDim2.fromOffset(194, 14)
status.Position = UDim2.fromOffset(188, 42)
status.BackgroundTransparency = 1
status.Font = THEME.Font
status.TextSize = 11
status.TextColor3 = THEME.TextFaint
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "loading..."
status.ZIndex = Z_BASE
status.Parent = pageMain

local statsLbl = Instance.new("TextLabel")
statsLbl.Size = UDim2.fromOffset(194, 14)
statsLbl.Position = UDim2.fromOffset(188, 58)
statsLbl.BackgroundTransparency = 1
statsLbl.Font = THEME.Font
statsLbl.TextSize = 11
statsLbl.TextColor3 = THEME.Accent
statsLbl.TextXAlignment = Enum.TextXAlignment.Left
statsLbl.Text = "kills 0  hp 100%"
statsLbl.ZIndex = Z_BASE
statsLbl.Parent = pageMain

local resumeHolder = Instance.new("Frame")
resumeHolder.Size = UDim2.fromOffset(194, 34)
resumeHolder.Position = UDim2.fromOffset(188, 80)
resumeHolder.BackgroundTransparency = 1
resumeHolder.ZIndex = Z_BASE
resumeHolder.Parent = pageMain

local mainBar = descBar(pageMain, 126, 194)
mainBar.Position = UDim2.fromOffset(188, 126)
mainBar.Size = UDim2.fromOffset(194, 100)
mainBar.Text = "Hover a control for details"

local resumeRow = toggleRow(resumeHolder, "resume after death", api, "resume",
	"On: after a death it respawns and returns to the mob type you were killing. Off: it stays idle after a death.", mainBar)
resumeRow.Size = UDim2.new(1, 0, 0, 34)

sectionHeader(pageSet, "Combat tuning", 0, 0, 176)
sectionHeader(pageSet, "Survivability", 188, 0, 194)

local colA = Instance.new("Frame")
colA.Size = UDim2.fromOffset(176, 224)
colA.Position = UDim2.fromOffset(0, 22)
colA.BackgroundTransparency = 1
colA.ZIndex = Z_BASE
colA.Parent = pageSet

numRow(colA, "attack distance", "9", "standoff", 4, 28, 0)
numRow(colA, "retreat at % hp", "30", "retreat", 5, 95, 38)
numRow(colA, "escape height", "60", "escapeH", 10, 500, 76)

local setBar = descBar(pageSet, 254, 382)
setBar.Size = UDim2.fromOffset(382, 100)
setBar.Text = "Hover a control for details"

-- ---- hotkey row + center button (settings) --------------
local listening = false
local keyBtn, keyStroke

do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.Position = UDim2.fromOffset(0, 114)
	row.BackgroundTransparency = 1
	row.ZIndex = Z_BASE
	row.Parent = colA

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -96, 1, 0)
	l.BackgroundTransparency = 1
	l.Font = THEME.Font
	l.TextSize = 12
	l.TextColor3 = THEME.TextDim
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = "hide/show key"
	l.ZIndex = Z_BASE + 1
	l.Parent = row

	keyBtn = Instance.new("TextButton")
	keyBtn.Size = UDim2.fromOffset(88, 30)
	keyBtn.Position = UDim2.new(1, -88, 0.5, -15)
	keyBtn.BackgroundColor3 = THEME.Surface
	keyBtn.BorderSizePixel = 0
	keyBtn.AutoButtonColor = false
	keyBtn.Font = THEME.FontMedium
	keyBtn.TextSize = 11
	keyBtn.TextColor3 = THEME.Text
	keyBtn.Text = api.toggleKey.Name
	keyBtn.ZIndex = Z_BASE + 1
	keyBtn.Parent = row
	corner(keyBtn, THEME.RControl)
	keyStroke = strokeOf(keyBtn, THEME.Stroke, 0.3)

	keyBtn.MouseButton1Click:Connect(function()
		listening = true
		keyBtn.Text = "press key..."
		tw(keyStroke, { Color = THEME.Accent })
	end)
	hookDesc(keyBtn, setBar, "Click, then press a key to set the hide/show hotkey. Esc cancels. End still unloads the script.")

	local cb = Instance.new("TextButton")
	cb.Size = UDim2.fromOffset(176, 30)
	cb.Position = UDim2.fromOffset(0, 152)
	cb.BackgroundColor3 = THEME.Raised
	cb.BorderSizePixel = 0
	cb.AutoButtonColor = false
	cb.Font = THEME.FontMedium
	cb.TextSize = 12
	cb.TextColor3 = THEME.TextDim
	cb.Text = "center window"
	cb.ZIndex = Z_BASE + 1
	cb.Parent = colA
	corner(cb, THEME.RControl)
	cb.MouseEnter:Connect(function() cb.BackgroundColor3 = THEME.HoverBg end)
	cb.MouseLeave:Connect(function() cb.BackgroundColor3 = THEME.Raised end)
	cb.MouseButton1Click:Connect(function()
		main.Position = UDim2.new(0.5, 0, 0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0.5, 0)
		if fbtn then fbtn.Position = UDim2.new(1, -40, 0, 110) end
	end)
	hookDesc(cb, setBar, "Moves the window (and minimised icon) back to the centre of the screen.")
end

local floatRow = toggleRow(colA, "floating button", S, "float",
	"On: a small FSR button stays on screen (drag it anywhere) to hide/show the GUI without a hotkey. Default on for mobile.", setBar)
floatRow.Position = UDim2.fromOffset(0, 188)

local colB = Instance.new("Frame")
colB.Size = UDim2.fromOffset(194, 224)
colB.Position = UDim2.fromOffset(188, 22)
colB.BackgroundTransparency = 1
colB.ZIndex = Z_BASE
colB.Parent = pageSet
local blay = Instance.new("UIListLayout", colB)
blay.Padding = UDim.new(0, 4)

toggleRow(colB, "retreat to heal", S, "recover",
	"On: at the retreat % HP you float above the enemy until HP is +5% higher. Off: never retreats, so the enemy gets no time to heal; if you die, resume after death sends you back.", setBar)
toggleRow(colB, "block death screen", S, "screen",
	"On: the Death Screen overlay is hidden so your view stays clear. Off: normal death screen.", setBar)
toggleRow(colB, "mute death sound", S, "mute",
	"On: the death sound is silenced. Off: normal death sting.", setBar)
toggleRow(colB, "refuse ragdoll", S, "ragdoll",
	"On: when the game ragdolls or platform-stands you, it forces you back to Running. Off: you flop normally.", setBar)
toggleRow(colB, "keep control", S, "move",
	"On: while knocked down, WASD is injected so you keep walking. Off: you are frozen until recovery.", setBar)
toggleRow(colB, "undo death teleport", S, "tp",
	"On: if the game teleports you on knockdown, it rewinds you to your last good position (twice per knockdown). Off: you go where the game puts you.", setBar)

local function release(reason)
	if armedUntil == 0 then return end
	armedUntil = 0
	stats.releases = stats.releases + 1
	if hum and hum.Parent then
		hum.PlatformStand = false
		if hum.WalkSpeed <= 0.1 then hum.WalkSpeed = 22 end
	end
	if hrp and hrp.Parent then hrp.Anchored = false end
	print("[FSR] release: " .. tostring(reason))
end

local function keysDir()
	local cam = workspace.CurrentCamera
	if not cam then return Vector3.zero end
	local d = Vector3.zero
	if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + cam.CFrame.RightVector end
	return Vector3.new(d.X, 0, d.Z)
end

local mt = getrawmetatable(game)
local oldNI = mt.__newindex
local busy = false
setreadonly(mt, false)
mt.__newindex = newcclosure(function(self, key, value)
	if self == hum and key == "PlatformStand" then
		if value == true and armedUntil == 0 then
			armedAt = os.clock()
			armedUntil = os.clock() + 15
			restores = 0
			if hrp then lastGood = hrp.Position end
		end
		if not busy then
			busy = true
			oldNI(self, key, false)
			busy = false
			return
		end
	end
	return oldNI(self, key, value)
end)
setreadonly(mt, true)

local function allowed(h)
	if next(api.allow) == nil then return true end
	return h.Parent and api.allow[h.Parent.Name] == true
end

local function snap(pos)
	if not hrp then return end
	pcall(function() hrp.CFrame = CFrame.new(pos) end)
	pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
end

local function acquire(preferName)
	if not hrp or not enemies then return nil end
	local best, bestD
	for _, d in ipairs(enemies:GetDescendants()) do
		if d:IsA("Humanoid") and d.Health > 0 and d.Parent and allowed(d) then
			local p = d.Parent:FindFirstChild("HumanoidRootPart") or d.Parent.PrimaryPart
			if p then
				local dist = (p.Position - hrp.Position).Magnitude
				local score = dist
				if preferName and d.Parent.Name == preferName then
					score = score - 100000
				end
				if not bestD or score < bestD then
					best, bestD = d, score
				end
			end
		end
	end
	return best
end

local function streamedName(nm)
	if not enemies then return false end
	for _, d in ipairs(enemies:GetDescendants()) do
		if d:IsA("Humanoid") and d.Parent and d.Parent.Name == nm then
			local p = d.Parent:FindFirstChild("HumanoidRootPart") or d.Parent.PrimaryPart
			if p then return true end
		end
	end
	return false
end

local function noteSeen()
	if not enemies then return end
	for _, d in ipairs(enemies:GetDescendants()) do
		if d:IsA("Humanoid") and d.Parent then
			local p = d.Parent:FindFirstChild("HumanoidRootPart") or d.Parent.PrimaryPart
			if p then
				local nm = d.Parent.Name
				local t = seen[nm]
				if not t then
					t = {}
					seen[nm] = t
				end
				local dup = false
				for _, v in ipairs(t) do
					if (v - p.Position).Magnitude < 120 then
						dup = true
						break
					end
				end
				if not dup and #t < 40 then
					t[#t + 1] = p.Position
				end
			end
		end
	end
end

local function travelTo(nm)
	local t = seen[nm]
	if not t or #t == 0 or not hrp then return false end
	local here = hrp.Position
	table.sort(t, function(a, b)
		return (a - here).Magnitude < (b - here).Magnitude
	end)
	for i = 1, math.min(#t, 3) do
		snap(t[i] + Vector3.new(0, 8, 0))
		task.wait(1.0)
		if acquire(nm) then
			return true
		end
	end
	return false
end

local function approach(h)
	local ep = h and h.Parent and (h.Parent:FindFirstChild("HumanoidRootPart") or h.Parent.PrimaryPart)
	if not ep then return end
	for _ = 1, 10 do
		snap(ep.Position + Vector3.new(0, 3, api.standoff))
		task.wait(0.05)
	end
end

local function aimAt(ep)
	return CFrame.lookAt(ep.Position + Vector3.new(0, 0, 12), ep.Position + Vector3.new(0, 2, 0))
end

local function fireM1(ep)
	if not Input then return end
	pcall(function()
		Input:FireServer("mI", {
			mousehit = aimAt(ep), targ = target and target.Parent,
			velo = Vector3.zero, running = false, inair = false, shift = false,
		})
	end)
end

local function fireM2()
	if not Input then return end
	pcall(function()
		Input:FireServer("m2", {
			velo = Vector3.zero, running = false, inair = false, shift = false, space = false, ctrl = false,
		})
	end)
end

local function hpPct()
	if not hum or not hum.Parent then return 0 end
	return (hum.Health / math.max(hum.MaxHealth, 1)) * 100
end

local function hpGuard()
	if not S.recover then
		escaping = false
		return
	end
	local pct = hpPct()
	if not escaping and pct <= api.retreat then
		escaping = true
	elseif escaping and pct >= math.min(api.retreat + 5, 99) then
		escaping = false
	end
end

local function bind(c)
	char = c
	hum = c:WaitForChild("Humanoid", 10)
	hrp = c:WaitForChild("HumanoidRootPart", 10)
	if not hum or not hrp then return end
	if hum.WalkSpeed > 0.1 then baseWalk = hum.WalkSpeed end
	lastGood = hrp.Position
	prevPos = hrp.Position
	pcall(function() hum.BreakJointsOnDeath = false end)

	addC(hum.Died:Connect(function()
		escaping = false
		if target and target.Parent then
			api.preferName = target.Parent.Name
		end
		target = nil
		if api.running then
			status.Text = "died - respawning"
		else
			status.Text = "you died"
		end
	end))
end

local function setCountLabel()
	local n = 0
	for _ in pairs(api.allow) do
		n = n + 1
	end
	if n == 0 then
		targetLbl.Text = "nothing selected = nearest"
	else
		targetLbl.Text = n .. " selected"
	end
end

local function buildRow(nm)
	local up = streamedName(nm)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 26)
	b.BorderSizePixel = 0
	b.Font = THEME.Font
	b.TextSize = 11
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Text = "  " .. nm
	b.AutoButtonColor = false
	b.ZIndex = Z_BASE + 1
	b.Parent = list
	corner(b, 6)
	if api.allow[nm] then
		b.BackgroundColor3 = THEME.AccentDeep
		b.TextColor3 = Color3.fromRGB(198, 246, 252)
	elseif up then
		b.BackgroundColor3 = THEME.Raised
		b.TextColor3 = THEME.Text
	else
		b.BackgroundColor3 = THEME.Surface
		b.TextColor3 = THEME.TextFaint
	end
	b.MouseButton1Click:Connect(function()
		api.allow[nm] = (not api.allow[nm]) or nil
		if api.allow[nm] then
			b.BackgroundColor3 = THEME.AccentDeep
			b.TextColor3 = Color3.fromRGB(198, 246, 252)
		elseif streamedName(nm) then
			b.BackgroundColor3 = THEME.Raised
			b.TextColor3 = THEME.Text
		else
			b.BackgroundColor3 = THEME.Surface
			b.TextColor3 = THEME.TextFaint
		end
		setCountLabel()
	end)
	if filterText ~= "" and not nm:lower():find(filterText, 1, true) then
		b.Visible = false
	end
end

local function renderList()
	if not enemies then return end
	local names = {}
	for k in pairs(known) do
		names[k] = true
	end
	for k in pairs(seen) do
		names[k] = true
	end
	for _, d in ipairs(enemies:GetDescendants()) do
		if d:IsA("Humanoid") and d.Parent then
			names[d.Parent.Name] = true
		end
	end

	known = {}
	for _, d in ipairs(enemies:GetDescendants()) do
		if d:IsA("Humanoid") and d.Parent then
			known[d.Parent.Name] = true
		end
	end

	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	local arr = {}
	for k in pairs(names) do
		arr[#arr + 1] = k
	end
	table.sort(arr)
	for _, nm in ipairs(arr) do
		buildRow(nm)
	end
end

search:GetPropertyChangedSignal("Text"):Connect(function()
	filterText = search.Text:lower()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("TextButton") then
			if filterText == "" then
				c.Visible = true
			else
				c.Visible = c.Text:lower():find(filterText, 1, true) ~= nil
			end
		end
	end
end)

runBtn.MouseButton1Click:Connect(function()
	if not enemies or not Input then
		status.Text = "still loading"
		return
	end
	api.running = not api.running
	if api.running then
		api.t0 = os.clock()
		api.dmg = 0
		api.kills = 0
		escaping = false
		local h = acquire(api.preferName)
		target = h
		if h then
			task.spawn(function() approach(h) end)
		end
		runBtn.Text = "STOP"
		tw(runBtn, { BackgroundColor3 = THEME.Accent, TextColor3 = THEME.Window })
	else
		target = nil
		escaping = false
		runBtn.Text = "START"
		tw(runBtn, { BackgroundColor3 = THEME.Raised, TextColor3 = THEME.TextDim })
		status.Text = "idle"
	end
end)

-- ---- window drag (anywhere) / clamp / minimize ----------
local function viewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

-- main / icon / floating button all use AnchorPoint 0.5, so Position == centre
local function centerOf(obj)
	local vp = viewport()
	local p = obj.Position
	return Vector2.new(p.X.Scale * vp.X + p.X.Offset, p.Y.Scale * vp.Y + p.Y.Offset)
end

-- keeps the whole object inside the screen so it can never get lost
local function placeClamped(obj, c, w, h)
	local vp = viewport()
	local x = (vp.X <= w) and (vp.X / 2) or math.clamp(c.X, w / 2, vp.X - w / 2)
	local y = (vp.Y <= h) and (vp.Y / 2) or math.clamp(c.Y, h / 2, vp.Y - h / 2)
	obj.Position = UDim2.fromOffset(x, y)
end

local function reclamp()
	placeClamped(main, centerOf(main), THEME.W, THEME.H)
	placeClamped(icon, centerOf(icon), 44, 44)
	if fbtn then placeClamped(fbtn, centerOf(fbtn), 40, 40) end
end

local function inside(o, m)
	local p, s = o.AbsolutePosition, o.AbsoluteSize
	return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
end

local function shownInMain(o)
	while o and o ~= main do
		if o:IsA("GuiObject") and not o.Visible then return false end
		o = o.Parent
	end
	return true
end

-- true if the pointer is over a button / textbox / the mob list
local function overInteractive(m)
	if pageMain.Visible and inside(list, m) then return true end
	for _, o in ipairs(main:GetDescendants()) do
		if (o:IsA("TextButton") or o:IsA("TextBox")) and not o:IsDescendantOf(list) then
			if shownInMain(o) and inside(o, m) then
				return true
			end
		end
	end
	return false
end

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch
end

local function pointerPos(i)
	if i.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(i.Position.X, i.Position.Y) + GuiService:GetGuiInset()
	end
	return UIS:GetMouseLocation()
end

-- one shared drag state (mouse or a single touch)
local drag = nil
local wasDrag = false

local function beginDrag(obj, w, h, i)
	wasDrag = false
	drag = {
		obj = obj, w = w, h = h,
		start = i.Position, c = centerOf(obj),
		touch = (i.UserInputType == Enum.UserInputType.Touch) and i or nil,
	}
end

local function toggleGui()
	sg.Enabled = not sg.Enabled
	if fbtn then
		fbtn.TextColor3 = sg.Enabled and THEME.Accent or THEME.TextDim
	end
end

local savedPos = main.Position

minBtn.MouseButton1Click:Connect(function()
	savedPos = main.Position
	main.Visible = false
	icon.Position = savedPos
	icon.Visible = true
	placeClamped(icon, centerOf(icon), 44, 44)
end)

icon.MouseButton1Click:Connect(function()
	if wasDrag then
		wasDrag = false
		return
	end
	icon.Visible = false
	main.Position = icon.Position
	placeClamped(main, centerOf(main), THEME.W, THEME.H)
	main.Visible = true
end)

icon.InputBegan:Connect(function(i)
	if isPress(i) then beginDrag(icon, 44, 44, i) end
end)

-- floating show/hide button (own ScreenGui so it stays visible when the main GUI is hidden)
floatGui = Instance.new("ScreenGui")
floatGui.Name = "FSRToggle"
floatGui.ResetOnSpawn = false
floatGui.IgnoreGuiInset = true
floatGui.DisplayOrder = 1000
floatGui.Enabled = S.float
floatGui.Parent = parentGui()

fbtn = Instance.new("TextButton")
fbtn.Size = UDim2.fromOffset(40, 40)
fbtn.AnchorPoint = Vector2.new(0.5, 0.5)
fbtn.Position = UDim2.new(1, -40, 0, 110)
fbtn.BackgroundColor3 = THEME.Window
fbtn.BackgroundTransparency = 0.12
fbtn.BorderSizePixel = 0
fbtn.AutoButtonColor = false
fbtn.Font = THEME.FontBold
fbtn.TextSize = 11
fbtn.TextColor3 = THEME.Accent
fbtn.Text = "FSR"
fbtn.ZIndex = Z_ICON
fbtn.Parent = floatGui
pillCorner(fbtn)
strokeOf(fbtn, THEME.Accent, 0.35)

fbtn.Activated:Connect(function()
	if wasDrag then
		wasDrag = false
		return
	end
	toggleGui()
end)
fbtn.InputBegan:Connect(function(i)
	if isPress(i) then beginDrag(fbtn, 40, 40, i) end
end)

addC(UIS.InputChanged:Connect(function(i)
	if not drag then return end
	if drag.touch then
		if i ~= drag.touch then return end
	elseif i.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	local d = i.Position - drag.start
	if d.Magnitude > 3 then
		wasDrag = true
	end
	placeClamped(drag.obj, drag.c + Vector2.new(d.X, d.Y), drag.w, drag.h)
end))

addC(UIS.InputEnded:Connect(function(i)
	if not drag or not isPress(i) then return end
	if drag.touch then
		if i == drag.touch then drag = nil end
	else
		drag = nil
	end
end))

addC(UIS.InputBegan:Connect(function(i, gp)
	-- cancel key capture if the user clicks elsewhere
	if listening and isPress(i) then
		listening = false
		keyBtn.Text = api.toggleKey.Name
		tw(keyStroke, { Color = THEME.Stroke })
		return
	end

	-- start dragging from anywhere on the window that isn't a control
	if isPress(i) and sg.Enabled and main.Visible then
		local m = pointerPos(i)
		local onFloat = floatGui.Enabled and inside(fbtn, m)
		if inside(main, m) and not onFloat and not overInteractive(m) then
			beginDrag(main, THEME.W, THEME.H, i)
		end
	end

	-- hotkey capture
	if listening then
		if i.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			local k = i.KeyCode
			if k ~= Enum.KeyCode.Escape and k ~= Enum.KeyCode.End and k ~= Enum.KeyCode.Unknown then
				api.toggleKey = k
			end
			keyBtn.Text = api.toggleKey.Name
			tw(keyStroke, { Color = THEME.Stroke })
		end
		return
	end

	if gp then return end

	-- hide / show the whole GUI (script keeps running)
	if i.KeyCode == api.toggleKey then
		toggleGui()
		return
	end

	if i.KeyCode == Enum.KeyCode.End then
		if _G.FSR_UNLOAD then
			_G.FSR_UNLOAD()
		end
	end
end))

-- re-clamp when the screen/viewport size changes
do
	local cam = workspace.CurrentCamera
	if cam then
		addC(cam:GetPropertyChangedSignal("ViewportSize"):Connect(reclamp))
	end
end
reclamp()

closeBtn.MouseButton1Click:Connect(function()
	if _G.FSR_UNLOAD then
		_G.FSR_UNLOAD()
	end
end)

_G.FSR_UNLOAD = function()
	_G.FSR_UNLOAD = nil

	alive = false
	listening = false
	api.running = false
	escaping = false
	armedUntil = 0
	armedAt = 0
	restores = 0
	target = nil

	for _, c in ipairs(conns) do
		pcall(function() c:Disconnect() end)
	end
	conns = {}

	setreadonly(mt, false)
	mt.__newindex = oldNI
	setreadonly(mt, true)

	local d = deathScreen()
	if d then
		pcall(function() d.Enabled = true end)
		local s = d:FindFirstChild("DeathSound")
		if s and savedVol then
			pcall(function() s.Volume = savedVol end)
		end
	end

	if hum then
		pcall(function()
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.Running)
			if baseWalk and baseWalk > 0.1 then
				hum.WalkSpeed = baseWalk
			end
			hum.BreakJointsOnDeath = true
		end)
	end
	if hrp then
		pcall(function()
			hrp.Anchored = false
			hrp.AssemblyLinearVelocity = Vector3.zero
		end)
	end

	char, hum, hrp = nil, nil, nil
	savedVol = nil
	filterText = ""

	if floatGui then pcall(function() floatGui:Destroy() end) end
	sg:Destroy()
	print("[FSR] unloaded")
end

if lp.Character then
	bind(lp.Character)
end

addC(lp.CharacterAdded:Connect(function(c)
	task.wait(0.3)
	if not alive then return end
	bind(c)
	if api.running and api.resume then
		task.wait(1.5)
		local h = acquire(api.preferName)
		if h then
			target = h
			approach(h)
			status.Text = "resumed"
		elseif api.preferName then
			if travelTo(api.preferName) then
				local h2 = acquire(api.preferName)
				if h2 then
					target = h2
					approach(h2)
					status.Text = "resumed"
				end
			end
		end
	end
end))

addC(RunService.RenderStepped:Connect(function(dt)
	if not alive then return end
	if not char or not hum or not hum.Parent or not hrp then return end

	local st = hum:GetState()
	local rag = false
	if st == Enum.HumanoidStateType.PlatformStanding then rag = true end
	if st == Enum.HumanoidStateType.Physics then rag = true end
	if st == Enum.HumanoidStateType.Ragdoll then rag = true end

	if S.ragdoll and rag then
		stats.flops = stats.flops + 1
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end

	if armedUntil > 0 then
		if hrp.Anchored then hrp.Anchored = false end
		if hum.WalkSpeed <= 0.1 then hum.WalkSpeed = 22 end

		if S.move and hum.MoveDirection.Magnitude < 0.1 then
			local d = keysDir()
			if d.Magnitude > 0.1 then
				local step = math.clamp(dt, 0, 0.1)
				hrp.CFrame = hrp.CFrame + d.Unit * 20 * step
				stats.manual = stats.manual + 1
			end
		end

		if S.tp then
			local jump = (hrp.Position - prevPos).Magnitude
			if jump > 60 and restores < 2 then
				hrp.CFrame = CFrame.new(lastGood + Vector3.new(0, 3, 0))
				hrp.AssemblyLinearVelocity = Vector3.zero
				prevPos = lastGood
				restores = restores + 1
				stats.yanks = stats.yanks + 1
			end
		end

		if os.clock() - armedAt > 15 then
			release("timeout")
		end
		prevPos = hrp.Position
	elseif not rag then
		lastGood = hrp.Position
		prevPos = hrp.Position
	end

	local ds = deathScreen()
	if ds then
		if S.screen and ds.Enabled then
			ds.Enabled = false
		end
		local snd = ds:FindFirstChild("DeathSound")
		if snd and S.mute then
			if savedVol == nil then
				savedVol = snd.Volume
			end
			if snd.Volume > 0 then
				snd.Volume = 0
			end
		end
	end
end))

task.spawn(function()
	while alive do
		task.wait(0.1)
		if not api.running or not hrp or not target or not target.Parent or target.Health <= 0 then
			continue
		end
		local ep = target.Parent:FindFirstChild("HumanoidRootPart") or target.Parent.PrimaryPart
		if not ep then continue end
		if escaping then
			snap(ep.Position + Vector3.new(0, api.escapeH, 0))
		else
			snap(ep.Position + Vector3.new(0, 3, api.standoff))
		end
	end
end)

task.spawn(function()
	local flip, lastHp = false, nil
	while alive do
		task.wait(0.3)
		if not api.running then continue end
		hpGuard()

		if not target or not target.Parent or target.Health <= 0 then
			if target and target.Health <= 0 then
				api.kills = api.kills + 1
				if target.Parent then
					api.preferName = target.Parent.Name
				end
			end
			local h = acquire(api.preferName)
			target, lastHp = h, nil
			if h then
				approach(h)
			elseif api.preferName and os.clock() - lastTravel > 2.5 then
				lastTravel = os.clock()
				if not streamedName(api.preferName) then
					status.Text = "travelling to " .. api.preferName
					if travelTo(api.preferName) then
						local h2 = acquire(api.preferName)
						if h2 then
							target = h2
							approach(h2)
						end
					end
				end
			end
		end

		if target and target.Parent then
			api.preferName = target.Parent.Name
		end

		if not target then
			status.Text = "no matching enemy"
		elseif escaping then
			status.Text = string.format("escaped - recovering %.0f%%", hpPct())
		else
			local ep = target.Parent:FindFirstChild("HumanoidRootPart") or target.Parent.PrimaryPart
			if ep and hrp then
				if not lastHp then
					lastHp = target.Health
				end
				if target.Health < lastHp then
					api.dmg = api.dmg + (lastHp - target.Health)
					lastHp = target.Health
				end
				if flip then
					fireM1(ep)
				else
					fireM2()
				end
				flip = not flip
				status.Text = string.format("%s  %.0f/%.0f", target.Parent.Name, target.Health, target.MaxHealth)
				statsLbl.Text = string.format("kills %d  hp %.0f%%", api.kills, hpPct())
			end
		end
	end
end)

task.spawn(function()
	enemies = workspace:FindFirstChild("Enemies") or workspace:WaitForChild("Enemies", 30)
	local bp = lp:FindFirstChild("Backpack")
	if bp then
		Input = bp:FindFirstChild("Input")
	else
		Input = lp:WaitForChild("Backpack"):WaitForChild("Input", 30)
	end
	if not alive then return end
	if not enemies or not Input then
		status.Text = "missing Enemies/Input"
		return
	end
	noteSeen()
	renderList()
	setCountLabel()
	status.Text = "ready"
end)

task.spawn(function()
	while alive do
		task.wait(1)
		tick = tick + 1
		pcall(noteSeen)
		if tick % 3 == 0 then
			pcall(renderList)
		end
	end
end)

end)

if not ok then
	print("[FSR] ERROR: " .. tostring(err))
	local sg2 = Instance.new("ScreenGui")
	sg2.Name = "FSRErr"
	sg2.Parent = lp:WaitForChild("PlayerGui")
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromOffset(520, 60)
	l.Position = UDim2.fromOffset(40, 40)
	l.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
	l.TextColor3 = Color3.fromRGB(255, 220, 220)
	l.Font = Enum.Font.Code
	l.TextSize = 12
	l.TextWrapped = true
	l.Text = tostring(err)
	l.Parent = sg2
end
