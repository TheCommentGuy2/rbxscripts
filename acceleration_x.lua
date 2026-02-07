local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Theme Presets
local themePresets = {
	Purple = {
		primary = Color3.fromRGB(138, 43, 226),
		secondary = Color3.fromRGB(75, 0, 130),
		accent = Color3.fromRGB(186, 85, 211),
	},
	Cyan = {
		primary = Color3.fromRGB(0, 188, 212),
		secondary = Color3.fromRGB(0, 96, 100),
		accent = Color3.fromRGB(77, 208, 225),
	},
	Red = {
		primary = Color3.fromRGB(244, 67, 54),
		secondary = Color3.fromRGB(183, 28, 28),
		accent = Color3.fromRGB(239, 83, 80),
	},
	Green = {
		primary = Color3.fromRGB(76, 175, 80),
		secondary = Color3.fromRGB(27, 94, 32),
		accent = Color3.fromRGB(129, 199, 132),
	},
	Orange = {
		primary = Color3.fromRGB(255, 152, 0),
		secondary = Color3.fromRGB(230, 81, 0),
		accent = Color3.fromRGB(255, 183, 77),
	},
	Pink = {
		primary = Color3.fromRGB(233, 30, 99),
		secondary = Color3.fromRGB(136, 14, 79),
		accent = Color3.fromRGB(240, 98, 146),
	},
	Blue = {
		primary = Color3.fromRGB(33, 150, 243),
		secondary = Color3.fromRGB(13, 71, 161),
		accent = Color3.fromRGB(100, 181, 246),
	}
}

-- Customizable Settings
local settings = {
	increaseKey = Enum.KeyCode.Equals,
	decreaseKey = Enum.KeyCode.Minus,
	resetKey = Enum.KeyCode.R,
	toggleKey = Enum.KeyCode.LeftControl,
	incrementRate = 20,
	defaultSpeed = 16,
	currentTheme = "Purple",
	theme = {
		primary = themePresets.Purple.primary,
		secondary = themePresets.Purple.secondary,
		accent = themePresets.Purple.accent,
		background = Color3.fromRGB(20, 20, 25),
		surface = Color3.fromRGB(30, 30, 35),
		text = Color3.fromRGB(255, 255, 255),
		textDim = Color3.fromRGB(180, 180, 190),
		success = Color3.fromRGB(46, 204, 113),
		danger = Color3.fromRGB(231, 76, 60),
		warning = Color3.fromRGB(241, 196, 15)
	}
}

local currentSpeed = humanoid.WalkSpeed
local isIncreasing = false
local isDecreasing = false
local settingKeybind = nil
local isHidden = false

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AccelerationX"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame (increased height to fit all content)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.BackgroundColor3 = settings.theme.background
mainFrame.BorderSizePixel = 0
mainFrame.Position = UDim2.new(0.5, -180, 0.5, -250)
mainFrame.Size = UDim2.new(0, 360, 0, 500)
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Name = "MainStroke"
mainStroke.Color = settings.theme.primary
mainStroke.Thickness = 2
mainStroke.Transparency = 0.5
mainStroke.Parent = mainFrame

-- Header Bar
local headerBar = Instance.new("Frame")
headerBar.Name = "HeaderBar"
headerBar.BackgroundColor3 = settings.theme.surface
headerBar.BorderSizePixel = 0
headerBar.Size = UDim2.new(1, 0, 0, 50)
headerBar.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = headerBar

local headerAccent = Instance.new("Frame")
headerAccent.Name = "Accent"
headerAccent.BackgroundColor3 = settings.theme.primary
headerAccent.BorderSizePixel = 0
headerAccent.Size = UDim2.new(1, 0, 0, 3)
headerAccent.Position = UDim2.new(0, 0, 1, -3)
headerAccent.Parent = headerBar

-- Logo/Icon
local logo = Instance.new("TextLabel")
logo.Name = "Logo"
logo.BackgroundTransparency = 1
logo.Position = UDim2.new(0, 15, 0, 0)
logo.Size = UDim2.new(0, 40, 1, 0)
logo.Font = Enum.Font.GothamBold
logo.Text = "⚡"
logo.TextColor3 = settings.theme.primary
logo.TextSize = 28
logo.Parent = headerBar

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 60, 0, 0)
title.Size = UDim2.new(1, -180, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "ACCELERATION X"
title.TextColor3 = settings.theme.text
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = headerBar

-- Hide Button
local hideButton = Instance.new("TextButton")
hideButton.Name = "HideButton"
hideButton.BackgroundColor3 = settings.theme.surface
hideButton.BorderSizePixel = 0
hideButton.Position = UDim2.new(1, -50, 0, 10)
hideButton.Size = UDim2.new(0, 40, 0, 30)
hideButton.Font = Enum.Font.GothamBold
hideButton.Text = "—"
hideButton.TextColor3 = settings.theme.textDim
hideButton.TextSize = 16
hideButton.Parent = headerBar

local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 6)
hideCorner.Parent = hideButton

