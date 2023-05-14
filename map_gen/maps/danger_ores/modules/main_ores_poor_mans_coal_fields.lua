local Helper = require 'map_gen.maps.danger_ores.modules.helper'
local b = require 'map_gen.shared.builders'

return function(config)
    local main_ores = config.main_ores
    local main_ores_split_count = config.main_ores_split_count or 1

    main_ores = Helper.split_ore(main_ores, main_ores_split_count)

    return function(tile_builder, ore_builder, spawn_shape, water_shape)
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

        local copper_shape = shapes[1]
        local coal_shape = shapes[2]
        local iron_shape = shapes[3]
        local stone_shape = shapes[4]

        local function iron_bounds(x, y)
            return x < 0 and y < 0
        end

        local function copper_bounds(x, y)
            return x >= 0 and y < 0
        end

        local function coal_bounds(_, y)
            return y >= 0
        end

        local h_water_bounds = b.line_x(3)
        local v_water_bounds = b.translate(b.line_y(3), -1, 0)
        local water_bounds = b.add(h_water_bounds, v_water_bounds)
        local water_sector = b.change_tile(water_bounds, true, 'water-shallow')

        local h_stone_bounds = b.line_x(7)
        local function v_stone_bounds(x, y)
            return x > -4 and x < 3 and y < 0
        end
        local stone_bounds = b.add(h_stone_bounds, v_stone_bounds)

        local iron_sector = b.choose(iron_bounds, iron_shape, b.empty_shape)
        local copper_sector = b.choose(copper_bounds, copper_shape, b.empty_shape)
        local coal_sector = b.choose(coal_bounds, coal_shape, b.empty_shape)
        local stone_sector = b.choose(stone_bounds, stone_shape, b.empty_shape)

        local ores = b.any({
            water_sector,
            stone_sector,
            iron_sector,
            copper_sector,
            coal_sector
        })

        local main_ores_shape = b.any {
            spawn_shape,
            water_shape,
            ores
        }

        return main_ores_shape
    end
end
