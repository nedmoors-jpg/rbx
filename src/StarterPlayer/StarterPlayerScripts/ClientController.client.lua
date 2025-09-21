local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local eventsFolder = remotesFolder:WaitForChild("Events")

local remotes = {
    StateUpdate = eventsFolder:WaitForChild("StateUpdate"),
    Notify = eventsFolder:WaitForChild("Notify"),
    ActionRequest = eventsFolder:WaitForChild("ActionRequest"),
    PurchaseRequest = eventsFolder:WaitForChild("PurchaseRequest"),
    Tutorial = eventsFolder:WaitForChild("Tutorial")
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrystalRushUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local fontMain = Enum.Font.Gotham
local fontBold = Enum.Font.GothamBold

local milestoneTargets = { 500, 2000, 7500, 22000, 64000, 185000, 520000, 1250000 }
local comboMaxCount = math.max(
    5,
    math.floor(
        ((Config.Combo and Config.Combo.MaxBonus) or 0.4)
            / math.max(((Config.Combo and Config.Combo.BonusPerStreak) or 0.04), 0.01)
    ) + 1
)

local function createShadow(frame)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageTransparency = 0.6
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.new(1, 12, 1, 12)
    shadow.Position = UDim2.new(0, -6, 0, -6)
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = frame.ZIndex - 1
    shadow.Parent = frame
end

local function applyCorner(frame, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = frame
    return corner
end

local function applyStroke(frame, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1.2
    stroke.Color = color or Color3.fromRGB(52, 82, 146)
    stroke.Transparency = 0.1
    stroke.Parent = frame
    return stroke
end

local function applyGradient(frame, color1, color2)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(color1, color2 or color1)
    gradient.Rotation = 90
    gradient.Parent = frame
    return gradient
end

local function updateGradient(frame, color1, color2)
    local gradient = frame:FindFirstChildOfClass("UIGradient")
    if gradient then
        gradient.Color = ColorSequence.new(color1, color2 or color1)
    end
    frame.BackgroundColor3 = color1
end

local function updateStroke(frame, color)
    local stroke = frame:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = color
    end
end

local function createLabel(parent, text, size, position, bold)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = bold and fontBold or fontMain
    label.TextColor3 = Color3.fromRGB(240, 244, 255)
    label.TextScaled = true
    label.Size = size
    label.Position = position
    label.Parent = parent
    return label
end

local hudPanel = Instance.new("Frame")
hudPanel.Name = "StatsPanel"
hudPanel.Size = UDim2.new(0, 340, 0, 240)
hudPanel.Position = UDim2.new(0, 24, 0, 24)
hudPanel.BackgroundColor3 = Color3.fromRGB(24, 32, 58)
hudPanel.BorderSizePixel = 0
hudPanel.ZIndex = 3
hudPanel.Parent = screenGui
applyCorner(hudPanel, 18)
applyStroke(hudPanel, Color3.fromRGB(58, 86, 144), 1.8)
applyGradient(hudPanel, Color3.fromRGB(32, 46, 82), Color3.fromRGB(18, 24, 42))

local hudPadding = Instance.new("UIPadding")
hudPadding.PaddingLeft = UDim.new(0, 18)
hudPadding.PaddingRight = UDim.new(0, 18)
hudPadding.PaddingTop = UDim.new(0, 16)
hudPadding.PaddingBottom = UDim.new(0, 14)
hudPadding.Parent = hudPanel

local hudLayout = Instance.new("UIListLayout")
hudLayout.Parent = hudPanel
hudLayout.FillDirection = Enum.FillDirection.Vertical
hudLayout.Padding = UDim.new(0, 10)
hudLayout.SortOrder = Enum.SortOrder.LayoutOrder

local energyHeader = Instance.new("Frame")
energyHeader.BackgroundTransparency = 1
energyHeader.Size = UDim2.new(1, 0, 0, 64)
energyHeader.LayoutOrder = 1
energyHeader.Parent = hudPanel

local energyIcon = Instance.new("ImageLabel")
energyIcon.BackgroundTransparency = 1
energyIcon.Image = "rbxassetid://6034509990"
energyIcon.ImageColor3 = Color3.fromRGB(255, 228, 125)
energyIcon.Size = UDim2.new(0, 40, 0, 40)
energyIcon.Position = UDim2.new(0, 0, 0, 10)
energyIcon.Parent = energyHeader

local energyLabel = createLabel(energyHeader, "0", UDim2.new(0, 180, 0, 40), UDim2.new(0, 48, 0, 4), true)
energyLabel.TextXAlignment = Enum.TextXAlignment.Left

local energyCaption = createLabel(energyHeader, "Energy", UDim2.new(0, 140, 0, 24), UDim2.new(0, 48, 0, 40), false)
energyCaption.TextXAlignment = Enum.TextXAlignment.Left
energyCaption.TextColor3 = Color3.fromRGB(198, 215, 255)

local vipStatusLabel = createLabel(energyHeader, "Adventurer", UDim2.new(0, 130, 0, 24), UDim2.new(1, -140, 0, 12), true)
vipStatusLabel.AnchorPoint = Vector2.new(0, 0)
vipStatusLabel.TextScaled = true
vipStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
vipStatusLabel.TextColor3 = Color3.fromRGB(255, 229, 115)

local inventoryContainer = Instance.new("Frame")
inventoryContainer.Size = UDim2.new(1, 0, 0, 46)
inventoryContainer.BackgroundColor3 = Color3.fromRGB(18, 26, 46)
inventoryContainer.BorderSizePixel = 0
inventoryContainer.LayoutOrder = 2
inventoryContainer.Parent = hudPanel
applyCorner(inventoryContainer, 12)
applyStroke(inventoryContainer, Color3.fromRGB(48, 72, 132), 1.4)

local inventoryFill = Instance.new("Frame")
inventoryFill.BackgroundColor3 = Color3.fromRGB(116, 206, 255)
inventoryFill.Size = UDim2.new(0, 0, 1, 0)
inventoryFill.BorderSizePixel = 0
inventoryFill.Parent = inventoryContainer
inventoryFill.Visible = false
applyCorner(inventoryFill, 12)
applyGradient(inventoryFill, Color3.fromRGB(104, 209, 240), Color3.fromRGB(80, 156, 255))

local inventoryLabel = createLabel(inventoryContainer, "Backpack 0 / 0", UDim2.new(1, -16, 1, -8), UDim2.new(0, 8, 0, 4), false)
inventoryLabel.TextXAlignment = Enum.TextXAlignment.Left

local comboContainer = Instance.new("Frame")
comboContainer.Size = UDim2.new(1, 0, 0, 42)
comboContainer.BackgroundColor3 = Color3.fromRGB(18, 28, 50)
comboContainer.BorderSizePixel = 0
comboContainer.LayoutOrder = 3
comboContainer.Parent = hudPanel
applyCorner(comboContainer, 12)
applyStroke(comboContainer, Color3.fromRGB(66, 98, 168), 1.2)

local comboFill = Instance.new("Frame")
comboFill.Size = UDim2.new(0, 0, 1, 0)
comboFill.BackgroundColor3 = Color3.fromRGB(180, 132, 255)
comboFill.BorderSizePixel = 0
comboFill.Parent = comboContainer
comboFill.Visible = false
applyCorner(comboFill, 12)
applyGradient(comboFill, Color3.fromRGB(210, 144, 255), Color3.fromRGB(128, 92, 255))

local comboLabel = createLabel(comboContainer, "Combo x1", UDim2.new(0.5, -10, 1, -8), UDim2.new(0, 10, 0, 4), true)
comboLabel.TextXAlignment = Enum.TextXAlignment.Left

local comboTimerLabel = createLabel(comboContainer, "Ready", UDim2.new(0.5, -10, 1, -8), UDim2.new(0.5, 10, 0, 4), false)
comboTimerLabel.TextXAlignment = Enum.TextXAlignment.Right
comboTimerLabel.TextColor3 = Color3.fromRGB(206, 214, 255)

local statRow = Instance.new("Frame")
statRow.BackgroundTransparency = 1
statRow.Size = UDim2.new(1, 0, 0, 36)
statRow.LayoutOrder = 4
statRow.Parent = hudPanel

local statLayout = Instance.new("UIListLayout")
statLayout.Parent = statRow
statLayout.FillDirection = Enum.FillDirection.Horizontal
statLayout.Padding = UDim.new(0, 8)
statLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function createStatPill(text)
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 104, 1, 0)
    pill.BackgroundColor3 = Color3.fromRGB(28, 36, 64)
    pill.BorderSizePixel = 0
    applyCorner(pill, 10)
    applyStroke(pill, Color3.fromRGB(58, 86, 144), 1)

    local label = createLabel(pill, text, UDim2.new(1, -12, 1, -8), UDim2.new(0, 6, 0, 4), false)
    label.TextXAlignment = Enum.TextXAlignment.Left
    return pill, label
end

local zonePill, zoneLabel = createStatPill("Zone 1")
zonePill.Parent = statRow

local rebirthPill, rebirthLabel = createStatPill("Rebirth 0")
rebirthPill.Parent = statRow

local multiplierPill, multiplierLabel = createStatPill("x1.00")
multiplierPill.Parent = statRow

local boostLabel = createLabel(hudPanel, "Boosts: None", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), false)
boostLabel.LayoutOrder = 5
boostLabel.TextXAlignment = Enum.TextXAlignment.Left
boostLabel.TextWrapped = true

local abilityDock = Instance.new("Frame")
abilityDock.Name = "AbilityDock"
abilityDock.Size = UDim2.new(0, 360, 0, 64)
abilityDock.Position = UDim2.new(0.5, -180, 1, -120)
abilityDock.BackgroundColor3 = Color3.fromRGB(22, 30, 54)
abilityDock.BorderSizePixel = 0
abilityDock.ZIndex = 3
abilityDock.Parent = screenGui
applyCorner(abilityDock, 18)
applyStroke(abilityDock, Color3.fromRGB(56, 86, 144), 1.8)
applyGradient(abilityDock, Color3.fromRGB(28, 42, 78), Color3.fromRGB(16, 20, 36))

local abilityLayout = Instance.new("UIListLayout")
abilityLayout.Parent = abilityDock
abilityLayout.FillDirection = Enum.FillDirection.Horizontal
abilityLayout.Padding = UDim.new(0, 12)
abilityLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
abilityLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local function createAbilityButton(name, text)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0.5, -12, 0, 48)
    button.BackgroundColor3 = Color3.fromRGB(64, 86, 150)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = fontBold
    button.TextScaled = true
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = abilityDock
    applyCorner(button, 14)
    applyStroke(button, Color3.fromRGB(82, 120, 192), 1)
    return button