local hideStroke = Instance.new("UIStroke")
hideStroke.Color = settings.theme.textDim
hideStroke.Thickness = 1
hideStroke.Transparency = 0.7
hideStroke.Parent = hideButton

-- Content Area
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.BackgroundTransparency = 1
contentFrame.Position = UDim2.new(0, 0, 0, 50)
contentFrame.Size = UDim2.new(1, 0, 1, -50)
contentFrame.Parent = mainFrame

-- Speed Display
local speedContainer = Instance.new("Frame")
speedContainer.Name = "SpeedContainer"
speedContainer.BackgroundColor3 = settings.theme.surface
speedContainer.BorderSizePixel = 0
speedContainer.Position = UDim2.new(0, 20, 0, 20)
speedContainer.Size = UDim2.new(1, -40, 0, 80)
speedContainer.Parent = contentFrame

local speedContainerCorner = Instance.new("UICorner")
speedContainerCorner.CornerRadius = UDim.new(0, 10)
speedContainerCorner.Parent = speedContainer

local speedContainerStroke = Instance.new("UIStroke")
speedContainerStroke.Name = "SpeedStroke"
speedContainerStroke.Color = settings.theme.primary
speedContainerStroke.Thickness = 1
speedContainerStroke.Transparency = 0.8
speedContainerStroke.Parent = speedContainer

local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.BackgroundTransparency = 1
speedLabel.Position = UDim2.new(0, 0, 0, 10)
speedLabel.Size = UDim2.new(1, 0, 0, 20)
speedLabel.Font = Enum.Font.Gotham
speedLabel.Text = "CURRENT SPEED"
speedLabel.TextColor3 = settings.theme.textDim
speedLabel.TextSize = 11
speedLabel.Parent = speedContainer

local speedDisplay = Instance.new("TextLabel")
speedDisplay.Name = "SpeedDisplay"
speedDisplay.BackgroundTransparency = 1
speedDisplay.Position = UDim2.new(0, 0, 0, 30)
speedDisplay.Size = UDim2.new(1, 0, 0, 40)
speedDisplay.Font = Enum.Font.GothamBold
speedDisplay.Text = string.format("%.0f", currentSpeed)
speedDisplay.TextColor3 = settings.theme.primary
speedDisplay.TextSize = 36
speedDisplay.Parent = speedContainer

-- Control Buttons
local controlsFrame = Instance.new("Frame")
controlsFrame.Name = "ControlsFrame"
controlsFrame.BackgroundTransparency = 1
controlsFrame.Position = UDim2.new(0, 20, 0, 115)
controlsFrame.Size = UDim2.new(1, -40, 0, 50)
controlsFrame.Parent = contentFrame

-- Decrease Button
local decreaseButton = Instance.new("TextButton")
decreaseButton.Name = "DecreaseButton"
decreaseButton.BackgroundColor3 = settings.theme.danger
decreaseButton.BorderSizePixel = 0
decreaseButton.Position = UDim2.new(0, 0, 0, 0)
decreaseButton.Size = UDim2.new(0.32, -5, 1, 0)
decreaseButton.Font = Enum.Font.GothamBold
decreaseButton.Text = "−"
decreaseButton.TextColor3 = settings.theme.text
decreaseButton.TextSize = 24
decreaseButton.Parent = controlsFrame

local decreaseCorner = Instance.new("UICorner")
decreaseCorner.CornerRadius = UDim.new(0, 8)
decreaseCorner.Parent = decreaseButton

local decreaseLabel = Instance.new("TextLabel")
decreaseLabel.BackgroundTransparency = 1
decreaseLabel.Position = UDim2.new(0, 0, 1, -18)
decreaseLabel.Size = UDim2.new(1, 0, 0, 15)
decreaseLabel.Font = Enum.Font.Gotham
decreaseLabel.Text = "SLOWER"
decreaseLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
decreaseLabel.TextSize = 9
decreaseLabel.Parent = decreaseButton

-- Reset Button
local resetButton = Instance.new("TextButton")
resetButton.Name = "ResetButton"
resetButton.BackgroundColor3 = settings.theme.surface
resetButton.BorderSizePixel = 0
resetButton.Position = UDim2.new(0.34, 0, 0, 0)
resetButton.Size = UDim2.new(0.32, 0, 1, 0)
resetButton.Font = Enum.Font.GothamBold
resetButton.Text = "↻"
resetButton.TextColor3 = settings.theme.textDim
resetButton.TextSize = 24
resetButton.Parent = controlsFrame

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 8)
resetCorner.Parent = resetButton

local resetStroke = Instance.new("UIStroke")
resetStroke.Color = settings.theme.textDim
resetStroke.Thickness = 1
resetStroke.Transparency = 0.7
resetStroke.Parent = resetButton

local resetLabel = Instance.new("TextLabel")
resetLabel.BackgroundTransparency = 1
resetLabel.Position = UDim2.new(0, 0, 1, -18)
resetLabel.Size = UDim2.new(1, 0, 0, 15)
resetLabel.Font = Enum.Font.Gotham
resetLabel.Text = "RESET"
resetLabel.TextColor3 = settings.theme.textDim
resetLabel.TextSize = 9
resetLabel.Parent = resetButton

