local Public = {}
Public.__index = Public

function Public.new()
    return setmetatable({}, Public)
end

function Public.timeout(self, delay, func)
    self[#self + 1] = {func = func, delay = delay or 1}
    return self
end

function Public.next(self, func)
    return self:timeout(1, func)
end

return Public
