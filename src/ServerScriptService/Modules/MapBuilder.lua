local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapBuilder = {}

local rng = Random.new()
local TWO_PI = math.pi * 2

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

local function applyZoneTheme(part, zoneConfig)
    local theme = zoneConfig.Theme
    if theme then
        if theme.GroundMaterial then
            part.Material = theme.GroundMaterial
        end
        if theme.GroundColor then
            part.Color = theme.GroundColor
        end
    else
        part.Material = Enum.Material.SmoothPlastic
        part.Color = zoneConfig.OrbColor:lerp(Color3.fromRGB(40, 40, 40), 0.45)
    end
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
end

local function addRingEffects(ringPart)
    local attachment = Instance.new("Attachment")
    attachment.Name = "RingAttachment"
    attachment.Parent = ringPart

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "RingEmitter"
    emitter.Color = ColorSequence.new(Color3.fromRGB(117, 255, 239), Color3.fromRGB(82, 148, 255))
    emitter.Lifetime = NumberRange.new(1.2, 1.6)
    emitter.Rate = 18
    emitter.Speed = NumberRange.new(2, 4)
    emitter.VelocityInheritance = 0.1
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.6),
        NumberSequenceKeypoint.new(0.6, 0.3),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Parent = attachment
end

local function decorateDepositPad(depositPad)
    local light = Instance.new("PointLight")
    light.Color = depositPad.Color
    light.Range = 16
    light.Brightness = 1.6
    light.Parent = depositPad

    local attachment = Instance.new("Attachment")
    attachment.Name = "DepositFX"
    attachment.Parent = depositPad

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "DepositEmitter"
    emitter.Color = ColorSequence.new(depositPad.Color, Color3.fromRGB(255, 255, 255))
    emitter.Lifetime = NumberRange.new(0.8, 1.2)
    emitter.Rate = 24
    emitter.Speed = NumberRange.new(2, 5)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.4),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Parent = attachment
end

local function createCenterpiece(mapFolder, basePlatform)
    local beacon = Instance.new("Part")
    beacon.Name = "CentralBeacon"
    beacon.Anchored = true
    beacon.CanCollide = false
    beacon.Material = Enum.Material.Neon
    beacon.Color = Color3.fromRGB(117, 255, 239)
    beacon.Size = Vector3.new(4, 18, 4)
    beacon.CFrame = CFrame.new(basePlatform.Position + Vector3.new(0, beacon.Size.Y / 2 + 0.5, 0))
    beacon.Parent = mapFolder

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Cylinder
    mesh.Scale = Vector3.new(0.7, 1, 0.7)
    mesh.Parent = beacon

    local light = Instance.new("PointLight")
    light.Color = beacon.Color
    light.Range = 22
    light.Brightness = 2.2
    light.Parent = beacon

    local attachment = Instance.new("Attachment")
    attachment.Parent = beacon

    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new(beacon.Color, Color3.fromRGB(255, 255, 255))
    emitter.Lifetime = NumberRange.new(1.2, 1.5)
    emitter.Rate = 28
    emitter.Speed = NumberRange.new(1, 3)
    emitter.SpreadAngle = Vector2.new(15, 15)
    emitter.Parent = attachment
end

local function createPortalEffect(portalPart, color)
    local attachment = Instance.new("Attachment")
    attachment.Name = "PortalAttachment"
    attachment.Parent = portalPart

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "PortalEmitter"
    emitter.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
    emitter.Lifetime = NumberRange.new(0.8, 1.3)
    emitter.Rate = 30
    emitter.Speed = NumberRange.new(4, 7)
    emitter.SpreadAngle = Vector2.new(25, 25)
    emitter.LightEmission = 0.3
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.2),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Parent = attachment

    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 2
    light.Range = 14
    light.Parent = portalPart
end