-- Increase Button
local increaseButton = Instance.new("TextButton")
increaseButton.Name = "IncreaseButton"
increaseButton.BackgroundColor3 = settings.theme.success
increaseButton.BorderSizePixel = 0
increaseButton.Position = UDim2.new(0.68, 5, 0, 0)
increaseButton.Size = UDim2.new(0.32, -5, 1, 0)
increaseButton.Font = Enum.Font.GothamBold
increaseButton.Text = "+"
increaseButton.TextColor3 = settings.theme.text
increaseButton.TextSize = 24
increaseButton.Parent = controlsFrame

local increaseCorner = Instance.new("UICorner")
increaseCorner.CornerRadius = UDim.new(0, 8)
increaseCorner.Parent = increaseButton

local increaseLabel = Instance.new("TextLabel")
increaseLabel.BackgroundTransparency = 1
increaseLabel.Position = UDim2.new(0, 0, 1, -18)
increaseLabel.Size = UDim2.new(1, 0, 0, 15)
increaseLabel.Font = Enum.Font.Gotham
increaseLabel.Text = "FASTER"
increaseLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
increaseLabel.TextSize = 9
increaseLabel.Parent = increaseButton

-- Settings Panel (Always Visible - Integrated)
local settingsPanel = Instance.new("Frame")
settingsPanel.Name = "SettingsPanel"
settingsPanel.BackgroundColor3 = settings.theme.surface
settingsPanel.BorderSizePixel = 0
settingsPanel.Position = UDim2.new(0, 20, 0, 180)
settingsPanel.Size = UDim2.new(1, -40, 0, 260)
settingsPanel.Parent = contentFrame

local settingsPanelCorner = Instance.new("UICorner")
settingsPanelCorner.CornerRadius = UDim.new(0, 10)
settingsPanelCorner.Parent = settingsPanel

local settingsPanelStroke = Instance.new("UIStroke")
settingsPanelStroke.Name = "SettingsStroke"
settingsPanelStroke.Color = settings.theme.primary
settingsPanelStroke.Thickness = 1
settingsPanelStroke.Transparency = 0.8
settingsPanelStroke.Parent = settingsPanel

local settingsTitle = Instance.new("TextLabel")
settingsTitle.BackgroundTransparency = 1
settingsTitle.Position = UDim2.new(0, 15, 0, 10)
settingsTitle.Size = UDim2.new(1, -30, 0, 20)
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.Text = "⚙ SETTINGS"
settingsTitle.TextColor3 = settings.theme.primary
settingsTitle.TextSize = 12
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.Parent = settingsPanel

-- Settings Grid
local settingsGrid = Instance.new("Frame")
settingsGrid.BackgroundTransparency = 1
settingsGrid.Position = UDim2.new(0, 15, 0, 35)
settingsGrid.Size = UDim2.new(1, -30, 1, -40)
settingsGrid.Parent = settingsPanel

-- Increase Key
local increaseKeyLabel = Instance.new("TextLabel")
increaseKeyLabel.BackgroundTransparency = 1
increaseKeyLabel.Position = UDim2.new(0, 0, 0, 0)
increaseKeyLabel.Size = UDim2.new(0.4, -5, 0, 25)
increaseKeyLabel.Font = Enum.Font.Gotham
increaseKeyLabel.Text = "Increase Key"
increaseKeyLabel.TextColor3 = settings.theme.textDim
increaseKeyLabel.TextSize = 10
increaseKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
increaseKeyLabel.Parent = settingsGrid

local increaseKeyButton = Instance.new("TextButton")
increaseKeyButton.BackgroundColor3 = settings.theme.background
increaseKeyButton.BorderSizePixel = 0
increaseKeyButton.Position = UDim2.new(0.4, 0, 0, 0)
increaseKeyButton.Size = UDim2.new(0.6, 0, 0, 25)
increaseKeyButton.Font = Enum.Font.GothamBold
increaseKeyButton.Text = settings.increaseKey.Name
increaseKeyButton.TextColor3 = settings.theme.text
increaseKeyButton.TextSize = 10
increaseKeyButton.Parent = settingsGrid

local increaseKeyCorner = Instance.new("UICorner")
increaseKeyCorner.CornerRadius = UDim.new(0, 5)
increaseKeyCorner.Parent = increaseKeyButton

-- Decrease Key
local decreaseKeyLabel = Instance.new("TextLabel")
decreaseKeyLabel.BackgroundTransparency = 1
decreaseKeyLabel.Position = UDim2.new(0, 0, 0, 30)
decreaseKeyLabel.Size = UDim2.new(0.4, -5, 0, 25)
decreaseKeyLabel.Font = Enum.Font.Gotham
decreaseKeyLabel.Text = "Decrease Key"
decreaseKeyLabel.TextColor3 = settings.theme.textDim
decreaseKeyLabel.TextSize = 10
decreaseKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
decreaseKeyLabel.Parent = settingsGrid

