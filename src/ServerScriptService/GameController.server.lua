local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapBuilder = require(ReplicatedStorage.Assets.MapBuilder)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local CrystalService = require(script.Parent.CrystalService)
local NpcService = require(script.Parent.NpcService)
local GameService = require(script.Parent.GameService)

local function ensureRemote(folder, className, name)
    local object = folder:FindFirstChild(name)
    if object and object:IsA(className) then
        return object
    end

    object = Instance.new(className)
    object.Name = name
    object.Parent = folder
    return object
end

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local remotes = {
    Announcement = ensureRemote(remotesFolder, "RemoteEvent", "Announcement"),
    TimerUpdate = ensureRemote(remotesFolder, "RemoteEvent", "TimerUpdate"),
    ScoreUpdate = ensureRemote(remotesFolder, "RemoteEvent", "ScoreUpdate"),
    RoundState = ensureRemote(remotesFolder, "RemoteEvent", "RoundState"),
    CrystalPickup = ensureRemote(remotesFolder, "RemoteEvent", "CrystalPickup"),
}

local mapBuilder = MapBuilder.new(workspace, GameConfig)
local crystalService = CrystalService.new(mapBuilder.Root, remotes)
local npcService = NpcService.new(mapBuilder.Root, remotes)
local gameService = GameService.new(mapBuilder, crystalService, npcService, remotes)

gameService.StateChanged:Connect(function(state)
    remotes.RoundState:FireAllClients(state)
end)

gameService:Start()