local function chooseDecorOffset(basePosition, zonePart)
    local baseDirection = zonePart.Position - basePosition
    local baseUnit

    if baseDirection.Magnitude > 0 then
        baseUnit = baseDirection.Unit
    end

    for _ = 1, 8 do
        local angle = rng:NextNumber(0, TWO_PI)
        local minRadius = Config.ZoneSize.X * 0.2
        local maxRadius = Config.ZoneSize.X * 0.48
        local distance = rng:NextNumber(minRadius, maxRadius)
        local offset = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)

        if not baseUnit then
            return offset
        end

        if offset.Magnitude > 0 then
            local dot = baseUnit:Dot(offset.Unit)
            if math.abs(dot) < 0.85 then
                return offset
            end
        end
    end

    return Vector3.new(0, 0, 0)
end

local function populateDecor(zoneFolder, zonePart, zoneConfig, basePosition)
    local theme = zoneConfig.Theme
    if not theme then
        return
    end

    local decorFolder = Instance.new("Folder")
    decorFolder.Name = "Decor"
    decorFolder.Parent = zoneFolder

    local count = theme.DecorCount or 6
    local heightRange = theme.DecorHeight or Vector2.new(7, 12)
    local radiusRange = theme.DecorRadius or Vector2.new(2, 4)

    for index = 1, count do
        local offset = chooseDecorOffset(basePosition, zonePart)
        local height = rng:NextNumber(heightRange.X, heightRange.Y)
        local radius = rng:NextNumber(radiusRange.X, radiusRange.Y)
        local position = zonePart.Position + offset + Vector3.new(0, height / 2 + 0.2, 0)

        local crystal = Instance.new("Part")
        crystal.Name = string.format("%sCrystal%d", zoneConfig.Name:gsub("%s", ""), index)
        crystal.Anchored = true
        crystal.CanCollide = false
        crystal.Material = theme.DecorMaterial or Enum.Material.Neon
        crystal.Color = theme.DecorColor or zoneConfig.OrbColor
        crystal.Size = Vector3.new(radius, height, radius)
        crystal.CFrame = CFrame.new(position)
        crystal.Parent = decorFolder

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Cone
        mesh.Scale = Vector3.new(0.6, 1, 0.6)
        mesh.Parent = crystal

        local light = Instance.new("PointLight")
        light.Color = crystal.Color
        light.Range = 12
        light.Brightness = 1.6
        light.Parent = crystal
    end
end

