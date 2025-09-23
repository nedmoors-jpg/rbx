local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))
local UpgradeService = require(script.Parent:WaitForChild("UpgradeService"))

local OrbManager = {}

local remotes
local mapReferences
local monetization
local stateUpdateCallback

local activeOrbs = {}
local spawnThreads = {}
local autoCollectorThreads = {}
local eventModifier

local function cloneTable(tbl)
    local copy = {}
    for key, value in pairs(tbl) do
        if typeof(value) == "table" then
            copy[key] = cloneTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

local function fireStateUpdate(player)
    if stateUpdateCallback then
        stateUpdateCallback(player)
    end
end

local function randomOrbPosition(zonePart, heightOffset)
    local size = zonePart.Size
    local margin = 8
    local xRange = math.max(4, size.X - margin)
    local zRange = math.max(4, size.Z - margin)
    local offsetX = (math.random() - 0.5) * xRange
    local offsetZ = (math.random() - 0.5) * zRange
    local baseY = zonePart.Position.Y + (zonePart.Size.Y / 2)
    return zonePart.Position + Vector3.new(offsetX, (heightOffset or 0) + baseY + 2.6, offsetZ)
end

local function markOrbDestroyed(zoneIndex, orb)
    if activeOrbs[zoneIndex] then
        activeOrbs[zoneIndex][orb] = nil
    end
end

local function destroyOrb(zoneIndex, orb)
    markOrbDestroyed(zoneIndex, orb)
    if orb and orb.Parent then
        orb:Destroy()
    end
end

local function collectOrb(player, orb)
    if not orb or not orb.Parent then
        return
    end

    local zoneIndex = orb:GetAttribute("ZoneIndex")
    local value = orb:GetAttribute("Value") or 1
    local isRare = orb:GetAttribute("IsRare") == true
    local rareValue = orb:GetAttribute("RareValue") or value

    local session = SessionService.GetSession(player)
    if not session then
        return
    end

    if session.Data.ZoneLevel < zoneIndex then
        return
    end

    local capacity = UpgradeService.GetCapacity(player)
    if capacity ~= math.huge and session.Inventory + value > capacity then
        return
    end

    if monetization and monetization.PlayerHasPass(player, "LUCKY_AURA") then
        local luckBonus = Config.Gamepasses.LUCKY_AURA.LuckBonus or 0
        if not isRare and luckBonus > 0 then
            if math.random() < luckBonus then
                isRare = true
                value = rareValue
            end
        end
    end

    local comboCount = SessionService.RegisterComboHit(player)
    local comboInfo = SessionService.GetComboInfo(player)

    orb:SetAttribute("Collected", true)
    destroyOrb(zoneIndex, orb)

    SessionService.AddInventory(player, value)

    if remotes and remotes.Notify and comboCount > 1 then
        local threshold = (Config.Combo and Config.Combo.NotifyThreshold) or 5
        if comboCount % threshold == 0 then
            local bonusPercent = math.floor((comboInfo.Multiplier - 1) * 100)
            remotes.Notify:FireClient(
                player,
                string.format("Combo x%d! +%d%% deposit bonus", comboCount, bonusPercent)
            )
        end
    end

    fireStateUpdate(player)
end

local function onOrbTouched(orb, otherPart)
    if orb:GetAttribute("Collected") then
        return
    end

    local character = otherPart.Parent
    if not character then
        return
    end

    local player = Players:GetPlayerFromCharacter(character)
    if not player then
        return
    end

    collectOrb(player, orb)
end

local function getActiveModifier(zoneIndex)
    if eventModifier and eventModifier.ZoneIndex == zoneIndex then
        return eventModifier
    end
end

