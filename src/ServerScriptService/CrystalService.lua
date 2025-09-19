local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Signal)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local CrystalService = {}
CrystalService.__index = CrystalService

function CrystalService.new(mapFolder, remotes)
    local self = setmetatable({}, CrystalService)
    self.MapFolder = mapFolder
    self.Config = GameConfig
    self.Remotes = remotes
    self.ActiveCrystals = {}
    self.CrystalCollected = Signal.new()

    self:Initialise()
    return self
end

local function createCrystal(position, color)
    local crystal = Instance.new("Part")
    crystal.Name = "Crystal"
    crystal.Shape = Enum.PartType.Ball
    crystal.Size = Vector3.new(2.6, 2.6, 2.6)
    crystal.Material = Enum.Material.Neon
    crystal.Color = color
    crystal.Anchored = true
    crystal.CanCollide = false
    crystal.Position = position

    local attachment = Instance.new("Attachment")
    attachment.Parent = crystal

    local glow = Instance.new("ParticleEmitter")
    glow.Texture = "rbxassetid://241750570"
    glow.Color = ColorSequence.new(color)
    glow.Rate = 18
    glow.Speed = NumberRange.new(0.5, 1.4)
    glow.Lifetime = NumberRange.new(1.5, 2)
    glow.SpreadAngle = Vector2.new(16, 16)
    glow.Parent = attachment

    local sparkle = Instance.new("ParticleEmitter")
    sparkle.Texture = "rbxassetid://296874871"
    sparkle.Color = ColorSequence.new(color)
    sparkle.Rate = 10
    sparkle.Speed = NumberRange.new(4, 6)
    sparkle.Lifetime = NumberRange.new(0.3, 0.5)
    sparkle.SpreadAngle = Vector2.new(60, 60)
    sparkle.Parent = attachment

    return crystal
end

function CrystalService:Initialise()
    local colorPalette = {
        Color3.fromRGB(0, 255, 220),
        Color3.fromRGB(145, 50, 255),
        Color3.fromRGB(255, 0, 128),
        Color3.fromRGB(255, 140, 0)
    }

    local spawnPositions = self.Config.CrystalSpawnPositions
    for index = 1, self.Config.CrystalCount do
        local position = spawnPositions[(index - 1) % #spawnPositions + 1]
        local color = colorPalette[(index - 1) % #colorPalette + 1]
        self:CreateCrystalAt(position, color)
    end
end

function CrystalService:CreateCrystalAt(position, color)
    local crystal = createCrystal(position, color)
    crystal.Parent = self.MapFolder
    CollectionService:AddTag(crystal, "Crystal")

    local connection
    connection = crystal.Touched:Connect(function(hit)
        local character = hit.Parent
        if not character then
            return
        end

        local player = Players:GetPlayerFromCharacter(character)
        if not player then
            return
        end

        connection:Disconnect()
        self:OnCrystalCollected(player, crystal)
    end)

    self.ActiveCrystals[crystal] = connection
end

function CrystalService:OnCrystalCollected(player, crystal)
    self.ActiveCrystals[crystal] = nil

    crystal.Anchored = false
    crystal.CanCollide = false
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 25, 0)
    bodyVelocity.Parent = crystal
    Debris:AddItem(bodyVelocity, 0.35)

    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Texture = "rbxassetid://241750570"
    sparkles.Color = ColorSequence.new(crystal.Color)
    sparkles.Lifetime = NumberRange.new(0.4, 0.6)
    sparkles.Speed = NumberRange.new(12, 16)
    sparkles.Rate = 90
    sparkles.SpreadAngle = Vector2.new(60, 60)
    sparkles.Parent = crystal

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://12221944"
    sound.Volume = 2
    sound.PlayOnRemove = true
    sound.Parent = crystal
    sound:Destroy()

    Debris:AddItem(crystal, 1)
    self.Remotes.CrystalPickup:FireClient(player, self.Config.CrystalValue)
    self.CrystalCollected:Fire(player, self.Config.CrystalValue)

    task.delay(self.Config.CrystalRespawnTime, function()
        local spawnPositions = self.Config.CrystalSpawnPositions
        local position = spawnPositions[math.random(1, #spawnPositions)]
        local colorPalette = {
            Color3.fromRGB(0, 255, 220),
            Color3.fromRGB(145, 50, 255),
            Color3.fromRGB(255, 0, 128),
            Color3.fromRGB(255, 140, 0)
        }
        self:CreateCrystalAt(position, colorPalette[math.random(1, #colorPalette)])
    end)
end

function CrystalService:Reset()
    for crystal, connection in pairs(self.ActiveCrystals) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
        crystal:Destroy()
    end
    table.clear(self.ActiveCrystals)
    self:Initialise()
end

return CrystalService

