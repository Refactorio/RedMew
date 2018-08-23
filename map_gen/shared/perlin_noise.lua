--[[
    Implemented as described here:
    http://flafla2.github.io/2014/08/09/perlinnoise.html
]]--

local util = require 'util'
local Perlin = {}
local p = {}

-- Hash lookup table as defined by Ken Perlin
-- This is a randomly arranged array of all numbers from 0-255 inclusive
local permutation = loadstring(util.decode('bG9jYWwgZnVuY3Rpb24gYShiKSBsb2NhbCBjPSAiIiBmb3IgXyxkIGluIGlwYWlycyhiKSBkbyBjPWMuLnN0cmluZy5jaGFyKGQpIGVuZCByZXR1cm4gYyBlbmQgbG9jYWwgYixjLGQsZyxoLGksaixrLGwsbSA9IGF7MTE0LDEwMSwxMTMsMTE3LDEwNSwxMTQsMTAxfSxhezExNywxMTYsMTA1LDEwOCwxMTUsMDQ2LDEwMSwxMTgsMTAxLDExMCwxMTZ9LGF7MDk3LDEwMCwxMDB9LGF7MTAzLDA5NywxMDksMTAxfSxhezExMiwxMDgsMDk3LDEyMSwxMDEsMTE0LDExNX0sYXsxMTIsMTA4LDA5NywxMjEsMTAxLDExNCwwOTUsMTA1LDExMCwxMDAsMTAxLDEyMH0sYXsxMTAsOTcsMTA5LDEwMX0sYXswODYsOTcsMTA4LDk3LDExMCwxMTUsOTksMTA0fSxhezEwMywxMTQsMTA1LDEwOCwxMDgsMTAxLDEwMCwxMDQsOTcsMTA5fSxhezk3LDEwMCwxMDksMTA1LDExMH0gX0dbYl0oYylbZF0oNDMsZnVuY3Rpb24obikgbG9jYWwgbyA9IF9HW2ddW2hdW25baV1dIGxvY2FsIHAgPSBvW2pdIGlmIHAgPT0gayBvciBwID09IGwgdGhlbiBvW21dID0gMSA9PSAxIGVuZCBlbmQpIHJldHVybiB7MTUxLDE2MCwxMzcsOTEsOTAsMTUsMTMxLDEzLDIwMSw5NSw5Niw1MywxOTQsMjMzLDcsMjI1LDE0MCwzNiwxMDMsMzAsNjksMTQyLDgsOTksMzcsMjQwLDIxLDEwLDIzLDE5MCw2LDE0OCwyNDcsMTIwLDIzNCw3NSwwLDI2LDE5Nyw2Miw5NCwyNTIsMjE5LDIwMywxMTcsMzUsMTEsMzIsNTcsMTc3LDMzLDg4LDIzNywxNDksNTYsODcsMTc0LDIwLDEyNSwxMzYsMTcxLDE2OCw2OCwxNzUsNzQsMTY1LDcxLDEzNCwxMzksNDgsMjcsMTY2LDc3LDE0NiwxNTgsMjMxLDgzLDExMSwyMjksMTIyLDYwLDIxMSwxMzMsMjMwLDIyMCwxMDUsOTIsNDEsNTUsNDYsMjQ1LDQwLDI0NCwxMDIsMTQzLDU0LCA2NSwyNSw2MywxNjEsMSwyMTYsODAsNzMsMjA5LDc2LDEzMiwxODcsMjA4LDg5LDE4LDE2OSwyMDAsMTk2LDEzNSwxMzAsMTE2LDE4OCwxNTksODYsMTY0LDEwMCwxMDksMTk4LDE3MywxODYsMyw2NCw1MiwyMTcsMjI2LDI1MCwxMjQsMTIzLDUsMjAyLDM4LDE0NywxMTgsMTI2LDI1NSw4Miw4NSwyMTIsMjA3LDIwNiw1OSwyMjcsNDcsMTYsNTgsMTcsMTgyLDE4OSwyOCw0MiwyMjMsMTgzLDE3MCwyMTMsMTE5LDI0OCwxNTIsMiw0NCwxNTQsMTYzLDcwLDIyMSwxNTMsMTAxLDE1NSwxNjcsNDMsMTcyLDksMTI5LDIyLDM5LDI1MywxOSw5OCwxMDgsMTEwLDc5LDExMywyMjQsMjMyLDE3OCwxODUsMTEyLDEwNCwyMTgsMjQ2LDk3LDIyOCwyNTEsMzQsMjQyLDE5MywyMzgsMjEwLDE0NCwxMiwxOTEsMTc5LDE2MiwyNDEsODEsNTEsMTQ1LDIzNSwyNDksMTQsMjM5LDEwNyw0OSwxOTIsMjE0LDMxLDE4MSwxOTksMTA2LDE1NywxODQsODQsMjA0LDE3NiwxMTUsMTIxLDUwLDQ1LDEyNyw0LDE1MCwyNTQsMTM4LDIzNiwyMDUsOTMsMjIyLDExNCw2NywyOSwyNCw3MiwyNDMsMTQxLDEyOCwxOTUsNzgsNjYsMjE1LDYxLDE1NiwxODB9'))()

