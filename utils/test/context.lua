local Public = {}
Public.__index = Public

function Public.new(player)
    return setmetatable({player = player, _steps = {}, _teardowns = {}}, Public)
end

function Public.timeout(self, delay, func)
    local steps = self._steps
    steps[#steps + 1] = {func = func, delay = delay or 1}
    return self
end

function Public.next(self, func)
    return self:timeout(1, func)
end

function Public.wait(self, delay)
    return self:timeout(delay, function()
    end)
end

function Public.add_teardown(self, func)
    local teardowns = self._teardowns
    teardowns[#teardowns + 1] = func
    return self
end

return Public