local decreaseKeyButton = Instance.new("TextButton")
decreaseKeyButton.BackgroundColor3 = settings.theme.background
decreaseKeyButton.BorderSizePixel = 0
decreaseKeyButton.Position = UDim2.new(0.4, 0, 0, 30)
decreaseKeyButton.Size = UDim2.new(0.6, 0, 0, 25)
decreaseKeyButton.Font = Enum.Font.GothamBold
decreaseKeyButton.Text = settings.decreaseKey.Name
decreaseKeyButton.TextColor3 = settings.theme.text
decreaseKeyButton.TextSize = 10
decreaseKeyButton.Parent = settingsGrid

local decreaseKeyCorner = Instance.new("UICorner")
decreaseKeyCorner.CornerRadius = UDim.new(0, 5)
decreaseKeyCorner.Parent = decreaseKeyButton

-- Reset Key
local resetKeyLabel = Instance.new("TextLabel")
resetKeyLabel.BackgroundTransparency = 1
resetKeyLabel.Position = UDim2.new(0, 0, 0, 60)
resetKeyLabel.Size = UDim2.new(0.4, -5, 0, 25)
resetKeyLabel.Font = Enum.Font.Gotham
resetKeyLabel.Text = "Reset Key"
resetKeyLabel.TextColor3 = settings.theme.textDim
resetKeyLabel.TextSize = 10
resetKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
resetKeyLabel.Parent = settingsGrid

local resetKeyButton = Instance.new("TextButton")
resetKeyButton.BackgroundColor3 = settings.theme.background
resetKeyButton.BorderSizePixel = 0
resetKeyButton.Position = UDim2.new(0.4, 0, 0, 60)
resetKeyButton.Size = UDim2.new(0.6, 0, 0, 25)
resetKeyButton.Font = Enum.Font.GothamBold
resetKeyButton.Text = settings.resetKey.Name
resetKeyButton.TextColor3 = settings.theme.text
resetKeyButton.TextSize = 10
resetKeyButton.Parent = settingsGrid

local resetKeyCorner = Instance.new("UICorner")
resetKeyCorner.CornerRadius = UDim.new(0, 5)
resetKeyCorner.Parent = resetKeyButton

-- Toggle GUI Key
local toggleKeyLabel = Instance.new("TextLabel")
toggleKeyLabel.BackgroundTransparency = 1
toggleKeyLabel.Position = UDim2.new(0, 0, 0, 90)
toggleKeyLabel.Size = UDim2.new(0.4, -5, 0, 25)
toggleKeyLabel.Font = Enum.Font.Gotham
toggleKeyLabel.Text = "Toggle GUI Key"
toggleKeyLabel.TextColor3 = settings.theme.textDim
toggleKeyLabel.TextSize = 10
toggleKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleKeyLabel.Parent = settingsGrid

local toggleKeyButton = Instance.new("TextButton")
toggleKeyButton.BackgroundColor3 = settings.theme.background
toggleKeyButton.BorderSizePixel = 0
toggleKeyButton.Position = UDim2.new(0.4, 0, 0, 90)
toggleKeyButton.Size = UDim2.new(0.6, 0, 0, 25)
toggleKeyButton.Font = Enum.Font.GothamBold
toggleKeyButton.Text = settings.toggleKey.Name
toggleKeyButton.TextColor3 = settings.theme.text
toggleKeyButton.TextSize = 10
toggleKeyButton.Parent = settingsGrid

local toggleKeyCorner = Instance.new("UICorner")
toggleKeyCorner.CornerRadius = UDim.new(0, 5)
toggleKeyCorner.Parent = toggleKeyButton

-- Speed Rate
local rateLabel = Instance.new("TextLabel")
rateLabel.BackgroundTransparency = 1
rateLabel.Position = UDim2.new(0, 0, 0, 120)
rateLabel.Size = UDim2.new(0.4, -5, 0, 25)
rateLabel.Font = Enum.Font.Gotham
rateLabel.Text = "Speed Rate (/sec)"
rateLabel.TextColor3 = settings.theme.textDim
rateLabel.TextSize = 10
rateLabel.TextXAlignment = Enum.TextXAlignment.Left
rateLabel.Parent = settingsGrid

local rateInput = Instance.new("TextBox")
rateInput.BackgroundColor3 = settings.theme.background
rateInput.BorderSizePixel = 0
rateInput.Position = UDim2.new(0.4, 0, 0, 120)
rateInput.Size = UDim2.new(0.6, 0, 0, 25)
rateInput.Font = Enum.Font.GothamBold
rateInput.Text = tostring(settings.incrementRate)
rateInput.TextColor3 = settings.theme.text
rateInput.TextSize = 10
rateInput.PlaceholderText = "20"
rateInput.Parent = settingsGrid

local rateInputCorner = Instance.new("UICorner")
rateInputCorner.CornerRadius = UDim.new(0, 5)
rateInputCorner.Parent = rateInput

