local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local RemotesModule = require(script.Parent.Modules.Remotes)
local MapBuilder = require(script.Parent.Modules.MapBuilder)
local SessionService = require(script.Parent.Modules.SessionService)
local Monetization = require(script.Parent.Modules.Monetization)
local UpgradeService = require(script.Parent.Modules.UpgradeService)
local OrbManager = require(script.Parent.Modules.OrbManager)
local ChatEffects = require(script.Parent.Modules.ChatEffects)
local EventService = require(script.Parent.Modules.EventService)

local remotes = RemotesModule.get()
local mapReferences = MapBuilder.build()

local vipItemsByKey = {}
for _, item in ipairs(Config.VIPShop) do
    vipItemsByKey[item.Key] = item
end

local function applyVipStatus(player)
    local isVip = Monetization.PlayerHasPass(player, "VIP")
    player:SetAttribute("IsVIP", isVip)

    if isVip then
        ChatEffects.ApplyVipFormatting(player, Config.Gamepasses.VIP.ChatTag, Config.Gamepasses.VIP.ChatColor)
    else
        ChatEffects.ClearVipFormatting(player)
    end
end

local function applyOwnedPassPerks(player)
    applyVipStatus(player)
    task.defer(UpgradeService.ApplyCharacterScaling, player)
    task.defer(OrbManager.UpdateAutoCollector, player)
end

local function createLeaderstats(player)
    local folder = Instance.new("Folder")
    folder.Name = "leaderstats"
    folder.Parent = player

    local energy = Instance.new("IntValue")
    energy.Name = "Energy"
    energy.Value = 0
    energy.Parent = folder

    local rebirths = Instance.new("IntValue")
    rebirths.Name = "Rebirths"
    rebirths.Value = 0
    rebirths.Parent = folder

    local zone = Instance.new("IntValue")
    zone.Name = "Zone"
    zone.Value = 1
    zone.Parent = folder
end

local function updateLeaderstats(player, summary)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end

    local energy = leaderstats:FindFirstChild("Energy")
    if energy then
        energy.Value = summary.Energy
    end

    local rebirths = leaderstats:FindFirstChild("Rebirths")
    if rebirths then
        rebirths.Value = summary.Rebirths
    end

    local zone = leaderstats:FindFirstChild("Zone")
    if zone then
        zone.Value = summary.ZoneLevel
    end
end

local function teleportPlayer(player, targetPosition)
    local character = player.Character
    if not character then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    root.CFrame = CFrame.new(targetPosition + Vector3.new(0, 4, 0))
end

local function sendState(player)
    local summary = UpgradeService.GetStateSummary(player)
    if not summary then
        return
    end

    updateLeaderstats(player, summary)
    local eventSummary = EventService.GetEventSummary()
    if eventSummary then
        summary.ActiveEvent = eventSummary
    end
    remotes.StateUpdate:FireClient(player, summary)
end

UpgradeService.SetDependencies(remotes, Monetization)
Monetization.SetStateUpdateCallback(sendState)
Monetization.OnPassUnlocked(function(player, passKey)
    if passKey == "HYPER_SPRINT" then
        SessionService.SetSetting(player, "HyperSprint", true)
        task.defer(UpgradeService.ApplyCharacterScaling, player)
    elseif passKey == "AUTO_COLLECTOR" then
        SessionService.SetSetting(player, "AutoCollector", true)
        task.defer(OrbManager.UpdateAutoCollector, player)
    end

    task.defer(applyOwnedPassPerks, player)

    if passKey == "VIP" or passKey == "INFINITE_STORAGE" or passKey == "LUCKY_AURA" or passKey == "HYPER_SPRINT" or passKey == "AUTO_COLLECTOR" then
        task.defer(sendState, player)
    end
end)

Monetization.Init(remotes)
OrbManager.Init(mapReferences, remotes, Monetization, sendState)
EventService.Init(remotes, OrbManager, sendState)

local function handleDeposit(player)
    local session = SessionService.GetSession(player)
    if not session or session.Inventory <= 0 then
        return
    end

    local now = os.clock()
    local last = player:GetAttribute("LastDepositTime") or 0
    if now - last < 0.6 then
        return
    end
    player:SetAttribute("LastDepositTime", now)

    local multiplier = UpgradeService.GetConverterMultiplier(player)
    local comboInfo = SessionService.GetComboInfo(player)
    local comboMultiplier = comboInfo and comboInfo.Multiplier or 1
    local amount = math.floor(session.Inventory * multiplier * comboMultiplier)
    if amount <= 0 then
        SessionService.SetInventory(player, 0)
        SessionService.ResetCombo(player)
        return
    end

    if Monetization.PlayerHasPass(player, "VIP") then
        local bonus = Config.Gamepasses.VIP.DepositBonus or 0
        amount = math.floor(amount * (1 + bonus))
    end
    SessionService.SetInventory(player, 0)
    SessionService.ResetCombo(player)
    SessionService.AdjustEnergy(player, amount)
    local message = string.format("Deposited for %d Energy", amount)
    if comboInfo and comboInfo.Count and comboInfo.Count > 1 then
        message = message .. string.format(" (Combo x%d)", comboInfo.Count)
    end
    remotes.Notify:FireClient(player, message)
    sendState(player)
end

local function onDepositTouched(part)
    if not part or not part.Parent then
        return
    end

    local player = Players:GetPlayerFromCharacter(part.Parent)
    if not player then
        return
    end

    handleDeposit(player)
end