end

local sprintToggleButton = createAbilityButton("SprintToggle", "Hyper Sprint")
local autoToggleButton = createAbilityButton("AutoToggle", "Auto Collector")

local upgradesPanel = Instance.new("Frame")
upgradesPanel.Name = "UpgradesPanel"
upgradesPanel.Size = UDim2.new(0, 340, 0, 320)
upgradesPanel.Position = UDim2.new(0, 24, 0, 284)
upgradesPanel.BackgroundColor3 = Color3.fromRGB(22, 30, 56)
upgradesPanel.BorderSizePixel = 0
upgradesPanel.ZIndex = 3
upgradesPanel.Parent = screenGui
applyCorner(upgradesPanel, 18)
applyStroke(upgradesPanel, Color3.fromRGB(56, 86, 144), 1.6)
applyGradient(upgradesPanel, Color3.fromRGB(28, 42, 78), Color3.fromRGB(16, 20, 36))

local upgradesPadding = Instance.new("UIPadding")
upgradesPadding.PaddingLeft = UDim.new(0, 18)
upgradesPadding.PaddingRight = UDim.new(0, 18)
upgradesPadding.PaddingTop = UDim.new(0, 22)
upgradesPadding.PaddingBottom = UDim.new(0, 18)
upgradesPadding.Parent = upgradesPanel