-- Default Speed
local defaultSpeedLabel = Instance.new("TextLabel")
defaultSpeedLabel.BackgroundTransparency = 1
defaultSpeedLabel.Position = UDim2.new(0, 0, 0, 150)
defaultSpeedLabel.Size = UDim2.new(0.4, -5, 0, 25)
defaultSpeedLabel.Font = Enum.Font.Gotham
defaultSpeedLabel.Text = "Default Speed"
defaultSpeedLabel.TextColor3 = settings.theme.textDim
defaultSpeedLabel.TextSize = 10
defaultSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
defaultSpeedLabel.Parent = settingsGrid

local defaultSpeedInput = Instance.new("TextBox")
defaultSpeedInput.BackgroundColor3 = settings.theme.background
defaultSpeedInput.BorderSizePixel = 0
defaultSpeedInput.Position = UDim2.new(0.4, 0, 0, 150)
defaultSpeedInput.Size = UDim2.new(0.6, 0, 0, 25)
defaultSpeedInput.Font = Enum.Font.GothamBold
defaultSpeedInput.Text = tostring(settings.defaultSpeed)
defaultSpeedInput.TextColor3 = settings.theme.text
defaultSpeedInput.TextSize = 10
defaultSpeedInput.PlaceholderText = "16"
defaultSpeedInput.Parent = settingsGrid

local defaultSpeedCorner = Instance.new("UICorner")
defaultSpeedCorner.CornerRadius = UDim.new(0, 5)
defaultSpeedCorner.Parent = defaultSpeedInput

-- Theme Color
local themeLabel = Instance.new("TextLabel")
themeLabel.BackgroundTransparency = 1
themeLabel.Position = UDim2.new(0, 0, 0, 180)
themeLabel.Size = UDim2.new(0.4, -5, 0, 25)
themeLabel.Font = Enum.Font.Gotham
themeLabel.Text = "Theme Color"
themeLabel.TextColor3 = settings.theme.textDim
themeLabel.TextSize = 10
themeLabel.TextXAlignment = Enum.TextXAlignment.Left
themeLabel.Parent = settingsGrid

local themeButton = Instance.new("TextButton")
themeButton.Name = "ThemeButton"
themeButton.BackgroundColor3 = settings.theme.background
themeButton.BorderSizePixel = 0
themeButton.Position = UDim2.new(0.4, 0, 0, 180)
themeButton.Size = UDim2.new(0.6, 0, 0, 25)
themeButton.Font = Enum.Font.GothamBold
themeButton.Text = settings.currentTheme
themeButton.TextColor3 = settings.theme.primary
themeButton.TextSize = 10
themeButton.Parent = settingsGrid

local themeButtonCorner = Instance.new("UICorner")
themeButtonCorner.CornerRadius = UDim.new(0, 5)
themeButtonCorner.Parent = themeButton

-- Minimized Display
local miniDisplay = Instance.new("Frame")
miniDisplay.Name = "MiniDisplay"
miniDisplay.BackgroundColor3 = settings.theme.background
miniDisplay.BorderSizePixel = 0
miniDisplay.Position = UDim2.new(1, -200, 0, 10)
miniDisplay.Size = UDim2.new(0, 190, 0, 80)
miniDisplay.Visible = false
miniDisplay.Parent = screenGui

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 10)
miniCorner.Parent = miniDisplay

local miniStroke = Instance.new("UIStroke")
miniStroke.Name = "MiniStroke"
miniStroke.Color = settings.theme.primary
miniStroke.Thickness = 2
miniStroke.Transparency = 0.5
miniStroke.Parent = miniDisplay

-- Mini Header
local miniHeader = Instance.new("Frame")
miniHeader.BackgroundColor3 = settings.theme.surface
miniHeader.BorderSizePixel = 0
miniHeader.Size = UDim2.new(1, 0, 0, 25)
miniHeader.Parent = miniDisplay

local miniHeaderCorner = Instance.new("UICorner")
miniHeaderCorner.CornerRadius = UDim.new(0, 10)
miniHeaderCorner.Parent = miniHeader

local miniAccent = Instance.new("Frame")
miniAccent.Name = "MiniAccent"
miniAccent.BackgroundColor3 = settings.theme.primary
miniAccent.BorderSizePixel = 0
miniAccent.Size = UDim2.new(1, 0, 0, 2)
miniAccent.Position = UDim2.new(0, 0, 1, -2)
miniAccent.Parent = miniHeader

local miniTitle = Instance.new("TextLabel")
miniTitle.BackgroundTransparency = 1
miniTitle.Position = UDim2.new(0, 8, 0, 0)
miniTitle.Size = UDim2.new(1, -50, 1, 0)
miniTitle.Font = Enum.Font.GothamBold
miniTitle.Text = "⚡ ACCELERATION X"
miniTitle.TextColor3 = settings.theme.text
miniTitle.TextSize = 11
miniTitle.TextXAlignment = Enum.TextXAlignment.Left
miniTitle.Parent = miniHeader

local showButton = Instance.new("TextButton")
showButton.BackgroundColor3 = settings.theme.background
showButton.BorderSizePixel = 0
showButton.Position = UDim2.new(1, -23, 0, 3)
showButton.Size = UDim2.new(0, 20, 0, 19)
showButton.Font = Enum.Font.GothamBold
showButton.Text = "+"
showButton.TextColor3 = settings.theme.primary
showButton.TextSize = 14
showButton.Parent = miniHeader

