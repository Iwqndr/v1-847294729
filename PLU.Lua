-- Prisonlife.txt (Ultimate V5 - Glassy UI + Settings + Keybinds)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- // CONFIGURATION (Default Keys - Can be changed in Settings) \\
local SETTINGS = {
	TOGGLE_KEY = Enum.KeyCode.R,
	DESTROY_KEY = Enum.KeyCode.P,
	PRIORITY_KEY = Enum.KeyCode.T,
	TELEPORT_KEY = Enum.KeyCode.Y,
	ONE_SHOT_TP_KEY = Enum.KeyCode.H,
	RANGE_INCREASE_KEY = Enum.KeyCode.RightBracket,
	RANGE_DECREASE_KEY = Enum.KeyCode.LeftBracket,
	UNSTICK_KEY = Enum.KeyCode.G,
	POSITION_TOGGLE_KEY = Enum.KeyCode.L,
	SPEED_TOGGLE_KEY = Enum.KeyCode.LeftControl,
	NOCLIP_KEY = Enum.KeyCode.N,
	UI_TOGGLE_KEY = Enum.KeyCode.End
}

-- Constants
local FIRE_RATE = 0.05
local MAX_DISTANCE = 100
local HIGHLIGHT_ENABLED = true
local VOID_HEIGHT = -50
local TELEPORT_SPEED_NORMAL = 0.3
local TELEPORT_SPEED_FAST = 0.8 -- Faster for Below mode

local NORMAL_SPEED = 16
local BOOSTED_SPEED = 50
local SPEED_MULTIPLIER = 1.5 -- CFrame speed multiplier

-- // STATE VARIABLES \\
local toggled = false
local teleportEnabled = false
local oneShotTeleporting = false
local oneShotTarget = nil
local firing = false
local currentTarget = nil
local currentHighlight = nil
local scriptActive = true
local connections = {}
local priorityMode = "closest"
local totalHits = 0
local sessionStartTime = tick()
local targetHistory = {}
local lockMode = "Behind"
local tracerLine = nil
local fovCircle = nil
local isSpeedEnabled = false
local currentSpeedValue = 50 -- Default speed value (1-200)
local isNoclipEnabled = false
local uiVisible = true

local lastSafePosition = Vector3.new(0, 0, 0)

local savedPositions = {}
local savedWaypointPos = UDim2.new(0, 20, 0, 20) -- Persists position
local waypointGui = nil
local scrollFrame = nil

-- // GLASSY THEME HELPER \\
local function applyGlassStyle(element)
	if element:IsA("GuiObject") then
		element.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
		element.BackgroundTransparency = 0.2
		element.BorderSizePixel = 0

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Thickness = 1
		stroke.Transparency = 0.85
		stroke.Parent = element

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = element

		-- Optional Subtle Gradient
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 35)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 25))
		})
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 0.3)
		})
		gradient.Rotation = 90
		gradient.Parent = element
	end
end