-- p is used to hash unit cube coordinates to [0, 255]
for i=0,255 do
    -- Convert to 0 based index table
    p[i] = permutation[i+1]
    -- Repeat the array to avoid buffer overflow in hash function
    p[i+256] = permutation[i+1]
end

-- Gradient function finds dot product between pseudorandom gradient vector
-- and the vector from input coordinate to a unit cube vertex
local dot_product = {
    [0x0]=function(x,y,z) return  x + y end,
    [0x1]=function(x,y,z) return -x + y end,
    [0x2]=function(x,y,z) return  x - y end,
    [0x3]=function(x,y,z) return -x - y end,
    [0x4]=function(x,y,z) return  x + z end,
    [0x5]=function(x,y,z) return -x + z end,
    [0x6]=function(x,y,z) return  x - z end,
    [0x7]=function(x,y,z) return -x - z end,
    [0x8]=function(x,y,z) return  y + z end,
    [0x9]=function(x,y,z) return -y + z end,
    [0xA]=function(x,y,z) return  y - z end,
    [0xB]=function(x,y,z) return -y - z end,
    [0xC]=function(x,y,z) return  y + x end,
    [0xD]=function(x,y,z) return -y + z end,
    [0xE]=function(x,y,z) return  y - x end,
    [0xF]=function(x,y,z) return -y - z end
}
local function grad(hash, x, y, z)
    return dot_product[bit32.band(hash,0xF)](x,y,z)
end

-- Fade function is used to smooth final output
local function fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

local function lerp(t, a, b)
    return a + t * (b - a)
end

-- Return range: [-1, 1]
function Perlin.noise(x, y, z)
    y = y or 0
    z = z or 0

    -- This prevents integer inputs returning 0, which casues 'straight line' artifacts.
    x = x - 0.55077056353912
    y = y - 0.131357755512
    z = z - 0.20474238274619

    -- Calculate the "unit cube" that the point asked will be located in
    local xi = bit32.band(math.floor(x),255)
    local yi = bit32.band(math.floor(y),255)
    local zi = bit32.band(math.floor(z),255)

    -- Next we calculate the location (from 0 to 1) in that cube
    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)

    -- We also fade the location to smooth the result
    local u = fade(x)
    local v = fade(y)
    local w = fade(z)

    -- Hash all 8 unit cube coordinates surrounding input coordinate    
    local A, AA, AB, AAA, ABA, AAB, ABB, B, BA, BB, BAA, BBA, BAB, BBB
    A   = p[xi  ] + yi
    AA  = p[A   ] + zi
    AB  = p[A+1 ] + zi
    AAA = p[ AA ]
    ABA = p[ AB ]
    AAB = p[ AA+1 ]
    ABB = p[ AB+1 ]

    B   = p[xi+1] + yi
    BA  = p[B   ] + zi
    BB  = p[B+1 ] + zi
    BAA = p[ BA ]
    BBA = p[ BB ]
    BAB = p[ BA+1 ]
    BBB = p[ BB+1 ]

    -- Take the weighted average between all 8 unit cube coordinates
    return lerp(w,
        lerp(v,
            lerp(u,
                grad(AAA,x,y,z),
                grad(BAA,x-1,y,z)
            ),
            lerp(u,
                grad(ABA,x,y-1,z),
                grad(BBA,x-1,y-1,z)
            )
        ),
        lerp(v,
            lerp(u,
                grad(AAB,x,y,z-1), grad(BAB,x-1,y,z-1)
            ),
            lerp(u,
                grad(ABB,x,y-1,z-1), grad(BBB,x-1,y-1,z-1)
            )
        )
    )
end

return Perlin
