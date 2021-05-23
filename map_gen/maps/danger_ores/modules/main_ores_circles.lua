local Helper = require 'map_gen.maps.danger_ores.modules.helper'
local b = require 'map_gen.shared.builders'
local table = require 'utils.table'

return function(config)
    local main_ores = config.main_ores
    local main_ores_split_count = config.main_ores_split_count or 1
    local main_ores_rotate = config.main_ores_rotate or 0
    local start_ore_shape = config.start_ore_shape
    local circle_thickenss = config.circle_thickness or 16

    main_ores = Helper.split_ore(main_ores, main_ores_split_count)

    return function(tile_builder, ore_builder, spawn_shape, water_shape, random_gen)
        local starting_ores_list = {}
        local shapes = {}

        for _, ore_data in pairs(main_ores) do
            local ore_name = ore_data.name
            local tiles = ore_data.tiles
            local start_amount = ore_data.start
            local ratios = ore_data.ratios
            local ore_weight = ore_data.weight
            local weighted = b.prepare_weighted_array(ratios)
            local land = tile_builder(tiles)

            local start_ore = b.apply_entity(land, b.resource(b.full_shape, ore_name, start_amount))
            start_ore = b.choose(start_ore_shape, start_ore, b.empty_shape)
            starting_ores_list[#starting_ores_list + 1] = {shape = start_ore, weight = ore_weight}

            local ore = ore_builder(ore_name, start_amount, ratios, weighted)
            local shape = b.apply_entity(land, ore)
            shapes[#shapes + 1] = {shape = shape, weight = ore_weight}
        end

        if config.main_ores_shuffle_order then
            table.shuffle_table(starting_ores_list, random_gen)
            table.shuffle_table(shapes, random_gen)
        end

        local starting_ores = b.segment_weighted_pattern(starting_ores_list)
        local ores = b.ring_weighted_pattern(shapes, circle_thickenss)

        if main_ores_rotate ~= 0 then
            -- Only makes sense to rotate starting ores as the main ores are a circle.
            starting_ores = b.rotate(starting_ores, math.rad(main_ores_rotate))
        end

        return b.any {spawn_shape, water_shape, starting_ores, ores}
    end
end
