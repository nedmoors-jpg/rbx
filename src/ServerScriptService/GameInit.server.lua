local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local RemotesModule = require(script.Parent.Modules.Remotes)
local MapBuilder = require(script.Parent.Modules.MapBuilder)
local SessionService = require(script.Parent.Modules.SessionService)
local Monetization = require(script.Parent.Modules.Monetization)
local UpgradeService = require(script.Parent.Modules.UpgradeService)
local OrbManager = require(script.Parent.Modules.OrbManager)

local remotes = RemotesModule.get()
local mapReferences = MapBuilder.build()

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
    remotes.StateUpdate:FireClient(player, summary)
end

UpgradeService.SetDependencies(remotes, Monetization)
Monetization.SetStateUpdateCallback(sendState)
Monetization.OnPassUnlocked(function(player, passKey)
    if passKey == "Speed" then
        task.defer(UpgradeService.ApplyCharacterScaling, player)
    end

    if passKey == "InfiniteStorage" or passKey == "VIP" or passKey == "LuckyAura" then
        task.defer(sendState, player)
    end
end)

Monetization.Init(remotes)
OrbManager.Init(mapReferences, remotes, Monetization, sendState)

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
    local amount = math.floor(session.Inventory * multiplier)
    if amount <= 0 then
        SessionService.SetInventory(player, 0)
        return
    end

    SessionService.SetInventory(player, 0)
    SessionService.AdjustEnergy(player, amount)
    remotes.Notify:FireClient(player, string.format("Deposited for %d Energy", amount))
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