local showCorner = Instance.new("UICorner")
showCorner.CornerRadius = UDim.new(0, 4)
showCorner.Parent = showButton

-- Mini Content
local miniContent = Instance.new("Frame")
miniContent.BackgroundTransparency = 1
miniContent.Position = UDim2.new(0, 8, 0, 30)
miniContent.Size = UDim2.new(1, -16, 1, -35)
miniContent.Parent = miniDisplay

local miniSpeedLabel = Instance.new("TextLabel")
miniSpeedLabel.BackgroundTransparency = 1
miniSpeedLabel.Size = UDim2.new(1, 0, 0, 12)
miniSpeedLabel.Font = Enum.Font.Gotham
miniSpeedLabel.Text = "Speed"
miniSpeedLabel.TextColor3 = settings.theme.textDim
miniSpeedLabel.TextSize = 9
miniSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
miniSpeedLabel.Parent = miniContent

local miniSpeedValue = Instance.new("TextLabel")
miniSpeedValue.Name = "MiniSpeedValue"
miniSpeedValue.BackgroundTransparency = 1
miniSpeedValue.Position = UDim2.new(0, 0, 0, 12)
miniSpeedValue.Size = UDim2.new(1, 0, 0, 15)
miniSpeedValue.Font = Enum.Font.GothamBold
miniSpeedValue.Text = string.format("%.0f", currentSpeed)
miniSpeedValue.TextColor3 = settings.theme.primary
miniSpeedValue.TextSize = 14
miniSpeedValue.TextXAlignment = Enum.TextXAlignment.Left
miniSpeedValue.Parent = miniContent

local miniHotkeyText = Instance.new("TextLabel")
miniHotkeyText.Name = "MiniHotkeyText"
miniHotkeyText.BackgroundTransparency = 1
miniHotkeyText.Position = UDim2.new(0, 0, 1, -18)
miniHotkeyText.Size = UDim2.new(1, 0, 0, 18)
miniHotkeyText.Font = Enum.Font.Gotham
miniHotkeyText.Text = ""
miniHotkeyText.TextColor3 = settings.theme.textDim
miniHotkeyText.TextSize = 8
miniHotkeyText.TextXAlignment = Enum.TextXAlignment.Left
miniHotkeyText.TextWrapped = true
miniHotkeyText.Parent = miniContent

-- Functions
local function updateTheme(themeName)
	if not themePresets[themeName] then return end
	
	settings.currentTheme = themeName
	settings.theme.primary = themePresets[themeName].primary
	settings.theme.secondary = themePresets[themeName].secondary
	settings.theme.accent = themePresets[themeName].accent
	
	-- Update all themed elements
	mainStroke.Color = settings.theme.primary
	headerAccent.BackgroundColor3 = settings.theme.primary
	logo.TextColor3 = settings.theme.primary
	speedContainerStroke.Color = settings.theme.primary
	speedDisplay.TextColor3 = settings.theme.primary
	settingsPanelStroke.Color = settings.theme.primary
	settingsTitle.TextColor3 = settings.theme.primary
	themeButton.Text = themeName
	themeButton.TextColor3 = settings.theme.primary
	miniStroke.Color = settings.theme.primary
	miniAccent.BackgroundColor3 = settings.theme.primary
	miniSpeedValue.TextColor3 = settings.theme.primary
	showButton.TextColor3 = settings.theme.primary
end

local function cycleTheme()
	local themes = {"Purple", "Cyan", "Red", "Green", "Orange", "Pink", "Blue"}
	local currentIndex = 1
	for i, theme in ipairs(themes) do
		if theme == settings.currentTheme then
			currentIndex = i
			break
		end
	end
	local nextIndex = (currentIndex % #themes) + 1
	updateTheme(themes[nextIndex])
end

local function updateSpeedDisplay()
	local displaySpeed = string.format("%.0f", currentSpeed)
	speedDisplay.Text = displaySpeed
	miniSpeedValue.Text = displaySpeed
	
	if currentSpeed > 50 then
		speedDisplay.TextColor3 = settings.theme.danger
		miniSpeedValue.TextColor3 = settings.theme.danger
	elseif currentSpeed > 20 then
		speedDisplay.TextColor3 = settings.theme.warning
		miniSpeedValue.TextColor3 = settings.theme.warning
	else
		speedDisplay.TextColor3 = settings.theme.primary
		miniSpeedValue.TextColor3 = settings.theme.primary
	end
end

local function updateHotkeyInfo()
	local hotkeyString = string.format("[%s] Faster  •  [%s] Slower  •  [%s] Reset  •  Rate: %d/s", 
		settings.increaseKey.Name, 
		settings.decreaseKey.Name,
		settings.resetKey.Name,
		settings.incrementRate)
	miniHotkeyText.Text = hotkeyString
end

local function setSpeed(speed)
	currentSpeed = math.max(0, speed)
	updateSpeedDisplay()
end

local function toggleHide()
	isHidden = not isHidden
	if isHidden then
		mainFrame:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.3, true)
		task.wait(0.3)
		mainFrame.Visible = false
		miniDisplay.Visible = true
		miniDisplay:TweenSize(UDim2.new(0, 190, 0, 80), "Out", "Back", 0.4, true)
	else
		miniDisplay:TweenSize(UDim2.new(0, 0, 0, 0), "In", "Quad", 0.2, true)
		task.wait(0.2)
		miniDisplay.Visible = false
		mainFrame.Visible = true
		mainFrame:TweenSize(UDim2.new(0, 360, 0, 500), "Out", "Back", 0.4, true)
	end
