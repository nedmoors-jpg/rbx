local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Signal)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local GameService = {}
GameService.__index = GameService

function GameService.new(mapBuilder, crystalService, npcService, remotes)
    local self = setmetatable({}, GameService)
    self.MapBuilder = mapBuilder
    self.CrystalService = crystalService
    self.NpcService = npcService
    self.Remotes = remotes
    self.Config = GameConfig

    self.StateChanged = Signal.new()
    self.TimerTick = Signal.new()
    self.ScoreChanged = Signal.new()

    self._currentState = "Lobby"
    self._timeRemaining = self.Config.LobbyDuration
    self._leaderboard = {}

    return self
end

function GameService:Start()
    self:ConfigureLighting()
    self:BindPlayerEvents()
    task.spawn(function()
        while true do
            self:RunLobby()
            self:RunRound()
            self:RunPostRound()
        end
    end)
end

function GameService:ConfigureLighting()
    Lighting.ClockTime = 22
    Lighting.Brightness = 1.8
    Lighting.Ambient = self.Config.AmbientLight
    Lighting.FogEnd = self.Config.FogEnd
    Lighting.FogStart = 80
    Lighting.FogColor = self.Config.FogColor
end

function GameService:BindPlayerEvents()
    Players.PlayerAdded:Connect(function(player)
        local leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player

        local score = Instance.new("IntValue")
        score.Name = "Crystals"
        score.Value = 0
        score.Parent = leaderstats

        player.CharacterAdded:Connect(function(character)
            self:PositionPlayer(character, player)
        end)

        task.defer(function()
            self:BroadcastScores()
        end)
    end)

    Players.PlayerRemoving:Connect(function()
        task.defer(function()
            self:BroadcastScores()
        end)
    end)
end

function GameService:PositionPlayer(character, player)
    if not character then
        return
    end

    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not root then
        return
    end

    local spawnLocations = self.Config.SpawnLocations
    local spawnIndex = (player.UserId % #spawnLocations) + 1
    root.CFrame = CFrame.new(spawnLocations[spawnIndex]) + Vector3.new(0, 3, 0)
end

function GameService:ResetScores()
    self._leaderboard = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local score = leaderstats:FindFirstChild("Crystals")
            if score then
                score.Value = 0
            end
        end
    end
    self:BroadcastScores()
end

function GameService:GetScoreboard()
    local scoreboard = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local leaderstats = player:FindFirstChild("leaderstats")
        local scoreValue = leaderstats and leaderstats:FindFirstChild("Crystals")
        table.insert(scoreboard, {
            name = player.DisplayName or player.Name,
            score = scoreValue and scoreValue.Value or 0,
            userId = player.UserId,
        })
    end

    table.sort(scoreboard, function(a, b)
        return a.score > b.score
    end)

    return scoreboard
end

function GameService:BroadcastScores()
    local scoreboard = self:GetScoreboard()
    self.Remotes.ScoreUpdate:FireAllClients(scoreboard)
    self.ScoreChanged:Fire(scoreboard)
end

function GameService:RunLobby()
    self._currentState = "Lobby"
    self._timeRemaining = self.Config.LobbyDuration
    self.StateChanged:Fire(self._currentState)
    self.Remotes.Announcement:FireAllClients("Gather your courage. A new delve begins soon!")
    self:ResetScores()

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            self:PositionPlayer(player.Character, player)
        end
    end

    self:RunTimer(self.Config.LobbyDuration)
end

function GameService:RunTimer(duration)
    self._timeRemaining = duration
    for remaining = duration, 0, -1 do
        self._timeRemaining = remaining
        self.TimerTick:Fire(remaining)
        self.Remotes.TimerUpdate:FireAllClients(remaining)
        if remaining <= 0 then
            break
        end
        task.wait(1)
    end
end

function GameService:RunRound()
    self._currentState = "Round"
    self.StateChanged:Fire(self._currentState)
    self.Remotes.Announcement:FireAllClients("Crystals have emerged. Collect them and beware the golems!")

    self.CrystalService:Reset()
    self.NpcService:Reset()

    local enemySpawnIndex = 1
    local spawnPositions = self.Config.EnemySpawnPositions

    task.delay(self.Config.EnemySpawnDelay, function()
        if self._currentState ~= "Round" then
            return
        end
        self.NpcService:SpawnEnemy(spawnPositions[enemySpawnIndex])
        enemySpawnIndex = enemySpawnIndex % #spawnPositions + 1
    end)

    local crystalConnection = self.CrystalService.CrystalCollected:Connect(function(player, points)
        self:AddScore(player, points)
    end)

    task.spawn(function()
        while self._currentState == "Round" do
            task.wait(self.Config.EnemySpawnInterval)
            self.NpcService:SpawnEnemy(spawnPositions[enemySpawnIndex])
            enemySpawnIndex = enemySpawnIndex % #spawnPositions + 1
        end
    end)

    self:RunTimer(self.Config.RoundDuration)

    crystalConnection:Disconnect()
    self.NpcService:Reset()
    self._currentState = "PostRound"
end

function GameService:RunPostRound()
    local winner = self:DetermineWinner()
    if winner then
        self.Remotes.Announcement:FireAllClients(winner .. " claimed the crystal crown!")
    else
        self.Remotes.Announcement:FireAllClients("The cavern falls silent. No victor this time.")
    end

    self:RunTimer(self.Config.PostRoundDuration)
end

function GameService:AddScore(player, amount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end

    local scoreValue = leaderstats:FindFirstChild("Crystals")
    if not scoreValue then
        return
    end

    scoreValue.Value += amount
    self:BroadcastScores()
end

function GameService:DetermineWinner()
    local topPlayer
    for _, player in ipairs(Players:GetPlayers()) do
        local leaderstats = player:FindFirstChild("leaderstats")
        local scoreValue = leaderstats and leaderstats:FindFirstChild("Crystals")
        if scoreValue then
            if not topPlayer or scoreValue.Value > topPlayer.score then
                topPlayer = {
                    player = player,
                    score = scoreValue.Value
                }
            end
        end
    end

    if topPlayer and topPlayer.score > 0 then
        return topPlayer.player.DisplayName or topPlayer.player.Name
    end
end

return GameService





