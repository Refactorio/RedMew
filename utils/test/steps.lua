local Public = {}
Public.__index = Public

function Public.new()
    return setmetatable({_child = nil, _func = nil, _delay = nil}, Public)
end

function Public.next(self, func, delay)
    local context = Public.new()
    self._child = context
    self._func = func
    self._delay = delay
    return context
end

return Public
