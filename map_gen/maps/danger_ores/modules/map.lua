local Global = require 'utils.global'
local b = require 'map_gen.shared.builders'
local Perlin = require 'map_gen.shared.perlin_noise'
local table = require 'utils.table'
local math = require 'utils.math'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'
local RS = require 'map_gen.shared.redmew_surface'

local deafult_main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores'

local binary_search = table.binary_search
local perlin_noise = Perlin.noise
local floor = math.floor
local random = math.random
local bnot = bit32.bnot

local function spawn_builder(config)
    local spawn_circle = config.spawn_shape or b.circle(64)

    local water = b.circle(16)
    water = b.change_tile(water, true, 'water')
    water = b.any {b.rectangle(32, 4), b.rectangle(4, 32), water}

    local start = b.if_else(water, spawn_circle)
    return b.change_map_gen_collision_tile(start, 'water-tile', 'grass-1')
end

local function tile_builder_factory(config)
    local tile_builder_scale = config.tile_builder_scale or (1 / 64)
    local seed = seed_provider()

    return function(tiles)
        local half = #tiles / 2

        return function(x, y)
            x, y = x * tile_builder_scale, y * tile_builder_scale
            local v = perlin_noise(x, y, seed)
            v = (v + 1) * half + 1
            v = floor(v)
            return tiles[v]
        end
    end
end

local function no_op()
end

local function empty_builder()
    return b.empty_shape
end

return function(config)
    local start_ore_shape
    local resource_patches
    local dense_patches

    local function ore_builder(ore_name, amount, ratios, weighted)
        local start_ore = b.resource(b.full_shape, ore_name, amount)
        local total = weighted.total

        return function(x, y, world)
            if start_ore_shape(x, y) then
                return start_ore(x, y, world)
            end

            local resource_patches_entity = resource_patches(x, y, world)
            if resource_patches_entity ~= false then
                return resource_patches_entity
            end

            local i = random() * total
            local index = binary_search(weighted, i)
            if index < 0 then
                index = bnot(index)
            end

            local resource = ratios[index].resource
            local entity = resource(x, y, world)

            dense_patches(x, y, entity)
            entity.enable_tree_removal = false

            return entity
        end
    end

    local map
    Global.register_init(
        {},
        function(tbl)
            tbl.seed = RS.get_surface().map_gen_settings.seed
            tbl.random = game.create_random_generator(tbl.seed)
        end,
        function(tbl)
            local spawn_shape = spawn_builder(config)
            local water_shape = (config.water or empty_builder)(config)
            local tile_builder = tile_builder_factory(config)
            local trees_shape = (config.trees or no_op)(config)
            local enemy_shape = (config.enemy or no_op)(config)
            local fish_spawn_rate = config.fish_spawn_rate
            local main_ores_builder = (config.main_ores_builder or deafult_main_ores_builder)(config)

            start_ore_shape = config.start_ore_shape or b.circle(68)
            resource_patches = (config.resource_patches or no_op)(config) or b.empty_shape
            dense_patches = (config.dense_patches or no_op)(config) or no_op

            local random_gen = tbl.random
            random_gen.re_seed(tbl.seed)
            map = main_ores_builder(tile_builder, ore_builder, spawn_shape, water_shape, random_gen)

            if enemy_shape then
                map = b.apply_entity(map, enemy_shape)
            end

            if trees_shape then
                map = b.apply_entity(map, trees_shape)
            end

            if fish_spawn_rate then
                map = b.fish(map, fish_spawn_rate)
            end
        end
    )

    return function(x, y, world)
        return map(x, y, world)
    end
end
