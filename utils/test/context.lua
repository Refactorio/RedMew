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

--- Waits until `done` returns true, checking it every tick, for at most `ticks`, then carries on
-- with the next step. If it never does, the test fails with `message`, which may be a function,
-- called then, to say what was there instead.
function Public.wait_until(self, ticks, done, message)
    local steps = self._steps
    steps[#steps + 1] = {func = done, delay = 1, wait_ticks = ticks, waited = 0, wait_message = message}
    return self
end

function Public.add_teardown(self, func)
    local teardowns = self._teardowns
    teardowns[#teardowns + 1] = func
    return self
end

return Public