local function bindTeleporters()
    for index, pad in pairs(mapReferences.TeleporterPads) do
        pad.Touched:Connect(function(part)
            if not part or not part.Parent then
                return
            end

            local player = Players:GetPlayerFromCharacter(part.Parent)
            if not player then
                return
            end

            local session = SessionService.GetSession(player)
            if not session then
                return
            end

            if session.Data.ZoneLevel < index then
                local zoneConfig = Config.getZone(index)
                if zoneConfig then
                    remotes.Notify:FireClient(player, string.format("Unlock %s first!", zoneConfig.Name))
                end
                return
            end

            local zonePart = mapReferences.ZonePlatforms[index]
            if zonePart then
                teleportPlayer(player, zonePart.Position)
            end
        end)
    end

    for index, pad in pairs(mapReferences.ReturnPads) do
        pad.Touched:Connect(function(part)
            if not part or not part.Parent then
                return
            end

            local player = Players:GetPlayerFromCharacter(part.Parent)
            if not player then
                return
            end

            local basePart = mapReferences.ZonePlatforms[1]
            if basePart then
                teleportPlayer(player, basePart.Position)
            end
        end)
    end
end

mapReferences.DepositPad.Touched:Connect(onDepositTouched)
bindTeleporters()

local function handleHyperSprintToggle(player, desiredState)
    if not UpgradeService.CanUseHyperSprint(player) then
        return false, "Hyper Sprint gamepass required"
    end

    local current = SessionService.GetSetting(player, "HyperSprint") == true
    local target
    if typeof(desiredState) == "boolean" then
        target = desiredState
    else
        target = not current
    end

    SessionService.SetSetting(player, "HyperSprint", target)
    UpgradeService.ApplyCharacterScaling(player)

    return true, target and "Hyper Sprint enabled" or "Hyper Sprint disabled"
end

local function handleAutoCollectorToggle(player, desiredState)
    if not UpgradeService.CanUseAutoCollector(player) then
        return false, "Auto Collector gamepass required"
    end

    local current = SessionService.GetSetting(player, "AutoCollector")
    current = current == nil and true or current == true

    local target
    if typeof(desiredState) == "boolean" then
        target = desiredState
    else
        target = not current
    end

    SessionService.SetSetting(player, "AutoCollector", target)
    OrbManager.UpdateAutoCollector(player)

    return true, target and "Auto Collector enabled" or "Auto Collector disabled"
end

local function handleVipShopPurchase(player, payload)
    if typeof(payload) ~= "table" then
        return false, "Invalid purchase"
    end

    local key = payload.Key
    local item = vipItemsByKey[key]
    if not item then
        return false, "Unavailable"
    end

    if not Monetization.PlayerHasPass(player, "VIP") then
        return false, "VIP exclusive item"
    end

    local session = SessionService.GetSession(player)
    if not session then
        return false, "No session"
    end

    if session.Data.Energy < item.Cost then
        return false, string.format("Need %d Energy", item.Cost)
    end

    SessionService.AdjustEnergy(player, -item.Cost)
    if item.Multiplier and item.Duration then
        local expires = os.time() + item.Duration
        SessionService.AddBoost(player, item.Key, { Multiplier = item.Multiplier, Expires = expires })
    end

    return true, string.format("%s activated!", item.Name)
end

local actionHandlers = {
    UpgradeCapacity = function(player)
        return UpgradeService.HandleUpgrade(player, "Capacity")
    end,
    UpgradeSpeed = function(player)
        return UpgradeService.HandleUpgrade(player, "Speed")
    end,
    UpgradeConverter = function(player)
        return UpgradeService.HandleUpgrade(player, "Converter")
    end,
    UnlockZone = function(player)
        return UpgradeService.HandleZoneUnlock(player)
    end,
    Rebirth = function(player)
        return UpgradeService.HandleRebirth(player)
    end,
    ToggleHyperSprint = function(player, desiredState)
        return handleHyperSprintToggle(player, desiredState)
    end,
    ToggleAutoCollector = function(player, desiredState)
        return handleAutoCollectorToggle(player, desiredState)
    end,
    PurchaseVIPItem = function(player, payload)
        return handleVipShopPurchase(player, payload)
    end,
    __REQUEST_STATE__ = function(player)
        sendState(player)
        return false
    end
}

remotes.ActionRequest.OnServerEvent:Connect(function(player, action, payload)
    if typeof(action) ~= "string" then
        return
    end

    local handler = actionHandlers[action]
    if not handler then
        return
    end

    local success, message = handler(player, payload)
    if message then
        remotes.Notify:FireClient(player, message)
    end

    if success then
        sendState(player)
    end
end)

local function showTutorial(player)
    for index, text in ipairs(Config.TutorialMessages) do
        task.delay(3 + (index - 1) * 6, function()
            if player.Parent then
                remotes.Tutorial:FireClient(player, text)
            end
        end)
    end
end

local function onCharacterAdded(player, character)
    task.wait(0.2)
    UpgradeService.ApplyCharacterScaling(player)
end

local function onPlayerAdded(player)
    createLeaderstats(player)
    local session = SessionService.CreateSession(player)

    Monetization.RegisterPlayer(player)
    Monetization.SyncSession(player)
    OrbManager.RegisterPlayer(player)
    applyOwnedPassPerks(player)

    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)

    if player.Character then
        onCharacterAdded(player, player.Character)
    end

    sendState(player)
    showTutorial(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    Monetization.CleanupPlayer(player)
    OrbManager.UnregisterPlayer(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