-- // DRAGGABLE LOGIC (Now saves position) \\
local function makeDraggable(frame, handle, onSave)
	local dragging = false
	local dragInput, dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if onSave then onSave(frame.Position) end
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- // SETTINGS MENU \\
local function openSettingsMenu()
	if not waypointGui then return end

	local existing = waypointGui:FindFirstChild("SettingsMenu")
	if existing then 
		existing:Destroy() 
		return 
	end

	local settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "SettingsMenu"
	settingsFrame.Size = UDim2.new(0, 300, 0, 400)
	settingsFrame.Position = UDim2.new(1, 10, 0, 0)
	settingsFrame.AnchorPoint = Vector2.new(1, 0)
	settingsFrame.ZIndex = 100
	settingsFrame.Parent = waypointGui
	applyGlassStyle(settingsFrame)

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundTransparency = 1
	header.Text = "⚙️ Global Keybinds"
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.Font = Enum.Font.GothamBold
	header.TextSize = 18
	header.Parent = settingsFrame

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -10, 1, -50)
	scroll.Position = UDim2.new(0, 5, 0, 45)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.Parent = settingsFrame
	applyGlassStyle(scroll)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.Parent = scroll

	local function createSettingRow(name, settingKey)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		row.BackgroundTransparency = 0.5
		row.Parent = scroll

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0, 150, 1, 0)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = Color3.fromRGB(200, 200, 200)
		label.Font = Enum.Font.Gotham
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 100, 0, 20)
		btn.Position = UDim2.new(1, -110, 0.5, -10)
		btn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
		btn.Text = tostring(SETTINGS[settingKey].Name or SETTINGS[settingKey])
		btn.TextColor3 = Color3.new(1,1,1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 10
		btn.Parent = row

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			btn.Text = "Press Key..."
			local input = UserInputService.InputBegan:Wait()
			if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
				SETTINGS[settingKey] = input.KeyCode
				btn.Text = input.KeyCode.Name
			end
		end)
	end

	createSettingRow("Toggle Script", "TOGGLE_KEY")
	createSettingRow("Destroy Script", "DESTROY_KEY")
	createSettingRow("Priority Mode", "PRIORITY_KEY")
	createSettingRow("Teleport Spam", "TELEPORT_KEY")
	createSettingRow("One-Shot TP", "ONE_SHOT_TP_KEY")
	createSettingRow("Range +", "RANGE_INCREASE_KEY")
	createSettingRow("Range -", "RANGE_DECREASE_KEY")
	createSettingRow("Unstick", "UNSTICK_KEY")
	createSettingRow("Toggle Pos", "POSITION_TOGGLE_KEY")
	createSettingRow("Speed Boost", "SPEED_TOGGLE_KEY")
	createSettingRow("Noclip", "NOCLIP_KEY")
	createSettingRow("Toggle UI", "UI_TOGGLE_KEY")

	-- Speed Slider Section
	local speedSection = Instance.new("Frame")
	speedSection.Size = UDim2.new(1, -10, 0, 60)
	speedSection.Position = UDim2.new(0, 5, 0, 0)
	speedSection.BackgroundTransparency = 1
	speedSection.Parent = scroll

	local speedLabel = Instance.new("TextLabel")
	speedLabel.Size = UDim2.new(1, 0, 0, 20)
	speedLabel.Position = UDim2.new(0, 0, 0, 0)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "⚡ Speed: " .. currentSpeedValue
	speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	speedLabel.Font = Enum.Font.Gotham
	speedLabel.TextSize = 12
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.Parent = speedSection

	-- Slider
	local sliderFrame = Instance.new("Frame")
	sliderFrame.Size = UDim2.new(0, 150, 0, 20)
	sliderFrame.Position = UDim2.new(0, 0, 0, 25)
	sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	sliderFrame.BorderSizePixel = 0
	sliderFrame.Parent = speedSection

	local sliderCorner = Instance.new("UICorner")
	sliderCorner.CornerRadius = UDim.new(0, 10)
	sliderCorner.Parent = sliderFrame

	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new(currentSpeedValue / 200, 0, 1, 0)
	sliderFill.Position = UDim2.new(0, 0, 0, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderFrame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 10)
	fillCorner.Parent = sliderFill

	local sliderButton = Instance.new("TextButton")
	sliderButton.Size = UDim2.new(0, 20, 0, 20)
	sliderButton.Position = UDim2.new(currentSpeedValue / 200, -10, 0, 0)
	sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderButton.BorderSizePixel = 0
	sliderButton.Text = ""
	sliderButton.Parent = sliderFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = sliderButton

	-- Text Box
	local speedBox = Instance.new("TextBox")
	speedBox.Size = UDim2.new(0, 50, 0, 20)
	speedBox.Position = UDim2.new(0, 160, 0, 25)
	speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	speedBox.Text = tostring(currentSpeedValue)
	speedBox.TextColor3 = Color3.new(1, 1, 1)
	speedBox.Font = Enum.Font.Gotham
	speedBox.TextSize = 12
	speedBox.Parent = speedSection

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 4)
	boxCorner.Parent = speedBox

	-- Slider functionality
	local draggingSlider = false

	local function updateSpeed(value)
		value = math.clamp(math.floor(value), 1, 200)
		currentSpeedValue = value
		speedLabel.Text = "⚡ Speed: " .. value
		speedBox.Text = tostring(value)
		sliderFill.Size = UDim2.new(value / 200, 0, 1, 0)
		sliderButton.Position = UDim2.new(value / 200, -10, 0, 0)
		updateSpeed()
	end

	sliderButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
			local relativeX = input.Position.X - sliderFrame.AbsolutePosition.X
			local percentage = math.clamp(relativeX / sliderFrame.AbsoluteSize.X, 0, 1)
			updateSpeed(percentage * 200)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = false
		end
	end)

	speedBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local value = tonumber(speedBox.Text)
			if value then
				updateSpeed(value)
			else
				speedBox.Text = tostring(currentSpeedValue)
			end
		end
	end)

	-- Animate In
	settingsFrame:TweenPosition(UDim2.new(1, -310, 0, 0), "Out", "Quad", 0.3, true)
end

