local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapBuilder = {}

local rng = Random.new()

local function createBillboard(parent, title, description)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Billboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(8, 0, 3, 0)
    billboard.ExtentsOffset = Vector3.new(0, 6, 0)
    billboard.Parent = parent

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextScaled = true
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Parent = billboard

    local descLabel = Instance.new("TextLabel")
    descLabel.BackgroundTransparency = 1
    descLabel.TextWrapped = true
    descLabel.Text = description
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextScaled = true
    descLabel.TextColor3 = Color3.fromRGB(213, 233, 255)
    descLabel.Size = UDim2.new(1, 0, 0.4, 0)
    descLabel.Position = UDim2.new(0, 0, 0.6, 0)
    descLabel.Parent = billboard

    return billboard
end

local function createUICorneredPart(name, size, position, material, color, parent)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.Material = material or Enum.Material.SmoothPlastic
    part.Color = color or Color3.fromRGB(60, 60, 60)
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function randomOffset(size, margin)
    margin = margin or 16
    return Vector3.new(
        rng:NextNumber(-1, 1) * (size.X / 2 - margin),
        0,
        rng:NextNumber(-1, 1) * (size.Z / 2 - margin)
    )
end

local function createCrystalCluster(parent, zonePart, baseColor, accentColor)
    local clusterFolder = Instance.new("Folder")
    clusterFolder.Name = "CrystalCluster"
    clusterFolder.Parent = parent

    local offset = randomOffset(zonePart.Size, 18)
    local basePosition = zonePart.Position + offset

    local pedestal = Instance.new("Part")
    pedestal.Name = "Pedestal"
    pedestal.Size = Vector3.new(4, 1.2, 4)
    pedestal.Anchored = true
    pedestal.Material = Enum.Material.Rock
    pedestal.Color = baseColor:lerp(Color3.fromRGB(40, 40, 40), 0.5)
    pedestal.Position = basePosition + Vector3.new(0, zonePart.Size.Y / 2 + pedestal.Size.Y / 2, 0)
    pedestal.Parent = clusterFolder

    for i = 1, rng:NextInteger(3, 5) do
        local shard = Instance.new("Part")
        shard.Name = "Shard" .. i
        shard.Size = Vector3.new(1.4, rng:NextNumber(4, 8), 1.4)
        shard.Material = Enum.Material.Neon
        shard.Color = accentColor or baseColor
        shard.Anchored = true
        shard.CanCollide = false
        local angle = math.rad(rng:NextNumber(-18, 18))
        local rotation = CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), angle, 0)
        local shardPos = basePosition + Vector3.new(rng:NextNumber(-1.4, 1.4), pedestal.Size.Y / 2 + shard.Size.Y / 2, rng:NextNumber(-1.4, 1.4))
        shard.CFrame = CFrame.new(shardPos) * rotation
        shard.Parent = clusterFolder

        local sparkle = Instance.new("Sparkles")
        sparkle.SparkleColor = accentColor or baseColor
        sparkle.Parent = shard
    end

    local light = Instance.new("PointLight")
    light.Color = accentColor or baseColor
    light.Brightness = 1.6
    light.Range = 18
    light.Parent = pedestal

    return clusterFolder
end

local function createTree(parent, zonePart, accentColor)
    local offset = randomOffset(zonePart.Size, 20)
    local basePosition = zonePart.Position + offset

    local trunk = Instance.new("Part")
    trunk.Name = "CrystalTreeTrunk"
    trunk.Size = Vector3.new(1.8, 8, 1.8)
    trunk.Anchored = true
    trunk.Material = Enum.Material.Wood
    trunk.Color = Color3.fromRGB(112, 82, 54)
    trunk.Position = basePosition + Vector3.new(0, zonePart.Size.Y / 2 + trunk.Size.Y / 2, 0)
    trunk.Parent = parent

    local canopy = Instance.new("Part")
    canopy.Name = "CrystalTreeCanopy"
    canopy.Shape = Enum.PartType.Ball
    canopy.Size = Vector3.new(5.6, 5.6, 5.6)
    canopy.Material = Enum.Material.Neon
    canopy.Color = accentColor
    canopy.Anchored = true
    canopy.CanCollide = false
    canopy.Position = trunk.Position + Vector3.new(0, trunk.Size.Y / 2 + canopy.Size.Y / 2 - 1, 0)
    canopy.Parent = parent

    local light = Instance.new("PointLight")
    light.Color = accentColor
    light.Brightness = 1.2
    light.Range = 20
    light.Parent = canopy
