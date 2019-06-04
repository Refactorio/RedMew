local type = type
local tostring = tostring
local setmetatable = setmetatable

local Public = {}

local add

local function set_tail(self, tail)
    local mt = getmetatable(self)
    mt.tail = tail
end

local function new(obj)
    local mt = {add = add, tail = nil}
    mt.__index = mt

    return setmetatable(obj, mt)
end

local function localise(item)
    local t = type(item)
    if t == 'table' then
        return item
    elseif t == 'string' then
        return {'', item}
    else
        return {'', tostring(item)}
    end
end

function add(self, item)
    if not item then
        item = self
        self = nil
    end

    item = localise(item)

    if not self then
        return new(item)
    end

    local tail = self.tail
    if not tail then
        tail = {'', self}
        self = new(tail)
        set_tail(self, tail)
    end

    local count = #tail
    if count < 20 then
        tail[count + 1] = item
    else
        local new_tail = {'', item}
        tail[count + 1] = new_tail
        set_tail(self, new_tail)
    end

    return self
end

Public.add = add

return Public