-- // GUI BUILDER \\
local function createNotificationGui()
	local screenGui = playerGui:FindFirstChild("MeleeTargetNotification")
	if screenGui then return screenGui end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MeleeTargetNotification"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true

	tracerLine = Instance.new("Frame")
	tracerLine.Name = "TracerLine"
	tracerLine.AnchorPoint = Vector2.new(0.5, 0.5)
	tracerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	tracerLine.BorderSizePixel = 0
	tracerLine.BackgroundTransparency = 0.5
	tracerLine.Visible = false
	tracerLine.Parent = screenGui



	local frame = Instance.new("Frame")
	frame.Name = "NotificationFrame"
	frame.Size = UDim2.new(0, 320, 0, 110)
	frame.Position = UDim2.new(1, 20, 1, 0)
	frame.AnchorPoint = Vector2.new(1, 1)
	applyGlassStyle(frame)
	frame.Parent = screenGui

	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(1, 0, 0, 4)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	accentBar.BorderSizePixel = 0
	accentBar.Parent = frame

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 14)
	accentCorner.Parent = accentBar

	local avatarFrame = Instance.new("Frame")
	avatarFrame.Name = "AvatarFrame"
	avatarFrame.Size = UDim2.new(0, 70, 0, 70)
	avatarFrame.Position = UDim2.new(0, 15, 0, 25)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	avatarFrame.BorderSizePixel = 0
	avatarFrame.BackgroundTransparency = 0.2
	avatarFrame.Parent = frame

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 12)
	avatarCorner.Parent = avatarFrame

	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Name = "AvatarStroke"
	avatarStroke.Color = Color3.fromRGB(100, 255, 100)
	avatarStroke.Thickness = 3
	avatarStroke.Parent = avatarFrame

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(1, 0, 1, 0)
	avatar.BackgroundTransparency = 1
	avatar.Image = ""
	avatar.Parent = avatarFrame

	local avatarImgCorner = Instance.new("UICorner")
	avatarImgCorner.CornerRadius = UDim.new(0, 12)
	avatarImgCorner.Parent = avatar

	local statusDot = Instance.new("Frame")
	statusDot.Name = "StatusDot"
	statusDot.Size = UDim2.new(0, 12, 0, 12)
	statusDot.Position = UDim2.new(0, 100, 0, 18)
	statusDot.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	statusDot.BorderSizePixel = 0
	statusDot.BackgroundTransparency = 0
	statusDot.Parent = frame

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = statusDot

	task.spawn(function()
		while frame.Parent and scriptActive do
			TweenService:Create(statusDot, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
				Size = UDim2.new(0, 14, 0, 14),
				BackgroundTransparency = 0.3
			}):Play()
			task.wait(0.8)
		end
	end)

	local textContainer = Instance.new("Frame")
	textContainer.Name = "TextContainer"
	textContainer.Size = UDim2.new(1, -125, 1, -30)
	textContainer.Position = UDim2.new(0, 115, 0, 15)
	textContainer.BackgroundTransparency = 1
	textContainer.Parent = frame

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 18)
	statusLabel.Position = UDim2.new(0, 0, 0, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "● TARGETING"
	statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.GothamMedium
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = textContainer

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 28)
	nameLabel.Position = UDim2.new(0, 0, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "No Target"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = textContainer

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoLabel"
	infoLabel.Size = UDim2.new(1, 0, 0, 16)
	infoLabel.Position = UDim2.new(0, 0, 0, 44)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Distance: --"
	infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	infoLabel.TextSize = 10
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = textContainer

	local healthLabel = Instance.new("TextLabel")
	healthLabel.Name = "HealthLabel"
	healthLabel.Size = UDim2.new(1, 0, 0, 16)
	healthLabel.Position = UDim2.new(0, 0, 0, 58)
	healthLabel.BackgroundTransparency = 1
	healthLabel.Text = "Health: --"
	healthLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	healthLabel.TextSize = 10
	healthLabel.Font = Enum.Font.Gotham
	healthLabel.TextXAlignment = Enum.TextXAlignment.Left
	healthLabel.Parent = textContainer

	screenGui.Parent = playerGui
	return screenGui
end

-- // WAYPOINT MANAGER (Overhauled) \\
local function createWaypointManager()
	local screenGui = playerGui:FindFirstChild("MeleeTargetNotification")
	if not screenGui then return end
	if waypointGui then waypointGui:Destroy() end

	waypointGui = Instance.new("Frame")
	waypointGui.Name = "WaypointManager"
	waypointGui.Size = UDim2.new(0, 300, 0, 400)
	waypointGui.Position = UDim2.new(1, -320, 0.5, -200) -- Start in middle right
	waypointGui.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	waypointGui.BorderSizePixel = 0
	waypointGui.Parent = screenGui
	applyGlassStyle(waypointGui)

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 35)
	topBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	topBar.BackgroundTransparency = 0.9
	topBar.BorderSizePixel = 0
	topBar.Parent = waypointGui

	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 12)
	topCorner.Parent = topBar

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -40, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "📍 Waypoints"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = topBar

	-- Settings Button
	local settingsBtn = Instance.new("TextButton")
	settingsBtn.Size = UDim2.new(0, 25, 0, 25)
	settingsBtn.Position = UDim2.new(1, -30, 0.5, -12)
	settingsBtn.BackgroundTransparency = 1
	settingsBtn.Text = "⚙️"
	settingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	settingsBtn.TextSize = 14
	settingsBtn.Parent = topBar
	settingsBtn.MouseButton1Click:Connect(function()
		openSettingsMenu()
	end)

	makeDraggable(waypointGui, topBar, function(pos) 
		savedWaypointPos = pos -- Save on drag end
	end)

	local actionsFrame = Instance.new("Frame")
	actionsFrame.Size = UDim2.new(1, -10, 0, 35)
	actionsFrame.Position = UDim2.new(0, 5, 0, 40)
	actionsFrame.BackgroundTransparency = 1
	actionsFrame.Parent = waypointGui

	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(1, 0, 0, 25)
	saveBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	saveBtn.BackgroundTransparency = 0.2
	saveBtn.TextColor3 = Color3.new(1, 1, 1)
	saveBtn.Font = Enum.Font.GothamBold
	saveBtn.TextSize = 12
	saveBtn.Text = "💾 Save Current Position"
	saveBtn.Parent = actionsFrame

	local saveCorner = Instance.new("UICorner")
	saveCorner.CornerRadius = UDim.new(0, 6)
	saveCorner.Parent = saveBtn

	saveBtn.MouseButton1Click:Connect(function()
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local pos = char.HumanoidRootPart.Position
			local name = string.format("(%d, %d, %d)", math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))

			table.insert(savedPositions, {
				name = name,
				cframe = char.HumanoidRootPart.CFrame,
				keybind = nil
			})
			refreshWaypointList()
			showModeNotification("Saved: " .. name)
		end
	end)

	scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -10, 1, -90)
	scrollFrame.Position = UDim2.new(0, 5, 0, 85)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 3
	scrollFrame.Parent = waypointGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = scrollFrame

	refreshWaypointList = function()
		if not scrollFrame then return end
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		for i, data in ipairs(savedPositions) do
			local itemFrame = Instance.new("Frame")
			itemFrame.Name = "Item" .. i
			itemFrame.Size = UDim2.new(1, 0, 0, 35) -- Taller for keybind
			itemFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			itemFrame.BackgroundTransparency = 0.4
			itemFrame.Parent = scrollFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 6)
			itemCorner.Parent = itemFrame

			-- Name Button
			local nameBtn = Instance.new("TextButton")
			nameBtn.Size = UDim2.new(1, -130, 0, 18)
			nameBtn.Position = UDim2.new(0, 5, 0, 2)
			nameBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
			nameBtn.BackgroundTransparency = 0.6
			nameBtn.TextColor3 = Color3.new(1, 1, 1)
			nameBtn.Font = Enum.Font.Gotham
			nameBtn.TextSize = 10
			nameBtn.TextXAlignment = Enum.TextXAlignment.Left
			nameBtn.ClipsDescendants = true
			nameBtn.Text = data.name
			nameBtn.Parent = itemFrame

			local nameCorner = Instance.new("UICorner")
			nameCorner.CornerRadius = UDim.new(0, 4)
			nameCorner.Parent = nameBtn

			nameBtn.MouseButton1Click:Connect(function()
				local char = player.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					TweenService:Create(char.HumanoidRootPart, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
						CFrame = data.cframe
					}):Play()
					showModeNotification("Teleported to: " .. data.name)
				end
			end)

			-- Keybind Button (NEW)
			local keyBtn = Instance.new("TextButton")
			keyBtn.Size = UDim2.new(0, 40, 0, 18)
			keyBtn.Position = UDim2.new(1, -120, 0, 2)
			keyBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
			keyBtn.BackgroundTransparency = 0.4
			keyBtn.TextColor3 = Color3.new(1,1,1)
			keyBtn.Font = Enum.Font.GothamBold
			keyBtn.TextSize = 9
			keyBtn.Text = data.keybind and data.keybind.Name or "🔗"
			keyBtn.Parent = itemFrame

			local kCorner = Instance.new("UICorner")
			kCorner.CornerRadius = UDim.new(0, 4)
			kCorner.Parent = keyBtn

			keyBtn.MouseButton1Click:Connect(function()
				keyBtn.Text = "..."
				local input = UserInputService.InputBegan:Wait()
				if input.KeyCode then
					savedPositions[i].keybind = input.KeyCode
					refreshWaypointList()
				end
			end)

			-- Rename Button
			local renameBtn = Instance.new("TextButton")
			renameBtn.Size = UDim2.new(0, 25, 0, 15)
			renameBtn.Position = UDim2.new(1, -75, 0.5, 2)
			renameBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			renameBtn.BackgroundTransparency = 0.8
			renameBtn.Text = "✏️"
			renameBtn.TextColor3 = Color3.new(1, 1, 1)
			renameBtn.TextSize = 9
			renameBtn.Parent = itemFrame

			local rCorner = Instance.new("UICorner")
			rCorner.CornerRadius = UDim.new(0, 4)
			rCorner.Parent = renameBtn

			renameBtn.MouseButton1Click:Connect(function() openRenamePrompt(i) end)

			-- Delete Button
			local delBtn = Instance.new("TextButton")
			delBtn.Size = UDim2.new(0, 25, 0, 15)
			delBtn.Position = UDim2.new(1, -45, 0.5, 2)
			delBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
			delBtn.BackgroundTransparency = 0.4
			delBtn.Text = "🗑️"
			delBtn.TextColor3 = Color3.new(1, 1, 1)
			delBtn.TextSize = 9
			delBtn.Parent = itemFrame

			local dCorner = Instance.new("UICorner")
			dCorner.CornerRadius = UDim.new(0, 4)
			dCorner.Parent = delBtn

			delBtn.MouseButton1Click:Connect(function()
				table.remove(savedPositions, i)
				refreshWaypointList()
			end)
		end
	end

	refreshWaypointList()

	-- Slide In Animation
	waypointGui:TweenPosition(UDim2.new(1, -320, 0.5, -200), "Out", "Quad", 0.5, true)