local upgradesLayout = Instance.new("UIListLayout")
upgradesLayout.Parent = upgradesPanel
upgradesLayout.Padding = UDim.new(0, 8)
upgradesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
upgradesLayout.VerticalAlignment = Enum.VerticalAlignment.Top
upgradesLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function createActionButton(parent, text, action)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 48)
    button.Text = text
    button.Font = fontBold
    button.TextScaled = true
    button.BackgroundColor3 = Color3.fromRGB(68, 108, 204)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Parent = parent
    button.LayoutOrder = #parent:GetChildren()
    applyCorner(button, 14)
    applyStroke(button, Color3.fromRGB(94, 140, 255), 1.2)
    applyGradient(button, Color3.fromRGB(92, 148, 255), Color3.fromRGB(60, 94, 198))
    button.TextWrapped = true

    button.MouseButton1Click:Connect(function()
        remotes.ActionRequest:FireServer(action)
    end)

    return button
end

local buttons = {
    Capacity = createActionButton(upgradesPanel, "Upgrade Backpack", "UpgradeCapacity"),
    Speed = createActionButton(upgradesPanel, "Upgrade Speed", "UpgradeSpeed"),
    Converter = createActionButton(upgradesPanel, "Upgrade Converter", "UpgradeConverter"),
    UnlockZone = createActionButton(upgradesPanel, "Unlock Next Zone", "UnlockZone"),
    Rebirth = createActionButton(upgradesPanel, "Rebirth", "Rebirth")
}

local shopToggle = Instance.new("TextButton")
shopToggle.Name = "ShopToggle"
shopToggle.Size = UDim2.new(0, 220, 0, 50)
shopToggle.Position = UDim2.new(1, -24, 0, 24)
shopToggle.AnchorPoint = Vector2.new(1, 0)
shopToggle.BackgroundColor3 = Color3.fromRGB(32, 44, 82)
shopToggle.Text = "Open Crystal Shop"
shopToggle.TextScaled = true
shopToggle.Font = fontBold
shopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopToggle.Parent = screenGui
applyCorner(shopToggle, 16)
applyStroke(shopToggle, Color3.fromRGB(86, 132, 228), 1.4)
applyGradient(shopToggle, Color3.fromRGB(72, 110, 210), Color3.fromRGB(44, 62, 120))

local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.new(0, 440, 0, 440)
shopFrame.Position = UDim2.new(1, -24, 0, 96)
shopFrame.AnchorPoint = Vector2.new(1, 0)
shopFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 38)
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.ZIndex = 5
shopFrame.Parent = screenGui
applyCorner(shopFrame, 18)
applyStroke(shopFrame, Color3.fromRGB(60, 92, 160), 1.6)
applyGradient(shopFrame, Color3.fromRGB(32, 46, 82), Color3.fromRGB(18, 22, 36))

local shopPadding = Instance.new("UIPadding")
shopPadding.PaddingLeft = UDim.new(0, 18)
shopPadding.PaddingRight = UDim.new(0, 18)
shopPadding.PaddingTop = UDim.new(0, 18)
shopPadding.PaddingBottom = UDim.new(0, 18)
shopPadding.Parent = shopFrame

local shopClose = Instance.new("TextButton")
shopClose.Size = UDim2.new(0, 28, 0, 28)
shopClose.Position = UDim2.new(1, -36, 0, 10)
shopClose.BackgroundTransparency = 1
shopClose.Text = "✕"
shopClose.Font = fontBold
shopClose.TextColor3 = Color3.fromRGB(255, 255, 255)
shopClose.Parent = shopFrame

local shopTitle = createLabel(shopFrame, "Crystal Shop", UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 10), true)
shopTitle.TextXAlignment = Enum.TextXAlignment.Left

local shopScroll = Instance.new("ScrollingFrame")
shopScroll.Size = UDim2.new(1, -20, 1, -60)
shopScroll.Position = UDim2.new(0, 10, 0, 50)
shopScroll.BackgroundTransparency = 1
shopScroll.BorderSizePixel = 0
shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
shopScroll.ScrollBarThickness = 6
shopScroll.Parent = shopFrame

local shopLayout = Instance.new("UIListLayout")
shopLayout.Parent = shopScroll
shopLayout.Padding = UDim.new(0, 10)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder

local eventBanner = Instance.new("Frame")
eventBanner.Name = "EventBanner"
eventBanner.Size = UDim2.new(0, 440, 0, 68)
eventBanner.Position = UDim2.new(0.5, -220, 0, 20)
eventBanner.AnchorPoint = Vector2.new(0.5, 0)
eventBanner.BackgroundColor3 = Color3.fromRGB(22, 30, 58)
eventBanner.Visible = false
eventBanner.ZIndex = 6
eventBanner.Parent = screenGui
applyCorner(eventBanner, 18)
applyStroke(eventBanner, Color3.fromRGB(86, 132, 228), 1.6)
applyGradient(eventBanner, Color3.fromRGB(44, 62, 120), Color3.fromRGB(28, 36, 70))

local eventPadding = Instance.new("UIPadding")
eventPadding.PaddingLeft = UDim.new(0, 18)
eventPadding.PaddingRight = UDim.new(0, 18)
eventPadding.PaddingTop = UDim.new(0, 12)
eventPadding.PaddingBottom = UDim.new(0, 12)
eventPadding.Parent = eventBanner

