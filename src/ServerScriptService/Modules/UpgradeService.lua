local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))

local UpgradeService = {}

UpgradeService.Monetization = nil
UpgradeService.Remotes = nil

local function getSession(player)
    return SessionService.GetSession(player)
end

local function applyWalkSpeed(player)
    local session = getSession(player)
    if not session then
        return
    end

    local character = player.Character
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    humanoid.WalkSpeed = UpgradeService.GetWalkSpeed(player)
end

local function cleanBoosts(session)
    local now = os.time()
    for key, data in pairs(session.Boosts) do
        if data.Expires and data.Expires <= now then
            session.Boosts[key] = nil
        end
    end
end

function UpgradeService.SetDependencies(remotes, monetization)
    UpgradeService.Remotes = remotes
    UpgradeService.Monetization = monetization
end

function UpgradeService.GetCapacity(player)
    local session = getSession(player)
    if not session then
        return 0
    end

    local level = session.Data.CapacityLevel
    local stats = Config.getUpgradeStats("Capacity", level)
    local capacity = stats and stats.Capacity or 0

    if UpgradeService.Monetization and UpgradeService.Monetization.PlayerHasPass(player, "InfiniteStorage") then
        capacity = math.huge
    end

    return capacity
end

function UpgradeService.GetWalkSpeed(player)
    local session = getSession(player)
    if not session then
        return Config.BaseWalkSpeed
    end

    local stats = Config.getUpgradeStats("Speed", session.Data.SpeedLevel)
    local speed = stats and stats.WalkSpeed or Config.BaseWalkSpeed

    if UpgradeService.Monetization and UpgradeService.Monetization.PlayerHasPass(player, "Speed") then
        speed += Config.Gamepasses.Speed.ExtraSpeed
    end

    return speed
end

function UpgradeService.GetConverterMultiplier(player)
    local session = getSession(player)
    if not session then
        return 1
    end

    cleanBoosts(session)

    local stats = Config.getUpgradeStats("Converter", session.Data.ConverterLevel)
    local multiplier = stats and stats.Multiplier or 1

    if UpgradeService.Monetization and UpgradeService.Monetization.PlayerHasPass(player, "VIP") then
        multiplier *= Config.Gamepasses.VIP.MultiplierBonus
    end

    local boosts = SessionService.GetBoosts(player)
    for key, data in pairs(boosts) do
        if data.Multiplier then
            multiplier *= data.Multiplier
        end
    end

    multiplier *= Config.getRebirthMultiplier(session.Data.Rebirths)

    return multiplier
end

function UpgradeService.GetStateSummary(player)
    local session = getSession(player)
    if not session then
        return nil
    end

    cleanBoosts(session)

    local summary = {
        Energy = session.Data.Energy,
        TotalEnergy = session.Data.TotalEnergy,
        Inventory = session.Inventory,
        Capacity = UpgradeService.GetCapacity(player),
        CapacityLevel = session.Data.CapacityLevel,
        CapacityNextCost = Config.getNextUpgradeCost("Capacity", session.Data.CapacityLevel),
        Speed = UpgradeService.GetWalkSpeed(player),
        SpeedLevel = session.Data.SpeedLevel,
        SpeedNextCost = Config.getNextUpgradeCost("Speed", session.Data.SpeedLevel),
        ConverterLevel = session.Data.ConverterLevel,
        ConverterMultiplier = UpgradeService.GetConverterMultiplier(player),
        ConverterNextCost = Config.getNextUpgradeCost("Converter", session.Data.ConverterLevel),
        ZoneLevel = session.Data.ZoneLevel,
        NextZoneCost = Config.getZoneUnlockCost(session.Data.ZoneLevel + 1),
        Rebirths = session.Data.Rebirths,
        RebirthCost = Config.getRebirthCost(session.Data.Rebirths)
    }

    if summary.Capacity == math.huge then
        summary.CapacityDisplay = "Infinite"
    else
        summary.CapacityDisplay = tostring(summary.Capacity)
    end

    if UpgradeService.Monetization then
        summary.Gamepasses = {}
        for key, value in pairs(UpgradeService.Monetization.GetOwnedPasses(player)) do
            if value then
                summary.Gamepasses[key] = true
            end
        end
    end

    local boosts = SessionService.GetBoosts(player)
    local boostSummary = {}
    local now = os.time()
    for key, data in pairs(boosts) do
        boostSummary[key] = {
            Multiplier = data.Multiplier,
            ExpiresIn = data.Expires and math.max(0, data.Expires - now) or nil
        }
    end
    summary.ActiveBoosts = boostSummary

    return summary
end

function UpgradeService.HandleUpgrade(player, upgradeType)
    local session = getSession(player)
    if not session then
        return false, "No session"
    end

    local path = Config.getUpgradePath(upgradeType)
    if not path then
        return false, "Invalid upgrade"
    end

    local currentLevel = session.Data[upgradeType .. "Level"]
    local nextTier = path[currentLevel + 1]
    if not nextTier then
        return false, "Maxed"
    end

    local cost = nextTier.Cost
    if session.Data.Energy < cost then
        return false, string.format("Need %d Energy", cost)
    end

    SessionService.AdjustEnergy(player, -cost)
    SessionService.RecordUpgrade(player, upgradeType, currentLevel + 1)

    if upgradeType == "Speed" then
        task.defer(applyWalkSpeed, player)
    end

    return true, string.format("%s upgraded to level %d", upgradeType, currentLevel + 1)
end

function UpgradeService.HandleZoneUnlock(player)
    local session = getSession(player)
    if not session then
        return false, "No session"
    end

    local nextIndex = session.Data.ZoneLevel + 1
    local zone = Config.getZone(nextIndex)
    if not zone then
        return false, "No more zones"
    end

    local cost = zone.UnlockCost
    if session.Data.Energy < cost then
        return false, string.format("Need %d Energy", cost)
    end

    SessionService.AdjustEnergy(player, -cost)
    SessionService.RecordZoneUnlock(player, nextIndex)

    return true, string.format("Unlocked %s", zone.Name)
end

function UpgradeService.HandleRebirth(player)
    local session = getSession(player)
    if not session then
        return false, "No session"
    end

    if session.Data.ZoneLevel < #Config.Zones then
        return false, "Unlock all zones first"
    end

    local cost = Config.getRebirthCost(session.Data.Rebirths)
    if session.Data.Energy < cost then
        return false, string.format("Need %d Energy", cost)
    end

    SessionService.AdjustEnergy(player, -cost)
    SessionService.RecordRebirth(player)

    task.defer(applyWalkSpeed, player)

    return true, "Rebirth complete!"
end

function UpgradeService.ApplyCharacterScaling(player)
    task.defer(applyWalkSpeed, player)
end

return UpgradeService
