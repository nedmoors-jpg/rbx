local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local function getOrCreateRemote(folder, className, name)
    local remote = folder:FindFirstChild(name)
    if not remote then
        remote = Instance.new(className)
        remote.Name = name
        remote.Parent = folder
    end

    return remote
end

function Remotes.get()
    local container = ReplicatedStorage:FindFirstChild("Remotes")
    if not container then
        container = Instance.new("Folder")
        container.Name = "Remotes"
        container.Parent = ReplicatedStorage
    end

    local eventsFolder = container:FindFirstChild("Events")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "Events"
        eventsFolder.Parent = container
    end

    local remotes = {
        StateUpdate = getOrCreateRemote(eventsFolder, "RemoteEvent", "StateUpdate"),
        Notify = getOrCreateRemote(eventsFolder, "RemoteEvent", "Notify"),
        ActionRequest = getOrCreateRemote(eventsFolder, "RemoteEvent", "ActionRequest"),
        PurchaseRequest = getOrCreateRemote(eventsFolder, "RemoteEvent", "PurchaseRequest"),
        Tutorial = getOrCreateRemote(eventsFolder, "RemoteEvent", "Tutorial")
    }

    return remotes
end

return Remotes