end

-- // RENAME PROMPT \\
local function openRenamePrompt(index)
	local data = savedPositions[index]
	if not data then return end

	local screenGui = playerGui:FindFirstChild("MeleeTargetNotification")
	if not screenGui then return end

	local overlay = Instance.new("Frame")
	overlay.Name = "RenameOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.ZIndex = 100
	overlay.Parent = screenGui

	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0, 300, 0, 150)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	applyGlassStyle(popup)
	popup.ZIndex = 101
	popup.Parent = overlay

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "Rename Waypoint"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.Parent = popup

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -20, 0, 30)
	box.Position = UDim2.new(0, 10, 0, 40)
	box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Text = data.name
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.ClearTextOnFocus = false
	box.Parent = popup

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 5)
	bCorner.Parent = box

	local confirm = Instance.new("TextButton")
	confirm.Size = UDim2.new(1, -20, 0, 30)
	confirm.Position = UDim2.new(0, 10, 0, 85)
	confirm.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	confirm.Text = "Confirm"
	confirm.TextColor3 = Color3.new(1, 1, 1)
	confirm.Font = Enum.Font.GothamBold
	confirm.Parent = popup

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 5)
	cCorner.Parent = confirm

	confirm.MouseButton1Click:Connect(function()
		local newName = box.Text
		if newName and newName ~= "" then
			savedPositions[index].name = newName
			refreshWaypointList()
		end
		overlay:Destroy()
	end)

	overlay.MouseButton1Click:Connect(function() overlay:Destroy() end)
end

