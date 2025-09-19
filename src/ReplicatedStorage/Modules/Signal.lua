local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self._connections = {}
    return self
end

function Signal:Connect(callback)
    assert(typeof(callback) == "function", "Signal:Connect expects a function")

    local connections = self._connections
    local connection = {
        Connected = true,
    }

    function connection:Disconnect()
        if not self.Connected then
            return
        end

        self.Connected = false

        local index = table.find(connections, self)
        if index then
            table.remove(connections, index)
        end
    end

    local function handler(...)
        if connection.Connected then
            callback(...)
        end
    end

    connection._handler = handler
    table.insert(connections, connection)

    return connection
end

function Signal:Fire(...)
    local snapshot = {}

    for index, connection in ipairs(self._connections) do
        snapshot[index] = connection
    end

    for _, connection in ipairs(snapshot) do
        connection._handler(...)
    end
end

function Signal:Once(callback)
    local connection
    connection = self:Connect(function(...)
        if connection then
            connection:Disconnect()
        end
        callback(...)
    end)
    return connection
end

function Signal:DisconnectAll()
    for _, connection in ipairs(self._connections) do
        connection.Connected = false
    end
    table.clear(self._connections)
end

return Signal
