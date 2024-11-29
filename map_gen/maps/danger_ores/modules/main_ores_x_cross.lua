local Helper = require 'map_gen.maps.danger_ores.modules.helper'
local b = require 'map_gen.shared.builders'
local table = require 'utils.table'

return function(config)
    local main_ores = config.main_ores
    local shuffle_order = config.main_ores_shuffle_order
    local main_ores_rotate = config.main_ores_rotate or 0
    local main_ores_split_count = config.main_ores_split_count or 1

    main_ores = Helper.split_ore(main_ores, main_ores_split_count)

    return function(tile_builder, ore_builder, spawn_shape, water_shape, random_gen)
        local shapes = {}

        for _, ore_data in pairs(main_ores) do
            local ore_name = ore_data.name
            local tiles = ore_data.tiles
            local land = tile_builder(tiles)

            local ratios = ore_data.ratios
            local weighted = b.prepare_weighted_array(ratios)
            local amount = ore_data.start

            local ore = ore_builder(ore_name, amount, ratios, weighted)

            local shape = b.apply_entity(land, ore)
            shapes[#shapes + 1] = {shape = shape, weight = ore_data.weight}
        end

        if shuffle_order then
            table.shuffle_table(shapes, random_gen)
        end

        local ores = b.segment_weighted_pattern(shapes)
        ores = b.rotate(ores, math.rad(135))

        local main_ores_shape = b.any {spawn_shape, water_shape, ores}

        local h_bound = b.line_x(124)
        local v_bound = b.line_y(124)
        local cross = b.any {h_bound, v_bound}

        local water_h_bound = b.line_x(128)
        local water_v_bound = b.line_y(128)
        local water_cross = b.any {water_h_bound, water_v_bound}
        local water_tiles = b.tile('water')
        local water_border = b.choose(water_cross, water_tiles, b.empty_shape)

        local main_shape = b.choose(cross, main_ores_shape, water_border)

        if main_ores_rotate ~= 0 then
            main_shape = b.rotate(main_shape, math.rad(main_ores_rotate))
        end

        return main_shape
    end
end