-- // UPDATE UI \\
local function createStatsPanel()
	local screenGui = playerGui:FindFirstChild("MeleeTargetNotification")
	if not screenGui then return end

	local statsFrame = screenGui:FindFirstChild("StatsFrame")
	if statsFrame then return end 

	statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.new(0, 320, 0, 130)
	statsFrame.Position = UDim2.new(1, 20, 1, -150)
	statsFrame.AnchorPoint = Vector2.new(1, 1)
	applyGlassStyle(statsFrame)
	statsFrame.Parent = screenGui

	local statsTitle = Instance.new("TextLabel")
	statsTitle.Name = "StatsTitle"
	statsTitle.Size = UDim2.new(1, -20, 0, 20)
	statsTitle.Position = UDim2.new(0, 10, 0, 8)
	statsTitle.BackgroundTransparency = 1
	statsTitle.Text = "📊 SESSION STATS"
	statsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsTitle.TextSize = 12
	statsTitle.Font = Enum.Font.GothamBold
	statsTitle.TextXAlignment = Enum.TextXAlignment.Left
	statsTitle.Parent = statsFrame

	local hitsLabel = Instance.new("TextLabel")
	hitsLabel.Name = "HitsLabel"
	hitsLabel.Size = UDim2.new(0.5, -15, 0, 18)
	hitsLabel.Position = UDim2.new(0, 10, 0, 32)
	hitsLabel.BackgroundTransparency = 1
	hitsLabel.Text = "Hits: 0"
	hitsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	hitsLabel.TextSize = 14
	hitsLabel.Font = Enum.Font.GothamMedium
	hitsLabel.TextXAlignment = Enum.TextXAlignment.Left
	hitsLabel.Parent = statsFrame

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(0.5, -15, 0, 18)
	timeLabel.Position = UDim2.new(0.5, 5, 0, 32)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "Time: 0s"
	timeLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	timeLabel.TextSize = 14
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Parent = statsFrame

	local modeLabel = Instance.new("TextLabel")
	modeLabel.Name = "ModeLabel"
	modeLabel.Size = UDim2.new(1, -20, 0, 16)
	modeLabel.Position = UDim2.new(0, 10, 0, 54)
	modeLabel.BackgroundTransparency = 1
	modeLabel.Text = "Mode: Closest Enemy"
	modeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	modeLabel.TextSize = 11
	modeLabel.Font = Enum.Font.Gotham
	modeLabel.TextXAlignment = Enum.TextXAlignment.Left
	modeLabel.Parent = statsFrame

	local lockPosLabel = Instance.new("TextLabel")
	lockPosLabel.Name = "LockPosLabel"
	lockPosLabel.Size = UDim2.new(1, -20, 0, 16)
	lockPosLabel.Position = UDim2.new(0, 10, 0, 70)
	lockPosLabel.BackgroundTransparency = 1
	lockPosLabel.Text = "📍 Lock Pos: Behind"
	lockPosLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	lockPosLabel.TextSize = 11
	lockPosLabel.Font = Enum.Font.Gotham
	lockPosLabel.TextXAlignment = Enum.TextXAlignment.Left
	lockPosLabel.Parent = statsFrame

	local extraLabel = Instance.new("TextLabel")
	extraLabel.Name = "ExtraLabel"
	extraLabel.Size = UDim2.new(1, -20, 0, 16)
	extraLabel.Position = UDim2.new(0, 10, 0, 86)
	extraLabel.BackgroundTransparency = 1
	extraLabel.Text = "⚡ Speed: OFF | 🧱 Noclip: OFF"
	extraLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	extraLabel.TextSize = 11
	extraLabel.Font = Enum.Font.Gotham
	extraLabel.TextXAlignment = Enum.TextXAlignment.Left
	extraLabel.Parent = statsFrame

	local tpLabel = Instance.new("TextLabel")
	tpLabel.Name = "TeleportLabel"
	tpLabel.Size = UDim2.new(1, -20, 0, 16)
	tpLabel.Position = UDim2.new(0, 10, 0, 102)
	tpLabel.BackgroundTransparency = 1
	tpLabel.Text = "📍 Teleport: OFF"
	tpLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	tpLabel.TextSize = 11
	tpLabel.Font = Enum.Font.Gotham
	tpLabel.TextXAlignment = Enum.TextXAlignment.Left
	tpLabel.Parent = statsFrame

	statsFrame.Position = UDim2.new(1, 20, 1, -150)
	TweenService:Create(statsFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -20, 1, -150)
	}):Play()
end

local function updateStatsPanel()
	local screenGui = playerGui:FindFirstChild("MeleeTargetNotification")
	if not screenGui then return end

	local statsFrame = screenGui:FindFirstChild("StatsFrame")
	if not statsFrame then return end

	local hitsLabel = statsFrame:FindFirstChild("HitsLabel")
	local timeLabel = statsFrame:FindFirstChild("TimeLabel")
	local modeLabel = statsFrame:FindFirstChild("ModeLabel")
	local lockPosLabel = statsFrame:FindFirstChild("LockPosLabel")
	local extraLabel = statsFrame:FindFirstChild("ExtraLabel")
	local tpLabel = statsFrame:FindFirstChild("TeleportLabel")

	if hitsLabel then hitsLabel.Text = "Hits: " .. totalHits end

	if timeLabel then
		local elapsed = math.floor(tick() - sessionStartTime)
		local minutes = math.floor(elapsed / 60)
		local seconds = elapsed % 60
		timeLabel.Text = string.format("Time: %dm %ds", minutes, seconds)
	end

	if modeLabel then
		local rangeText = string.format("Range: %.0f", MAX_DISTANCE)
		if priorityMode == "closest" then
			modeLabel.Text = "🎯 Mode: Closest | " .. rangeText
		else
			modeLabel.Text = "❤️ Mode: Lowest HP | " .. rangeText
		end
	end

	if lockPosLabel then
		lockPosLabel.Text = "📍 Lock Pos: " .. lockMode
	end

	if extraLabel then
		local speedStr = isSpeedEnabled and "ON" or "OFF"
		local noclipStr = isNoclipEnabled and "ON" or "OFF"
		extraLabel.Text = string.format("⚡ Speed: %s | 🧱 Noclip: %s", speedStr, noclipStr)
	end

	if tpLabel then
		if teleportEnabled then
			tpLabel.Text = "📍 Teleport (Y): ON"
			tpLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		elseif oneShotTeleporting then
			tpLabel.Text = "📍 One-Shot (H): ACTIVE"
			tpLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		else
			tpLabel.Text = "📍 Teleport: OFF"
			tpLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	end
end

local function updateTracer()
	if not tracerLine then return end
	local character = player.Character
	local targetChar = currentTarget and currentTarget.Character

	if not character or not character:FindFirstChild("HumanoidRootPart") then
		tracerLine.Visible = false
		return
	end

	local myHead = character:FindFirstChild("Head")
	local targetHead = targetChar and targetChar:FindFirstChild("Head")

	if myHead and targetHead then
		local myHeadPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(myHead.Position)
		local targetPos = Workspace.CurrentCamera:WorldToViewportPoint(targetHead.Position)

		if onScreen then
			tracerLine.Visible = true
			tracerLine.Position = UDim2.new(0, myHeadPos.X, 0, myHeadPos.Y)
			local center = Vector2.new(playerGui.AbsoluteSize.X / 2, playerGui.AbsoluteSize.Y / 2)

			local dist = (Vector2.new(targetPos.X, targetPos.Y) - center).Magnitude
			local angle = math.atan2(targetPos.Y - center.Y, targetPos.X - center.X)

			tracerLine.Size = UDim2.new(0, dist, 0, 2)
			tracerLine.Rotation = math.deg(angle)
		else
			tracerLine.Visible = false
		end
	else
		tracerLine.Visible = false
	end
