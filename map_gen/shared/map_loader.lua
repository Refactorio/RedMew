local success, shape = pcall(function() return require 'map_selection' end)
if not success then
	error('\n\n--map_selection.lua not found--\nReleases on github include this file.\nFor info: \nhttps://redmew.com/guide\n - The RedMew Team ', 0)
end

local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
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

if type(shape) == 'function' then
    local surfaces = {
        [RS.get_surface_name()] = shape
    }

    local gen = require('map_gen.shared.generate')
    gen.init({surfaces = surfaces, regen_decoratives = config.regen_decoratives, tiles_per_tick = config.tiles_per_tick})
    gen.register()
elseif shape ~= true then
    error('You forgot to require a map')
end
