local Helper = require 'map_gen.maps.danger_ores.modules.helper'
local b = require 'map_gen.shared.builders'
local table = require 'utils.table'

-- MAP SHAPE GENERATION
local gradient = 0.5
local segment_height = 64
local branch_gradient = 0.3

local baubel_1 = b.picture(require 'map_gen.data.presets.baubel_1')
baubel_1 = b.scale(baubel_1, 0.4)

local baubel_2 = b.picture(require 'map_gen.data.presets.baubel_2')
baubel_2 = b.scale(baubel_2, 0.1)

local baubel_3 = b.picture(require 'map_gen.data.presets.baubel_3')
baubel_3 = b.scale(baubel_3, 0.1)

local baubel_4 = b.picture(require 'map_gen.data.presets.baubel_4')
baubel_4 = b.scale(baubel_4, 0.1)

local star = b.picture(require 'map_gen.data.presets.star')
star = b.scale(star, 0.1)
star = b.change_tile(star, true, 'sand-1')
star = b.translate(star, 0, -70)

return function(config)
    local raw_spawn_shape = config.spawn_shape
    local raw_start_ore_shape = config.start_ore_shape
    local main_ores = config.main_ores
    local main_ores_split_count = config.main_ores_split_count or 1

    main_ores = Helper.split_ore(main_ores, main_ores_split_count)

    return function(tile_builder, ore_builder, _, _, random_gen)

        local function tree(x, y)
            local abs_x = math.abs(x)
            local abs_y = math.abs(y)
            return abs_x <= ((abs_y * gradient) + (branch_gradient * (abs_y % segment_height))) and y >= 0
        end

        tree = b.translate(tree, 0, -30)
        tree = b.change_tile(tree, true, 'grass-2')

        local icons = {baubel_1, baubel_2, baubel_3, baubel_4}

        local icons_count = #icons
        local value = b.euclidean_value
        local ore_value = b.exponential_value(0, 0.3, 1.3)

        local function non_transform(shape)
            return shape
        end

        local function empty_transform()
            return b.empty_shape
        end

        local full_oil_shape = b.translate(b.throttle_xy(b.full_shape, 3, 6, 3, 6), -1, -1)
        full_oil_shape = b.use_world_as_local(full_oil_shape)
        local oil_shape = b.throttle_world_xy(b.full_shape, 1, 6, 1, 6)

        local ores = {
            {transform = non_transform, resource = 'iron-ore', value = ore_value, weight = 10},
            {transform = non_transform, resource = 'copper-ore', value = ore_value, weight = 10},
            {transform = non_transform, resource = 'stone', value = ore_value, weight = 2},
            {transform = non_transform, resource = 'coal', value = ore_value, weight = 10},
            {transform = non_transform, resource = 'uranium-ore', value = value(100, 1.55), weight = 5},
            {transform = non_transform, resource = 'crude-oil', value = value(100000, 3500), weight = 15},
            {transform = empty_transform, weight = 100}
        }

        local total_weights = {}
        local t = 0
        for _, v in ipairs(ores) do
            t = t + v.weight
            table.insert(total_weights, t)
        end

        local p_cols = 50
        local p_rows = 50
        local pattern = {}

        for _ = 1, p_rows do
            local row = {}
            table.insert(pattern, row)
            for _ = 1, p_cols do
                local shape = icons[random_gen(1, icons_count)]

                local i = random_gen(1, t)
                local index = table.binary_search(total_weights, i)
                if (index < 0) then
                    index = bit32.bnot(index)
                end

                local ore_data = ores[index]
                shape = ore_data.transform(shape)

                local x = random_gen(-24, 24)
                local y = random_gen(-24, 24)
                shape = b.translate(shape, x, y)

                local filter_shape = b.full_shape
                if ore_data.resource == 'crude-oil' then
                    filter_shape = oil_shape
                    shape = b.all {shape, full_oil_shape}
                end

                local ore = b.resource(filter_shape, ore_data.resource, ore_data.value)

                table.insert(row, b.apply_entity(shape, ore))
            end
        end

        local ore_shape = b.project_pattern(pattern, 250, 1.0625, 50, 50)
        ore_shape = b.scale(ore_shape, 0.1)
        ore_shape = b.if_else(ore_shape, b.no_entity)

        local baubel_ore = b.choose(b.subtract(tree, raw_start_ore_shape), ore_shape, b.empty_shape)

        -- COMBINGING IT ALL
        local sea = b.change_tile(b.full_shape, true, 'water') -- turn the void to water.

        local shapes = {}

        -- Move iron ore to middle.
        main_ores = {main_ores[1], main_ores[3], main_ores[2]}

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

        local ore_weight = 3
        local additional_weight = 9.75
        local total_weight = ore_weight + additional_weight
        local rotation = (0.25 - (ore_weight / total_weight / 2)) * 2 * math.pi

        shapes[#shapes + 1] = {shape = b.full_shape, weight = additional_weight}

        local ores_part = b.segment_weighted_pattern(shapes)
        ores_part = b.rotate(ores_part, rotation)

        local main_ores_shape = b.any {raw_spawn_shape, ores_part}
        main_ores_shape = b.choose(tree, main_ores_shape, b.empty_shape)
        main_ores_shape = b.any {star, baubel_ore, main_ores_shape, sea}
        main_ores_shape = b.change_map_gen_collision_tile(main_ores_shape, 'water-tile', 'grass-2')

        return main_ores_shape
    end
end