end

local function updateHighlight(targetPlayer)
	if currentHighlight then
		currentHighlight:Destroy()
		currentHighlight = nil
	end

	if not HIGHLIGHT_ENABLED or not targetPlayer then return end

	local character = targetPlayer.Character
	if not character then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "TargetHighlight"
	highlight.Adornee = character
	highlight.FillTransparency = 0.6
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	if targetPlayer.Team then
		highlight.FillColor = targetPlayer.TeamColor.Color
		highlight.OutlineColor = targetPlayer.TeamColor.Color
	else
		highlight.FillColor = Color3.fromRGB(255, 100, 100)
		highlight.OutlineColor = Color3.fromRGB(255, 100, 100)
	end

	highlight.Parent = character
	currentHighlight = highlight



	task.spawn(function()
		while currentHighlight and currentHighlight.Parent and scriptActive do
			TweenService:Create(highlight, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				OutlineTransparency = 0.3
			}):Play()
			task.wait(0.6)
		end
	end)
end

-- // CORE LOGIC \\
local function getTarget()
	local character = player.Character
	if not character then return nil, nil, nil end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return nil, nil, nil end

	local myTeam = player.Team
	local targetPlayer = nil
	local targetDistance = MAX_DISTANCE
	local targetHealth = math.huge

	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Team ~= myTeam then
			local otherCharacter = otherPlayer.Character
			if otherCharacter then
				local otherHRP = otherCharacter:FindFirstChild("HumanoidRootPart")
				local otherHumanoid = otherCharacter:FindFirstChild("Humanoid")
				if otherHRP and otherHumanoid and otherHumanoid.Health > 0 then
					local distance = (humanoidRootPart.Position - otherHRP.Position).Magnitude

					if distance <= MAX_DISTANCE then
						if priorityMode == "closest" then
							if distance < targetDistance then
								targetDistance = distance
								targetPlayer = otherPlayer
								targetHealth = otherHumanoid.Health
							end
						else
							if otherHumanoid.Health < targetHealth then
								targetHealth = otherHumanoid.Health
								targetPlayer = otherPlayer
								targetDistance = distance
							end
						end
					end
				end
			end
		end
	end

	return targetPlayer, targetDistance, targetHealth
end

local function getTargetOffsetCFrame(targetHRP)
	local targetCFrame = targetHRP.CFrame

	if lockMode == "Below" then
		-- Change -5 here to go deeper if you want
		return targetCFrame * CFrame.new(0, -6.5, 0)
	else
		return targetCFrame * CFrame.new(0, 0, 4) 
	end
end

local function manualUnstick()
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local goalPos = hrp.Position + Vector3.new(0, 15, 5)
	local goalCFrame = CFrame.new(goalPos)

	print("[G] Manual Unstick Activated")
	TweenService:Create(hrp, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = goalCFrame
	}):Play()

	hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
end

local function forceNoclip(character)
	if not character then return end
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

local function restoreCollision(character)
	if not character then return end
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end
end

local function handleTeleport()
	if not teleportEnabled or not scriptActive then return end

	RunService.Heartbeat:Connect(function()
		if not teleportEnabled or not scriptActive then return end

		local character = player.Character
		local myHRP = character and character:FindFirstChild("HumanoidRootPart")

		if currentTarget and myHRP then
			local targetChar = currentTarget.Character
			local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
			local targetHum = targetChar and targetChar:FindFirstChild("Humanoid")

			if targetHRP and targetHum and targetHum.Health > 0 then
				forceNoclip(character)

				local goalCFrame = getTargetOffsetCFrame(targetHRP)
				local speed = (lockMode == "Below") and TELEPORT_SPEED_FAST or TELEPORT_SPEED_NORMAL

				myHRP.CFrame = myHRP.CFrame:Lerp(goalCFrame, speed)

				if lockMode ~= "Below" then
					if targetHRP.Position.Y > myHRP.Position.Y + 5 then
						local hum = character:FindFirstChild("Humanoid")
						if hum and hum.FloorMaterial ~= Enum.Material.Air then
							hum:ChangeState(Enum.HumanoidStateType.Jumping)
						end
					end
				end

				myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				lastSafePosition = myHRP.Position
			end
		end
	end)
end

local function handleOneShotTeleport()
	if not oneShotTeleporting or not oneShotTarget or not scriptActive then return end

	task.spawn(function()
		while oneShotTeleporting and oneShotTarget and scriptActive do
			local character = player.Character
			local myHRP = character and character:FindFirstChild("HumanoidRootPart")

			local targetChar = oneShotTarget.Character
			local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
			local targetHum = targetChar and targetChar:FindFirstChild("Humanoid")

			if myHRP and targetHRP then
				forceNoclip(character)

				if targetHum and targetHum.Health > 0 then
					local goalCFrame = getTargetOffsetCFrame(targetHRP)
					local speed = (lockMode == "Below") and TELEPORT_SPEED_FAST or TELEPORT_SPEED_NORMAL

					myHRP.CFrame = myHRP.CFrame:Lerp(goalCFrame, speed)

					if lockMode ~= "Below" then
						if targetHRP.Position.Y > myHRP.Position.Y + 5 then
							local hum = character:FindFirstChild("Humanoid")
							if hum and hum.FloorMaterial ~= Enum.Material.Air then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
						end
					end

					myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					lastSafePosition = myHRP.Position
				else
					print("Target died. Teleporting to body for loot...")
					myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2)
					oneShotTeleporting = false
					oneShotTarget = nil
					updateStatsPanel()
				end
			end
			task.wait(0.02)
		end
	end)
end

-- // SPEED & NOCLIP LOOPS \\
local speedConnection = nil

local function updateSpeed()
	-- This function now just updates the WalkSpeed when needed
end

