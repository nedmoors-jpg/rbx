local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local SessionService = {}

local DATASTORE_NAME = "CrystalRush_PlayerData_V1"
local dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

local DEFAULT_DATA = {
    Energy = 0,
    TotalEnergy = 0,
    CapacityLevel = 1,
    SpeedLevel = 1,
    ConverterLevel = 1,
    ZoneLevel = 1,
    Rebirths = 0,
    Settings = {
        HyperSprint = false,
        AutoCollector = true
    },
    TutorialStep = 0
}

local sessions = {}

local function deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if typeof(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

local function createDefaultData()
    return deepCopy(DEFAULT_DATA)
end

local function ensureSettings(session)
    session.Data.Settings = session.Data.Settings or {}
    if session.Data.Settings.HyperSprint == nil then
        session.Data.Settings.HyperSprint = false
    end
    if session.Data.Settings.AutoCollector == nil then
        session.Data.Settings.AutoCollector = true
    end
end

local function getKey(player)
    return string.format("Player_%d", player.UserId)
end

function SessionService.GetSession(player)
    return sessions[player]
end

function SessionService.GetData(player)
    local session = sessions[player]
    return session and session.Data
end

local function loadData(player)
    local key = getKey(player)
    local success, stored = pcall(function()
        return dataStore:GetAsync(key)
    end)

    if success and stored then
        local newData = createDefaultData()
        for k, v in pairs(stored) do
            if newData[k] ~= nil then
                if typeof(newData[k]) == "table" and typeof(v) == "table" then
                    newData[k] = deepCopy(v)
                else
                    newData[k] = v
                end
            end
        end
        return newData
    end

    if not success then
        warn("[SessionService] Failed to load data for", player.Name, stored)
    end

    return createDefaultData()
end

function SessionService.CreateSession(player)
    local data = loadData(player)

    local session = {
        Player = player,
        Data = data,
        Inventory = 0,
        Boosts = {},
        OwnedGamepasses = {},
        LastSave = os.time(),
        LastDeposit = 0
    }

    ensureSettings(session)
    sessions[player] = session
    return session
end

local function serializeData(data)
    local serialized = {}
    for k, v in pairs(data) do
        if typeof(v) == "table" then
            serialized[k] = deepCopy(v)
        else
            serialized[k] = v
        end
    end
    return serialized
end

function SessionService.SaveSession(player)
    local session = sessions[player]
    if not session then
        return
    end

    local key = getKey(player)
    local serialized = serializeData(session.Data)

    local success, err = pcall(function()
        dataStore:SetAsync(key, serialized)
    end)

    if not success then
        warn("[SessionService] Failed to save data for", player.Name, err)
    else
        session.LastSave = os.time()
    end
end

function SessionService.RemoveSession(player)
    sessions[player] = nil
end

function SessionService.AdjustEnergy(player, delta)
    local session = sessions[player]
    if not session then
        return 0
    end

    session.Data.Energy = math.max(0, session.Data.Energy + delta)
    if delta > 0 then
        session.Data.TotalEnergy = session.Data.TotalEnergy + delta
    end
    return session.Data.Energy
end

function SessionService.SetInventory(player, amount)
    local session = sessions[player]
    if not session then
        return 0
    end
    session.Inventory = math.max(0, amount)
    return session.Inventory
end

function SessionService.AddInventory(player, delta)
    local session = sessions[player]
    if not session then
        return 0
    end
    session.Inventory = math.max(0, session.Inventory + delta)
    return session.Inventory
end

function SessionService.RecordZoneUnlock(player, zoneLevel)
    local session = sessions[player]
    if not session then
        return
    end
    session.Data.ZoneLevel = math.max(session.Data.ZoneLevel, zoneLevel)
end

function SessionService.RecordUpgrade(player, upgradeType, newLevel)
    local session = sessions[player]
    if not session then
        return
    end
    local key = upgradeType .. "Level"
    if session.Data[key] ~= nil then
        session.Data[key] = newLevel
    end
end

function SessionService.RecordRebirth(player)
    local session = sessions[player]
    if not session then
        return
    end
    session.Data.Rebirths += 1
    session.Data.Energy = Config.Rebirth.BonusEnergy
    session.Data.TotalEnergy = session.Data.TotalEnergy + Config.Rebirth.BonusEnergy
    session.Data.CapacityLevel = 1
    session.Data.SpeedLevel = 1
    session.Data.ConverterLevel = 1
    session.Data.ZoneLevel = 1
    session.Inventory = 0
    ensureSettings(session)
end

function SessionService.AddBoost(player, key, data)
    local session = sessions[player]
    if not session then
        return
    end
    session.Boosts[key] = data
end

function SessionService.GetSettings(player)
    local session = sessions[player]
    if not session then
        return {}
    end
    ensureSettings(session)
    return session.Data.Settings
end

function SessionService.GetSetting(player, key)
    local settings = SessionService.GetSettings(player)
    return settings[key]
end

function SessionService.SetSetting(player, key, value)
    local session = sessions[player]
    if not session then
        return
    end

    ensureSettings(session)
    session.Data.Settings[key] = value
end

function SessionService.GetBoosts(player)
    local session = sessions[player]
    if not session then
        return {}
    end
    return session.Boosts
end

function SessionService.ClearBoost(player, key)
    local session = sessions[player]
    if not session then
        return
    end
    session.Boosts[key] = nil
end

function SessionService.GetAllSessions()
    return sessions
end

function SessionService.SaveAll()
    for player in pairs(sessions) do
        SessionService.SaveSession(player)
    end
end

Players.PlayerRemoving:Connect(function(player)
    SessionService.SaveSession(player)
    SessionService.RemoveSession(player)
end)

game:BindToClose(function()
    SessionService.SaveAll()
end)

return SessionService
