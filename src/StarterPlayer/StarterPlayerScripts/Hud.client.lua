local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hud = Instance.new("ScreenGui")
hud.Name = "CrystalHud"
hud.ResetOnSpawn = false
hud.IgnoreGuiInset = true
hud.Parent = player:WaitForChild("PlayerGui")

local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(1, -40, 0, 140)
container.Position = UDim2.fromOffset(20, 20)
container.BackgroundTransparency = 1
container.Parent = hud

local stateLabel = Instance.new("TextLabel")
stateLabel.Name = "StateLabel"
stateLabel.Size = UDim2.new(0.5, -10, 0, 36)
stateLabel.Position = UDim2.new(0, 0, 0, 0)
stateLabel.BackgroundTransparency = 0.2
stateLabel.BackgroundColor3 = Color3.fromRGB(26, 36, 58)
stateLabel.TextColor3 = Color3.fromRGB(220, 240, 255)
stateLabel.Font = Enum.Font.GothamBold
stateLabel.TextScaled = true
stateLabel.Text = "Awaiting round"
stateLabel.Parent = container

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(0.5, -10, 0, 36)
timerLabel.Position = UDim2.new(0.5, 10, 0, 0)
timerLabel.BackgroundTransparency = 0.2
timerLabel.BackgroundColor3 = Color3.fromRGB(26, 36, 58)
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextScaled = true
timerLabel.Text = "02:00"
timerLabel.Parent = container

local announcement = Instance.new("TextLabel")
announcement.Name = "Announcement"
announcement.AnchorPoint = Vector2.new(0.5, 0)
announcement.Position = UDim2.new(0.5, 0, 0, 50)
announcement.Size = UDim2.new(0.6, 0, 0, 40)
announcement.BackgroundTransparency = 0.4
announcement.BackgroundColor3 = Color3.fromRGB(14, 25, 42)
announcement.TextColor3 = Color3.fromRGB(255, 223, 150)
announcement.Font = Enum.Font.GothamSemibold
announcement.TextScaled = true
announcement.Text = "Welcome to the Crystal Cavern"
announcement.Parent = container

local scoreList = Instance.new("Frame")
scoreList.Name = "ScoreList"
scoreList.Position = UDim2.new(0, 0, 0, 80)
scoreList.Size = UDim2.new(1, 0, 0, 60)
scoreList.BackgroundTransparency = 0.4
scoreList.BackgroundColor3 = Color3.fromRGB(18, 28, 44)
scoreList.Parent = container

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scoreList

local function formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

local function showAnnouncement(text)
    announcement.Text = text
    announcement.TextTransparency = 1
    announcement.BackgroundTransparency = 1

    local tweenIn = TweenService:Create(announcement, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0,
        BackgroundTransparency = 0.2,
    })
    tweenIn:Play()
    task.delay(4, function()
        local tweenOut = TweenService:Create(announcement, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1,
            BackgroundTransparency = 1,
        })
        tweenOut:Play()
    end)
end

local function rebuildScoreboard(entries)
    for _, child in ipairs(scoreList:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    for index, entry in ipairs(entries) do
        local label = Instance.new("TextLabel")
        label.Name = "Entry" .. index
        label.Size = UDim2.new(0, 140, 0, 40)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(190, 215, 255)
        label.Font = Enum.Font.GothamSemibold
        label.TextScaled = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = string.format("%s  %d", entry.name, entry.score)
        label.Parent = scoreList
    end
end

remotes.Announcement.OnClientEvent:Connect(showAnnouncement)

remotes.TimerUpdate.OnClientEvent:Connect(function(remaining)
    timerLabel.Text = formatTime(remaining)
end)

remotes.RoundState.OnClientEvent:Connect(function(state)
    local message = {
        Lobby = "Next delve in progress...",
        Round = "Collect the crystals!",
        PostRound = "Round complete",
    }
    stateLabel.Text = message[state] or state
end)

remotes.ScoreUpdate.OnClientEvent:Connect(function(entries)
    rebuildScoreboard(entries)
end)

remotes.CrystalPickup.OnClientEvent:Connect(function(amount)
    showAnnouncement("Collected crystal +" .. amount)
end)

