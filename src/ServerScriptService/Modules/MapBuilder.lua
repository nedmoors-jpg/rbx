local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapBuilder = {}

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

    local basePlatform = Instance.new("Part")
    basePlatform.Name = "BasePlatform"
    basePlatform.Size = Config.ZoneSize
    basePlatform.Position = Vector3.new(0, Config.ZoneY, 0)
    basePlatform.Anchored = true
    basePlatform.Material = Enum.Material.Grass
    basePlatform.Color = Color3.fromRGB(51, 120, 51)
    basePlatform.Parent = mapFolder

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
    teleporterRing.Size = Vector3.new(70, 1, 70)
    teleporterRing.Position = basePlatform.Position + Vector3.new(0, 0.6, 0)
    teleporterRing.Anchored = true
    teleporterRing.Transparency = 0.6
    teleporterRing.Color = Color3.fromRGB(137, 155, 255)
    teleporterRing.Material = Enum.Material.ForceField
    teleporterRing.Parent = mapFolder

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
            zonePart.Size = Config.ZoneSize
            zonePart.Position = Vector3.new((index - 1) * Config.ZoneSpacing, Config.ZoneY, 0)
            zonePart.Anchored = true
            zonePart.Material = Enum.Material.SmoothPlastic
            zonePart.Color = zoneConfig.OrbColor:lerp(Color3.fromRGB(40, 40, 40), 0.5)
            zonePart.Parent = zoneFolder
        end
        zonePlatforms[index] = zonePart

        local orbFolder = Instance.new("Folder")
        orbFolder.Name = "Orbs"
        orbFolder.Parent = zoneFolder
        orbContainers[index] = orbFolder

        if index > 1 then
            local portal = Instance.new("Part")
            portal.Name = zoneConfig.Name:gsub(" ", "") .. "Portal"
            portal.Size = Config.TeleportPadSize
            portal.Anchored = true
            portal.CanCollide = false
            portal.Material = Enum.Material.Neon
            portal.Color = zoneConfig.OrbColor
            local angle = math.rad((index - 2) * (360 / math.max(1, (#Config.Zones - 1))))
            local radius = 32
            portal.Position = teleporterRing.Position + Vector3.new(math.cos(angle) * radius, 0.6, math.sin(angle) * radius)
            portal.Parent = teleporterFolder
            createBillboard(portal, zoneConfig.Name, string.format("Unlock for %d Energy", zoneConfig.UnlockCost))
            teleporterPads[index] = portal
        end

        local returnPad = Instance.new("Part")
        returnPad.Name = zoneConfig.Name:gsub(" ", "") .. "ReturnPad"
        returnPad.Size = Config.TeleportPadSize
        local offsetX = -Config.ZoneSize.X / 2 + 14
        local offsetZ = Config.ZoneSize.Z / 2 - 14
        returnPad.Position = zonePart.Position + Vector3.new(offsetX, 0.6, offsetZ)
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