RunService.Heartbeat:Connect(function()
	if scriptActive then
		local character = player.Character
		local hum = character and character:FindFirstChild("Humanoid")

		if hum then
			hum.WalkSpeed = isSpeedEnabled and (currentSpeedValue / 2) or NORMAL_SPEED
		end

		-- Continuous noclip enforcement
		if isNoclipEnabled and character then
			forceNoclip(character)
		end
	end
end)

local function updateNotification(targetPlayer, distance, health)
	local notifGui = playerGui:FindFirstChild("MeleeTargetNotification")
	if not notifGui then notifGui = createNotificationGui() end

	local frame = notifGui.NotificationFrame
	local nameLabel = frame.TextContainer.NameLabel
	local infoLabel = frame.TextContainer.InfoLabel
	local healthLabel = frame.TextContainer.HealthLabel
	local avatar = frame.AvatarFrame.Avatar
	local avatarStroke = frame.AvatarFrame.AvatarStroke
	local statusDot = frame.StatusDot
	local accentBar = frame.AccentBar

	if targetPlayer then
		nameLabel.Text = targetPlayer.Name
		if distance then infoLabel.Text = string.format("📏 Distance: %.1f studs", distance) end

		if health then
			healthLabel.Text = string.format("❤️ Health: %.0f HP", health)
			local healthPercent = health / 100
			healthLabel.TextColor3 = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
		end

		local teamColor = Color3.fromRGB(100, 255, 100)
		if targetPlayer.Team then
			teamColor = targetPlayer.TeamColor.Color
			nameLabel.TextColor3 = teamColor
			frame.BackgroundColor3 = Color3.fromRGB(math.clamp(teamColor.R * 50, 15, 40), math.clamp(teamColor.G * 50, 15, 40), math.clamp(teamColor.B * 50, 15, 40))
		else
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end

		local userId = targetPlayer.UserId
		avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
		avatarStroke.Color = teamColor
		statusDot.BackgroundColor3 = teamColor
		accentBar.BackgroundColor3 = teamColor
	else
		nameLabel.Text = "No Target"
		nameLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		infoLabel.Text = "📏 Distance: --"
		healthLabel.Text = "❤️ Health: --"
		healthLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		avatar.Image = ""
		frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		statusDot.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		avatarStroke.Color = Color3.fromRGB(255, 100, 100)
		accentBar.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	end
end

local function showNotification()
	local notifGui = playerGui:FindFirstChild("MeleeTargetNotification")
	if not notifGui then notifGui = createNotificationGui() end

	local frame = notifGui.NotificationFrame
	frame.Position = UDim2.new(1, 20, 1, 0)

	TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -20, 1, -20)
	}):Play()

	createStatsPanel()
	createWaypointManager()
end

local function hideNotification()
	local notifGui = playerGui:FindFirstChild("MeleeTargetNotification")
	if not notifGui then return end

	local frame = notifGui.NotificationFrame
	local statsFrame = notifGui:FindFirstChild("StatsFrame")
	local wpGui = notifGui:FindFirstChild("WaypointManager")

	TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 20, 1, 0)
	}):Play()

	if statsFrame then
		TweenService:Create(statsFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 20, 1, -150)
		}):Play()
	end

	if wpGui then
		TweenService:Create(wpGui, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(0, -300, 0, 20)
		}):Play()
	end
end

local function showModeNotification(mode)
	local notifGui = playerGui:FindFirstChild("MeleeTargetNotification")
	if not notifGui then return end

	local modeNotif = Instance.new("Frame")
	modeNotif.Name = "ModeChangeNotif"
	modeNotif.Size = UDim2.new(0, 250, 0, 50)
	modeNotif.Position = UDim2.new(1, -20, 1, -200)
	modeNotif.AnchorPoint = Vector2.new(1, 1)
	modeNotif.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	modeNotif.BorderSizePixel = 0
	modeNotif.Parent = notifGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = modeNotif

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = modeNotif

	if mode == "closest" then
		label.Text = "🎯 Mode: Closest Enemy"
	elseif mode == "lowestHealth" then
		label.Text = "❤️ Mode: Lowest Health"
	elseif mode == "teleportOn" then
		label.Text = "📍 Teleport (Y): ON"
	elseif mode == "teleportOff" then
		label.Text = "📍 Teleport (Y): OFF"
	elseif mode == "oneShotOn" then
		label.Text = "🔹 One-Shot (H): LOCKED"
	elseif mode == "oneShotOff" then
		label.Text = "🔸 One-Shot (H): OFF"
	elseif mode == "posBehind" then
		label.Text = "🔙 Position: Behind Target"
	elseif mode == "posBelow" then
		label.Text = "🔻 Position: Below Target"
	elseif mode == "unstick" then
		label.Text = "🆘 Unsticking..."
	elseif mode == "speedOn" then
		label.Text = "⚡ Speed Boost: ON"
	elseif mode == "speedOff" then
		label.Text = "⚡ Speed Boost: OFF"
	elseif mode == "noclipOn" then
		label.Text = "🧱 Noclip: ON"
	elseif mode == "noclipOff" then
		label.Text = "🧱 Noclip: OFF"
	end

	TweenService:Create(modeNotif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -20, 1, -170)
	}):Play()

	task.wait(1.5)
	TweenService:Create(modeNotif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(1, -20, 1, -200)
	}):Play()
	task.wait(0.3)
	modeNotif:Destroy()
end

local function startFiring()
	if firing then return end
	firing = true

	RunService.RenderStepped:Connect(function()
		if not scriptActive then return end
		updateTracer()
	end)

	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		lastSafePosition = character.HumanoidRootPart.Position
	end

	task.spawn(function()
		while firing and toggled and scriptActive do
			local target, distance, health = getTarget()

			if target ~= currentTarget then
				currentTarget = target
				updateNotification(target, distance, health)
				updateHighlight(target)

				if target and target.Name and not targetHistory[target.Name] then
					targetHistory[target.Name] = true
				end
			elseif target then
				updateNotification(target, distance, health)
			end

			if target then
				pcall(function()
					local meleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")
				if meleeEvent then
					meleeEvent:FireServer(target)
				end
					totalHits = totalHits + 1
				end)
			end

			updateStatsPanel()
			task.wait(FIRE_RATE)
		end
		firing = false
	end)
