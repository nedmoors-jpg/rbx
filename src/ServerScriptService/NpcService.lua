local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local NpcService = {}
NpcService.__index = NpcService

local function createLimb(name, size, color, parent)
    local limb = Instance.new("Part")
    limb.Name = name
    limb.Size = size
    limb.Material = Enum.Material.Slate
    limb.Color = color
    limb.Parent = parent
    return limb
end

local function createGolemModel()
    local model = Instance.new("Model")
    model.Name = "StoneGolem"

    local root = createLimb("HumanoidRootPart", Vector3.new(3, 3, 2), Color3.fromRGB(105, 105, 105), model)
    root.Anchored = false

    local torso = createLimb("Torso", Vector3.new(3, 3.5, 2.4), Color3.fromRGB(99, 95, 89), model)
    torso.Anchored = false

    local neck = Instance.new("Motor6D")
    neck.Part0 = torso
    neck.Part1 = root
    neck.Parent = torso

    local head = createLimb("Head", Vector3.new(2.4, 2.2, 2.2), Color3.fromRGB(130, 130, 130), model)
    head.Anchored = false
    local face = Instance.new("Decal")
    face.Texture = "rbxassetid://7074864"
    face.Parent = head

    local leftArm = createLimb("LeftArm", Vector3.new(1.6, 3.2, 1.6), Color3.fromRGB(120, 120, 120), model)
    local rightArm = createLimb("RightArm", Vector3.new(1.6, 3.2, 1.6), Color3.fromRGB(120, 120, 120), model)
    local leftLeg = createLimb("LeftLeg", Vector3.new(1.6, 3.2, 1.6), Color3.fromRGB(90, 90, 90), model)
    local rightLeg = createLimb("RightLeg", Vector3.new(1.6, 3.2, 1.6), Color3.fromRGB(90, 90, 90), model)

    local function weld(part, offset)
        local weldConstraint = Instance.new("WeldConstraint")
        weldConstraint.Part0 = torso
        weldConstraint.Part1 = part
        weldConstraint.Parent = part
        part.CFrame = torso.CFrame * CFrame.new(offset)
    end

    weld(head, Vector3.new(0, 2.8, 0))
    weld(leftArm, Vector3.new(-2, 0.1, 0))
    weld(rightArm, Vector3.new(2, 0.1, 0))
    weld(leftLeg, Vector3.new(-1, -3.2, 0))
    weld(rightLeg, Vector3.new(1, -3.2, 0))

    torso.CFrame = CFrame.new(0, 0, 0)
    root.CFrame = torso.CFrame * CFrame.new(0, -1.8, 0)

    local rootWeld = Instance.new("WeldConstraint")
    rootWeld.Part0 = torso
    rootWeld.Part1 = root
    rootWeld.Parent = torso

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayName = "Stone Golem"
    humanoid.Health = 120
    humanoid.MaxHealth = 120
    humanoid.WalkSpeed = GameConfig.EnemySpeed
    humanoid.Parent = model

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 180, 120)
    light.Brightness = 1.6
    light.Range = 16
    light.Parent = head

    return model, humanoid, root, torso
end

function NpcService.new(mapFolder, remotes)
    local self = setmetatable({}, NpcService)
    self.Config = GameConfig
    self.Remotes = remotes
    self.MapFolder = mapFolder
    self.ActiveNpcs = {}
    return self
end

local function getClosestCharacter(root)
    local closestCharacter
    local closestDistance
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local distance = (hrp.Position - root.Position).Magnitude
            if not closestDistance or distance < closestDistance then
                closestDistance = distance
                closestCharacter = character
            end
        end
    end
    return closestCharacter
end

function NpcService:SpawnEnemy(spawnPosition)
    if #self.ActiveNpcs >= self.Config.MaxEnemies then
        return
    end

    local model, humanoid, root, torso = createGolemModel()
    model.Parent = workspace
    model:PivotTo(CFrame.new(spawnPosition))

    local connections = {}

    local function disconnectAll()
        for _, connection in ipairs(connections) do
            if connection.Connected then
                connection:Disconnect()
            end
        end
    end

    local function onDied()
        self:OnNpcDefeated(model, disconnectAll)
    end

    table.insert(connections, humanoid.Died:Connect(onDied))

    local lastPathCompute = 0
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if humanoid.Health <= 0 then
            return
        end

        local targetCharacter = getClosestCharacter(root)
        if not targetCharacter then
            humanoid:MoveTo(root.Position)
            return
        end

        if os.clock() - lastPathCompute > 1.2 then
            lastPathCompute = os.clock()
            local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
            if not targetRoot then
                return
            end

            local path = PathfindingService:CreatePath({
                AgentRadius = 3,
                AgentHeight = 5,
                AgentCanJump = true,
            })
            path:ComputeAsync(root.Position, targetRoot.Position)
            local waypoints = path:GetWaypoints()
            if waypoints and #waypoints > 1 then
                humanoid:MoveTo(waypoints[2].Position)
            elseif targetRoot then
                humanoid:MoveTo(targetRoot.Position)
            end
        end
    end))

    local function onTouch(part)
        local character = part.Parent
        if not character then
            return
        end

        local player = Players:GetPlayerFromCharacter(character)
        if not player then
            return
        end

        local targetHumanoid = character:FindFirstChildOfClass("Humanoid")
        if targetHumanoid and targetHumanoid.Health > 0 then
            targetHumanoid:TakeDamage(self.Config.EnemyDamage)
        end
    end

    table.insert(connections, root.Touched:Connect(onTouch))
    table.insert(connections, torso.Touched:Connect(onTouch))

    table.insert(self.ActiveNpcs, {
        Model = model,
        Humanoid = humanoid,
        Root = root,
        Connections = connections,
    })

    self.Remotes.Announcement:FireAllClients("A stone golem awakens!")
end

function NpcService:OnNpcDefeated(model, disconnectAll)
    for index, npc in ipairs(self.ActiveNpcs) do
        if npc.Model == model then
            if disconnectAll then
                disconnectAll()
            end

            for _, connection in ipairs(npc.Connections) do
                if connection.Connected then
                    connection:Disconnect()
                end
            end

            local crumble = Instance.new("ParticleEmitter")
            crumble.Texture = "rbxassetid://542909274"
            crumble.Color = ColorSequence.new(Color3.fromRGB(125, 125, 125))
            crumble.Speed = NumberRange.new(14, 18)
            crumble.Lifetime = NumberRange.new(0.5, 0.8)
            crumble.Rate = 100
            crumble.SpreadAngle = Vector2.new(120, 120)
            crumble.Parent = model:FindFirstChild("HumanoidRootPart") or model

            Debris:AddItem(model, 2)
            table.remove(self.ActiveNpcs, index)
            break
        end
    end
end

function NpcService:Reset()
    for _, npc in ipairs(self.ActiveNpcs) do
        for _, connection in ipairs(npc.Connections) do
            if connection.Connected then
                connection:Disconnect()
            end
        end
        if npc.Model then
            npc.Model:Destroy()
        end
    end
    table.clear(self.ActiveNpcs)
end

return NpcService