local function createWalkway(walkwayFolder, basePlatform, zonePart, zoneConfig)
    local direction = zonePart.Position - basePlatform.Position
    if direction.Magnitude < 1 then
        return
    end

    local theme = zoneConfig.Theme
    local walkwayHeight = 0.6
    local startOffset = math.min(basePlatform.Size.X / 2 - 6, Config.TeleporterRadius + 8)
    local endOffset = Config.ZoneSize.Z / 2 - 9
    local baseY = Config.ZoneY + walkwayHeight / 2
    local startPosition = Vector3.new(basePlatform.Position.X, baseY, basePlatform.Position.Z) + direction.Unit * startOffset
    local endPosition = Vector3.new(zonePart.Position.X, baseY, zonePart.Position.Z) - direction.Unit * endOffset
    local length = (endPosition - startPosition).Magnitude
    if length <= 2 then
        return
    end

    local walkway = Instance.new("Part")
    walkway.Name = zoneConfig.Name:gsub("%s", "") .. "Walkway"
    walkway.Anchored = true
    walkway.CanCollide = true
    walkway.Material = theme and (theme.AccentMaterial or Enum.Material.SmoothPlastic) or Enum.Material.SmoothPlastic
    walkway.Color = theme and (theme.AccentColor or zoneConfig.OrbColor) or zoneConfig.OrbColor
    walkway.Size = Vector3.new(Config.WalkwayWidth, walkwayHeight, length)
    walkway.CFrame = CFrame.lookAt((startPosition + endPosition) / 2, endPosition)
    walkway.TopSurface = Enum.SurfaceType.Smooth
    walkway.BottomSurface = Enum.SurfaceType.Smooth
    walkway.Parent = walkwayFolder

    local railColor = theme and (theme.AccentColor or zoneConfig.OrbColor) or zoneConfig.OrbColor
    for sign = -1, 1, 2 do
        local rail = Instance.new("Part")
        rail.Name = walkway.Name .. (sign > 0 and "RightRail" or "LeftRail")
        rail.Anchored = true
        rail.CanCollide = false
        rail.Material = theme and (theme.AccentMaterial or Enum.Material.Neon) or Enum.Material.Neon
        rail.Color = railColor
        rail.Size = Vector3.new(0.5, 1.2, length)
        rail.CFrame = walkway.CFrame * CFrame.new((Config.WalkwayWidth / 2 - 0.55) * sign, 0.9, 0)
        rail.Parent = walkwayFolder
    end
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

    local walkwayFolder = Instance.new("Folder")
    walkwayFolder.Name = "Walkways"
    walkwayFolder.Parent = mapFolder

    local basePlatform = Instance.new("Part")
    basePlatform.Name = "BasePlatform"
    basePlatform.Size = Config.ZoneSize
    basePlatform.Position = Vector3.new(0, Config.ZoneY, 0)
    basePlatform.Anchored = true
    basePlatform.Material = Enum.Material.Grass
    basePlatform.Color = Color3.fromRGB(51, 120, 51)
    basePlatform.TopSurface = Enum.SurfaceType.Smooth
    basePlatform.BottomSurface = Enum.SurfaceType.Smooth
    basePlatform.Parent = mapFolder
    applyZoneTheme(basePlatform, Config.Zones[1])

    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Name = "Spawn"
    spawnLocation.Size = Vector3.new(8, 1, 8)
    spawnLocation.Position = basePlatform.Position + Vector3.new(0, 1.05, 0)
    spawnLocation.Anchored = true
    spawnLocation.Neutral = true
    spawnLocation.Transparency = 1
    spawnLocation.CanCollide = false
    spawnLocation.Parent = mapFolder

    local depositPad = Instance.new("Part")
    depositPad.Name = "DepositPad"
    depositPad.Size = Config.DepositPadSize
    depositPad.Position = Config.DepositPosition
    depositPad.Anchored = true
    depositPad.Material = Enum.Material.Neon
    depositPad.Color = Color3.fromRGB(255, 215, 79)
    depositPad.TopSurface = Enum.SurfaceType.Smooth
    depositPad.BottomSurface = Enum.SurfaceType.Smooth
    depositPad.Parent = mapFolder
    decorateDepositPad(depositPad)

    createBillboard(depositPad, "Deposit", "Convert shards into Energy here")

    local upgradePedestal = Instance.new("Part")
    upgradePedestal.Name = "UpgradePedestal"
    upgradePedestal.Size = Vector3.new(12, 1, 12)
    upgradePedestal.Position = basePlatform.Position + Vector3.new(0, 0.6, 20)
    upgradePedestal.Anchored = true
    upgradePedestal.Material = Enum.Material.Metal
    upgradePedestal.Color = Color3.fromRGB(93, 93, 131)
    upgradePedestal.Parent = mapFolder

    createBillboard(upgradePedestal, "Upgrades", "Use the UI to purchase upgrades")

    local teleporterRing = Instance.new("Part")
    teleporterRing.Name = "TeleporterRing"
    teleporterRing.Size = Vector3.new(Config.TeleporterRadius * 2 + 14, 0.6, Config.TeleporterRadius * 2 + 14)
    teleporterRing.Position = basePlatform.Position + Vector3.new(0, 0.3, 0)
    teleporterRing.Anchored = true
    teleporterRing.Transparency = 0.45
    teleporterRing.Color = Color3.fromRGB(137, 155, 255)
    teleporterRing.Material = Enum.Material.ForceField
    teleporterRing.Parent = mapFolder
    addRingEffects(teleporterRing)

    createCenterpiece(mapFolder, basePlatform)

    local teleporterPads = {}
    local returnPads = {}
    local zonePlatforms = {}
    local orbContainers = {}

    local totalZones = #Config.Zones
    local teleporterRadius = Config.TeleporterRadius or 32
    local zoneRadius = Config.ZoneRingRadius or Config.ZoneSpacing or 220

    for index, zoneConfig in ipairs(Config.Zones) do
        local zoneFolder = Instance.new("Folder")
        zoneFolder.Name = string.format("Zone_%d", index)
        zoneFolder.Parent = zonesFolder

        local zonePart = basePlatform
        local zoneAngle

        if index > 1 then
            zonePart = Instance.new("Part")
            zonePart.Name = zoneConfig.Name:gsub(" ", "") .. "Platform"
            zonePart.Size = Config.ZoneSize
            zonePart.Anchored = true
            zoneAngle = math.rad((index - 2) * (360 / math.max(1, totalZones - 1)))
            local offset = Vector3.new(math.cos(zoneAngle) * zoneRadius, 0, math.sin(zoneAngle) * zoneRadius)
            zonePart.Position = basePlatform.Position + offset
            applyZoneTheme(zonePart, zoneConfig)
            zonePart.Parent = zoneFolder
        end

        zonePlatforms[index] = zonePart

        local orbFolder = Instance.new("Folder")
        orbFolder.Name = "Orbs"
        orbFolder.Parent = zoneFolder
        orbContainers[index] = orbFolder

        if index > 1 then
            populateDecor(zoneFolder, zonePart, zoneConfig, basePlatform.Position)
            createWalkway(walkwayFolder, basePlatform, zonePart, zoneConfig)

            local portal = Instance.new("Part")
            portal.Name = zoneConfig.Name:gsub(" ", "") .. "Portal"
            portal.Size = Config.TeleportPadSize
            portal.Anchored = true
            portal.CanCollide = false
            local theme = zoneConfig.Theme
            portal.Material = theme and (theme.AccentMaterial or Enum.Material.Neon) or Enum.Material.Neon
            portal.Color = theme and (theme.AccentColor or zoneConfig.OrbColor) or zoneConfig.OrbColor
            portal.Position = teleporterRing.Position + Vector3.new(math.cos(zoneAngle) * teleporterRadius, 0.4, math.sin(zoneAngle) * teleporterRadius)
            portal.Parent = teleporterFolder
            createBillboard(portal, zoneConfig.Name, string.format("Unlock for %d Energy", zoneConfig.UnlockCost))
            createPortalEffect(portal, portal.Color)
            teleporterPads[index] = portal
        end

        local returnPad = Instance.new("Part")
        returnPad.Name = zoneConfig.Name:gsub(" ", "") .. "ReturnPad"
        returnPad.Size = Config.TeleportPadSize
        returnPad.Anchored = true
        returnPad.CanCollide = false
        local theme = zoneConfig.Theme
        returnPad.Material = theme and (theme.AccentMaterial or Enum.Material.Neon) or Enum.Material.Neon
        returnPad.Color = theme and (theme.AccentColor or zoneConfig.OrbColor) or zoneConfig.OrbColor

        if index > 1 then
            local direction = zonePart.Position - basePlatform.Position
            local unit = direction.Unit
            local position = zonePart.Position - unit * (Config.ZoneSize.Z / 2 - 9) + Vector3.new(0, 0.6, 0)
            returnPad.CFrame = CFrame.new(position, basePlatform.Position + Vector3.new(0, 0.6, 0))
        else
            local offsetX = -Config.ZoneSize.X / 2 + 14
            local offsetZ = Config.ZoneSize.Z / 2 - 14
            returnPad.Position = zonePart.Position + Vector3.new(offsetX, 0.6, offsetZ)
        end

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
