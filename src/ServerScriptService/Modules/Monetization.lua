local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))

local Monetization = {}

local remotes = nil
local stateUpdateCallback = nil

local passOwnership = {}
local passLookupById = {}
local productLookupById = {}
local productLookupByKey = {}

local passUnlockedCallbacks = {}

local function buildLookups()
    passLookupById = {}
    productLookupById = {}
    productLookupByKey = {}

    for key, passInfo in pairs(Config.Gamepasses) do
        if passInfo.Id and passInfo.Id > 0 then
            passLookupById[passInfo.Id] = key
        end
    end

    for categoryName, items in pairs(Config.DeveloperProducts) do
        for _, info in ipairs(items) do
            local entry = { Category = categoryName, Info = info }
            productLookupByKey[info.Key] = entry
            if info.Id and info.Id > 0 then
                productLookupById[info.Id] = entry
            end
        end
    end
end

local function notify(player, message)
    if remotes and remotes.Notify then
        remotes.Notify:FireClient(player, message)
    end
end

local function updateState(player)
    if stateUpdateCallback then
        stateUpdateCallback(player)
    end
end

local function setPass(player, key, value, suppressFeedback)
    passOwnership[player] = passOwnership[player] or {}
    passOwnership[player][key] = value or nil

    local session = SessionService.GetSession(player)
    if session then
        session.OwnedGamepasses = session.OwnedGamepasses or {}
        session.OwnedGamepasses[key] = value and true or nil
    end

    player:SetAttribute("Gamepass_" .. key, value and true or false)

    if value then
        if not suppressFeedback then
            notify(player, string.format("%s unlocked!", Config.Gamepasses[key].Name))
        end

        for _, callback in ipairs(passUnlockedCallbacks) do
            task.defer(callback, player, key)
        end
    end

    if not suppressFeedback then
        updateState(player)
    end
end

function Monetization.SetRemotes(remoteTable)
    remotes = remoteTable
    buildLookups()
end

function Monetization.SetStateUpdateCallback(callback)
    stateUpdateCallback = callback
end

function Monetization.OnPassUnlocked(callback)
    table.insert(passUnlockedCallbacks, callback)
end

function Monetization.PlayerHasPass(player, key)
    local owned = passOwnership[player]
    return owned and owned[key] == true or false
end

function Monetization.GetOwnedPasses(player)
    return passOwnership[player] or {}
end

function Monetization.RegisterPlayer(player)
    passOwnership[player] = passOwnership[player] or {}
    local session = SessionService.GetSession(player)
    if session then
        session.OwnedGamepasses = session.OwnedGamepasses or {}
    end

    for key, info in pairs(Config.Gamepasses) do
        if info.Id and info.Id > 0 then
            local success, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, info.Id)
            if success and owns then
                setPass(player, key, true, true)
            end
        end
    end

    updateState(player)
end

function Monetization.SyncSession(player)
    local session = SessionService.GetSession(player)
    if not session then
        return
    end

    session.OwnedGamepasses = session.OwnedGamepasses or {}
    local owned = passOwnership[player]
    if owned then
        for key, value in pairs(owned) do
            if value then
                session.OwnedGamepasses[key] = true
            end
        end
    end
end

function Monetization.CleanupPlayer(player)
    passOwnership[player] = nil
end

local function handlePurchaseRequest(player, payload)
    if typeof(payload) ~= "table" then
        return
    end

    local requestType = payload.Type
    if requestType == "Gamepass" then
        local passKey = payload.Key
        local info = Config.Gamepasses[passKey]
        if info and info.Id and info.Id > 0 then
            MarketplaceService:PromptGamePassPurchase(player, info.Id)
        else
            notify(player, "Gamepass ID not set yet.")
        end
    elseif requestType == "Product" then
        local productKey = payload.Key
        local entry = productLookupByKey[productKey]
        if entry and entry.Info.Id and entry.Info.Id > 0 then
            MarketplaceService:PromptProductPurchase(player, entry.Info.Id)
        else
            notify(player, "Product ID not set yet.")
        end
    end
end

local function awardProduct(player, entry)
    local session = SessionService.GetSession(player)
    if not session then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local info = entry.Info
    if entry.Category == "EnergyPacks" then
        SessionService.AdjustEnergy(player, info.Amount)
        notify(player, string.format("+%d Energy!", info.Amount))
        updateState(player)
    elseif entry.Category == "Boosts" then
        local expiresAt = os.time() + info.Duration
        SessionService.AddBoost(player, info.Key, { Multiplier = info.Multiplier, Expires = expiresAt })
        notify(player, string.format("%s activated!", info.Name))
        updateState(player)
    end

    return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function processReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local entry = productLookupById[receiptInfo.ProductId]
    if not entry then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    return awardProduct(player, entry)
end

local function onGamePassFinished(player, gamePassId, wasPurchased)
    if not wasPurchased then
        return
    end

    local passKey = passLookupById[gamePassId]
    if passKey then
        setPass(player, passKey, true)
    end
end

function Monetization.Init(remoteTable)
    Monetization.SetRemotes(remoteTable)

    if not remotes then
        return
    end

    remotes.PurchaseRequest.OnServerEvent:Connect(handlePurchaseRequest)
    MarketplaceService.ProcessReceipt = processReceipt
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamePassFinished)
end

return Monetization
