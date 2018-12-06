require 'utils.table'
require 'map_gen.shared.perlin_noise'
local map_name = require 'map_selection'
local regen_decoratives = false
local tiles_per_tick = 32
local shape

local maps = require('map_names')

if map_name == 'default' then
    return
elseif table.contains(maps['shape_maps'], map_name) then
    shape = require('map_gen.presets.' .. map_name)
elseif table.contains(maps['non_shape_maps'], map_name) then
    require('map_gen.presets.' .. map_name)
elseif map_name == 'map_layout' then
    require 'map_gen.map_layout'
else
    error('Incorrect map name/map name not found in table')
end

if shape then
    local surfaces = {['nauvis'] = shape}
    require('map_gen.shared.generate')({surfaces = surfaces, regen_decoratives = regen_decoratives, tiles_per_tick = tiles_per_tick})
end
