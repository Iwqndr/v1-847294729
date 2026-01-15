-- Wonders UPLS (Universal Premium Loading System)
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WondersUPLS"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, 420, 0, 140)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainContainer.BorderSizePixel = 0
mainContainer.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainContainer

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 70, 80)
stroke.Thickness = 1.5
stroke.Transparency = 0.5
stroke.Parent = mainContainer

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 0, 35)
titleLabel.Position = UDim2.new(0, 20, 0, 15)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Wonders UPLS"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainContainer

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -40, 0, 22)
statusLabel.Position = UDim2.new(0, 20, 0, 55)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Initializing System..."
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainContainer

local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, -40, 0, 6)
progressBg.Position = UDim2.new(0, 20, 0, 92)
progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
progressBg.BorderSizePixel = 0
progressBg.Parent = mainContainer

local progressBgCorner = Instance.new("UICorner")
progressBgCorner.CornerRadius = UDim.new(1, 0)
progressBgCorner.Parent = progressBg

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(88, 166, 255)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(1, 0)
progressBarCorner.Parent = progressBar

local percentLabel = Instance.new("TextLabel")
percentLabel.Size = UDim2.new(1, -40, 0, 18)
percentLabel.Position = UDim2.new(0, 20, 0, 108)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "0%"
percentLabel.Font = Enum.Font.GothamMedium
percentLabel.TextSize = 12
percentLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
percentLabel.TextXAlignment = Enum.TextXAlignment.Right
percentLabel.Parent = mainContainer

local function updateProgress(progress, status)
    statusLabel.Text = status
    percentLabel.Text = math.floor(progress * 100) .. "%"
    TweenService:Create(progressBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(progress, 0, 1, 0)
    }):Play()
end

local function closeLoader()
    TweenService:Create(mainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, -0.5, 0)
    }):Play()
    task.wait(0.4)
    screenGui:Destroy()
end

-- URLs
local baseUrl = "https://raw.githubusercontent.com/Iwqndr/v1-847294729/main/"
local mainUrl = baseUrl .. "PLU.Lua?t=" .. tick()
local saveUrl = baseUrl .. "SaveManager.lua?t=" .. tick()

print("-------------------------------------------")
updateProgress(0.1, "Initializing System...")
task.wait(0.3)

-- Step 1: Load Save Manager
updateProgress(0.2, "Preparing File System...")
local saveSuccess = pcall(function()
    loadstring(game:HttpGet(saveUrl))()
end)
task.wait(0.3)

-- Step 2: Connect to Main Script
updateProgress(0.4, "Connecting to server...")
local success, code = pcall(function()
    return game:HttpGet(mainUrl)
end)

if success then
    updateProgress(0.6, "Verifying integrity...")
    task.wait(0.2)
    
    local currentHash = #code + (string.byte(string.sub(code, 1, 1)) or 0) + (string.byte(string.sub(code, -1)) or 0)
    
    if _G.LastScriptHash ~= nil and _G.LastScriptHash ~= currentHash then
        updateProgress(0.8, "Update Detected! Patching...")
        task.wait(0.5)
    elseif _G.LastScriptHash == nil then
        updateProgress(0.8, "First time load initialized...")
        task.wait(0.3)
    else
        updateProgress(0.8, "No updates found, Your all good!")
        task.wait(0.3)
    end
    
    _G.LastScriptHash = currentHash
    
    updateProgress(0.9, "Loading PLU.Lua...")
    task.wait(0.3)
    
    updateProgress(1, "Complete!")
    task.wait(0.3)
    
    local loadSuccess, loadError = pcall(function()
        loadstring(code)()
    end)
    
    if not loadSuccess then
        warn("Error loading script: " .. tostring(loadError))
    end
    
    task.wait(0.5)
    closeLoader()
else
    updateProgress(0.4, "CRITICAL ERROR: Connection failed.")
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    task.wait(3)
    closeLoader()
end
