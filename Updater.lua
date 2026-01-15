-- Wonders UPLS (Universal Premium Loading System)
-- Modern Loading Screen with Smooth Animations

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WondersUPLS"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main Frame (Background)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.Position = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Gradient Background Effect
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
}
gradient.Rotation = 45
gradient.Parent = mainFrame

-- Animated Background Particles
for i = 1, 15 do
    local particle = Instance.new("Frame")
    particle.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
    particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
    particle.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    particle.BackgroundTransparency = 0.7
    particle.BorderSizePixel = 0
    particle.Parent = mainFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = particle
    
    -- Animate particles
    task.spawn(function()
        while particle.Parent do
            local randomX = math.random()
            local randomY = math.random()
            local tween = TweenService:Create(particle, TweenInfo.new(math.random(5, 10), Enum.EasingStyle.Linear), {
                Position = UDim2.new(randomX, 0, randomY, 0)
            })
            tween:Play()
            tween.Completed:Wait()
        end
    end)
end

-- Content Container
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(0, 450, 0, 300)
contentFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
contentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
contentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
contentFrame.BorderSizePixel = 0
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 16)
contentCorner.Parent = contentFrame

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -40, 0, 60)
titleLabel.Position = UDim2.new(0, 20, 0, 20)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Wonders UPLS"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 36
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextTransparency = 1
titleLabel.Parent = contentFrame

-- Subtitle Label
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "SubtitleLabel"
subtitleLabel.Size = UDim2.new(1, -40, 0, 25)
subtitleLabel.Position = UDim2.new(0, 20, 0, 75)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Universal Premium Loading System"
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextSize = 14
subtitleLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.TextTransparency = 1
subtitleLabel.Parent = contentFrame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -40, 0, 30)
statusLabel.Position = UDim2.new(0, 20, 0, 130)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Initializing System..."
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 16
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextTransparency = 1
statusLabel.Parent = contentFrame

-- Progress Bar Container
local progressContainer = Instance.new("Frame")
progressContainer.Name = "ProgressContainer"
progressContainer.Size = UDim2.new(1, -40, 0, 6)
progressContainer.Position = UDim2.new(0, 20, 0, 180)
progressContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
progressContainer.BorderSizePixel = 0
progressContainer.BackgroundTransparency = 1
progressContainer.Parent = contentFrame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0)
progressCorner.Parent = progressContainer

-- Progress Bar
local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressContainer

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(1, 0)
progressBarCorner.Parent = progressBar

-- Progress Bar Gradient
local progressGradient = Instance.new("UIGradient")
progressGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 180, 255))
}
progressGradient.Parent = progressBar

-- Detail Label
local detailLabel = Instance.new("TextLabel")
detailLabel.Name = "DetailLabel"
detailLabel.Size = UDim2.new(1, -40, 0, 20)
detailLabel.Position = UDim2.new(0, 20, 0, 200)
detailLabel.BackgroundTransparency = 1
detailLabel.Text = ""
detailLabel.Font = Enum.Font.GothamMedium
detailLabel.TextSize = 12
detailLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
detailLabel.TextXAlignment = Enum.TextXAlignment.Left
detailLabel.TextTransparency = 1
detailLabel.Parent = contentFrame

-- Animation Functions
local function fadeIn(object, duration)
    local tween = TweenService:Create(object, TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
        TextTransparency = 0
    })
    tween:Play()
    return tween
end

local function updateProgress(progress, status, detail)
    statusLabel.Text = status or statusLabel.Text
    if detail then
        detailLabel.Text = detail
    end
    
    local tween = TweenService:Create(progressBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(progress, 0, 1, 0)
    })
    tween:Play()
end

local function closeLoader()
    local tween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    })
    tween:Play()
    
    TweenService:Create(contentFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 1.5, 0)
    }):Play()
    
    tween.Completed:Wait()
    screenGui:Destroy()
end

-- Initial Animations
contentFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
TweenService:Create(contentFrame, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundTransparency = 0.1
}):Play()

task.wait(0.3)
fadeIn(titleLabel, 0.6)
task.wait(0.2)
fadeIn(subtitleLabel, 0.6)
task.wait(0.2)
fadeIn(statusLabel, 0.6)
fadeIn(progressContainer, 0.6)
fadeIn(detailLabel, 0.6)

-- Main Script Logic
task.wait(0.5)

local mainUrl = "https://raw.githubusercontent.com/Iwqndr/v1-847294729/main/PLU.Lua?t=" .. tick()

updateProgress(0.1, "Connecting to server...", "Establishing secure connection")
print("-------------------------------------------")
print("Initializing System...")

task.wait(0.5)
updateProgress(0.25, "Downloading script...", "Fetching latest version")

local success, code = pcall(function()
    return game:HttpGet(mainUrl)
end)

if success then
    updateProgress(0.5, "Verifying integrity...", "Checking for updates")
    task.wait(0.3)
    
    local currentHash = #code + (string.byte(string.sub(code, 1, 1)) or 0) + (string.byte(string.sub(code, -1)) or 0)
    
    if _G.LastScriptHash ~= nil and _G.LastScriptHash ~= currentHash then
        print("Update Detected!")
        updateProgress(0.65, "Update detected!", "Installing new patches...")
        print("Installing new patches...")
        task.wait(0.5)
    elseif _G.LastScriptHash == nil then
        print("First time load initialized.")
        updateProgress(0.65, "First time initialization", "Setting up environment")
        task.wait(0.3)
    else
        print("No updates found, You're all good!")
        updateProgress(0.65, "No updates needed", "System is up to date")
        task.wait(0.3)
    end
    
    _G.LastScriptHash = currentHash
    
    updateProgress(0.85, "Loading PLU.Lua...", "Executing main script")
    print("Loading PLU.Lua...")
    print("-------------------------------------------")
    task.wait(0.5)
    
    updateProgress(1, "Complete!", "Successfully loaded")
    task.wait(0.5)
    
    loadstring(code)()
    
    task.wait(0.5)
    closeLoader()
else
    updateProgress(0.3, "Connection failed!", "Please check your internet")
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    warn("CRITICAL ERROR: Connection failed.")
    task.wait(3)
    closeLoader()
end
