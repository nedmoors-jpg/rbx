local TweenService = game:GetService("TweenService")

local MapBuilder = {}
MapBuilder.__index = MapBuilder

local function createPart(properties, parent)
    local part = Instance.new("Part")
    for key, value in pairs(properties) do
        part[key] = value
    end
    part.Parent = parent
    return part
end

local function createCrystalLight(parent, color)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = 20
    light.Brightness = 2.6
    light.Parent = parent

    local tween = TweenService:Create(light, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Brightness = 4.2,
        Range = 28,
    })
    tween:Play()
    return light
end

function MapBuilder.new(root, config)
    local self = setmetatable({}, MapBuilder)
    self.Root = Instance.new("Folder")
    self.Root.Name = "CrystalCavern"
    self.Root.Parent = root
    self.Config = config

    self:_createEnvironment()
    self:_createCrystals()
    self:_createWaterfalls()
    self:_createAmbientSound()
    return self
end

function MapBuilder:_createEnvironment()
    local cavern = self.Root

    createPart({
        Name = "CavernFloor",
        Size = Vector3.new(240, 4, 240),
        Position = Vector3.new(0, -4, 0),
        Anchored = true,
        Material = Enum.Material.Rock,
        BrickColor = BrickColor.new("Black")
    }, cavern)

    createPart({
        Name = "CentralDias",
        Size = Vector3.new(34, 2, 34),
        Position = Vector3.new(0, 3, 0),
        Anchored = true,
        Material = Enum.Material.Slate,
        BrickColor = BrickColor.new("Dark stone grey")
    }, cavern)

    for index, spawnPosition in ipairs(self.Config.SpawnLocations) do
        createPart({
            Name = ("SpawnPad%02d"):format(index),
            Size = Vector3.new(12, 1, 12),
            Position = spawnPosition + Vector3.new(0, -2.5, 0),
            Anchored = true,
            Material = Enum.Material.Neon,
            Color = Color3.fromRGB(60, 140, 255),
            Transparency = 0.25
        }, cavern)
    end

    local function createCliffRing(radius, height, variation, segments)
        for i = 1, segments do
            local theta = (i / segments) * math.pi * 2
            local offset = variation * (math.noise(i * 0.2, theta) * 0.5)
            local size = Vector3.new(16 + offset, height + math.random(-4, 4), 6 + variation * 0.25)
            local position = Vector3.new(math.cos(theta) * radius, size.Y / 2, math.sin(theta) * radius)

            createPart({
                Name = "CavernWall",
                Size = size,
                Position = position,
                Anchored = true,
                Material = Enum.Material.Slate,
                Color = Color3.fromRGB(50, 50, 50)
            }, cavern)
        end
    end

    createCliffRing(120, 60, 6, 28)
    createCliffRing(60, 40, 12, 16)

    local mist = Instance.new("ParticleEmitter")
    mist.Name = "AmbientMist"
    mist.Color = ColorSequence.new(Color3.fromRGB(120, 155, 255))
    mist.LightEmission = 0.7
    mist.Lifetime = NumberRange.new(8, 12)
    mist.Rate = 30
    mist.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 4),
        NumberSequenceKeypoint.new(0.5, 16),
        NumberSequenceKeypoint.new(1, 4)
    })
    mist.Speed = NumberRange.new(1, 2)
    mist.SpreadAngle = Vector2.new(15, 15)
    mist.Parent = cavern:FindFirstChild("CentralDias")
end

function MapBuilder:_createCrystals()
    local cavern = self.Root
    local colorPalette = {
        Color3.fromRGB(0, 255, 220),
        Color3.fromRGB(145, 50, 255),
        Color3.fromRGB(255, 0, 128),
        Color3.fromRGB(255, 140, 0)
    }

    for _, position in ipairs(self.Config.CrystalSpawnPositions) do
        local crystal = Instance.new("Part")
        crystal.Name = "CrystalMarker"
        crystal.Material = Enum.Material.Neon
        crystal.Color = colorPalette[math.random(1, #colorPalette)]
        crystal.Anchored = true
        crystal.CanCollide = false
        crystal.Shape = Enum.PartType.Ball
        crystal.Size = Vector3.new(2, 2, 2)
        crystal.Position = position
        crystal.Transparency = 0.6
        crystal.Parent = cavern

        createCrystalLight(crystal, crystal.Color)
    end
end

function MapBuilder:_createWaterfalls()
    local cavern = self.Root
    for index = 1, 4 do
        local wall = Instance.new("Part")
        wall.Name = "WaterfallBase" .. index
        wall.Size = Vector3.new(8, 40, 1)
        wall.Anchored = true
        wall.CanCollide = false
        wall.Material = Enum.Material.Glass
        wall.Color = Color3.fromRGB(80, 150, 255)
        wall.Transparency = 0.35

        local angle = (index / 4) * math.pi * 2
        wall.CFrame = CFrame.new(math.cos(angle) * 85, 18, math.sin(angle) * 85)
        wall.Parent = cavern

        local waterEffect = Instance.new("ParticleEmitter")
        waterEffect.Color = ColorSequence.new(Color3.fromRGB(120, 180, 255))
        waterEffect.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        waterEffect.Lifetime = NumberRange.new(1.8, 2.2)
        waterEffect.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 2),
            NumberSequenceKeypoint.new(0.6, 5),
            NumberSequenceKeypoint.new(1, 0)
        })
        waterEffect.Speed = NumberRange.new(12, 16)
        waterEffect.Rotation = NumberRange.new(0, 360)
        waterEffect.LightInfluence = 0.4
        waterEffect.Rate = 35
        waterEffect.Parent = wall
    end
end

function MapBuilder:_createAmbientSound()
    local ambience = Instance.new("Sound")
    ambience.Name = "CavernAmbience"
    ambience.SoundId = "rbxassetid://9127405931"
    ambience.Volume = 0.4
    ambience.Looped = true
    ambience.RollOffMaxDistance = 200
    ambience.Parent = self.Root
    ambience:Play()

    local drip = Instance.new("Sound")
    drip.Name = "WaterDrip"
    drip.SoundId = "rbxassetid://9127240297"
    drip.Volume = 0.25
    drip.Looped = true
    drip.PlaybackSpeed = 0.8
    drip.RollOffMaxDistance = 120
    drip.Parent = self.Root
    drip:Play()
end

return MapBuilder