local eventNameLabel = createLabel(eventBanner, "", UDim2.new(0.6, 0, 0, 24), UDim2.new(0, 0, 0, 0), true)
eventNameLabel.TextXAlignment = Enum.TextXAlignment.Left

local eventZoneLabel = createLabel(eventBanner, "", UDim2.new(0.6, 0, 0, 20), UDim2.new(0, 0, 0, 28), false)
eventZoneLabel.TextXAlignment = Enum.TextXAlignment.Left
eventZoneLabel.TextColor3 = Color3.fromRGB(198, 215, 255)

local eventTimerLabel = createLabel(eventBanner, "", UDim2.new(0.4, 0, 0, 24), UDim2.new(1, -160, 0, 0), true)
eventTimerLabel.AnchorPoint = Vector2.new(0, 0)
eventTimerLabel.TextXAlignment = Enum.TextXAlignment.Right

local eventDescriptionLabel = createLabel(eventBanner, "", UDim2.new(0.4, 0, 0, 20), UDim2.new(1, -160, 0, 28), false)
eventDescriptionLabel.AnchorPoint = Vector2.new(0, 0)
eventDescriptionLabel.TextXAlignment = Enum.TextXAlignment.Right
eventDescriptionLabel.TextColor3 = Color3.fromRGB(206, 214, 255)

local eventProgress = Instance.new("Frame")
eventProgress.Size = UDim2.new(1, -20, 0, 6)
eventProgress.Position = UDim2.new(0, 10, 1, -14)
eventProgress.BackgroundColor3 = Color3.fromRGB(18, 24, 42)
eventProgress.BorderSizePixel = 0
eventProgress.Parent = eventBanner
applyCorner(eventProgress, 6)

local eventProgressFill = Instance.new("Frame")
eventProgressFill.Size = UDim2.new(0, 0, 1, 0)
eventProgressFill.BackgroundColor3 = Color3.fromRGB(120, 196, 255)
eventProgressFill.BorderSizePixel = 0
eventProgressFill.Parent = eventProgress
eventProgressFill.Visible = false
applyCorner(eventProgressFill, 6)

local zoneTrack = Instance.new("Frame")
zoneTrack.Name = "ZoneTrack"
zoneTrack.Size = UDim2.new(0, 340, 0, 60)
zoneTrack.Position = UDim2.new(0, 24, 1, -96)
zoneTrack.BackgroundColor3 = Color3.fromRGB(20, 28, 52)
zoneTrack.BorderSizePixel = 0
zoneTrack.ZIndex = 3
zoneTrack.Parent = screenGui
applyCorner(zoneTrack, 16)
applyStroke(zoneTrack, Color3.fromRGB(52, 82, 146), 1.2)

local zoneTrackPadding = Instance.new("UIPadding")
zoneTrackPadding.PaddingLeft = UDim.new(0, 16)
zoneTrackPadding.PaddingRight = UDim.new(0, 16)
zoneTrackPadding.PaddingTop = UDim.new(0, 12)
zoneTrackPadding.PaddingBottom = UDim.new(0, 12)
zoneTrackPadding.Parent = zoneTrack

local zoneTrackLayout = Instance.new("UIListLayout")
zoneTrackLayout.Parent = zoneTrack
zoneTrackLayout.FillDirection = Enum.FillDirection.Horizontal
zoneTrackLayout.Padding = UDim.new(0, 10)
zoneTrackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
zoneTrackLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local zoneNodes = {}
for index, zoneConfig in ipairs(Config.Zones) do
    local node = Instance.new("Frame")
    node.Name = "ZoneNode" .. index
    node.Size = UDim2.new(0, 30, 0, 30)
    node.BackgroundColor3 = Color3.fromRGB(46, 58, 92)
    node.BorderSizePixel = 0
    node.Parent = zoneTrack
    applyCorner(node, 15)
    applyStroke(node, zoneConfig.AccentColor or zoneConfig.OrbColor, 1)

    local nodeLabel = createLabel(node, tostring(index), UDim2.new(1, -4, 1, -4), UDim2.new(0, 2, 0, 2), true)
    nodeLabel.TextXAlignment = Enum.TextXAlignment.Center
    nodeLabel.TextYAlignment = Enum.TextYAlignment.Center

    zoneNodes[index] = { Frame = node, Label = nodeLabel }
end

local milestoneCard = Instance.new("Frame")
milestoneCard.Name = "MilestoneCard"
milestoneCard.Size = UDim2.new(0, 220, 0, 120)
milestoneCard.Position = UDim2.new(1, -24, 0, 96)
milestoneCard.AnchorPoint = Vector2.new(1, 0)
milestoneCard.BackgroundColor3 = Color3.fromRGB(24, 34, 60)
milestoneCard.BorderSizePixel = 0
milestoneCard.ZIndex = 4
milestoneCard.Parent = screenGui
applyCorner(milestoneCard, 16)
applyStroke(milestoneCard, Color3.fromRGB(70, 108, 200), 1.2)
applyGradient(milestoneCard, Color3.fromRGB(32, 46, 82), Color3.fromRGB(20, 28, 50))

local milestonePadding = Instance.new("UIPadding")
milestonePadding.PaddingLeft = UDim.new(0, 14)
milestonePadding.PaddingRight = UDim.new(0, 14)
milestonePadding.PaddingTop = UDim.new(0, 14)
milestonePadding.PaddingBottom = UDim.new(0, 14)
milestonePadding.Parent = milestoneCard

local milestoneTitle = createLabel(milestoneCard, "Next Goal", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), true)
milestoneTitle.TextXAlignment = Enum.TextXAlignment.Left