end

-- Hover Effects
local function addHoverEffect(button, normalColor, hoverColor, isStroke)
	button.MouseEnter:Connect(function()
		if isStroke then
			for _, child in pairs(button:GetChildren()) do
				if child:IsA("UIStroke") then
					TweenService:Create(child, TweenInfo.new(0.2), {Color = hoverColor}):Play()
				end
			end
		else
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
		end
	end)
	button.MouseLeave:Connect(function()
		if isStroke then
			for _, child in pairs(button:GetChildren()) do
				if child:IsA("UIStroke") then
					TweenService:Create(child, TweenInfo.new(0.2), {Color = normalColor}):Play()
				end
			end
		else
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
		end
	end)
end

addHoverEffect(increaseButton, settings.theme.success, Color3.fromRGB(56, 224, 133))
addHoverEffect(decreaseButton, settings.theme.danger, Color3.fromRGB(241, 96, 80))
addHoverEffect(resetButton, settings.theme.surface, settings.theme.background)
addHoverEffect(hideButton, settings.theme.surface, settings.theme.background)
addHoverEffect(increaseKeyButton, settings.theme.background, settings.theme.surface)
addHoverEffect(decreaseKeyButton, settings.theme.background, settings.theme.surface)
addHoverEffect(resetKeyButton, settings.theme.background, settings.theme.surface)
addHoverEffect(toggleKeyButton, settings.theme.background, settings.theme.surface)
addHoverEffect(themeButton, settings.theme.background, settings.theme.surface)
addHoverEffect(showButton, settings.theme.background, settings.theme.surface)

-- Button Events
increaseButton.MouseButton1Down:Connect(function()
	isIncreasing = true
end)

increaseButton.MouseButton1Up:Connect(function()
	isIncreasing = false
end)

decreaseButton.MouseButton1Down:Connect(function()
	isDecreasing = true
end)

decreaseButton.MouseButton1Up:Connect(function()
	isDecreasing = false
end)

resetButton.MouseButton1Click:Connect(function()
	setSpeed(settings.defaultSpeed)
end)

hideButton.MouseButton1Click:Connect(toggleHide)
showButton.MouseButton1Click:Connect(toggleHide)

increaseKeyButton.MouseButton1Click:Connect(function()
	settingKeybind = "increase"
	increaseKeyButton.Text = "Press any key..."
	increaseKeyButton.TextColor3 = settings.theme.primary
end)

decreaseKeyButton.MouseButton1Click:Connect(function()
	settingKeybind = "decrease"
	decreaseKeyButton.Text = "Press any key..."
	decreaseKeyButton.TextColor3 = settings.theme.primary
end)

resetKeyButton.MouseButton1Click:Connect(function()
	settingKeybind = "reset"
	resetKeyButton.Text = "Press any key..."
	resetKeyButton.TextColor3 = settings.theme.primary
end)

toggleKeyButton.MouseButton1Click:Connect(function()
	settingKeybind = "toggle"
	toggleKeyButton.Text = "Press any key..."
	toggleKeyButton.TextColor3 = settings.theme.primary
end)

themeButton.MouseButton1Click:Connect(function()
	cycleTheme()
end)

rateInput.FocusLost:Connect(function()
	local newRate = tonumber(rateInput.Text)
	if newRate and newRate > 0 then
		settings.incrementRate = newRate
		updateHotkeyInfo()
	else
		rateInput.Text = tostring(settings.incrementRate)
	end
end)

defaultSpeedInput.FocusLost:Connect(function()
	local newDefault = tonumber(defaultSpeedInput.Text)
	if newDefault and newDefault >= 0 then
		settings.defaultSpeed = newDefault
	else
		defaultSpeedInput.Text = tostring(settings.defaultSpeed)
	end
end)

-- Keybind Conflict Check Function
local function isKeybindInUse(keyCode, excludeAction)
	if excludeAction ~= "increase" and settings.increaseKey == keyCode then
		return true, "Increase Speed"
	end
	
	if excludeAction ~= "decrease" and settings.decreaseKey == keyCode then
		return true, "Decrease Speed"
	end
	
	if excludeAction ~= "reset" and settings.resetKey == keyCode then
		return true, "Reset Speed"
	end
	
	if excludeAction ~= "toggle" and settings.toggleKey == keyCode then
		return true, "Toggle GUI"
	end
	
	return false, nil
end