local function spawnOrbInZone(zoneIndex, overrides)
    local zonePart = mapReferences.ZonePlatforms[zoneIndex]
    local container = mapReferences.OrbContainers[zoneIndex]
    local zoneConfig = Config.getZone(zoneIndex)

    if not zonePart or not container or not zoneConfig then
        return
    end

    local modifier = getActiveModifier(zoneIndex)
    local orb = Instance.new("Part")
    orb.Name = overrides and overrides.Name or "EnergyOrb"
    orb.Shape = overrides and overrides.Shape or Enum.PartType.Ball
    orb.Size = overrides and overrides.Size or Vector3.new(2.8, 2.8, 2.8)
    orb.Material = overrides and overrides.Material or Enum.Material.Neon
    orb.Anchored = true
    orb.CanCollide = false
    orb.Position = randomOrbPosition(zonePart, overrides and overrides.HeightOffset or 0)

    local baseValue = overrides and overrides.Value or zoneConfig.OrbValue
    local rareValue = overrides and overrides.RareValue or zoneConfig.RareOrbValue
    local valueMultiplier = 1

    if modifier and modifier.ValueMultiplier then
        valueMultiplier *= modifier.ValueMultiplier
    end
    if overrides and overrides.ValueMultiplier then
        valueMultiplier *= overrides.ValueMultiplier
    end

    baseValue = math.max(1, math.floor(baseValue * valueMultiplier))
    rareValue = math.max(baseValue + 1, math.floor(rareValue * valueMultiplier))

    local rareChance = overrides and overrides.RareChance or zoneConfig.RareChance
    if modifier and modifier.RareChanceBonus then
        rareChance += modifier.RareChanceBonus
    end
    if overrides and overrides.RareChanceBonus then
        rareChance += overrides.RareChanceBonus
    end
    rareChance = math.clamp(rareChance, 0, 1)

    local isRare
    if overrides and overrides.ForceRare then
        isRare = true
    else
        isRare = math.random() < rareChance
    end

    local color = overrides and overrides.Color or zoneConfig.OrbColor
    if modifier and modifier.ColorShift then
        local blend = modifier.ColorBlend or 0.45
        color = color:Lerp(modifier.ColorShift, blend)
    end

    if isRare and not (overrides and overrides.KeepRareColor) then
        color = color:lerp(Color3.fromRGB(255, 255, 255), 0.35)
    end

    orb.Color = color

    orb:SetAttribute("ZoneIndex", zoneIndex)
    local storedValue = isRare and rareValue or baseValue
    orb:SetAttribute("Value", storedValue)
    orb:SetAttribute("RareValue", rareValue)
    orb:SetAttribute("IsRare", isRare)
    if overrides and overrides.IsEvent then
        orb:SetAttribute("IsEvent", true)
    end

    local shouldGlow = (modifier and modifier.Glow) or (overrides and overrides.Glow) or isRare
    if shouldGlow then
        local light = Instance.new("PointLight")
        light.Color = overrides and overrides.LightColor or color
        light.Brightness = overrides and overrides.LightBrightness or (isRare and 2.2 or 1.6)
        light.Range = overrides and overrides.LightRange or 16
        light.Parent = orb
    end

    if overrides and overrides.Sparkle then
        local sparkle = Instance.new("Sparkles")
        sparkle.SparkleColor = overrides.SparkleColor or color
        sparkle.Parent = orb
    end

    orb.Touched:Connect(function(part)
        onOrbTouched(orb, part)
    end)

    orb.Parent = container
    activeOrbs[zoneIndex] = activeOrbs[zoneIndex] or {}
    activeOrbs[zoneIndex][orb] = true

    if overrides and overrides.Duration then
        task.delay(overrides.Duration, function()
            destroyOrb(zoneIndex, orb)
        end)
    end
end

local function maintainZone(zoneIndex)
    spawnThreads[zoneIndex] = task.spawn(function()
        local zoneConfig = Config.getZone(zoneIndex)
        if not zoneConfig then
            return
        end

        while true do
            local container = mapReferences.OrbContainers[zoneIndex]
            if not container then
                break
            end

            local modifier = getActiveModifier(zoneIndex)
            local densityMultiplier = modifier and (modifier.TargetMultiplier or 1) or 1
            local baseTarget = zoneConfig.OrbDensity
            local computedTarget = math.floor(baseTarget * densityMultiplier + 0.5)
            if densityMultiplier < 1 then
                computedTarget = math.max(computedTarget, math.floor(baseTarget * 0.6))
            end
            local target = math.clamp(computedTarget, 6, Config.MaxOrbsPerZone * 2)
            if target <= 0 then
                target = math.min(baseTarget, Config.MaxOrbsPerZone)
            end

            local existing = #container:GetChildren()
            if existing < target then
                spawnOrbInZone(zoneIndex)
            end

            local rateMultiplier = modifier and (modifier.SpawnRateMultiplier or 1) or 1
            local waitTime = math.max(0.5, (Config.OrbRespawnSeconds / rateMultiplier) + math.random())
            task.wait(waitTime)
        end
    end)