end

local function stopFiring()
	firing = false
	currentTarget = nil
	updateHighlight(nil)

	if tracerLine then tracerLine.Visible = false end
end

local function cleanup()
	scriptActive = false
	toggled = false
	teleportEnabled = false
	oneShotTeleporting = false
	stopFiring()

	for _, connection in pairs(connections) do
		connection:Disconnect()
	end

	hideNotification()
	task.wait(0.5)
	local notifGui = playerGui:FindFirstChild("MeleeTargetNotification")
	if notifGui then notifGui:Destroy() end

	if currentHighlight then currentHighlight:Destroy() end

	print("✓ Auto Melee script destroyed successfully!")
	print(string.format("📊 Final Stats - Hits: %d | Unique Targets: %d | Session Time: %.0fs", 
		totalHits, #targetHistory, tick() - sessionStartTime))

	script:Destroy()
end

connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not scriptActive then return end
	if gameProcessed then return end

	-- Check Waypoint Keybinds First
	for _, wp in ipairs(savedPositions) do
		if wp.keybind and input.KeyCode == wp.keybind then
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				TweenService:Create(char.HumanoidRootPart, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
					CFrame = wp.cframe
				}):Play()
				showModeNotification("Teleported to: " .. wp.name)
			end
			return -- Consumed input
		end
	end

	-- Global Keys
	if input.KeyCode == SETTINGS.UI_TOGGLE_KEY then
		uiVisible = not uiVisible
		local notifGui = playerGui:FindFirstChild("MeleeTargetNotification")
		if notifGui then notifGui.Enabled = uiVisible end
		return
	end

	if input.KeyCode == SETTINGS.TOGGLE_KEY then
		toggled = not toggled

		if toggled then
			print("⚔ Auto Melee: ON")
			sessionStartTime = tick()
			totalHits = 0
			targetHistory = {}
			showNotification()
			startFiring()
		else
			print("⚔ Auto Melee: OFF")
			stopFiring()
			hideNotification()
			teleportEnabled = false
			oneShotTeleporting = false
			oneShotTarget = nil
			updateStatsPanel()
		end

	elseif input.KeyCode == SETTINGS.DESTROY_KEY then
		print("🗑 Destroying Auto Melee script...")
		cleanup()

	elseif input.KeyCode == SETTINGS.PRIORITY_KEY and toggled then
		priorityMode = priorityMode == "closest" and "lowestHealth" or "closest"
		showModeNotification(priorityMode)
		print("🎯 Priority Mode: " .. priorityMode)
		updateStatsPanel()

	elseif input.KeyCode == SETTINGS.POSITION_TOGGLE_KEY then
		lockMode = lockMode == "Behind" and "Below" or "Behind"
		showModeNotification(lockMode == "Behind" and "posBehind" or "posBelow")
		updateStatsPanel()

	elseif input.KeyCode == SETTINGS.UNSTICK_KEY then
		manualUnstick()
		showModeNotification("unstick")

	elseif input.KeyCode == SETTINGS.SPEED_TOGGLE_KEY then
		isSpeedEnabled = not isSpeedEnabled
		showModeNotification(isSpeedEnabled and "speedOn" or "speedOff")
		updateStatsPanel()

	elseif input.KeyCode == SETTINGS.NOCLIP_KEY then
		isNoclipEnabled = not isNoclipEnabled
		
		local character = player.Character
		if isNoclipEnabled then
			print("🧱 Noclip: ON - You can now walk through walls!")
			if character then
				forceNoclip(character)
			end
		else
			print("🧱 Noclip: OFF - Collision restored")
			if character then
				restoreCollision(character)
			end
		end
		
		showModeNotification(isNoclipEnabled and "noclipOn" or "noclipOff")
		updateStatsPanel()

	elseif input.KeyCode == SETTINGS.TELEPORT_KEY and toggled then
		if oneShotTeleporting then
			oneShotTeleporting = false
			oneShotTarget = nil
		end

		teleportEnabled = not teleportEnabled

		if teleportEnabled then
			print("📍 Spam Teleport: ON")
			handleTeleport()
			showModeNotification("teleportOn")
		else
			print("📍 Spam Teleport: OFF")
			teleportEnabled = false
			showModeNotification("teleportOff")
		end
		updateStatsPanel()

	elseif input.KeyCode == SETTINGS.ONE_SHOT_TP_KEY and toggled then
		if teleportEnabled then teleportEnabled = false end

		if not oneShotTeleporting then
			local target = currentTarget
			if target then
				oneShotTarget = target
				oneShotTeleporting = true
				handleOneShotTeleport()
				print("🔹 One-Shot Teleport: LOCKED ON " .. target.Name)
				showModeNotification("oneShotOn")
			else
				print("No target to lock onto!")
			end
		else
			oneShotTeleporting = false
			oneShotTarget = nil
			print("🔸 One-Shot Teleport: OFF")
			showModeNotification("oneShotOff")
		end
		updateStatsPanel()

	elseif input.KeyCode == SETTINGS.RANGE_INCREASE_KEY and toggled then
		MAX_DISTANCE = MAX_DISTANCE + 10
		print("📏 Range Increased: " .. MAX_DISTANCE)
		updateStatsPanel()
	elseif input.KeyCode == SETTINGS.RANGE_DECREASE_KEY and toggled then
		MAX_DISTANCE = math.max(10, MAX_DISTANCE - 10)
		print("📏 Range Decreased: " .. MAX_DISTANCE)
		updateStatsPanel()
	end
end)

print("✅ PLU.V5 Loaded")
print("New: Custom Keybinds, Persistent UI, Glassy Theme")