-- Keyboard Controls
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Toggle key to toggle hide/show GUI
	if input.KeyCode == settings.toggleKey then
		toggleHide()
		return
	end
	
	if settingKeybind then
		if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Unknown then
			-- Check if keybind is already in use
			local inUse, usedBy = isKeybindInUse(input.KeyCode, settingKeybind)
			
			if inUse then
				-- Show error message
				if settingKeybind == "increase" then
					increaseKeyButton.Text = "KEYBIND IN USE!"
					increaseKeyButton.TextColor3 = settings.theme.danger
				elseif settingKeybind == "decrease" then
					decreaseKeyButton.Text = "KEYBIND IN USE!"
					decreaseKeyButton.TextColor3 = settings.theme.danger
				elseif settingKeybind == "reset" then
					resetKeyButton.Text = "KEYBIND IN USE!"
					resetKeyButton.TextColor3 = settings.theme.danger
				elseif settingKeybind == "toggle" then
					toggleKeyButton.Text = "KEYBIND IN USE!"
					toggleKeyButton.TextColor3 = settings.theme.danger
				end
				
				-- Reset to original after 1 second
				task.wait(1)
				if settingKeybind == "increase" then
					increaseKeyButton.Text = settings.increaseKey.Name
					increaseKeyButton.TextColor3 = settings.theme.text
				elseif settingKeybind == "decrease" then
					decreaseKeyButton.Text = settings.decreaseKey.Name
					decreaseKeyButton.TextColor3 = settings.theme.text
				elseif settingKeybind == "reset" then
					resetKeyButton.Text = settings.resetKey.Name
					resetKeyButton.TextColor3 = settings.theme.text
				elseif settingKeybind == "toggle" then
					toggleKeyButton.Text = settings.toggleKey.Name
					toggleKeyButton.TextColor3 = settings.theme.text
				end
				settingKeybind = nil
				return
			end
			
			-- Assign new keybind if not in use
			if settingKeybind == "increase" then
				settings.increaseKey = input.KeyCode
				increaseKeyButton.Text = input.KeyCode.Name
				increaseKeyButton.TextColor3 = settings.theme.text
			elseif settingKeybind == "decrease" then
				settings.decreaseKey = input.KeyCode
				decreaseKeyButton.Text = input.KeyCode.Name
				decreaseKeyButton.TextColor3 = settings.theme.text
			elseif settingKeybind == "reset" then
				settings.resetKey = input.KeyCode
				resetKeyButton.Text = input.KeyCode.Name
				resetKeyButton.TextColor3 = settings.theme.text
			elseif settingKeybind == "toggle" then
				settings.toggleKey = input.KeyCode
				toggleKeyButton.Text = input.KeyCode.Name
				toggleKeyButton.TextColor3 = settings.theme.text
			end
			updateHotkeyInfo()
		else
			if settingKeybind == "increase" then
				increaseKeyButton.Text = settings.increaseKey.Name
				increaseKeyButton.TextColor3 = settings.theme.text
			elseif settingKeybind == "decrease" then
				decreaseKeyButton.Text = settings.decreaseKey.Name
				decreaseKeyButton.TextColor3 = settings.theme.text
			elseif settingKeybind == "reset" then
				resetKeyButton.Text = settings.resetKey.Name
				resetKeyButton.TextColor3 = settings.theme.text
			elseif settingKeybind == "toggle" then
				toggleKeyButton.Text = settings.toggleKey.Name
				toggleKeyButton.TextColor3 = settings.theme.text
			end
		end
		settingKeybind = nil
		return
	end
	
	if input.KeyCode == settings.increaseKey then
		isIncreasing = true
	elseif input.KeyCode == settings.decreaseKey then
		isDecreasing = true
	elseif input.KeyCode == settings.resetKey then
		setSpeed(settings.defaultSpeed)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == settings.increaseKey then
		isIncreasing = false
	elseif input.KeyCode == settings.decreaseKey then
		isDecreasing = false
	end
end)

-- Continuous Speed Loop (LoopWS)
RunService.Heartbeat:Connect(function(deltaTime)
	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed = currentSpeed
	end
	
	if isIncreasing then
		currentSpeed = currentSpeed + (settings.incrementRate * deltaTime)
		updateSpeedDisplay()
	elseif isDecreasing then
		currentSpeed = math.max(0, currentSpeed - (settings.incrementRate * deltaTime))
		updateSpeedDisplay()
	end
end)

-- Character Respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = currentSpeed
end)

-- Draggable
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
	local delta = input.Position - dragStart
	local targetFrame = isHidden and miniDisplay or mainFrame
	targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

for _, frame in pairs({mainFrame, miniDisplay}) do
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = (isHidden and miniDisplay or mainFrame).Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
end

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

-- Initialize
updateHotkeyInfo()
updateSpeedDisplay()

print("╔══════════════════════════════════╗")
print("║   ACCELERATION X - INITIALIZED   ║")
print("╚══════════════════════════════════╝")
print("Hotkeys: [" .. settings.increaseKey.Name .. "] Faster | [" .. settings.decreaseKey.Name .. "] Slower | [" .. settings.resetKey.Name .. "] Reset")
print("Press [" .. settings.toggleKey.Name .. "] to hide/show GUI")
