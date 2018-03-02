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

local function get_uint(self)
    self.z = 36969 * bit32.band(self.z, 65535) + bit32.rshift(self.z, 16)
    self.w = 18000 * bit32.band(self.w, 65535) + bit32.rshift(self.w, 16)
    local ret = bit32.lshift(self.z, 16) + self.w
    return bit32.band(ret, 4294967295)
end

local e = 1 / (2 ^ 32 + 2)

-- return float (0, 1) exclusive
function Random:next()
    local u = get_uint(self)
    return (u + 1.0) * e
end

-- returns int [min, max] inclusive
function Random:next_int(min, max)
    local u = self:next()
    
    u = u * (max - min + 1) + min
    return math.floor(u)
end

return Random