end

local function createStonePillar(parent, zonePart, accentColor)
    local offset = randomOffset(zonePart.Size, 18)
    local basePosition = zonePart.Position + offset

    local pillar = Instance.new("Part")
    pillar.Name = "StonePillar"
    pillar.Size = Vector3.new(2.4, rng:NextNumber(12, 18), 2.4)
    pillar.Anchored = true
    pillar.Material = Enum.Material.Slate
    pillar.Color = accentColor:lerp(Color3.fromRGB(50, 50, 50), 0.35)
    pillar.Position = basePosition + Vector3.new(0, zonePart.Size.Y / 2 + pillar.Size.Y / 2, 0)
    pillar.Parent = parent

    local glow = Instance.new("SurfaceLight")
    glow.Face = Enum.NormalId.Top
    glow.Color = accentColor
    glow.Brightness = 2
    glow.Range = 14
    glow.Parent = pillar
end

local function createFlameTorch(parent, zonePart, accentColor)
    local offset = randomOffset(zonePart.Size, 18)
    local basePosition = zonePart.Position + offset

    local base = Instance.new("Part")
    base.Name = "TorchBase"
    base.Size = Vector3.new(2, 4, 2)
    base.Anchored = true
    base.Material = Enum.Material.Slate
    base.Color = accentColor:lerp(Color3.fromRGB(60, 40, 20), 0.7)
    base.Position = basePosition + Vector3.new(0, zonePart.Size.Y / 2 + base.Size.Y / 2, 0)
    base.Parent = parent

    local flame = Instance.new("Fire")
    flame.Color = accentColor
    flame.SecondaryColor = Color3.fromRGB(255, 214, 120)
    flame.Size = 8
    flame.Heat = 10
    flame.Parent = base
end

local function createStormEmitter(parent, zonePart, accentColor)
    local offset = randomOffset(zonePart.Size, 22)
    local basePosition = zonePart.Position + offset

    local spire = Instance.new("Part")
    spire.Name = "StormSpire"
    spire.Size = Vector3.new(1.4, rng:NextNumber(12, 18), 1.4)
    spire.Anchored = true
    spire.Material = Enum.Material.Metal
    spire.Color = Color3.fromRGB(200, 210, 255)
    spire.Position = basePosition + Vector3.new(0, zonePart.Size.Y / 2 + spire.Size.Y / 2, 0)
    spire.Parent = parent

    local spark = Instance.new("ParticleEmitter")
    spark.LightEmission = 1
    spark.Rate = 40
    spark.Speed = NumberRange.new(6, 9)
    spark.Lifetime = NumberRange.new(0.4, 0.6)
    spark.Color = ColorSequence.new(accentColor)
    spark.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
    spark.Parent = spire

    local light = Instance.new("PointLight")
    light.Color = accentColor
    light.Brightness = 3
    light.Range = 22
    light.Parent = spire
end

local function createLagoonPool(parent, zonePart, accentColor)
    local offset = randomOffset(zonePart.Size, 24)
    local position = zonePart.Position + offset

    local pool = Instance.new("Part")
    pool.Name = "LagoonPool"
    pool.Size = Vector3.new(14, 1.2, 14)
    pool.Anchored = true
    pool.Material = Enum.Material.Water
    pool.Color = accentColor
    pool.Transparency = 0.35
    pool.Position = position + Vector3.new(0, zonePart.Size.Y / 2 + 0.6, 0)
    pool.Parent = parent

    local glow = Instance.new("SurfaceLight")
    glow.Brightness = 1.4
    glow.Range = 18
    glow.Color = accentColor
    glow.Parent = pool
