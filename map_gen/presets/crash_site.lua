require 'map_gen.presets.crash_site.blueprint_extractor'
require 'map_gen.presets.crash_site.entity_died_events'
require 'map_gen.presets.crash_site.weapon_balance'

local b = require 'map_gen.shared.builders'
local Global = require('utils.global')
local Random = require 'map_gen.shared.random'
local OutpostBuilder = require 'map_gen.presets.crash_site.outpost_builder'
local math = require "utils.math"

-- leave seeds nil to have them filled in based on teh map seed.
local outpost_seed = nil --91000
local ore_seed = nil --92000

local small_iron_plate_factory = require 'map_gen.presets.crash_site.outpost_data.small_iron_plate_factory'
local medium_iron_plate_factory = require 'map_gen.presets.crash_site.outpost_data.medium_iron_plate_factory'
local big_iron_plate_factory = require 'map_gen.presets.crash_site.outpost_data.big_iron_plate_factory'

local small_copper_plate_factory = require 'map_gen.presets.crash_site.outpost_data.small_copper_plate_factory'
local medium_copper_plate_factory = require 'map_gen.presets.crash_site.outpost_data.medium_copper_plate_factory'
local big_copper_plate_factory = require 'map_gen.presets.crash_site.outpost_data.big_copper_plate_factory'

local small_stone_factory = require 'map_gen.presets.crash_site.outpost_data.small_stone_factory'
local medium_stone_factory = require 'map_gen.presets.crash_site.outpost_data.medium_stone_factory'
local big_stone_factory = require 'map_gen.presets.crash_site.outpost_data.big_stone_factory'

local small_gear_factory = require 'map_gen.presets.crash_site.outpost_data.small_gear_factory'
local medium_gear_factory = require 'map_gen.presets.crash_site.outpost_data.medium_gear_factory'
local big_gear_factory = require 'map_gen.presets.crash_site.outpost_data.big_gear_factory'

local small_circuit_factory = require 'map_gen.presets.crash_site.outpost_data.small_circuit_factory'
local medium_circuit_factory = require 'map_gen.presets.crash_site.outpost_data.medium_circuit_factory'
local big_circuit_factory = require 'map_gen.presets.crash_site.outpost_data.big_circuit_factory'

local small_ammo_factory = require 'map_gen.presets.crash_site.outpost_data.small_ammo_factory'
local medium_ammo_factory = require 'map_gen.presets.crash_site.outpost_data.medium_ammo_factory'
local big_ammo_factory = require 'map_gen.presets.crash_site.outpost_data.big_ammo_factory'

local small_weapon_factory = require 'map_gen.presets.crash_site.outpost_data.small_weapon_factory'
local medium_weapon_factory = require 'map_gen.presets.crash_site.outpost_data.medium_weapon_factory'
local big_weapon_factory = require 'map_gen.presets.crash_site.outpost_data.big_weapon_factory'

local small_science_factory = require 'map_gen.presets.crash_site.outpost_data.small_science_factory'
local medium_science_factory = require 'map_gen.presets.crash_site.outpost_data.medium_science_factory'
local big_science_factory = require 'map_gen.presets.crash_site.outpost_data.big_science_factory'

local small_oil_refinery = require 'map_gen.presets.crash_site.outpost_data.small_oil_refinery'
local medium_oil_refinery = require 'map_gen.presets.crash_site.outpost_data.medium_oil_refinery'
local big_oil_refinery = require 'map_gen.presets.crash_site.outpost_data.big_oil_refinery'

local small_chemical_factory = require 'map_gen.presets.crash_site.outpost_data.small_chemical_factory'
local medium_chemical_factory = require 'map_gen.presets.crash_site.outpost_data.medium_chemical_factory'
local big_chemical_factory = require 'map_gen.presets.crash_site.outpost_data.big_chemical_factory'

local small_power_factory = require 'map_gen.presets.crash_site.outpost_data.small_power_factory'
local medium_power_factory = require 'map_gen.presets.crash_site.outpost_data.medium_power_factory'
local big_power_factory = require 'map_gen.presets.crash_site.outpost_data.big_power_factory'

local thin_walls = require 'map_gen.presets.crash_site.outpost_data.thin_walls'

