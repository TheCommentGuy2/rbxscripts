local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local DEFAULT_HOTKEY = Enum.KeyCode.RightShift
local ICON_TEXT = "LOG"
local FRAME_W, FRAME_H = 520, 320
local BAR_H = 30
local FONT, FONT_SIZE = Enum.Font.Code, 14
local WHEEL_ROWS = 3

local SCROLLBAR_W = 12
local PAD = 6
local VIEW_H = FRAME_H - BAR_H

local metrics = TextService:GetTextSize("M", FONT_SIZE, FONT, Vector2.new(1000, 1000))
local charW, lineH = metrics.X, metrics.Y
local COLS = math.max(10, math.floor((FRAME_W - SCROLLBAR_W - PAD * 2) / charW) - 1)
local VISIBLE = math.max(1, math.floor(VIEW_H / lineH))

local lines = {}
local rows = {}
local top = 1
local dirty = true
local paused = false
local hotkey = DEFAULT_HOTKEY
local listening = false
local minimized = false
local hovering = false
local connections = {}

local function track(c)
	table.insert(connections, c)
	return c
end

local TAGS = {
	[Enum.MessageType.MessageOutput] = "",
	[Enum.MessageType.MessageInfo] = "[INFO] ",
	[Enum.MessageType.MessageWarning] = "[WARN] ",
	[Enum.MessageType.MessageError] = "[ERROR] ",
}

local function addRows(text)
	text = text:gsub("\r", ""):gsub("\t", "    ")
	for _, segment in ipairs(string.split(text, "\n")) do
		local len = #segment
		if len <= COLS then
			table.insert(rows, segment)
		else
			local pos = 1
			while pos <= len do
				local nextPos = pos + COLS
				if nextPos <= len then
					nextPos = utf8.offset(segment, 0, nextPos) or nextPos
					if nextPos <= pos then nextPos = pos + COLS end
				end
				table.insert(rows, segment:sub(pos, nextPos - 1))
				pos = nextPos
			end
		end
	end
end

local function addLine(message, messageType)
	if paused then return end
	local line = os.date("%H:%M:%S") .. " " .. (TAGS[messageType] or "") .. message
	table.insert(lines, line)
	addRows(line)
	dirty = true
end

for _, m in ipairs(LogService:GetLogHistory()) do
	addLine(m.message, m.messageType)
end

track(LogService.MessageOut:Connect(addLine))

local gui = Instance.new("ScreenGui")
gui.Name = "ConsoleLogger"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

local parent
pcall(function() parent = (gethui and gethui()) or game:GetService("CoreGui") end)
gui.Parent = parent or Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(FRAME_W, FRAME_H)
frame.Position = UDim2.fromOffset(20, 60)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Parent = gui

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, BAR_H)
bar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
bar.BorderSizePixel = 0
bar.Parent = frame

local barLayout = Instance.new("UIListLayout")
barLayout.FillDirection = Enum.FillDirection.Horizontal
barLayout.Padding = UDim.new(0, 4)
barLayout.VerticalAlignment = Enum.VerticalAlignment.Center
barLayout.Parent = bar

local function makeButton(text, width)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(width, 24)
	b.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 13
	b.Text = text
	b.BorderSizePixel = 0
	b.Parent = bar
	return b
end

local copyBtn  = makeButton("Copy", 60)
local clearBtn = makeButton("Clear", 60)
local pauseBtn = makeButton("Pause", 60)
local endBtn   = makeButton("End", 45)
local keyBtn   = makeButton("Key: " .. hotkey.Name, 120)
local minBtn   = makeButton("-", 28)
local closeBtn = makeButton("X", 28)

local view = Instance.new("Frame")
view.Position = UDim2.fromOffset(0, BAR_H)
view.Size = UDim2.new(1, -SCROLLBAR_W, 0, VIEW_H)
view.BackgroundTransparency = 1
view.ClipsDescendants = true
view.Parent = frame

local text = Instance.new("TextLabel")
text.Position = UDim2.fromOffset(PAD, 0)
text.Size = UDim2.new(1, -PAD, 1, 0)
text.BackgroundTransparency = 1
text.TextColor3 = Color3.fromRGB(220, 220, 220)
text.Font = FONT
text.TextSize = FONT_SIZE
text.TextXAlignment = Enum.TextXAlignment.Left
text.TextYAlignment = Enum.TextYAlignment.Top
text.TextWrapped = false
text.RichText = false
text.Text = ""
text.Parent = view

local scrollTrack = Instance.new("Frame")
scrollTrack.Position = UDim2.new(1, -SCROLLBAR_W, 0, BAR_H)
scrollTrack.Size = UDim2.fromOffset(SCROLLBAR_W, VIEW_H)
scrollTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
scrollTrack.BorderSizePixel = 0
scrollTrack.Parent = frame

