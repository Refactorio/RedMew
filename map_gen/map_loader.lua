require 'utils.table'
require 'map_gen.shared.perlin_noise'
local map_selection = require 'map_selection'
local map_name = map_selection['name']
local regen_decoratives = false
local tiles_per_tick = 32
local shape

local maps = require('map_names')

if map_name == 'default' then
    return
elseif table.contains(maps, map_name) then
    shape = require('map_gen.maps.' .. map_name)
    if not shape then
        return
    else
        local surfaces = {['nauvis'] = shape}

        if map_selection['threaded'] then
            require('map_gen.shared.generate')({surfaces = surfaces, regen_decoratives = regen_decoratives, tiles_per_tick = tiles_per_tick})
        else
            require ("map_gen.shared.generate_not_threaded")({surfaces = surfaces, regen_decoratives = regen_decoratives})
        end
    end
else
    error('Incorrect map name/map name not found in table')
end
