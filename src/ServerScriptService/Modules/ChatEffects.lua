local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")

local ChatEffects = {}

local DEFAULT_COLOR = Color3.fromRGB(255, 226, 110)
local DEFAULT_TAG = "VIP"

local chatService
local success, service = pcall(function()
    local runner = ServerScriptService:FindFirstChild("ChatServiceRunner")
    if runner then
        return require(runner:WaitForChild("ChatService"))
    end
end)

if success then
    chatService = service
end

local vipDataByUserId = {}
local speakerListenerConnected = false

local function ensureSpeakerListener()
    if not chatService or speakerListenerConnected then
        return
    end

    speakerListenerConnected = true
    chatService.SpeakerAdded:Connect(function(speakerName)
        local player = Players:FindFirstChild(speakerName)
        if not player then
            for _, candidate in ipairs(Players:GetPlayers()) do
                if candidate.Name == speakerName then
                    player = candidate
                    break
                end
            end
        end

        if player then
            local info = vipDataByUserId[player.UserId]
            if info then
                task.defer(ChatEffects.ApplyVipFormatting, player, info.Tag, info.Color)
            end
        end
    end)
end

local function colorToHex(color)
    local r = math.floor(math.clamp(color.R, 0, 1) * 255 + 0.5)
    local g = math.floor(math.clamp(color.G, 0, 1) * 255 + 0.5)
    local b = math.floor(math.clamp(color.B, 0, 1) * 255 + 0.5)
    return string.format("#%02X%02X%02X", r, g, b)
end

if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    local previousHandler = TextChatService.OnIncomingMessage

    TextChatService.OnIncomingMessage = function(message)
        if previousHandler then
            local result = previousHandler(message)
            if result then
                return result
            end
        end

        if not message.TextSource then
            return nil
        end

        local player = Players:GetPlayerByUserId(message.TextSource.UserId)
        if not player then
            return nil
        end

        local info = vipDataByUserId[player.UserId]
        if not info then
            return nil
        end

        local properties = Instance.new("TextChatMessageProperties")
        local color = info.Color or DEFAULT_COLOR
        local hex = colorToHex(color)
        local tag = info.Tag or DEFAULT_TAG

        properties.PrefixText = string.format("<font color=\"%s\">[%s]</font> %s", hex, tag, message.PrefixText)
        properties.Text = string.format("<font color=\"%s\">%s</font>", hex, message.Text)
        return properties
    end
end

function ChatEffects.ApplyVipFormatting(player, tag, color)
    if not player then
        return
    end

    ensureSpeakerListener()

    local info = {
        Tag = tag or DEFAULT_TAG,
        Color = color or DEFAULT_COLOR
    }
    vipDataByUserId[player.UserId] = info

    if chatService then
        local speaker = chatService:GetSpeaker(player.Name)
        if speaker then
            speaker:SetExtraData("Tags", {{ TagText = info.Tag, TagColor = info.Color }})
            speaker:SetExtraData("ChatColor", info.Color)
        end
    end
end

function ChatEffects.ClearVipFormatting(player)
    if not player then
        return
    end

    vipDataByUserId[player.UserId] = nil

    if chatService then
        local speaker = chatService:GetSpeaker(player.Name)
        if speaker then
            speaker:SetExtraData("Tags", {})
            speaker:SetExtraData("ChatColor", Color3.fromRGB(255, 255, 255))
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    vipDataByUserId[player.UserId] = nil
end)

return ChatEffects
