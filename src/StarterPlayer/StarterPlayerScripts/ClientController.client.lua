local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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

local mainPanel = Instance.new("Frame")
mainPanel.Name = "StatsPanel"
mainPanel.Size = UDim2.new(0, 300, 0, 220)
mainPanel.Position = UDim2.new(0, 20, 0, 20)
mainPanel.BackgroundColor3 = Color3.fromRGB(32, 41, 69)
mainPanel.BorderSizePixel = 0
mainPanel.ZIndex = 3
mainPanel.Parent = screenGui
createShadow(mainPanel)

local titleLabel = createLabel(mainPanel, Config.GameName, UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0, 8), true)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(255, 229, 115)

local energyLabel = createLabel(mainPanel, "Energy: 0", UDim2.new(1, -20, 0, 26), UDim2.new(0, 10, 0, 50), true)
energyLabel.TextXAlignment = Enum.TextXAlignment.Left

local inventoryLabel = createLabel(mainPanel, "Inventory: 0 / 0", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 80), false)
inventoryLabel.TextXAlignment = Enum.TextXAlignment.Left

local multiplierLabel = createLabel(mainPanel, "Multiplier: 1x", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 105), false)
multiplierLabel.TextXAlignment = Enum.TextXAlignment.Left

local zoneLabel = createLabel(mainPanel, "Zone: 1", UDim2.new(0.5, -10, 0, 22), UDim2.new(0, 10, 0, 132), false)
zoneLabel.TextXAlignment = Enum.TextXAlignment.Left

local rebirthLabel = createLabel(mainPanel, "Rebirths: 0", UDim2.new(0.5, -10, 0, 22), UDim2.new(0.5, 0, 0, 132), false)
rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left

local boostLabel = createLabel(mainPanel, "Boosts: None", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 152), false)
boostLabel.TextXAlignment = Enum.TextXAlignment.Left

local vipStatusLabel = createLabel(mainPanel, "Status: Adventurer", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 176), false)
vipStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
vipStatusLabel.TextColor3 = Color3.fromRGB(255, 229, 115)

local abilityContainer = Instance.new("Frame")
abilityContainer.Name = "AbilityContainer"
abilityContainer.BackgroundTransparency = 1
abilityContainer.Size = UDim2.new(1, -20, 0, 36)
abilityContainer.Position = UDim2.new(0, 10, 1, -46)
abilityContainer.Parent = mainPanel

local sprintToggleButton = Instance.new("TextButton")
sprintToggleButton.Name = "SprintToggle"
sprintToggleButton.Size = UDim2.new(0.5, -6, 1, 0)
sprintToggleButton.Position = UDim2.new(0, 0, 0, 0)
sprintToggleButton.BackgroundColor3 = Color3.fromRGB(67, 94, 160)
sprintToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
sprintToggleButton.BorderSizePixel = 0
sprintToggleButton.Font = fontBold
sprintToggleButton.TextScaled = true
sprintToggleButton.Text = "Hyper Sprint"
sprintToggleButton.Parent = abilityContainer

local autoToggleButton = Instance.new("TextButton")
autoToggleButton.Name = "AutoToggle"
autoToggleButton.Size = UDim2.new(0.5, -6, 1, 0)
autoToggleButton.Position = UDim2.new(0.5, 6, 0, 0)
autoToggleButton.BackgroundColor3 = Color3.fromRGB(67, 94, 160)
autoToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoToggleButton.BorderSizePixel = 0
autoToggleButton.Font = fontBold
autoToggleButton.TextScaled = true
autoToggleButton.Text = "Auto Collector"
autoToggleButton.Parent = abilityContainer

