local success, shape = pcall(function() require 'map_selection' end)
if not success then
	error('\n NO MAP SELECTED \n The RedMew scenario contains many different maps. If you are unsure how to select a map checkout our guide at: \n https://redmew.com/guide \n -The RedMew Team ', 0)
end
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