local milestoneValueLabel = createLabel(milestoneCard, "", UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 30), true)
milestoneValueLabel.TextXAlignment = Enum.TextXAlignment.Left
milestoneValueLabel.TextColor3 = Color3.fromRGB(120, 196, 255)

local milestoneHintLabel = createLabel(milestoneCard, "", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 66), false)
milestoneHintLabel.TextXAlignment = Enum.TextXAlignment.Left
milestoneHintLabel.TextColor3 = Color3.fromRGB(206, 214, 255)

local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "Notification"
notificationFrame.Size = UDim2.new(0, 420, 0, 36)
notificationFrame.Position = UDim2.new(0.5, -210, 0, 24)
notificationFrame.BackgroundColor3 = Color3.fromRGB(47, 60, 102)
notificationFrame.BackgroundTransparency = 0.2
notificationFrame.Visible = false
notificationFrame.ZIndex = 10
notificationFrame.Parent = screenGui
createShadow(notificationFrame)

local notificationLabel = createLabel(notificationFrame, "", UDim2.new(1, -20, 1, 0), UDim2.new(0, 10, 0, 0), true)
notificationLabel.TextXAlignment = Enum.TextXAlignment.Left

local tutorialFrame = Instance.new("Frame")
tutorialFrame.Name = "TutorialFrame"
tutorialFrame.Size = UDim2.new(0, 500, 0, 60)
tutorialFrame.Position = UDim2.new(0.5, -250, 1, -140)
tutorialFrame.BackgroundColor3 = Color3.fromRGB(38, 46, 80)
tutorialFrame.Visible = false
tutorialFrame.ZIndex = 8
tutorialFrame.Parent = screenGui
createShadow(tutorialFrame)

local tutorialLabel = createLabel(tutorialFrame, "", UDim2.new(1, -20, 1, -10), UDim2.new(0, 10, 0, 5), false)
tutorialLabel.TextWrapped = true

tutorialLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

local currentState
local serverTimeOffset = 0
local comboExpireTime = 0
local activeEvent