local upgradesPanel = Instance.new("Frame")
upgradesPanel.Name = "UpgradesPanel"
upgradesPanel.Size = UDim2.new(0, 280, 0, 300)
upgradesPanel.Position = UDim2.new(0, 20, 0, 260)
upgradesPanel.BackgroundColor3 = Color3.fromRGB(28, 32, 52)
upgradesPanel.BorderSizePixel = 0
upgradesPanel.ZIndex = 3
upgradesPanel.Parent = screenGui
createShadow(upgradesPanel)

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
    button.BackgroundColor3 = Color3.fromRGB(72, 120, 212)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Parent = parent
    button.LayoutOrder = #parent:GetChildren()

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
shopToggle.Size = UDim2.new(0, 180, 0, 44)
shopToggle.Position = UDim2.new(1, -200, 0, 20)
shopToggle.AnchorPoint = Vector2.new(0, 0)
shopToggle.BackgroundColor3 = Color3.fromRGB(36, 45, 74)
shopToggle.Text = "Open Crystal Shop"
shopToggle.TextScaled = true
shopToggle.Font = fontBold
shopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopToggle.Parent = screenGui
createShadow(shopToggle)

local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.new(0, 420, 0, 420)
shopFrame.Position = UDim2.new(1, -440, 0, 80)
shopFrame.BackgroundColor3 = Color3.fromRGB(23, 27, 46)
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.ZIndex = 5
shopFrame.Parent = screenGui
createShadow(shopFrame)

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
        button.BackgroundColor3 = Color3.fromRGB(72, 120, 212)
        button.AutoButtonColor = true
    else
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        button.AutoButtonColor = false
    end
end

local function updateAbilityButtons()
    local passes = currentState and currentState.Gamepasses or {}
    local settings = currentState and currentState.Settings or {}

    local isVip = passes and passes.VIP
    if isVip then
        vipStatusLabel.Text = "Status: Crystal VIP"
        vipStatusLabel.TextColor3 = Color3.fromRGB(255, 229, 115)
    else
        vipStatusLabel.Text = "Status: Adventurer"
        vipStatusLabel.TextColor3 = Color3.fromRGB(194, 206, 255)
    end

    local hasSprint = passes and passes.HYPER_SPRINT
    local sprintEnabled = settings and settings.HyperSprint == true
    if hasSprint then
        if sprintEnabled then
            sprintToggleButton.Text = "Hyper Sprint\n[ON]"
            sprintToggleButton.BackgroundColor3 = Color3.fromRGB(93, 204, 146)
        else
            sprintToggleButton.Text = "Hyper Sprint\n[OFF]"
            sprintToggleButton.BackgroundColor3 = Color3.fromRGB(67, 94, 160)
        end
        sprintToggleButton.AutoButtonColor = true
    else
        sprintToggleButton.Text = "Hyper Sprint\nUnlock Gamepass"
        sprintToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
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
            autoToggleButton.BackgroundColor3 = Color3.fromRGB(93, 204, 146)
        else
            autoToggleButton.Text = "Auto Collector\n[OFF]"
            autoToggleButton.BackgroundColor3 = Color3.fromRGB(67, 94, 160)
        end
        autoToggleButton.AutoButtonColor = true
    else
        autoToggleButton.Text = "Auto Collector\nUnlock Gamepass"
        autoToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
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

    local energyValue = currentState.Energy or 0
    local inventoryValue = currentState.Inventory or 0
    local multiplierValue = currentState.ConverterMultiplier or 1
    local zoneValue = currentState.ZoneLevel or 1
    local rebirthValue = currentState.Rebirths or 0

    energyLabel.Text = string.format("Energy: %s", formatNumber(energyValue))
    local capacityText = currentState.CapacityDisplay or tostring(currentState.Capacity or 0)
    inventoryLabel.Text = string.format("Inventory: %s / %s", formatNumber(inventoryValue), capacityText)
    multiplierLabel.Text = string.format("Multiplier: %.2fx", multiplierValue)
    zoneLabel.Text = string.format("Zone: %d", zoneValue)
    rebirthLabel.Text = string.format("Rebirths: %d", rebirthValue)

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
    rebuildShop()
end

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
