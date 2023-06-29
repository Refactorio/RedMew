local b = require 'map_gen.shared.builders'
local Helper = require 'map_gen.maps.danger_ores.modules.helper'
local table = require 'utils.table'
local pic = b.decompress(require 'map_gen.data.presets.honeycomb')

local function no_op()
end

return function(config)
    local main_ores = config.main_ores
    local shuffle_order = config.main_ores_shuffle_order
    local main_ores_rotate = config.main_ores_rotate or 0
    local resource_patches = (config.resource_patches or no_op)(config) or b.empty_shape
    local dense_patches = (config.dense_patches or no_op)(config) or no_op
    local main_ores_split_count = config.main_ores_split_count or 1

    local map_preset = b.picture(pic)

    main_ores = Helper.split_ore(main_ores, main_ores_split_count)

    local start_ore_shape = config.start_ore_shape or b.circle(68)

    local function apply_resource_patches(x, y, world, entity)
        local resource_patches_entity = resource_patches(x, y, world)
        if resource_patches_entity ~= false then
            return resource_patches_entity
        end

        dense_patches(x, y, entity)
        entity.enable_tree_removal = false

        return entity
    end

    return function(tile_builder, _, spawn_shape, _, random_gen)
        if shuffle_order then
            local rot = random_gen(#main_ores)
            main_ores = table.rotate_table(main_ores, rot)
        end

        local start_ore_shapes = {}
        local ore_pattern = {}
        for _, ore_data in pairs(main_ores) do
            local ore_name = ore_data.name
            start_ore_shapes[#start_ore_shapes + 1] = b.resource(b.full_shape, ore_name, ore_data.start)
            ore_pattern[#ore_pattern + 1] = ore_data
        end

        local land = tile_builder({'sand-1', 'sand-2', 'sand-1', 'sand-2'})
        local start_ores = b.segment_pattern(start_ore_shapes)
        start_ores = b.rotate(start_ores, math.rad(45))
        local main_ores_shape = b.gradient_pattern(ore_pattern)
        main_ores_shape = b.apply_effect(main_ores_shape, apply_resource_patches)

        local ores = b.choose(start_ore_shape, start_ores, main_ores_shape)

        local invers_map = b.single_pattern(b.invert(map_preset), pic.width-1, pic.height-1)
        local map = b.apply_entity(land, ores)

        if main_ores_rotate ~= 0 then
            map = b.rotate(map, math.rad(main_ores_rotate))
        end
        map = b.subtract(map, invers_map)
        map = b.change_tile(map, false, 'water-shallow')
        return b.any{spawn_shape, map}
    end
end
