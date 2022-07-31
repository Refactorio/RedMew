local b = require 'map_gen.shared.builders'

return function(config)
    local main_ores = config.main_ores
    local shuffle_order = config.main_ores_shuffle_order

    return function(tile_builder, ore_builder, spawn_shape, water_shape, random_gen)
        local grid_tile_size = 64

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
            shapes[#shapes + 1] = shape
        end

        local count = #shapes

        local pattern = {}
        for r = 1, count do
            local row = {}
            pattern[r] = row
            for c = 1, count do
                local index = (c - r) % count + 1
                row[c] = shapes[index]
            end
        end
        local ores = b.grid_pattern_no_offset(pattern, count, count, grid_tile_size, grid_tile_size)

        if shuffle_order then
            local outer_pattern = {}
            for r = 1, 50 do
                local row = {}
                outer_pattern[r] = row
                for c = 1, 50 do
                    local index = random_gen(count)
                    row[c] = shapes[index]
                end
            end

            local outer_ores = b.grid_pattern_no_offset(outer_pattern, 50, 50, grid_tile_size, grid_tile_size)

            local start_size = grid_tile_size * 3
            ores = b.choose(b.rectangle(start_size), ores, outer_ores)
        end

        return b.any {spawn_shape, water_shape, ores}
    end
end
