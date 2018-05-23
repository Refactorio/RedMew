local b = require 'map_gen.shared.builders'
local gb = require 'map_gen.shared.global_builders'
local Token = require('utils.global_token')

local tiles = {
    'grass-1',
    'concrete',
    'dirt-1',
    'stone-path',
    'lab-dark-1',
    'lab-white'
}

local shapes = {
    gb.pack(require('map_gen.presets.fruit_loops')),
    gb.pack(require('map_gen.presets.creation_of_adam'))
}

local function pattern_func()
    local i = math.random(#shapes)
    --return gb.tile(tiles[i])
    return shapes[i]
end

local pt = Token.register(pattern_func)

local shape = gb.grid_pattern_endless({}, 128, 128, pt)

shape = gb.unpack(shape)

--shape = b.rotate(shape, math.rad(45))

--return shape

return b.rotate(require('map_gen.presets.creation_of_adam'), math.rad(45))
