local Config = {}

Config.GameName = "Crystal Rush Tycoon"
Config.ZoneSpacing = 220
Config.ZoneY = 0
Config.ZoneSize = Vector3.new(140, 1, 140)
Config.ZoneRingRadius = 260
Config.TeleporterRadius = 36
Config.WalkwayWidth = 14
Config.BaseWalkSpeed = 14
Config.TeleportPadSize = Vector3.new(10, 1, 10)
Config.DepositPadSize = Vector3.new(14, 1, 14)
Config.DepositPosition = Vector3.new(0, 0.6, -20)
Config.OrbRespawnSeconds = 8
Config.MaxOrbsPerZone = 40
Config.InventoryTick = 0.25

Config.Zones = {
    {
        Name = "Starter Meadow",
        Description = "Collect shimmering shards and learn the basics.",
        UnlockCost = 0,
        OrbValue = 1,
        OrbColor = Color3.fromRGB(83, 203, 255),
        RareOrbValue = 8,
        RareChance = 0.08,
        OrbDensity = 26,
        Theme = {
            GroundMaterial = Enum.Material.Grass,
            GroundColor = Color3.fromRGB(52, 198, 136),
            AccentColor = Color3.fromRGB(117, 255, 239),
            AccentMaterial = Enum.Material.Neon,
            DecorColor = Color3.fromRGB(130, 255, 220),
            DecorMaterial = Enum.Material.Neon,
            DecorCount = 8,
            DecorHeight = Vector2.new(7, 12),
            DecorRadius = Vector2.new(2, 4)
        }
    },
    {
        Name = "Crystal Caves",
        Description = "Hidden caverns with higher value finds.",
        UnlockCost = 750,
        OrbValue = 4,
        OrbColor = Color3.fromRGB(255, 89, 89),
        RareOrbValue = 30,
        RareChance = 0.1,
        OrbDensity = 28,
        Theme = {
            GroundMaterial = Enum.Material.Slate,
            GroundColor = Color3.fromRGB(77, 80, 109),
            AccentColor = Color3.fromRGB(255, 141, 198),
            AccentMaterial = Enum.Material.Neon,
            DecorColor = Color3.fromRGB(255, 170, 214),
            DecorMaterial = Enum.Material.Neon,
            DecorCount = 9,
            DecorHeight = Vector2.new(9, 16),
            DecorRadius = Vector2.new(2.4, 4.4)
        }
    },
    {
        Name = "Sunspire Desert",
        Description = "Hot sands with frequent energy bursts.",
        UnlockCost = 5200,
        OrbValue = 12,
        OrbColor = Color3.fromRGB(245, 205, 48),
        RareOrbValue = 70,
        RareChance = 0.12,
        OrbDensity = 30,
        Theme = {
            GroundMaterial = Enum.Material.Sand,
            GroundColor = Color3.fromRGB(235, 189, 92),
            AccentColor = Color3.fromRGB(255, 223, 164),
            AccentMaterial = Enum.Material.SmoothPlastic,
            DecorColor = Color3.fromRGB(255, 196, 92),
            DecorMaterial = Enum.Material.Sandstone,
            DecorCount = 10,
            DecorHeight = Vector2.new(8, 15),
            DecorRadius = Vector2.new(2.6, 4.8)
        }
    },
    {
        Name = "Storm Peaks",
        Description = "Lightning-charged air produces volatile shards.",
        UnlockCost = 18600,
        OrbValue = 28,
        OrbColor = Color3.fromRGB(124, 156, 255),
        RareOrbValue = 140,
        RareChance = 0.14,
        OrbDensity = 32,
        Theme = {
            GroundMaterial = Enum.Material.Snow,
            GroundColor = Color3.fromRGB(210, 231, 255),
            AccentColor = Color3.fromRGB(156, 208, 255),
            AccentMaterial = Enum.Material.Ice,
            DecorColor = Color3.fromRGB(189, 226, 255),
            DecorMaterial = Enum.Material.Ice,
            DecorCount = 7,
            DecorHeight = Vector2.new(9, 17),
            DecorRadius = Vector2.new(2.2, 4.2)
        }
    },
    {
        Name = "Luminous Lagoon",
        Description = "Bioluminescent waters with radiant energy.",
        UnlockCost = 52800,
        OrbValue = 60,
        OrbColor = Color3.fromRGB(16, 252, 194),
        RareOrbValue = 320,
        RareChance = 0.16,
        OrbDensity = 34,
        Theme = {
            GroundMaterial = Enum.Material.SmoothPlastic,
            GroundColor = Color3.fromRGB(24, 184, 178),
            AccentColor = Color3.fromRGB(120, 255, 226),
            AccentMaterial = Enum.Material.Neon,
            DecorColor = Color3.fromRGB(106, 255, 221),
            DecorMaterial = Enum.Material.Neon,
            DecorCount = 9,
            DecorHeight = Vector2.new(8, 15),
            DecorRadius = Vector2.new(2.4, 4.2)
        }
    },
    {
        Name = "Galactic Rift",
        Description = "Zero-gravity void with monumental shards.",
        UnlockCost = 158000,
        OrbValue = 140,
        OrbColor = Color3.fromRGB(206, 44, 255),
        RareOrbValue = 650,
        RareChance = 0.18,
        OrbDensity = 36,
        Theme = {
            GroundMaterial = Enum.Material.Neon,
            GroundColor = Color3.fromRGB(38, 18, 56),
            AccentColor = Color3.fromRGB(206, 44, 255),
            AccentMaterial = Enum.Material.Neon,
            DecorColor = Color3.fromRGB(255, 120, 255),
            DecorMaterial = Enum.Material.Neon,
            DecorCount = 10,
            DecorHeight = Vector2.new(10, 18),
            DecorRadius = Vector2.new(2.8, 5.2)
        }
    }
}

