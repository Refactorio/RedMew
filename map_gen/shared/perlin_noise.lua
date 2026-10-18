--[[
    Implemented as described here:
    http://flafla2.github.io/2014/08/09/perlinnoise.html
]] --

local floor = math.floor

local Perlin = {}
local p = {}

-- Hash lookup table as defined by Ken Perlin
-- This is a randomly arranged array of all numbers from 0-255 inclusive
local permutation = {151,160,137,91,90,15,
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
}

-- p is used to hash unit cube coordinates to [0, 255]
for i = 0, 255 do
    -- Convert to 0 based index table
    p[i] = permutation[i + 1]
    -- Repeat the array to avoid buffer overflow in hash function
    p[i + 256] = permutation[i + 1]
end

-- Gradient function finds dot product between pseudorandom gradient vector
-- and the vector from input coordinate to a unit cube vertex. hash % 16 picks one of
-- Ken Perlin's 12 gradients (4 repeated); a branch tree on its bits keeps it to 4 tests.
local function grad(hash, x, y, z)
    local h = hash % 16
    if h < 8 then
        if h < 4 then
            if h < 2 then
                if h == 0 then return x + y end
                return -x + y
            end
            if h == 2 then return x - y end
            return -x - y
        end
        if h < 6 then
            if h == 4 then return x + z end
            return -x + z
        end
        if h == 6 then return x - z end
        return -x - z
    end
    if h < 12 then
        if h < 10 then
            if h == 8 then return y + z end
            return -y + z
        end
        if h == 10 then return y - z end
        return -y - z
    end
    if h < 14 then
        if h == 12 then return y + x end
        return -y + z
    end
    if h == 14 then return y - x end
    return -y - z
end

-- Return range: [-1, 1]
function Perlin.noise(x, y, z)
    y = y or 0
    z = z or 0

    -- This prevents integer inputs returning 0, which causes 'straight line' artifacts.
    x = x - 0.55077056353912
    y = y - 0.131357755512
    z = z - 0.20474238274619

    -- Calculate the "unit cube" that the point asked will be located in
    local fx, fy, fz = floor(x), floor(y), floor(z)
    local xi = fx % 256
    local yi = fy % 256
    local zi = fz % 256

    -- Next we calculate the location (from 0 to 1) in that cube
    x = x - fx
    y = y - fy
    z = z - fz

    -- We also fade the location to smooth the result: t^3 * (t * (t * 6 - 15) + 10)
    local u = x * x * x * (x * (x * 6 - 15) + 10)
    local v = y * y * y * (y * (y * 6 - 15) + 10)
    local w = z * z * z * (z * (z * 6 - 15) + 10)

    -- Hash all 8 unit cube coordinates surrounding input coordinate
    local A = p[xi] + yi
    local AA = p[A] + zi
    local AB = p[A + 1] + zi

    local B = p[xi + 1] + yi
    local BA = p[B] + zi
    local BB = p[B + 1] + zi

    local x1, y1, z1 = x - 1, y - 1, z - 1

    -- Take the weighted average between all 8 unit cube coordinates: lerp(t, a, b) = a + t * (b - a)
    local g1 = grad(p[AA], x, y, z)
    local x00 = g1 + u * (grad(p[BA], x1, y, z) - g1)
    g1 = grad(p[AB], x, y1, z)
    local x10 = g1 + u * (grad(p[BB], x1, y1, z) - g1)
    local y0 = x00 + v * (x10 - x00)

    g1 = grad(p[AA + 1], x, y, z1)
    local x01 = g1 + u * (grad(p[BA + 1], x1, y, z1) - g1)
    g1 = grad(p[AB + 1], x, y1, z1)
    local x11 = g1 + u * (grad(p[BB + 1], x1, y1, z1) - g1)
    local y1v = x01 + v * (x11 - x01)

    return y0 + w * (y1v - y0)
end

return Perlin
