local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local EventService = {}

local remotes
local orbManager
local sendStateCallback
local currentEvent
local nextEventTime = 0

local function cloneTable(original)
    local copy = {}
    for key, value in pairs(original) do
        if typeof(value) == "table" then
            copy[key] = cloneTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

local function notifyState()
    if not sendStateCallback then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        sendStateCallback(player)
    end
end

local function scheduleNextEvent()
    local cooldown = Config.DynamicEventCooldown or {}
    local minDelay = math.max(30, cooldown.Min or 60)
    local maxDelay = math.max(minDelay, cooldown.Max or (minDelay + 20))
    nextEventTime = Workspace:GetServerTimeNow() + math.random(minDelay, maxDelay)
end

local function pickEventDefinition()
    local definitions = Config.DynamicEvents or {}
    local keys = {}
    for key in pairs(definitions) do
        table.insert(keys, key)
    end

    if #keys == 0 then
        return nil, nil
    end

    local chosenKey = keys[math.random(1, #keys)]
    return chosenKey, definitions[chosenKey]
end

local function stopBurstThread(eventData)
    if eventData and eventData.Controller then
        eventData.Controller.Cancelled = true
    end
end

local function startBurstLoop(eventData, burstConfig)
    if not burstConfig then
        return
    end

    local controller = eventData.Controller
    task.spawn(function()
        while currentEvent == eventData and controller and not controller.Cancelled do
            if orbManager and orbManager.SpawnBurst then
                orbManager.SpawnBurst(eventData.ZoneIndex, burstConfig)
            end
            local interval = burstConfig.Interval or 15
            task.wait(math.max(4, interval))
        end
    end)
end

local function announce(message)
    if remotes and remotes.Notify and message then
        remotes.Notify:FireAllClients(message)
    end
end

local function beginEvent(key, definition)
    if not definition then
        return
    end

    local zoneIndex = math.random(1, #Config.Zones)
    local zoneConfig = Config.getZone(zoneIndex)
    local zoneName = zoneConfig and zoneConfig.Name or ("Zone " .. zoneIndex)
    local now = Workspace:GetServerTimeNow()
    local duration = definition.Duration or 60

    currentEvent = {
        Key = key,
        Name = definition.Name or key,
        Description = definition.Description or "",
        ZoneIndex = zoneIndex,
        ZoneName = zoneName,
        Color = definition.Color or (zoneConfig and zoneConfig.OrbColor) or Color3.new(1, 1, 1),
        StartedAt = now,
        EndsAt = now + duration,
        Controller = { Cancelled = false }
    }

    if definition.ZoneModifier and orbManager and orbManager.SetEventModifier then
        local modifier = cloneTable(definition.ZoneModifier)
        modifier.ZoneIndex = zoneIndex
        orbManager.SetEventModifier(modifier)
    end

    if definition.Burst and orbManager then
        startBurstLoop(currentEvent, definition.Burst)
    end

    if orbManager and orbManager.SpawnBurst and definition.Burst and definition.Burst.Warmup ~= false then
        orbManager.SpawnBurst(zoneIndex, definition.Burst)
    end

    announce(string.format(definition.Announcement or "%s is surging with energy!", zoneName))
    notifyState()
end

function EventService.StopEvent(message)
    if not currentEvent then
        return
    end

    stopBurstThread(currentEvent)

    if orbManager and orbManager.ClearEventModifier then
        orbManager.ClearEventModifier(currentEvent.ZoneIndex)
    end

    currentEvent = nil
    announce(message)
    notifyState()
    scheduleNextEvent()
end

function EventService.GetEventSummary()
    if not currentEvent then
        return nil
    end

    local now = Workspace:GetServerTimeNow()
    if now >= currentEvent.EndsAt then
        return nil
    end

    return {
        Key = currentEvent.Key,
        Name = currentEvent.Name,
        Description = currentEvent.Description,
        ZoneIndex = currentEvent.ZoneIndex,
        ZoneName = currentEvent.ZoneName,
        Color = currentEvent.Color,
        StartedAt = currentEvent.StartedAt,
        EndsAt = currentEvent.EndsAt
    }
end

local function eventHeartbeat()
    scheduleNextEvent()

    while true do
        task.wait(1)
        local now = Workspace:GetServerTimeNow()

        if currentEvent then
            if now >= currentEvent.EndsAt then
                local finished = currentEvent
                EventService.StopEvent(string.format("%s has settled.", finished.Name))
            end
        elseif now >= nextEventTime then
            local key, definition = pickEventDefinition()
            if key and definition then
                beginEvent(key, definition)
            else
                scheduleNextEvent()
            end
        end
    end
end

function EventService.Init(remoteTable, orbManagerModule, sendState)
    remotes = remoteTable
    orbManager = orbManagerModule
    sendStateCallback = sendState

    if not EventService._initialized then
        EventService._initialized = true
        task.spawn(eventHeartbeat)
    end
end

return EventService
