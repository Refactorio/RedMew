local shape = require 'map_selection'
local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local config = global.config.map_generation

local line = '-----------------------------\n'
local shape_type = type(shape)

--- Check if shape is a function, if it isn't throw an error.
local function shape_check()
    if shape_type ~= 'function' then
        error(line .. 'You cannot use entity or terrain modules together with this map as it does not return a function.')
    end
end

--- Run each function once to trigger the require
local function initialize(array)
    for i = 1, #array do
        array[i] = array[i]()
    end
end

--- Initializes and applies entity modules after checking for errors.
if #config.entity_modules > 0 then
    shape_check()
    initialize(config.entity_modules)
    shape = shape or b.full_shape
    shape = b.apply_entities(shape, config.entity_modules)
end

--- Initializes and applies terrain modules after checking for errors.
if #config.terrain_modules > 0 then
    shape_check()
    initialize(config.terrain_modules)
    shape = shape or b.full_shape

    for _, m in ipairs(config.terrain_modules) do
        shape = b.overlay_tile_land(shape, m)
    end
end

--- If shape is a function, initialize the generator
if shape_type == 'function' then
    local surfaces = {
        [RS.get_surface_name()] = shape
    }

    local gen = require('map_gen.shared.generate')
    gen.init({surfaces = surfaces, regen_decoratives = config.regen_decoratives, tiles_per_tick = config.tiles_per_tick})
    gen.register()
elseif shape ~= true then -- If a map is returning neither true nor a function, they did not include a map, or the map is returning an unexpected type.
    error(line .. 'The map selected in map_selection.lua is either missing or is returning a non-true non-function data type.')
end