end

local function createVoidPrism(parent, zonePart, accentColor)
    local offset = randomOffset(zonePart.Size, 22)
    local basePosition = zonePart.Position + offset

    local prism = Instance.new("Part")
    prism.Name = "VoidPrism"
    prism.Size = Vector3.new(2.6, rng:NextNumber(10, 16), 2.6)
    prism.Anchored = true
    prism.Material = Enum.Material.Neon
    prism.Color = accentColor
    prism.Position = basePosition + Vector3.new(0, zonePart.Size.Y / 2 + prism.Size.Y / 2, 0)
    prism.Parent = parent

    local aura = Instance.new("ParticleEmitter")
    aura.LightEmission = 1
    aura.Rate = 20
    aura.Lifetime = NumberRange.new(1.2, 1.6)
    aura.Speed = NumberRange.new(0.4, 1)
    aura.Rotation = NumberRange.new(0, 360)
    aura.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.2, 1.2),
        NumberSequenceKeypoint.new(1, 0)
    })
    aura.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, accentColor),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    aura.Parent = prism
end

local function decorateZone(zoneFolder, zonePart, zoneConfig)
    local props = zoneConfig.Props or {}
    local accent = zoneConfig.AccentColor or zoneConfig.OrbColor

    if props.Crystals then
        local count = typeof(props.Crystals) == "number" and props.Crystals or 4
        for _ = 1, count do
            createCrystalCluster(zoneFolder, zonePart, zoneConfig.OrbColor, accent)
        end
    end

    if props.Trees then
        local count = typeof(props.Trees) == "number" and props.Trees or 5
        for _ = 1, count do
            createTree(zoneFolder, zonePart, accent)
        end
    end

    if props.Pillars then
        local count = typeof(props.Pillars) == "number" and props.Pillars or 3
        for _ = 1, count do
            createStonePillar(zoneFolder, zonePart, accent)
        end
    end

    if props.Flames then
        local count = typeof(props.Flames) == "number" and props.Flames or 2
        for _ = 1, count do
            createFlameTorch(zoneFolder, zonePart, accent)
        end
    end

    if props.Storm then
        local count = typeof(props.Storm) == "number" and props.Storm or 3
        for _ = 1, count do
            createStormEmitter(zoneFolder, zonePart, accent)
        end
    end

    if props.Water then
        local count = typeof(props.Water) == "number" and props.Water or 3
        for _ = 1, count do
            createLagoonPool(zoneFolder, zonePart, accent)
        end
    end

    if props.Void then
        local count = typeof(props.Void) == "number" and props.Void or 4
        for _ = 1, count do
            createVoidPrism(zoneFolder, zonePart, accent)
        end
    end
end

local function createHoverCrystal(parent, position, color)
    local crystal = Instance.new("Part")
    crystal.Name = "HoverCrystal"
    crystal.Size = Vector3.new(3, 7, 3)
    crystal.Anchored = true
    crystal.CanCollide = false
    crystal.Material = Enum.Material.Neon
    crystal.Color = color
    crystal.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), math.rad(18))
    crystal.Parent = parent

    local sparkles = Instance.new("Sparkles")
    sparkles.SparkleColor = color
    sparkles.Parent = crystal

    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 2
    light.Range = 24
    light.Parent = crystal
end