local function formatNumber(num)
    if num >= 1e6 then
        return string.format("%.1fm", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fk", num / 1e3)
    else
        return tostring(num)
    end
end

local function setButtonState(button, enabled, text)
    button.Text = text
    if enabled then
        updateGradient(button, Color3.fromRGB(92, 148, 255), Color3.fromRGB(60, 94, 198))
        updateStroke(button, Color3.fromRGB(94, 140, 255))
        button.AutoButtonColor = true
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        updateGradient(button, Color3.fromRGB(42, 48, 68), Color3.fromRGB(30, 34, 50))
        updateStroke(button, Color3.fromRGB(64, 76, 108))
        button.AutoButtonColor = false
        button.TextColor3 = Color3.fromRGB(182, 194, 220)
    end
end

local function updateInventoryBarUI(inventoryValue, capacityValue, capacityDisplay)
    local ratio = 0
    if capacityValue and capacityValue ~= math.huge and capacityValue > 0 then
        ratio = math.clamp(inventoryValue / capacityValue, 0, 1)
    end

    inventoryFill.Size = UDim2.new(ratio, 0, 1, 0)
    inventoryFill.Visible = ratio > 0

    local capacityText = capacityDisplay
    if capacityText == "Infinite" or capacityValue == math.huge then
        capacityText = "∞"
    elseif not capacityText then
        capacityText = formatNumber(capacityValue or 0)
    end

    inventoryLabel.Text = string.format("Backpack %s / %s", formatNumber(inventoryValue), capacityText)
end

local function updateZoneTrackUI(zoneLevel)
    for index, node in ipairs(zoneNodes) do
        local unlocked = zoneLevel and index <= zoneLevel
        local frame = node.Frame
        local label = node.Label
        if unlocked then
            frame.BackgroundColor3 = Color3.fromRGB(104, 148, 255)
            updateStroke(frame, (Config.Zones[index].AccentColor or Config.Zones[index].OrbColor))
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            frame.BackgroundColor3 = Color3.fromRGB(46, 58, 92)
            updateStroke(frame, Color3.fromRGB(64, 76, 108))
            label.TextColor3 = Color3.fromRGB(182, 194, 220)
        end
    end
end

local function updateMilestoneCardUI(totalEnergy)
    local nextTarget
    for _, target in ipairs(milestoneTargets) do
        if totalEnergy < target then
            nextTarget = target
            break
        end
    end

    if nextTarget then
        local remaining = math.max(0, nextTarget - totalEnergy)
        milestoneValueLabel.Text = string.format("%s Energy", formatNumber(nextTarget))
        milestoneHintLabel.Text = string.format("Earn %s more to reach it.", formatNumber(remaining))
    else
        milestoneValueLabel.Text = "Legendary Harvester"
        milestoneHintLabel.Text = "Rebirth for even higher rewards."
    end
end

local function updateComboTimerDisplay(combo)
    if not combo or (combo.Count or 0) <= 1 or comboExpireTime <= 0 then
        comboTimerLabel.Text = "Ready"
        return
    end

    local now = workspace:GetServerTimeNow() + serverTimeOffset
    local remaining = math.max(0, comboExpireTime - now)
    local bonusPercent = math.floor(((combo.Multiplier or 1) - 1) * 100)
    if remaining <= 0 then
        comboExpireTime = 0
        comboTimerLabel.Text = "Ready"
        comboFill.Visible = false
        return
    end
    comboTimerLabel.Text = string.format("+%d%% bonus • %.1fs", bonusPercent, remaining)
end

local function updateComboUI(combo)
    local count = combo and combo.Count or 0
    comboLabel.Text = string.format("Combo x%d", math.max(1, count))
    local ratio = math.clamp(count / comboMaxCount, 0, 1)
    comboFill.Size = UDim2.new(ratio, 0, 1, 0)
    if combo and combo.Remaining and count > 1 then
        comboExpireTime = workspace:GetServerTimeNow() + serverTimeOffset + math.max(0, combo.Remaining)
    else
        comboExpireTime = 0
    end

    comboFill.Visible = ratio > 0 and comboExpireTime > 0
    updateComboTimerDisplay(combo)
end

local function updateEventTimerDisplay()
    if not activeEvent then
        return
    end

    local now = workspace:GetServerTimeNow() + serverTimeOffset
    local totalDuration = math.max(1, (activeEvent.EndsAt or now) - (activeEvent.StartedAt or now))
    local remaining = math.max(0, (activeEvent.EndsAt or now) - now)
    eventTimerLabel.Text = string.format("%.0fs remaining", remaining)
    local progress = math.clamp(1 - (remaining / totalDuration), 0, 1)
    eventProgressFill.Size = UDim2.new(progress, 0, 1, 0)

    if remaining <= 0 then
        activeEvent = nil
        eventBanner.Visible = false
        eventProgressFill.Visible = false
    end
end

local function updateEventUI()
    local summary = currentState and currentState.ActiveEvent or nil
    if not summary then
        activeEvent = nil
        eventBanner.Visible = false
        eventProgressFill.Visible = false
        return
    end

    local now = workspace:GetServerTimeNow() + serverTimeOffset
    if summary.EndsAt and summary.EndsAt <= now then
        activeEvent = nil
        eventBanner.Visible = false
        eventProgressFill.Visible = false
        return
    end

    activeEvent = summary
    eventBanner.Visible = true

    local color = summary.Color or Color3.fromRGB(120, 196, 255)
    updateStroke(eventBanner, color)
    updateGradient(
        eventBanner,
        color:Lerp(Color3.fromRGB(255, 255, 255), 0.15),
        color:Lerp(Color3.fromRGB(16, 22, 40), 0.55)
    )
    updateGradient(eventProgressFill, color, color)
    eventProgressFill.Visible = true

    eventNameLabel.Text = summary.Name or "Crystal Event"
    eventZoneLabel.Text = string.format("Zone: %s", summary.ZoneName or ("#" .. tostring(summary.ZoneIndex or "?")))
    eventDescriptionLabel.Text = summary.Description or "Bonus crystals active."

    updateEventTimerDisplay()
end

local function updateAbilityButtons()
    local passes = currentState and currentState.Gamepasses or {}
    local settings = currentState and currentState.Settings or {}

    local isVip = passes and passes.VIP
    if isVip then
        vipStatusLabel.Text = "Crystal VIP"
        vipStatusLabel.TextColor3 = Color3.fromRGB(255, 229, 115)
    else
        vipStatusLabel.Text = "Adventurer"
        vipStatusLabel.TextColor3 = Color3.fromRGB(194, 206, 255)
    end

    local hasSprint = passes and passes.HYPER_SPRINT
    local sprintEnabled = settings and settings.HyperSprint == true
    if hasSprint then
        if sprintEnabled then
            sprintToggleButton.Text = "Hyper Sprint\n[ON]"
            updateGradient(sprintToggleButton, Color3.fromRGB(96, 210, 168), Color3.fromRGB(60, 150, 118))
            updateStroke(sprintToggleButton, Color3.fromRGB(132, 236, 196))
            sprintToggleButton.TextColor3 = Color3.fromRGB(24, 36, 36)
        else
            sprintToggleButton.Text = "Hyper Sprint\n[OFF]"
            updateGradient(sprintToggleButton, Color3.fromRGB(64, 86, 150), Color3.fromRGB(48, 60, 112))
            updateStroke(sprintToggleButton, Color3.fromRGB(82, 120, 192))
            sprintToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        sprintToggleButton.AutoButtonColor = true
    else
        sprintToggleButton.Text = "Hyper Sprint\nUnlock"
        updateGradient(sprintToggleButton, Color3.fromRGB(38, 42, 62), Color3.fromRGB(24, 26, 40))
        updateStroke(sprintToggleButton, Color3.fromRGB(60, 68, 96))
        sprintToggleButton.TextColor3 = Color3.fromRGB(182, 194, 220)
        sprintToggleButton.AutoButtonColor = true
    end

    local hasAuto = passes and passes.AUTO_COLLECTOR
    local autoEnabled = settings and settings.AutoCollector
    if autoEnabled == nil then
        autoEnabled = true
    end
    if hasAuto then
        if autoEnabled then
            autoToggleButton.Text = "Auto Collector\n[ON]"
            updateGradient(autoToggleButton, Color3.fromRGB(120, 206, 255), Color3.fromRGB(80, 148, 220))
            updateStroke(autoToggleButton, Color3.fromRGB(144, 224, 255))
            autoToggleButton.TextColor3 = Color3.fromRGB(24, 36, 44)
        else
            autoToggleButton.Text = "Auto Collector\n[OFF]"
            updateGradient(autoToggleButton, Color3.fromRGB(64, 86, 150), Color3.fromRGB(48, 60, 112))
            updateStroke(autoToggleButton, Color3.fromRGB(82, 120, 192))
            autoToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        autoToggleButton.AutoButtonColor = true
    else
        autoToggleButton.Text = "Auto Collector\nUnlock"
        updateGradient(autoToggleButton, Color3.fromRGB(38, 42, 62), Color3.fromRGB(24, 26, 40))
        updateStroke(autoToggleButton, Color3.fromRGB(60, 68, 96))
        autoToggleButton.TextColor3 = Color3.fromRGB(182, 194, 220)
        autoToggleButton.AutoButtonColor = true
    end
end

local function rebuildShop()
    shopScroll:ClearAllChildren()
    shopLayout.Parent = shopScroll

    local entryIndex = 0

    local function createEntry(title, subtitle, priceText, purchaseData, owned, customClick, customColor)
        entryIndex += 1
        local entry = Instance.new("Frame")
        entry.Size = UDim2.new(1, -4, 0, 90)
        entry.BackgroundColor3 = Color3.fromRGB(33, 40, 65)
        entry.BorderSizePixel = 0
        entry.LayoutOrder = entryIndex
        entry.Parent = shopScroll
        entry.ZIndex = 6

        local entryTitle = createLabel(entry, title, UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0, 8), true)
        entryTitle.TextXAlignment = Enum.TextXAlignment.Left
        entryTitle.ZIndex = 7

        local entrySubtitle = createLabel(entry, subtitle, UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 38), false)
        entrySubtitle.TextXAlignment = Enum.TextXAlignment.Left
        entrySubtitle.TextColor3 = Color3.fromRGB(194, 206, 255)
        entrySubtitle.ZIndex = 7

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 160, 0, 32)
        button.Position = UDim2.new(1, -170, 1, -42)
        button.AnchorPoint = Vector2.new(0, 0)
        button.BackgroundColor3 = customColor or Color3.fromRGB(76, 151, 255)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = fontBold
        button.TextScaled = true
        button.Text = priceText
        button.Parent = entry
        button.ZIndex = 7

        if owned then
            button.Text = "Owned"
            button.AutoButtonColor = false
            button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        elseif customClick then
            button.MouseButton1Click:Connect(customClick)
        elseif purchaseData then
            button.MouseButton1Click:Connect(function()
                remotes.PurchaseRequest:FireServer(purchaseData)
            end)
        else
            button.Text = "Coming Soon"
            button.AutoButtonColor = false
            button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end
    end

    local passOrder = {"VIP", "HYPER_SPRINT", "INFINITE_STORAGE", "LUCKY_AURA", "AUTO_COLLECTOR"}
    for _, key in ipairs(passOrder) do
        local info = Config.Gamepasses[key]
        if info then
            local owned = currentState and currentState.Gamepasses and currentState.Gamepasses[key]
            local priceText = owned and "Owned" or string.format("R$ %d", info.Price)
            local subtitle = info.Benefit
            local purchaseData = info.Id ~= 0 and { Type = "Gamepass", Key = key } or nil
            if info.Id == 0 then
                priceText = string.format("Set ID • R$ %d", info.Price)
            end
            createEntry(info.Name, subtitle, priceText, purchaseData, owned)
        end
    end

    for _, product in ipairs(Config.DeveloperProducts.EnergyPacks) do
        local priceText = string.format("R$ %d", product.Price)
        local subtitle = string.format("+%s Energy", formatNumber(product.Amount))
        local purchaseData = product.Id ~= 0 and { Type = "Product", Key = product.Key } or nil
        if product.Id == 0 then
            priceText = string.format("Set ID • R$ %d", product.Price)
        end
        createEntry(product.Name, subtitle, priceText, purchaseData, false)
    end

    for _, boost in ipairs(Config.DeveloperProducts.Boosts) do
        local priceText = string.format("R$ %d", boost.Price)
        local subtitle = string.format("%d min %dx Converter", math.floor(boost.Duration / 60), boost.Multiplier)
        local purchaseData = boost.Id ~= 0 and { Type = "Product", Key = boost.Key } or nil
        if boost.Id == 0 then
            priceText = string.format("Set ID • R$ %d", boost.Price)
        end
        createEntry(boost.Name, subtitle, priceText, purchaseData, false)
    end

    local hasVip = currentState and currentState.Gamepasses and currentState.Gamepasses.VIP
    if hasVip then
        for _, item in ipairs(Config.VIPShop) do
            local priceText = string.format("%s Energy", formatNumber(item.Cost))
            local subtitle = string.format("%s", item.Description)
            createEntry(
                item.Name,
                subtitle,
                priceText,
                nil,
                false,
                function()
                    remotes.ActionRequest:FireServer("PurchaseVIPItem", { Key = item.Key })
                end,
                Color3.fromRGB(104, 209, 140)
            )
        end
    else
        local vipInfo = Config.Gamepasses.VIP
        local subtitle = "Unlock Crystal VIP to access exclusive boosts"
        local priceText
        local purchaseData
        if vipInfo then
            priceText = string.format("Unlock VIP • R$ %d", vipInfo.Price)
            if vipInfo.Id ~= 0 then
                purchaseData = { Type = "Gamepass", Key = "VIP" }
            end
        else
            priceText = "Unlock VIP"
        end

        createEntry("VIP Crystal Boutique", subtitle, priceText, purchaseData, false)
    end

    shopScroll.CanvasSize = UDim2.new(0, 0, 0, shopLayout.AbsoluteContentSize.Y)