local thumb = Instance.new("Frame")
thumb.Size = UDim2.new(1, 0, 0, 24)
thumb.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
thumb.BorderSizePixel = 0
thumb.Visible = false
thumb.Parent = scrollTrack

local icon = Instance.new("TextButton")
icon.Name = "LoggerIcon"
icon.Size = UDim2.fromOffset(44, 44)
icon.Position = frame.Position
icon.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
icon.TextColor3 = Color3.new(1, 1, 1)
icon.Font = Enum.Font.GothamBold
icon.TextSize = 14
icon.Text = ICON_TEXT
icon.AutoButtonColor = true
icon.BorderSizePixel = 0
icon.Visible = false
icon.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = icon

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(110, 110, 135)
stroke.Thickness = 1.5
stroke.Parent = icon

local function maxTop()
	return math.max(1, #rows - VISIBLE + 1)
end

local function render()
	dirty = false
	local total = #rows
	top = math.clamp(top, 1, maxTop())

	if total == 0 then
		text.Text = ""
	else
		text.Text = table.concat(rows, "\n", top, math.min(total, top + VISIBLE - 1))
	end

	if total <= VISIBLE then
		thumb.Visible = false
	else
		local thumbH = math.max(24, VIEW_H * VISIBLE / total)
		local range = VIEW_H - thumbH
		thumb.Size = UDim2.new(1, 0, 0, thumbH)
		thumb.Position = UDim2.fromOffset(0, range * (top - 1) / (maxTop() - 1))
		thumb.Visible = true
	end
end

local function setTop(v)
	top = v
	dirty = true
end

ContextActionService:BindActionAtPriority("ConsoleLoggerWheel", function(_, _, input)
	if hovering and not minimized then
		setTop(top - input.Position.Z * WHEEL_ROWS)
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, 3000, Enum.UserInputType.MouseWheel)
frame.MouseEnter:Connect(function() hovering = true end)
frame.MouseLeave:Connect(function() hovering = false end)

do
	local dragging, startY, startTop = false, 0, 1

	scrollTrack.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local rel = input.Position.Y - scrollTrack.AbsolutePosition.Y
		setTop(math.floor(rel / VIEW_H * #rows - VISIBLE / 2))
	end)

	thumb.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startY, startTop = true, input.Position.Y, top
		end
	end)
	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local range = VIEW_H - thumb.AbsoluteSize.Y
			if range > 0 then
				local delta = input.Position.Y - startY
				setTop(math.floor(startTop + delta / range * (maxTop() - 1) + 0.5))
			end
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

local function makeDraggable(handle, target, onClick)
	local dragging, moved, dragStart, startPos = false, false, nil, nil

	track(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			dragStart, startPos = input.Position, target.Position
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			if d.Magnitude > 4 then moved = true end
			if moved then
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if not moved and onClick then onClick() end
		end
	end))
end

local function setMinimized(state)
	if state == minimized then return end
	minimized = state
	if state then
		icon.Position = frame.Position
		hovering = false
	else
		frame.Position = icon.Position
		dirty = true
	end
	frame.Visible = not state
	icon.Visible = state
end

makeDraggable(bar, frame)
makeDraggable(icon, icon, function() setMinimized(false) end)

minBtn.MouseButton1Click:Connect(function() setMinimized(true) end)

keyBtn.MouseButton1Click:Connect(function()
	listening = true
	keyBtn.Text = "Press a key..."
end)

track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	if listening then
		listening = false
		if input.KeyCode ~= Enum.KeyCode.Escape then
			hotkey = input.KeyCode
		end
		keyBtn.Text = "Key: " .. hotkey.Name
		return
	end

	if not gameProcessed and input.KeyCode == hotkey then
		setMinimized(not minimized)
	end
end))

local clip = setclipboard or toclipboard or (syn and syn.write_clipboard)

local function flash(btn, label, orig)
	btn.Text = label
	task.delay(1.5, function() btn.Text = orig end)
end

copyBtn.MouseButton1Click:Connect(function()
	if not clip then
		flash(copyBtn, "No clip fn", "Copy")
		return
	end
	clip(table.concat(lines, "\n"))
	flash(copyBtn, "Copied!", "Copy")
end)

clearBtn.MouseButton1Click:Connect(function()
	table.clear(lines)
	table.clear(rows)
	setTop(1)
end)

pauseBtn.MouseButton1Click:Connect(function()
	paused = not paused
	pauseBtn.Text = paused and "Resume" or "Pause"
end)

endBtn.MouseButton1Click:Connect(function()
	setTop(math.huge)
end)

closeBtn.MouseButton1Click:Connect(function()
	ContextActionService:UnbindAction("ConsoleLoggerWheel")
	for _, c in ipairs(connections) do c:Disconnect() end
	gui:Destroy()
end)

track(RunService.Heartbeat:Connect(function()
	if dirty and not minimized then
		render()
	end
end))