Config.Upgrades = {
    Capacity = {
        { Level = 1, Capacity = 20, Cost = 0 },
        { Level = 2, Capacity = 40, Cost = 150 },
        { Level = 3, Capacity = 75, Cost = 550 },
        { Level = 4, Capacity = 120, Cost = 1800 },
        { Level = 5, Capacity = 200, Cost = 5200 },
        { Level = 6, Capacity = 320, Cost = 14800 },
        { Level = 7, Capacity = 480, Cost = 42400 },
        { Level = 8, Capacity = 720, Cost = 120000 }
    },
    Speed = {
        { Level = 1, WalkSpeed = 14, Cost = 0 },
        { Level = 2, WalkSpeed = 16, Cost = 400 },
        { Level = 3, WalkSpeed = 18, Cost = 1600 },
        { Level = 4, WalkSpeed = 20, Cost = 5200 },
        { Level = 5, WalkSpeed = 22, Cost = 16800 },
        { Level = 6, WalkSpeed = 24, Cost = 56000 }
    },
    Converter = {
        { Level = 1, Multiplier = 1, Cost = 0 },
        { Level = 2, Multiplier = 1.3, Cost = 950 },
        { Level = 3, Multiplier = 1.6, Cost = 4400 },
        { Level = 4, Multiplier = 2.1, Cost = 15600 },
        { Level = 5, Multiplier = 2.8, Cost = 49800 },
        { Level = 6, Multiplier = 3.6, Cost = 162000 }
    }
}

Config.Rebirth = {
    BaseCost = 325000,
    CostMultiplier = 2.85,
    RewardMultiplier = 1.75,
    BonusEnergy = 3500
}

Config.Gamepasses = {
    VIP = {
        Name = "VIP Quantum Membership",
        Benefit = "Permanent 2x deposit multiplier, golden name tag",
        Price = 350,
        Id = 1475674453,
        MultiplierBonus = 2
    },
    Speed = {
        Name = "Hyper Sprint",
        Benefit = "+6 WalkSpeed permanently",
        Price = 100,
        Id = 1475675105,
        ExtraSpeed = 6
    },
    InfiniteStorage = {
        Name = "Infinite Storage",
        Benefit = "Never run out of backpack space",
        Price = 700,
        Id = 1475674980
    },
    LuckyAura = {
        Name = "Lucky Aura",
        Benefit = "50% more rare shards whenever you collect",
        Price = 200,
        Id = 1475674639,
        RareBonus = 0.5
    },
    AutoCollector = {
        Name = "Auto Collector Drone",
        Benefit = "Automatically vacuum nearby shards",
        Price = 500,
        Id = 1475674830,
        Radius = 14,
        Interval = 1.5
    }
}

Config.DeveloperProducts = {
    EnergyPacks = {
        { Key = "SmallPack", Name = "Pocketful of Energy", Amount = 800, Price = 49, Id = 0 },
        { Key = "MediumPack", Name = "Crate of Energy", Amount = 2800, Price = 149, Id = 0 },
        { Key = "LargePack", Name = "Truck of Energy", Amount = 9200, Price = 399, Id = 0 },
        { Key = "UltraPack", Name = "Planetary Cache", Amount = 18500, Price = 799, Id = 0 }
    },
    Boosts = {
        { Key = "TwoXMultiplier10", Name = "10 min 2x Converter", Duration = 600, Multiplier = 2, Price = 99, Id = 0 },
        { Key = "TwoXMultiplier30", Name = "30 min 2x Converter", Duration = 1800, Multiplier = 2, Price = 249, Id = 0 }
    }
}

Config.TutorialMessages = {
    "Welcome to Crystal Rush! Collect glowing shards on the island to fill your backpack.",
    "Step on the golden deposit pad at base to convert shards into Energy.",
    "Spend Energy on upgrades for capacity, speed, and converter multiplier for faster runs.",
    "Unlock new zones from the teleporter ring once you can afford them.",
    "Rebirth after maxing zones to permanently multiply your earnings!"
}

function Config.getZone(index)
    return Config.Zones[index]
end

function Config.getUpgradePath(upgradeType)
    return Config.Upgrades[upgradeType]
end

function Config.getNextUpgradeCost(upgradeType, currentLevel)
    local path = Config.Upgrades[upgradeType]
    if not path then
        return nil
    end

    local nextLevel = path[currentLevel + 1]
    return nextLevel and nextLevel.Cost or nil
end

function Config.getUpgradeStats(upgradeType, level)
    local path = Config.Upgrades[upgradeType]
    if not path then
        return nil
    end

    return path[level]
end

function Config.getZoneUnlockCost(index)
    local zone = Config.Zones[index]
    return zone and zone.UnlockCost or nil
end

function Config.getRebirthCost(rebirthCount)
    return math.floor(Config.Rebirth.BaseCost * (Config.Rebirth.CostMultiplier ^ rebirthCount))
end

function Config.getRebirthMultiplier(rebirths)
    return Config.Rebirth.RewardMultiplier ^ rebirths
end

return Config
