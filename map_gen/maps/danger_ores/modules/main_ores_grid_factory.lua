local b = require 'map_gen.shared.builders'
local gear_pic = b.decompress(require 'map_gen.data.presets.gear_64by64')
return function(config)
    local main_ores = config.main_ores
    local shuffle_order = config.main_ores_shuffle_order
    local gear = b.picture(gear_pic)
    return function(tile_builder, ore_builder, spawn_shape, _, random_gen)
        local grid_tile_size = 64

        local shapes = {}
        for _, ore_data in pairs(main_ores) do
            local ore_name = ore_data.name
            local tiles = {
                [1] = 'concrete'
            }
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
        -- concrete grid below ores
        local concrete_ores = b.change_tile(ores, 'concrete', 'refined-concrete')
        local plus64 = b.add(b.rectangle(64, 2), b.rectangle(2, 64))
        local plus_grid = b.single_pattern(plus64, grid_tile_size, grid_tile_size)
        ores = b.choose(plus_grid, concrete_ores, ores)

        -- water via throttle
        -- ores = b.translate(ores, 31, 31)
        -- local concrete_map = b.throttle_xy(ores, 62, 64, 62, 64)
        -- concrete_map = b.translate(concrete_map, -31, -31)
        -- local water_map = b.change_tile(concrete_map, false, 'water-shallow')

        -- spawn setup::
        local gear_shape = b.add(b.scale(gear, 1), b.circle(16))
        local square_o = b.subtract(b.rectangle(64, 64), b.rectangle(62, 62))
        gear_shape = b.subtract(gear_shape, square_o) -- trim 1 tile around
        gear_shape = b.choose(gear_shape, b.tile('orange-refined-concrete'), b.empty_shape)

        local cc_gear_shadow = b.choose(b.circle((grid_tile_size / 2) - 1), b.tile('concrete'), b.empty_shape)
        local spawn_cc_rect = b.choose(b.rectangle(grid_tile_size), concrete_ores, ores) --overlay ores
        spawn_cc_rect =  b.any({spawn_shape, gear_shape, cc_gear_shadow, spawn_cc_rect})

        -- walkways::
        local left_tile = b.tile('refined-hazard-concrete-left')
        local right_tile = b.tile('refined-hazard-concrete-right')
        local water_tiles = {
            [1] = b.tile('water'),
            [2] = b.tile('deepwater'),
            [3] = b.tile('water-shallow'),
            [4] = b.tile('water-wube')
        }
        local water_tile = water_tiles[random_gen(#water_tiles)]
        local walk_pattern = {}
        for i = 1, grid_tile_size do
            walk_pattern[i] = {}
            for j = 1, grid_tile_size do
                walk_pattern[i][j] = b.empty_shape()
                if i == 1 or i == 64 then
                    walk_pattern[i][j] = water_tile
                end
                if j == 1 or j == 64 then
                    walk_pattern[i][j] = water_tile
                end
            end
          end
        -- middle x
        -- top
        walk_pattern[ 1][32] = right_tile -- b.tile('red-refined-concrete')
        walk_pattern[ 1][33] = left_tile  -- b.tile('green-refined-concrete')
        -- bottom
        walk_pattern[64][32] = left_tile  -- b.tile('blue-refined-concrete')
        walk_pattern[64][33] = right_tile -- b.tile('yellow-refined-concrete')
        -- middle y
        -- left
        walk_pattern[32][ 1] = right_tile -- b.tile('orange-refined-concrete')
        walk_pattern[33][ 1] = left_tile  -- b.tile('pink-refined-concrete')
        -- right
        walk_pattern[32][64] = left_tile  -- b.tile('purple-refined-concrete')
        walk_pattern[33][64] = right_tile -- b.tile('cyan-refined-concrete')

        local hazard_grid =  b.grid_pattern_no_offset(walk_pattern, 64, 64, 1, 1)
        hazard_grid = b.translate(hazard_grid, 33, 33)

        local map = b.any {hazard_grid, spawn_cc_rect, ores}
        return b.set_hidden_tile(map, 'sand-1') -- tile below concrete
    end
end
