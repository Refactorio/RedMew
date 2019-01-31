local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local shape = require 'map_selection'
local config = global.config.map_generation

if #config.entity_modules > 0 then
    shape = shape or b.full_shape
    shape = b.apply_entities(shape, config.entity_modules)
end

if #config.terrain_modules > 0 then
    shape = shape or b.full_shape

    for _, m in ipairs(config.terrain_modules) do
        shape = b.overlay_tile_land(shape, m)
    end
end

if shape then
    local surfaces = {
        [RS.get_surface_name()] = shape
    }

    local gen = require('map_gen.shared.generate')
    gen.init({surfaces = surfaces, regen_decoratives = config.regen_decoratives, tiles_per_tick = config.tiles_per_tick})
    gen.register()
end
