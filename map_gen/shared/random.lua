--[[
Random number generator.
https://www.codeproject.com/Articles/25172/Simple-Random-Number-Generation
]]
local Random = {}
Random.__index = Random

function Random.new(seed1, seed2)
    seed1 = seed1 or 36969
    seed2 = seed2 or 18000

    local random = {z = seed1, w = seed2}
    setmetatable(random, Random)

    return random
end

local e = 1 / (2 ^ 32 + 2)

-- return float (0, 1) exclusive
function Random.next(self)
    local z, w = self.z, self.w
    z = 36969 * bit32.band(z, 65535) + bit32.rshift(z, 16)
    w = 18000 * bit32.band(w, 65535) + bit32.rshift(w, 16)
    self.z, self.w = z, w

    local ret = bit32.lshift(z, 16) + w
    ret = bit32.band(ret, 4294967295)
    return (ret + 1.0) * e
end

-- returns int [min, max] inclusive
function Random.next_int(self, min, max)
    local u = Random.next(self)

    u = u * (max - min + 1) + min
    return math.floor(u)
end

function Random.next_from_point(x, y)
    x = 36969 * bit32.band(x, 65535) + bit32.rshift(x, 16)
    y = 18000 * bit32.band(y, 65535) + bit32.rshift(y, 16)

    local ret = bit32.lshift(x, 16) + y
    ret = bit32.band(ret, 4294967295)
    return (ret + 1.0) * e
end

function Random.next_int_from_point(x, y, min, max)
    local u = Random.next_from_point(x, y)

    u = u * (max - min + 1) + min
    return math.floor(u)
end

return Random