function MapBuilder.build()
    local existing = Workspace:FindFirstChild("GeneratedMap")
    if existing then
        existing:Destroy()
    end

    local mapFolder = Instance.new("Folder")
    mapFolder.Name = "GeneratedMap"
    mapFolder.Parent = Workspace

    local zonesFolder = Instance.new("Folder")
    zonesFolder.Name = "Zones"
    zonesFolder.Parent = mapFolder

    local teleporterFolder = Instance.new("Folder")
    teleporterFolder.Name = "TeleportPads"
    teleporterFolder.Parent = mapFolder

    local basePlatform = createUICorneredPart(
        "BasePlatform",
        Config.ZoneSize + Vector3.new(40, 2, 40),
        Vector3.new(0, Config.ZoneY, 0),
        Enum.Material.Grass,
        Color3.fromRGB(44, 118, 72),
        mapFolder
    )

    local baseRim = createUICorneredPart(
        "BaseRim",
        basePlatform.Size + Vector3.new(18, 0.6, 18),
        basePlatform.Position + Vector3.new(0, -basePlatform.Size.Y / 2 + 0.3, 0),
        Enum.Material.Rock,
        Color3.fromRGB(58, 66, 84),
        mapFolder
    )

    local waterRing = createUICorneredPart(
        "WaterRing",
        basePlatform.Size + Vector3.new(80, 0.8, 80),
        basePlatform.Position + Vector3.new(0, -basePlatform.Size.Y / 2 - 0.4, 0),
        Enum.Material.Water,
        Color3.fromRGB(38, 108, 158),
        mapFolder
    )
    waterRing.Transparency = 0.4

    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Name = "Spawn"
    spawnLocation.Size = Vector3.new(8, 1, 8)
    spawnLocation.Position = basePlatform.Position + Vector3.new(0, basePlatform.Size.Y / 2 + 0.6, 0)
    spawnLocation.Anchored = true
    spawnLocation.Neutral = true
    spawnLocation.Transparency = 1
    spawnLocation.CanCollide = false
    spawnLocation.Parent = mapFolder

    local depositPad = Instance.new("Part")
    depositPad.Name = "DepositPad"
    depositPad.Size = Config.DepositPadSize
    depositPad.Position = basePlatform.Position + Vector3.new(0, basePlatform.Size.Y / 2 + 0.6, -24)
    depositPad.Anchored = true
    depositPad.Material = Enum.Material.Neon
    depositPad.Color = Color3.fromRGB(255, 215, 79)
    depositPad.TopSurface = Enum.SurfaceType.Smooth
    depositPad.BottomSurface = Enum.SurfaceType.Smooth
    depositPad.Parent = mapFolder

    createBillboard(depositPad, "Deposit", "Convert shards into Energy here")

    local upgradePedestal = createUICorneredPart(
        "UpgradePedestal",
        Vector3.new(16, 1.2, 16),
        basePlatform.Position + Vector3.new(0, basePlatform.Size.Y / 2 + 0.6, 26),
        Enum.Material.Metal,
        Color3.fromRGB(78, 88, 142),
        mapFolder
    )

    createBillboard(upgradePedestal, "Upgrades", "Use the UI to purchase upgrades")

    local teleporterRing = createUICorneredPart(
        "TeleporterRing",
        Vector3.new(70, 1.2, 70),
        basePlatform.Position + Vector3.new(0, basePlatform.Size.Y / 2 + 0.4, 0),
        Enum.Material.ForceField,
        Color3.fromRGB(137, 155, 255),
        mapFolder
    )
    teleporterRing.Transparency = 0.25

    for index = 1, 6 do
        local angle = math.rad((index - 1) * 60)
        local radius = 36
        local height = teleporterRing.Position.Y + 10 + rng:NextNumber(-2, 4)
        local position = teleporterRing.Position + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
        createHoverCrystal(mapFolder, position, Color3.fromRGB(140, 198, 255))
    end

    local teleporterPads = {}
    local returnPads = {}
    local zonePlatforms = {}
    local orbContainers = {}

    for index, zoneConfig in ipairs(Config.Zones) do
        local zoneFolder = Instance.new("Folder")
        zoneFolder.Name = string.format("Zone_%d", index)
        zoneFolder.Parent = zonesFolder

        local zonePart
        if index == 1 then
            zonePart = basePlatform
        else
            zonePart = Instance.new("Part")
            zonePart.Name = zoneConfig.Name:gsub(" ", "") .. "Platform"
            zonePart.Size = Config.ZoneSize + Vector3.new(0, 1, 0)
            local height = (zoneConfig.Height or 0)
            zonePart.Position = Vector3.new((index - 1) * Config.ZoneSpacing, Config.ZoneY + height, 0)
            zonePart.Anchored = true
            zonePart.Material = zoneConfig.TerrainMaterial or Enum.Material.SmoothPlastic
            zonePart.Color = zoneConfig.TerrainColor or zoneConfig.OrbColor:lerp(Color3.fromRGB(40, 40, 40), 0.5)
            zonePart.TopSurface = Enum.SurfaceType.Smooth
            zonePart.BottomSurface = Enum.SurfaceType.Smooth
            zonePart.Parent = zoneFolder

            local trim = Instance.new("Part")
            trim.Name = "ZoneTrim"
            trim.Size = zonePart.Size + Vector3.new(12, 0.6, 12)
            trim.Position = zonePart.Position + Vector3.new(0, -zonePart.Size.Y / 2 + 0.3, 0)
            trim.Anchored = true
            trim.Material = Enum.Material.Slate
            trim.Color = (zoneConfig.AccentColor or zoneConfig.OrbColor):lerp(Color3.fromRGB(20, 20, 20), 0.3)
            trim.Parent = zoneFolder

            decorateZone(zoneFolder, zonePart, zoneConfig)
        end
        zonePlatforms[index] = zonePart

        local orbFolder = Instance.new("Folder")
        orbFolder.Name = "Orbs"
        orbFolder.Parent = zoneFolder
        orbContainers[index] = orbFolder

        if index > 1 then
            local portal = Instance.new("Part")
            portal.Name = zoneConfig.Name:gsub(" ", "") .. "Portal"
            portal.Size = Config.TeleportPadSize + Vector3.new(4, 0, 4)
            portal.Anchored = true
            portal.CanCollide = false
            portal.Material = Enum.Material.Neon
            portal.Color = zoneConfig.AccentColor or zoneConfig.OrbColor
            local angle = math.rad((index - 2) * (360 / math.max(1, (#Config.Zones - 1))))
            local radius = 32
            portal.Position = teleporterRing.Position + Vector3.new(math.cos(angle) * radius, 0.8, math.sin(angle) * radius)
            portal.Parent = teleporterFolder

            local swirl = Instance.new("ParticleEmitter")
            swirl.LightEmission = 1
            swirl.Speed = NumberRange.new(2, 4)
            swirl.Lifetime = NumberRange.new(0.6, 0.8)
            swirl.Rate = 40
            swirl.Rotation = NumberRange.new(0, 360)
            swirl.Color = ColorSequence.new(zoneConfig.AccentColor or zoneConfig.OrbColor)
            swirl.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.2, 3.4),
                NumberSequenceKeypoint.new(1, 0)
            })
            swirl.Parent = portal

            createBillboard(portal, zoneConfig.Name, string.format("Unlock for %d Energy", zoneConfig.UnlockCost))
            teleporterPads[index] = portal
        end

        local returnPad = Instance.new("Part")
        returnPad.Name = zoneConfig.Name:gsub(" ", "") .. "ReturnPad"
        returnPad.Size = Config.TeleportPadSize
        local offsetX = -Config.ZoneSize.X / 2 + 14
        local offsetZ = Config.ZoneSize.Z / 2 - 14
        returnPad.Position = zonePart.Position + Vector3.new(offsetX, zonePart.Size.Y / 2 + 0.6, offsetZ)
        returnPad.Anchored = true
        returnPad.CanCollide = false
        returnPad.Material = Enum.Material.Neon
        returnPad.Color = Color3.fromRGB(255, 255, 255)
        returnPad.Parent = zoneFolder
        createBillboard(returnPad, "Return", "Step to teleport back")
        returnPads[index] = returnPad
    end

    return {
        MapFolder = mapFolder,
        DepositPad = depositPad,
        TeleporterPads = teleporterPads,
        ReturnPads = returnPads,
        ZonePlatforms = zonePlatforms,
        OrbContainers = orbContainers
    }
end

return MapBuilder