end

local function updateUI()
    if not currentState then
        return
    end

    local serverNow = workspace:GetServerTimeNow()
    if currentState.ServerTime then
        serverTimeOffset = currentState.ServerTime - serverNow
    end

    local energyValue = currentState.Energy or 0
    local inventoryValue = currentState.Inventory or 0
    local multiplierValue = currentState.ConverterMultiplier or 1
    local zoneValue = currentState.ZoneLevel or 1
    local rebirthValue = currentState.Rebirths or 0

    energyLabel.Text = formatNumber(energyValue)
    local capacityValue = currentState.Capacity
    local capacityText = currentState.CapacityDisplay or tostring(capacityValue or 0)
    updateInventoryBarUI(inventoryValue, capacityValue, capacityText)
    multiplierLabel.Text = string.format("x%.2f Converter", multiplierValue)
    zoneLabel.Text = string.format("Zone %d / %d", zoneValue, #Config.Zones)
    if rebirthValue == 1 then
        rebirthLabel.Text = "1 Rebirth"
    else
        rebirthLabel.Text = string.format("%d Rebirths", rebirthValue)
    end

    if currentState.ActiveBoosts then
        local boostStrings = {}
        for key, data in pairs(currentState.ActiveBoosts) do
            local remaining = data.ExpiresIn and math.max(0, math.floor(data.ExpiresIn)) or nil
            local text = string.format("%s %dx", key, data.Multiplier or 1)
            if remaining then
                text ..= string.format(" (%ds)", remaining)
            end
            table.insert(boostStrings, text)
        end
        if #boostStrings > 0 then
            boostLabel.Text = "Boosts: " .. table.concat(boostStrings, ", ")
        else
            boostLabel.Text = "Boosts: None"
        end
    else
        boostLabel.Text = "Boosts: None"
    end

    if currentState.CapacityNextCost then
        setButtonState(buttons.Capacity, true, string.format("Upgrade Backpack\nCost: %s", formatNumber(currentState.CapacityNextCost)))
    else
        setButtonState(buttons.Capacity, false, "Backpack Maxed")
    end

    if currentState.SpeedNextCost then
        setButtonState(buttons.Speed, true, string.format("Upgrade Speed\nCost: %s", formatNumber(currentState.SpeedNextCost)))
    else
        setButtonState(buttons.Speed, false, "Speed Maxed")
    end

    if currentState.ConverterNextCost then
        setButtonState(buttons.Converter, true, string.format("Upgrade Converter\nCost: %s", formatNumber(currentState.ConverterNextCost)))
    else
        setButtonState(buttons.Converter, false, "Converter Maxed")
    end

    if currentState.NextZoneCost then
        setButtonState(buttons.UnlockZone, true, string.format("Unlock Next Zone\nCost: %s", formatNumber(currentState.NextZoneCost)))
    else
        setButtonState(buttons.UnlockZone, false, "All Zones Unlocked")
    end

    local maxZones = #Config.Zones
    if zoneValue >= maxZones then
        setButtonState(buttons.Rebirth, true, string.format("Rebirth\nCost: %s", formatNumber(currentState.RebirthCost or 0)))
    else
        setButtonState(buttons.Rebirth, false, "Unlock all zones first")
    end

    updateAbilityButtons()
    updateZoneTrackUI(zoneValue)
    updateMilestoneCardUI(currentState.TotalEnergy or energyValue)
    updateComboUI(currentState.Combo)
    updateEventUI()
    rebuildShop()
end

RunService.RenderStepped:Connect(function()
    if activeEvent then
        updateEventTimerDisplay()
    end

    if currentState and currentState.Combo then
        updateComboTimerDisplay(currentState.Combo)
    end
end)

local notificationTween
local function showNotification(text, color)
    notificationLabel.Text = text
    notificationFrame.BackgroundColor3 = color or Color3.fromRGB(47, 60, 102)
    notificationFrame.Visible = true
    notificationFrame.BackgroundTransparency = 0.2

    if notificationTween then
        notificationTween:Cancel()
    end

    notificationTween = TweenService:Create(notificationFrame, TweenInfo.new(0.5), { BackgroundTransparency = 0.2 })
    notificationTween:Play()

    task.delay(3, function()
        if notificationFrame.Visible then
            local fade = TweenService:Create(notificationFrame, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
            fade.Completed:Connect(function()
                notificationFrame.Visible = false
                notificationFrame.BackgroundTransparency = 0.2
            end)
            fade:Play()
        end
    end)
end

local function showTutorial(text)
    tutorialLabel.Text = text
    tutorialFrame.Visible = true
    tutorialFrame.BackgroundTransparency = 0.05

    local fadeIn = TweenService:Create(tutorialFrame, TweenInfo.new(0.3), { BackgroundTransparency = 0.05 })
    fadeIn:Play()

    task.delay(6, function()
        local fadeOut = TweenService:Create(tutorialFrame, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
        fadeOut.Completed:Connect(function()
            tutorialFrame.Visible = false
            tutorialFrame.BackgroundTransparency = 0.05
        end)
        fadeOut:Play()
    end)
end

remotes.StateUpdate.OnClientEvent:Connect(function(state)
    currentState = state
    updateUI()
end)

remotes.Notify.OnClientEvent:Connect(function(message)
    showNotification(message)
end)

remotes.Tutorial.OnClientEvent:Connect(function(message)
    showTutorial(message)
end)

sprintToggleButton.MouseButton1Click:Connect(function()
    local passes = currentState and currentState.Gamepasses or {}
    if not (passes and passes.HYPER_SPRINT) then
        remotes.PurchaseRequest:FireServer({ Type = "Gamepass", Key = "HYPER_SPRINT" })
        return
    end

    local settings = currentState and currentState.Settings or {}
    local enabled = settings and settings.HyperSprint == true
    remotes.ActionRequest:FireServer("ToggleHyperSprint", not enabled)
end)

autoToggleButton.MouseButton1Click:Connect(function()
    local passes = currentState and currentState.Gamepasses or {}
    if not (passes and passes.AUTO_COLLECTOR) then
        remotes.PurchaseRequest:FireServer({ Type = "Gamepass", Key = "AUTO_COLLECTOR" })
        return
    end

    local settings = currentState and currentState.Settings or {}
    local enabled = settings and settings.AutoCollector
    if enabled == nil then
        enabled = true
    end
    remotes.ActionRequest:FireServer("ToggleAutoCollector", not enabled)
end)

shopToggle.MouseButton1Click:Connect(function()
    shopFrame.Visible = not shopFrame.Visible
    shopToggle.Text = shopFrame.Visible and "Close Crystal Shop" or "Open Crystal Shop"
    if shopFrame.Visible then
        rebuildShop()
    end
end)

shopClose.MouseButton1Click:Connect(function()
    shopFrame.Visible = false
    shopToggle.Text = "Open Crystal Shop"
end)

-- Request an initial state if the server hasn't sent one yet
remotes.ActionRequest:FireServer("__REQUEST_STATE__")
