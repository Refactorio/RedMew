local b = require 'map_gen.shared.builders'

return function(config)
    local main_ores = config.main_ores
    local shuffle_order = config.main_ores_shuffle_order
    local main_ores_rotate = config.main_ores_rotate or 0

    return function(tile_builder, ore_builder, spawn_shape, water_shape, random_gen)
        local shapes = {}

        for ore_name, ore_data in pairs(main_ores) do
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

        if main_ores_rotate ~= 0 then
            ores = b.rotate(ores, math.rad(main_ores_rotate))
        end

        return b.any {spawn_shape, water_shape, ores}
    end
end
