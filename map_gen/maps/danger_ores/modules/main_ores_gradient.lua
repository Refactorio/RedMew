local b = require 'map_gen.shared.builders'
local table = require 'utils.table'

return function(config)
    local main_ores = config.main_ores
    local shuffle_order = config.main_ores_shuffle_order
    local main_ores_rotate = config.main_ores_rotate or 0

    local start_ore_shape = config.start_ore_shape or b.circle(68)

    return function(tile_builder, ore_builder, spawn_shape, water_shape, random_gen)
        local pattern = {}
        for ore_name, data in pairs(main_ores) do
            pattern[#pattern + 1] = {ore_name = ore_name, data = data}
        end

        if shuffle_order then
            table.shuffle_table(pattern, random_gen)
        end

        local start_ore_shapes = {}
        local ore_pattern = {}
        for _, value in pairs(pattern) do
            local ore_name = value.ore_name
            local data = value.data
            start_ore_shapes[#start_ore_shapes + 1] = b.resource(b.full_shape, ore_name, data.start)
            ore_pattern[#ore_pattern + 1] = data
        end

        local land = tile_builder({'grass-1', 'grass-2', 'grass-3', 'grass-4'})

        local start_ores = b.segment_pattern(start_ore_shapes)
        start_ores = b.rotate(start_ores, math.rad(45))
        local main_ores = b.gradient_pattern(ore_pattern)
        local ores = b.choose(start_ore_shape, start_ores, main_ores)

        local map = b.apply_entity(land, ores)

        if main_ores_rotate ~= 0 then
            map = b.rotate(map, math.rad(main_ores_rotate))
        end

        return b.any {spawn_shape, water_shape, map}
    end
end