local function init()
    local outpost_random = Random.new(outpost_seed, outpost_seed * 2)

    local outpost_builder = OutpostBuilder.new(outpost_random)

    local stage1a = {
        small_iron_plate_factory,
        small_gear_factory,
        small_copper_plate_factory,
        small_stone_factory
    }

    local stage1a_pos = {
        {4, 5},
        {5, 4},
        {5, 6},
        {6, 5}
    }

    local stage1b = {
        small_circuit_factory,
        small_science_factory,
        small_oil_refinery,
        small_chemical_factory,
        small_power_factory
    }

    local stage1b_pos = {
        {4, 4},
        {4, 6},
        {6, 4},
        {6, 6},
        {3, 5},
        {5, 3},
        {5, 7},
        {7, 5}
    }

    local stage2 = {
        medium_iron_plate_factory,
        medium_copper_plate_factory,
        medium_stone_factory,
        medium_gear_factory,
        medium_circuit_factory,
        small_ammo_factory,
        small_ammo_factory,
        small_weapon_factory,
        small_science_factory,
        medium_science_factory,
        medium_oil_refinery,
        medium_chemical_factory,
        medium_power_factory
    }

    local stage2_pos = {
        {2, 5},
        {5, 2},
        {5, 8},
        {8, 5},
        {3, 3},
        {3, 4},
        {3, 6},
        {3, 7},
        {4, 3},
        {4, 7},
        {6, 3},
        {6, 7},
        {7, 3},
        {7, 4},
        {7, 6},
        {7, 7}
    }

    local stage3 = {
        big_iron_plate_factory,
        big_copper_plate_factory,
        big_stone_factory,
        big_gear_factory,
        big_circuit_factory,
        medium_ammo_factory,
        medium_ammo_factory,
        medium_weapon_factory,
        medium_science_factory,
        big_science_factory,
        big_oil_refinery,
        big_chemical_factory,
        big_power_factory
    }

    local stage4 = {
        big_iron_plate_factory,
        big_copper_plate_factory,
        big_gear_factory,
        big_circuit_factory,
        big_ammo_factory,
        big_ammo_factory,
        big_ammo_factory,
        big_weapon_factory,
        big_weapon_factory,
        big_weapon_factory,
        big_science_factory,
        big_oil_refinery,
        big_chemical_factory
    }

    local function fast_remove(tbl, index)
        local count = #tbl
        if index > count then
            return
        elseif index < count then
            tbl[index] = tbl[count]
        end

        tbl[count] = nil
    end

    local function itertor_builder(arr, random)
        local copy = {}

        return function()
            if #copy == 0 then
                for i = 1, #arr do
                    copy[i] = arr[i]
                end
            end

            local i = random:next_int(1, #copy)
            local res = copy[i]

            fast_remove(copy, i)

            return res
        end
    end

    local stage1a_iter = itertor_builder(stage1a, outpost_random)
    local stage1b_iter = itertor_builder(stage1b, outpost_random)

    local stage2_iter = itertor_builder(stage2, outpost_random)
    local stage3_iter = itertor_builder(stage3, outpost_random)
    local stage4_iter = itertor_builder(stage4, outpost_random)

    local start_outpost = outpost_builder:do_outpost(thin_walls)

    local function remove_water(shape)
        return function(x, y, world)
            local tile = shape(x, y, world)

            if type(tile) == 'table' then
                local gen_tile = world.surface.get_tile(world.x, world.y)
                if gen_tile.collides_with('water-tile') then
                    tile.tile = 'grass-1'
                end
            else
                local gen_tile = world.surface.get_tile(world.x, world.y)
                if gen_tile.collides_with('water-tile') then
                    tile = 'grass-1'
                end
            end

            return tile
        end
    end

    start_outpost = remove_water(start_outpost)

    local start_patch = b.circle(10)
    local start_iron_patch =
        b.resource(
        b.translate(start_patch, -32, -32),
        'iron-ore',
        function()
            return 1500
        end
    )
    local start_copper_patch =
        b.resource(
        b.translate(start_patch, 32, -32),
        'copper-ore',
        function()
            return 1200
        end
    )
    local start_stone_patch =
        b.resource(
        b.translate(start_patch, 32, 32),
        'stone',
        function()
            return 900
        end
    )
    local start_coal_patch =
        b.resource(
        b.translate(start_patch, -32, 32),
        'coal',
        function()
            return 1350
        end
    )

    local start_resources = b.any({start_iron_patch, start_copper_patch, start_stone_patch, start_coal_patch})
    start_outpost = b.apply_entity(start_outpost, start_resources)

    local water_corner =
        b.any {
        b.translate(b.rectangle(6, 16), -6, 0),
        b.translate(b.rectangle(16, 6), 0, -6)
    }
    water_corner = b.change_tile(water_corner, true, 'water')
    water_corner = b.translate(water_corner, -60, -60)

    start_outpost =
        b.any {
        water_corner,
        b.rotate(water_corner, degrees(90)),
        b.rotate(water_corner, degrees(180)),
        b.rotate(water_corner, degrees(270)),
        start_outpost
    }

    local pattern = {}

    for r = 1, 10 do
        local row = {}
        pattern[r] = row
    end

    pattern[5][5] = start_outpost

    local outpost_offset = 59
    local grid_block_size = 190
    local grid_number_of_blocks = 9

    local half_total_size = grid_block_size * 0.5 * 8

    for _, pos in ipairs(stage1a_pos) do
        local r, c = pos[1], pos[2]

        local row = pattern[r]

        local template = stage1a_iter()
        local shape = outpost_builder:do_outpost(template)

        local x = outpost_random:next_int(-outpost_offset, outpost_offset)
        local y = outpost_random:next_int(-outpost_offset, outpost_offset)
        shape = b.translate(shape, x, y)

        row[c] = shape
    end

    for _, pos in ipairs(stage1b_pos) do
        local r, c = pos[1], pos[2]

        local row = pattern[r]

        local template = stage1b_iter()
        local shape = outpost_builder:do_outpost(template)

        local x = outpost_random:next_int(-outpost_offset, outpost_offset)
        local y = outpost_random:next_int(-outpost_offset, outpost_offset)
        shape = b.translate(shape, x, y)

        row[c] = shape
    end

    for _, pos in ipairs(stage2_pos) do
        local r, c = pos[1], pos[2]

        local row = pattern[r]

        local template = stage2_iter()
        local shape = outpost_builder:do_outpost(template)

        local x = outpost_random:next_int(-outpost_offset, outpost_offset)
        local y = outpost_random:next_int(-outpost_offset, outpost_offset)
        shape = b.translate(shape, x, y)

        row[c] = shape
    end

    for r = 2, 8 do
        local row = pattern[r]
        for c = 2, 8 do
            if not row[c] then
                local template = stage3_iter()
                local shape = outpost_builder:do_outpost(template)

                local x = outpost_random:next_int(-outpost_offset, outpost_offset)
                local y = outpost_random:next_int(-outpost_offset, outpost_offset)
                shape = b.translate(shape, x, y)

                row[c] = shape
            end
        end
    end

    for r = 1, grid_number_of_blocks do
        local row = pattern[r]
        for c = 1, grid_number_of_blocks do
            if not row[c] then
                local template = stage4_iter()
                local shape = outpost_builder:do_outpost(template)

                local x = outpost_random:next_int(-outpost_offset, outpost_offset)
                local y = outpost_random:next_int(-outpost_offset, outpost_offset)
                shape = b.translate(shape, x, y)

                row[c] = shape
            end
        end
    end

    local outposts = b.grid_pattern(pattern, 10, 10, grid_block_size, grid_block_size)
    --outposts = b.if_else(outposts, b.full_shape)

    local spawners = {
        'biter-spawner',
        'spitter-spawner'
    }

    local worms = {
        'small-worm-turret',
        'medium-worm-turret',
        'big-worm-turret'
    }

    local max_spawner_chance = 1 / 256
    local spawner_chance_factor = 1 / (256 * 512)
    local max_worm_chance = 1 / 32
    local worm_chance_factor = 1 / (32 * 512)

    local scale_factor = 1 / 32

    local function enemy(x, y, world)
        local wx, wy = world.x, world.y
        local d = math.sqrt(wx * wx + wy * wy)

        --[[ if Perlin.noise(x * scale_factor, y * scale_factor, enemy_seed) < 0 then
        return nil
    end ]]
        local spawner_chance = d - 128

        if spawner_chance > 0 then
            spawner_chance = spawner_chance * spawner_chance_factor
            spawner_chance = math.min(spawner_chance, max_spawner_chance)

            if math.random() < spawner_chance then
                return {name = spawners[math.random(2)]}
            end
        end

        local worm_chance = d - 128

        if worm_chance > 0 then
            worm_chance = worm_chance * worm_chance_factor
            worm_chance = math.min(worm_chance, max_worm_chance)

            if math.random() < worm_chance then
                if d < 256 then
                    return {name = 'small-worm-turret'}
                else
                    local max_lvl
                    local min_lvl
                    if d < 512 then
                        max_lvl = 2
                        min_lvl = 1
                    else
                        max_lvl = 3
                        min_lvl = 2
                    end
                    local lvl = math.random() ^ (384 / d) * max_lvl
                    lvl = math.ceil(lvl)
                    --local lvl = math.floor(d / 256) + 1
                    lvl = math.clamp(lvl, min_lvl, 3)
                    return {name = worms[lvl]}
                end
            end
        end
    end

    local enemy_shape = b.apply_entity(b.full_shape, enemy)

    local ores_patch = b.circle(16)
    local function value(base, mult, pow)
        return function(x, y)
            local d_sq = x * x + y * y
            return base + mult * d_sq ^ (pow / 2) -- d^pow
        end
    end

    local function non_transform(shape)
        return shape
    end

    local function uranium_transform(shape)
        return b.scale(shape, 0.5)
    end

    local function oil_transform(shape)
        shape = b.scale(shape, 0.5)
        shape = b.throttle_world_xy(shape, 1, 5, 1, 5)
        return shape
    end

    local ores = {
        {weight = 300},
        {transform = non_transform, resource = 'iron-ore', value = value(500, 0.75, 1.1), weight = 16},
        {transform = non_transform, resource = 'copper-ore', value = value(400, 0.75, 1.1), weight = 10},
        {transform = non_transform, resource = 'stone', value = value(250, 0.3, 1.05), weight = 5},
        {transform = non_transform, resource = 'coal', value = value(400, 0.8, 1.075), weight = 8},
        {transform = uranium_transform, resource = 'uranium-ore', value = value(200, 0.3, 1.025), weight = 3},
        {transform = oil_transform, resource = 'crude-oil', value = value(180000, 50, 1.025), weight = 6}
    }

    local total_ore_weights = {}
    local ore_t = 0
    for _, v in ipairs(ores) do
        ore_t = ore_t + v.weight
        table.insert(total_ore_weights, ore_t)
    end

    local random_ore = Random.new(ore_seed, ore_seed * 2)
    local ore_pattern = {}

    for r = 1, 50 do
        local row = {}
        ore_pattern[r] = row
        for c = 1, 50 do
            local i = random_ore:next_int(1, ore_t)
            local index = table.binary_search(total_ore_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end
            local ore_data = ores[index]

            local transform = ore_data.transform
            if not transform then
                row[c] = b.no_entity
            else
                local ore_shape = transform(ores_patch)

                local x = random_ore:next_int(-24, 24)
                local y = random_ore:next_int(-24, 24)
                ore_shape = b.translate(ore_shape, x, y)

                local ore = b.resource(ore_shape, ore_data.resource, ore_data.value)
                row[c] = ore
            end
        end
    end

    local ore_grid = b.grid_pattern_full_overlap(ore_pattern, 50, 50, 64, 64)
    ore_grid = b.choose(b.rectangle(138), b.no_entity, ore_grid)

    local map = b.if_else(outposts, enemy_shape)
    --map = b.change_tile(map, true, 'grass-1')
    map = b.if_else(map, b.full_shape)

    map = b.translate(map, -half_total_size, -half_total_size)

    map = b.apply_entity(map, ore_grid)

    --map = b.apply_entity(map, enemy)

    local market = {
        callback = outpost_builder.market_set_items_callback,
        data = {
            {name = 'raw-wood', price = 1},
            {name = 'iron-plate', price = 2},
            {name = 'stone', price = 2},
            {name = 'coal', price = 1.25},
            {name = 'raw-fish', price = 4},
            {name = 'firearm-magazine', price = 5},
            {name = 'science-pack-1', price = 20},
            {name = 'science-pack-2', price = 40},
            {name = 'military-science-pack', price = 80},
            {name = 'science-pack-3', price = 120},
            {name = 'production-science-pack', price = 240},
            {name = 'high-tech-science-pack', price = 360},
            {name = 'small-plane', price = 100}
        }
    }

    local factory = {
        callback = outpost_builder.magic_item_crafting_callback,
        data = {
            output = {min_rate = 0.5 / 60, distance_factor = 0, item = 'coin'}
        }
    }

    local spawn = {
        size = 2,
        [1] = {
            market = market,
            [15] = {entity = {name = 'market', callback = 'market'}}
        },
        [2] = {
            force = 'player',
            factory = factory,
            [15] = {entity = {name = 'electric-furnace', callback = 'factory'}}
        }
    }

    local spawn_shape = outpost_builder.to_shape(spawn)
    spawn_shape = b.change_tile(spawn_shape, false, 'stone-path')

    map = b.choose(b.rectangle(16, 16), spawn_shape, map)

    local bounds = b.rectangle(grid_block_size * grid_number_of_blocks)
    map = b.choose(bounds, map, b.empty_shape)

    return map
end

local map

Global.register_init(
    {},
    function(tbl)
        local seed = game.surfaces[1].map_gen_settings.seed
        tbl.outpost_seed = outpost_seed or seed
        tbl.ore_seed = ore_seed or seed

        global.scenario.config.fish_market.enable = false
    end,
    function(tbl)
        outpost_seed = tbl.outpost_seed
        ore_seed = tbl.ore_seed
        map = init()
    end
)

return function(x, y, world)
    return map(x, y, world)
end