end

local function stopAutoCollector(player)
    local thread = autoCollectorThreads[player]
    if thread then
        thread.cancelled = true
        autoCollectorThreads[player] = nil
    end
end

local function runAutoCollector(player)
    stopAutoCollector(player)

    autoCollectorThreads[player] = {}
    local threadRef = autoCollectorThreads[player]

    task.spawn(function()
        local settings = Config.Gamepasses.AUTO_COLLECTOR
        while threadRef and not threadRef.cancelled do
            if not monetization or not monetization.PlayerHasPass(player, "AUTO_COLLECTOR") then
                break
            end

            local settingEnabled = SessionService.GetSetting(player, "AutoCollector")
            if settingEnabled == false then
                break
            end

            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then
                local radius = settings and settings.Radius or 12
                for zoneIndex, orbs in pairs(activeOrbs) do
                    for orb in pairs(orbs) do
                        if orb.Parent and not orb:GetAttribute("Collected") then
                            local distance = (orb.Position - root.Position).Magnitude
                            if distance <= radius then
                                collectOrb(player, orb)
                            end
                        end
                    end
                end
            end

            local interval = settings and settings.Interval or 2
            task.wait(interval)
        end
        autoCollectorThreads[player] = nil
    end)
end

local function isAutoCollectorEnabled(player)
    if not monetization or not monetization.PlayerHasPass(player, "AUTO_COLLECTOR") then
        return false
    end

    local setting = SessionService.GetSetting(player, "AutoCollector")
    if setting == nil then
        return true
    end

    return setting == true
end

local function ensureAutoCollector(player)
    if isAutoCollectorEnabled(player) then
        runAutoCollector(player)
    else
        stopAutoCollector(player)
    end
end

function OrbManager.Init(mapRefs, remoteTable, monetizationModule, updateCallback)
    mapReferences = mapRefs
    remotes = remoteTable
    monetization = monetizationModule
    stateUpdateCallback = updateCallback
    eventModifier = nil

    if monetization and monetization.OnPassUnlocked then
        monetization.OnPassUnlocked(function(player, passKey)
            if passKey == "AUTO_COLLECTOR" then
                task.defer(ensureAutoCollector, player)
            end
        end)
    end

    for index in ipairs(Config.Zones) do
        maintainZone(index)
    end
end

function OrbManager.RegisterPlayer(player)
    ensureAutoCollector(player)

    player.CharacterAdded:Connect(function()
        task.defer(ensureAutoCollector, player)
    end)
end

function OrbManager.UnregisterPlayer(player)
    stopAutoCollector(player)
end

function OrbManager.UpdateAutoCollector(player)
    ensureAutoCollector(player)
end

function OrbManager.SetEventModifier(modifier)
    if typeof(modifier) ~= "table" or not modifier.ZoneIndex then
        eventModifier = nil
        return
    end

    eventModifier = cloneTable(modifier)
end

function OrbManager.ClearEventModifier(zoneIndex)
    if not eventModifier then
        return
    end

    if not zoneIndex or eventModifier.ZoneIndex == zoneIndex then
        eventModifier = nil
    end
end

function OrbManager.GetEventModifier()
    if not eventModifier then
        return nil
    end

    return cloneTable(eventModifier)
end

function OrbManager.SpawnBurst(zoneIndex, burstConfig)
    if not burstConfig then
        return
    end

    local count = math.max(1, math.floor(burstConfig.Count or 3))
    for _ = 1, count do
        spawnOrbInZone(zoneIndex, {
            Name = burstConfig.Name or "EventCrystal",
            Size = burstConfig.Size,
            Material = burstConfig.Material,
            ValueMultiplier = burstConfig.ValueMultiplier or 4,
            Duration = burstConfig.Duration or 12,
            Color = burstConfig.Color,
            Glow = burstConfig.Glow ~= false,
            Sparkle = burstConfig.Sparkle ~= false,
            SparkleColor = burstConfig.SparkleColor,
            LightBrightness = burstConfig.LightBrightness,
            LightRange = burstConfig.LightRange,
            HeightOffset = burstConfig.HeightOffset or 3,
            ForceRare = burstConfig.ForceRare ~= false,
            RareChanceBonus = burstConfig.RareChanceBonus,
            IsEvent = true
        })
    end
end

return OrbManager
