local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
local orbTweens = {}

local function fireStateUpdate(player)
    if stateUpdateCallback then
        stateUpdateCallback(player)
    end
end

local function randomOrbPosition(zonePart)
    local size = zonePart.Size
    local margin = 8
    local xRange = math.max(4, size.X - margin)
    local zRange = math.max(4, size.Z - margin)
    local offsetX = (math.random() - 0.5) * xRange
    local offsetZ = (math.random() - 0.5) * zRange
    return zonePart.Position + Vector3.new(offsetX, 3, offsetZ)
end

local function markOrbDestroyed(zoneIndex, orb)
    if activeOrbs[zoneIndex] then
        activeOrbs[zoneIndex][orb] = nil
    end
end

local function destroyOrb(zoneIndex, orb)
    markOrbDestroyed(zoneIndex, orb)
    local tween = orbTweens[orb]
    if tween then
        tween:Cancel()
        orbTweens[orb] = nil
    end
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

    if isRare and monetization and monetization.PlayerHasPass(player, "LuckyAura") then
        value = math.floor(value * (1 + Config.Gamepasses.LuckyAura.RareBonus))
    end

    orb:SetAttribute("Collected", true)
    destroyOrb(zoneIndex, orb)

    SessionService.AddInventory(player, value)
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

local function spawnOrbInZone(zoneIndex)
    local zonePart = mapReferences.ZonePlatforms[zoneIndex]
    local container = mapReferences.OrbContainers[zoneIndex]
    local zoneConfig = Config.getZone(zoneIndex)

    if not zonePart or not container or not zoneConfig then
        return
    end

    local orb = Instance.new("Part")
    orb.Name = "EnergyOrb"
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(2.6, 2.6, 2.6)
    orb.Material = Enum.Material.Neon
    orb.Color = zoneConfig.OrbColor
    orb.Anchored = true
    orb.CanCollide = false
    orb.Position = randomOrbPosition(zonePart)

    local isRare = math.random() < zoneConfig.RareChance
    local value = zoneConfig.OrbValue
    local displayColor = zoneConfig.OrbColor
    if isRare then
        value = zoneConfig.RareOrbValue
        displayColor = displayColor:lerp(Color3.fromRGB(255, 255, 255), 0.35)
        orb.Color = displayColor
        local light = Instance.new("PointLight")
        light.Color = displayColor
        light.Brightness = 2.2
        light.Range = 12
        light.Parent = orb

        local sparkles = Instance.new("Sparkles")
        sparkles.SparkleColor = displayColor
        sparkles.Parent = orb
    end

    local aura = Instance.new("ParticleEmitter")
    aura.Name = "OrbAura"
    aura.Color = ColorSequence.new(zoneConfig.OrbColor, displayColor)
    aura.LightEmission = 0.25
    aura.Lifetime = NumberRange.new(0.6, 0.9)
    aura.Rate = 18
    aura.Speed = NumberRange.new(0.4, 1.4)
    aura.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.6),
        NumberSequenceKeypoint.new(0.6, 0.25),
        NumberSequenceKeypoint.new(1, 0)
    })
    aura.Parent = orb

    orb:SetAttribute("ZoneIndex", zoneIndex)
    orb:SetAttribute("Value", value)
    orb:SetAttribute("IsRare", isRare)

    orb.Touched:Connect(function(part)
        onOrbTouched(orb, part)
    end)

    orb.Parent = container

    local startPosition = orb.Position
    local tween = TweenService:Create(
        orb,
        TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Position = startPosition + Vector3.new(0, 1.35, 0) }
    )
    orbTweens[orb] = tween
    tween:Play()

    activeOrbs[zoneIndex] = activeOrbs[zoneIndex] or {}
    activeOrbs[zoneIndex][orb] = true
end

local function maintainZone(zoneIndex)
    spawnThreads[zoneIndex] = task.spawn(function()
        local zoneConfig = Config.getZone(zoneIndex)
        if not zoneConfig then
            return
        end

        local target = math.min(zoneConfig.OrbDensity, Config.MaxOrbsPerZone)
        while true do
            local container = mapReferences.OrbContainers[zoneIndex]
            if not container then
                break
            end

            local existing = #container:GetChildren()
            if existing < target then
                spawnOrbInZone(zoneIndex)
            end

            task.wait(Config.OrbRespawnSeconds + math.random())
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
        local settings = Config.Gamepasses.AutoCollector
        while threadRef and not threadRef.cancelled do
            if not monetization or not monetization.PlayerHasPass(player, "AutoCollector") then
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

local function ensureAutoCollector(player)
    if monetization and monetization.PlayerHasPass(player, "AutoCollector") then
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

    if monetization and monetization.OnPassUnlocked then
        monetization.OnPassUnlocked(function(player, passKey)
            if passKey == "AutoCollector" then
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

return OrbManager
