local Helper = require 'map_gen.maps.danger_ores.modules.helper'
local b = require 'map_gen.shared.builders'
local table = require 'utils.table'
local resource_patches_builder = require 'map_gen.maps.danger_ores.modules.resource_patches'
local default_main_ore_resource_patches_config = require 'map_gen.maps.danger_ores.config.main_ore_resource_patches'

return function(config)
    local main_ores = config.main_ores
    local shuffle_order = config.main_ores_shuffle_order
    local main_ores_rotate = config.main_ores_rotate or 0
    local main_ores_split_count = config.main_ores_split_count or 1
    local main_ore_resource_patches_config = config.main_ore_resource_patches_config
                                                 or default_main_ore_resource_patches_config
    local start_ore_shape = config.start_ore_shape or b.circle(68)

    main_ores = Helper.split_ore(main_ores, main_ores_split_count)

    return function(tile_builder, ore_builder, spawn_shape, water_shape, random_gen)
        local main_ore_resource_patches = resource_patches_builder({
            resource_patches_config = main_ore_resource_patches_config
        })

        local shapes = {}

        for _, ore_data in pairs(main_ores) do
            local ore_name = ore_data.name
            local tiles = ore_data.tiles
            local land = tile_builder(tiles)

            local ratios = ore_data.ratios
            local weighted = b.prepare_weighted_array(ratios)
            local amount = ore_data.start

            local background_ore = ore_builder(ore_name, amount, ratios, weighted)
            main_ore_resource_patches = b.choose(start_ore_shape, background_ore, main_ore_resource_patches)
            local ore = b.any {main_ore_resource_patches, background_ore}

            local shape = b.apply_entity(land, ore)
            shapes[#shapes + 1] = {shape = shape, weight = ore_data.weight}
        end

        if shuffle_order then
            table.shuffle_table(shapes, random_gen)
        end

        local ores = b.segment_weighted_pattern(shapes)

        if main_ores_rotate ~= 0 then
            ores = b.rotate(ores, math.rad(main_ores_rotate))
        end

        return b.any {spawn_shape, water_shape, ores}
    end
end
