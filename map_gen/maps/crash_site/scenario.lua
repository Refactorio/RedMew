require 'map_gen.maps.crash_site.blueprint_extractor'
require 'map_gen.maps.crash_site.events'
require 'map_gen.maps.crash_site.weapon_balance'
require 'map_gen.maps.crash_site.features.rocket_tanks'
require 'map_gen.maps.crash_site.features.vehicle_repair_beams'
require 'map_gen.maps.crash_site.features.deconstruction_targetting'
require 'features.fish_burps'

local b = require 'map_gen.shared.builders'
local Global = require('utils.global')
local Random = require 'map_gen.shared.random'
local OutpostBuilder = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'
local Task = require 'utils.task'
local math = require 'utils.math'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local RedmewConfig = require 'config'
local Cutscene = require 'map_gen.maps.crash_site.cutscene'
local cutscene_surface_settings = require 'map_gen.maps.crash_site.cutscene_surface_settings'

local degrees = math.degrees
local cutscene_force_name = 'cutscene'

local default_map_gen_settings = {
    MGSP.grass_only,
    MGSP.enable_water,
    {
        terrain_segmentation = 6,
        water = 0.25
    },
    MGSP.starting_area_very_low,
    MGSP.ore_oil_none,
    MGSP.enemy_none,
    MGSP.cliff_none
}

local configuration

local function control(config)
    configuration = config
    local CSCommand = require 'map_gen.maps.crash_site.commands'
    CSCommand.control(config)

    local map_gen_settings = config.map_gen_settings or default_map_gen_settings
    RS.set_map_gen_settings(map_gen_settings)
end

RedmewConfig.market.enabled = false
RedmewConfig.biter_attacks.enabled = false
RedmewConfig.dump_offline_inventories = {
    enabled = true,
    offline_timout_mins = 15,   -- time after which a player logs off that their inventory is provided to the team
}

-- leave seeds nil to have them filled in based on the map seed.
local outpost_seed = nil --91000
local ore_seed = nil --92000

local thin_walls = require 'map_gen.maps.crash_site.outpost_data.thin_walls'

local outpost_paths = {}
outpost_paths['small_iron_plate_factory'] = require 'map_gen.maps.crash_site.outpost_data.small_iron_plate_factory'
outpost_paths['medium_iron_plate_factory'] = require 'map_gen.maps.crash_site.outpost_data.medium_iron_plate_factory'
outpost_paths['big_iron_plate_factory'] = require 'map_gen.maps.crash_site.outpost_data.big_iron_plate_factory'

outpost_paths['small_copper_plate_factory'] = require 'map_gen.maps.crash_site.outpost_data.small_copper_plate_factory'
outpost_paths['medium_copper_plate_factory'] = require 'map_gen.maps.crash_site.outpost_data.medium_copper_plate_factory'
outpost_paths['big_copper_plate_factory'] = require 'map_gen.maps.crash_site.outpost_data.big_copper_plate_factory'

outpost_paths['small_stone_factory'] = require 'map_gen.maps.crash_site.outpost_data.small_stone_factory'
outpost_paths['medium_stone_factory'] = require 'map_gen.maps.crash_site.outpost_data.medium_stone_factory'
outpost_paths['big_stone_factory'] = require 'map_gen.maps.crash_site.outpost_data.big_stone_factory'

outpost_paths['small_gear_factory'] = require 'map_gen.maps.crash_site.outpost_data.small_gear_factory'
outpost_paths['medium_gear_factory'] = require 'map_gen.maps.crash_site.outpost_data.medium_gear_factory'
outpost_paths['big_gear_factory'] = require 'map_gen.maps.crash_site.outpost_data.big_gear_factory'

outpost_paths['small_circuit_factory'] = require 'map_gen.maps.crash_site.outpost_data.small_circuit_factory'
outpost_paths['medium_circuit_factory'] = require 'map_gen.maps.crash_site.outpost_data.medium_circuit_factory'
outpost_paths['big_circuit_factory'] = require 'map_gen.maps.crash_site.outpost_data.big_circuit_factory'

outpost_paths['small_ammo_factory'] = require 'map_gen.maps.crash_site.outpost_data.small_ammo_factory'
outpost_paths['medium_ammo_factory'] = require 'map_gen.maps.crash_site.outpost_data.medium_ammo_factory'
outpost_paths['big_ammo_factory'] = require 'map_gen.maps.crash_site.outpost_data.big_ammo_factory'

outpost_paths['small_weapon_factory'] = require 'map_gen.maps.crash_site.outpost_data.small_weapon_factory'
outpost_paths['medium_weapon_factory'] = require 'map_gen.maps.crash_site.outpost_data.medium_weapon_factory'
outpost_paths['big_weapon_factory'] = require 'map_gen.maps.crash_site.outpost_data.big_weapon_factory'

outpost_paths['small_science_factory'] = require 'map_gen.maps.crash_site.outpost_data.small_science_factory'
outpost_paths['medium_science_factory'] = require 'map_gen.maps.crash_site.outpost_data.medium_science_factory'
outpost_paths['big_science_factory'] = require 'map_gen.maps.crash_site.outpost_data.big_science_factory'

outpost_paths['small_oil_refinery'] = require 'map_gen.maps.crash_site.outpost_data.small_oil_refinery'
outpost_paths['medium_oil_refinery'] = require 'map_gen.maps.crash_site.outpost_data.medium_oil_refinery'
outpost_paths['big_oil_refinery'] = require 'map_gen.maps.crash_site.outpost_data.big_oil_refinery'

outpost_paths['small_chemical_factory'] = require 'map_gen.maps.crash_site.outpost_data.small_chemical_factory'
outpost_paths['medium_chemical_factory'] = require 'map_gen.maps.crash_site.outpost_data.medium_chemical_factory'
outpost_paths['big_chemical_factory'] = require 'map_gen.maps.crash_site.outpost_data.big_chemical_factory'

outpost_paths['small_power_factory'] = require 'map_gen.maps.crash_site.outpost_data.small_power_factory'
outpost_paths['medium_power_factory'] = require 'map_gen.maps.crash_site.outpost_data.medium_power_factory'
outpost_paths['big_power_factory'] = require 'map_gen.maps.crash_site.outpost_data.big_power_factory'

outpost_paths['mini_t1_ammo_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t1_ammo_factory'
outpost_paths['mini_t2_ammo_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t2_ammo_factory'

outpost_paths['mini_t1_weapon_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t1_weapon_factory'
outpost_paths['mini_t2_weapon_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t2_weapon_factory'

outpost_paths['mini_t2_logistics_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t2_logistics_factory'
outpost_paths['mini_t3_logistics_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t3_logistics_factory'

outpost_paths['mini_t1_science_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t1_science_factory'
outpost_paths['mini_t2_science_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t2_science_factory'
outpost_paths['mini_t3_science_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t3_science_factory'

outpost_paths['mini_t1_module_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t1_module_factory'
outpost_paths['mini_t2_module_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t2_module_factory'
outpost_paths['mini_t3_module_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t3_module_factory'

outpost_paths['mini_t1_robotics_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t1_robotics_factory'
outpost_paths['mini_t1_production_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t1_production_factory'
outpost_paths['mini_t2_energy_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t2_energy_factory'
outpost_paths['mini_t1_train_factory'] = require 'map_gen.maps.crash_site.outpost_data.mini_t1_train_factory'

local all_outpost_types_active = function()
    local active_outpost_types = {}
    for k , _ in pairs(outpost_paths) do
        active_outpost_types[k] = true
    end
    return active_outpost_types
end

local function stage_builder(stage_list, active_outpost_types)
    local stage = {}
    local j = 1
    for i = 1, #stage_list do
        local k = stage_list[i]
        if active_outpost_types[k] then
            stage[j] = outpost_paths[k]
            j = j + 1
        end
    end
    return stage
end

local spawn_callback_callback =
    Token.register(
    function(outpost_id)
        OutpostBuilder.activate_market_upgrade(outpost_id)
    end
)

local spawn_callback =
    Token.register(
    function(entity, data)
        Token.get(OutpostBuilder.market_set_items_callback)(entity, data)
        Task.set_timeout_in_ticks(1, spawn_callback_callback, data.outpost_id)
    end
)

local function cutscene_builder(name, x, y)
    return game.surfaces.cutscene.create_entity {name = name, position = {x, y}, force = cutscene_force_name}
end

local function cutscene_outpost()
    local tiles = {}
    for i = -11, 12 do
        for j = -11, 12 do
            table.insert(tiles, {name = 'stone-path', position = {i, j}})
        end
    end
    for i = 0, 22 do
        cutscene_builder('stone-wall', -11, -10 + i)
        cutscene_builder('stone-wall', -12, -10 + i)
        cutscene_builder('stone-wall', -12 + i, -11)
        cutscene_builder('stone-wall', -12 + i, -12)
        cutscene_builder('stone-wall', 11, -12 + i)
        cutscene_builder('stone-wall', 12, -12 + i)
        cutscene_builder('stone-wall', -10 + i, 11)
        cutscene_builder('stone-wall', -10 + i, 12)
        if i % 4 == 0 and i ~= 20 and i ~= 0 then
            cutscene_builder('gun-turret', -8, -8 + i)
            cutscene_builder('gun-turret', 10, -8 + i)
            cutscene_builder('gun-turret', -9 + i, -8)
            cutscene_builder('gun-turret', -9 + i, 10)
        end
    end
    for i = -2, 2 do
        for j = 3, 5 do
            local loot_box = cutscene_builder('steel-chest', i, j)
            loot_box.insert {name = 'iron-plate', count = 50}
        end
    end
    cutscene_builder('market', -4, 0)
    local furnace = cutscene_builder('electric-furnace', 4, 0)
    furnace.insert('iron-ore')
    game.surfaces.cutscene.set_tiles(tiles)
end

local function init(config)
    local on_init = (_LIFECYCLE == _STAGE.init)

    local outpost_random = Random.new(outpost_seed, outpost_seed * 2)

    local outpost_builder = OutpostBuilder.new(outpost_random)

    if on_init then
        game.create_surface('cutscene', cutscene_surface_settings)
        game.surfaces.cutscene.always_day = true
        game.surfaces.cutscene.request_to_generate_chunks({0, 0}, 2)
        game.surfaces.cutscene.force_generate_chunk_requests()
        cutscene_outpost()
        Cutscene.on_init()
    else
        Cutscene.on_load()
    end

    local outpost_offset = 59
    local grid_block_size = 180
    local grid_number_of_blocks = config.grid_number_of_blocks or 9
    local middle = math.ceil(grid_number_of_blocks / 2)

    local mini_outpost_offset = 36
    local mini_grid_block_size = 96
    local mini_grid_number_of_blocks = config.mini_grid_number_of_blocks or 21
    local mini_middle = math.ceil(mini_grid_number_of_blocks / 2)

    local active_outpost_types = config.active_outpost_types or all_outpost_types_active()

    local stage1a_list = config.stage1a_list or {
        'small_iron_plate_factory',
        'small_gear_factory',
        'small_copper_plate_factory',
        'small_stone_factory'
    }
    local stage1a = stage_builder(stage1a_list, active_outpost_types)

    local stage1a_pos = {
        {middle - 1, middle},
        {middle, middle - 1},
        {middle, middle + 1},
        {middle + 1, middle}
    }

    local stage1b_list = config.stage1b_list or  {
        'small_circuit_factory',
        'small_science_factory',
        'small_oil_refinery',
        'small_chemical_factory',
        'small_power_factory'
    }
    local stage1b = stage_builder(stage1b_list, active_outpost_types)

    local stage1b_pos = {
        {middle - 1, middle - 1},
        {middle - 1, middle + 1},
        {middle + 1, middle - 1},
        {middle + 1, middle + 1},
        {middle - 2, middle},
        {middle, middle - 2},
        {middle, middle + 2},
        {middle + 2, middle}
    }

    local stage2_list = config.stage2_list or {
        'medium_iron_plate_factory',
        'medium_copper_plate_factory',
        'medium_stone_factory',
        'medium_gear_factory',
        'medium_circuit_factory',
        'small_ammo_factory',
        'small_ammo_factory',
        'small_weapon_factory',
        'small_science_factory',
        'medium_science_factory',
        'medium_oil_refinery',
        'medium_chemical_factory',
        'medium_power_factory'
    }
    local stage2 = stage_builder(stage2_list, active_outpost_types)

    local stage2_pos = {
        {middle - 3, middle},
        {middle, middle - 3},
        {middle, middle + 3},
        {middle + 3, middle},
        {middle - 2, middle - 2},
        {middle - 2, middle - 1},
        {middle - 2, middle + 1},
        {middle - 2, middle + 2},
        {middle - 1, middle - 2},
        {middle - 1, middle + 2},
        {middle + 1, middle - 2},
        {middle + 1, middle + 2},
        {middle + 2, middle - 2},
        {middle + 2, middle - 1},
        {middle + 2, middle + 1},
        {middle + 2, middle + 2}
    }

    local stage3_list = config.stage3_list or  {
        'big_iron_plate_factory',
        'big_copper_plate_factory',
        'big_stone_factory',
        'big_gear_factory',
        'big_circuit_factory',
        'medium_ammo_factory',
        'medium_ammo_factory',
        'medium_weapon_factory',
        'medium_science_factory',
        'big_science_factory',
        'big_oil_refinery',
        'big_chemical_factory',
        'big_power_factory'
    }
    local stage3 = stage_builder(stage3_list, active_outpost_types)

    local stage4_list = config.stage4_list or {
        'big_iron_plate_factory',
        'big_copper_plate_factory',
        'big_gear_factory',
        'big_circuit_factory',
        'big_ammo_factory',
        'big_ammo_factory',
        'big_ammo_factory',
        'big_weapon_factory',
        'big_weapon_factory',
        'big_weapon_factory',
        'big_science_factory',
        'big_oil_refinery',
        'big_chemical_factory'
    }
    local stage4 = stage_builder(stage4_list, active_outpost_types)

    local mini1_list = config.mini1_list or {
        'mini_t1_ammo_factory',
        'mini_t1_ammo_factory',
        'mini_t1_weapon_factory',
        'mini_t1_weapon_factory',
        'mini_t2_logistics_factory',
        'mini_t2_logistics_factory',
        'mini_t1_science_factory',
        'mini_t1_science_factory',
        'mini_t1_module_factory',
        'mini_t1_production_factory',
        'mini_t2_energy_factory',
        'mini_t1_train_factory'
    }
    local mini1 = stage_builder(mini1_list, active_outpost_types)

    local mini2_list = config.mini2_list or {
        'mini_t2_ammo_factory',
        'mini_t2_ammo_factory',
        'mini_t2_weapon_factory',
        'mini_t2_weapon_factory',
        'mini_t3_logistics_factory',
        'mini_t3_logistics_factory',
        'mini_t2_science_factory',
        'mini_t2_science_factory',
        'mini_t2_module_factory',
        'mini_t1_robotics_factory',
        'mini_t2_energy_factory',
        'mini_t1_train_factory'
    }
    local mini2 = stage_builder(mini2_list, active_outpost_types)

    local mini3_list = config.mini3_list or {
        'mini_t2_ammo_factory',
        'mini_t2_ammo_factory',
        'mini_t2_weapon_factory',
        'mini_t2_weapon_factory',
        'mini_t3_science_factory',
        'mini_t3_module_factory',
        'mini_t1_robotics_factory'
    }
    local mini3 = stage_builder(mini3_list, active_outpost_types)

    local function fast_remove(tbl, index)
        local count = #tbl
        if index > count then
            return
        elseif index < count then
            tbl[index] = tbl[count]
        end

        tbl[count] = nil
    end

    local function iterator_builder(arr, random)
        local copy = {}
        if #arr == 0 then
            return function()
                return nil
            end
        end

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

    local stage1a_iter = iterator_builder(stage1a, outpost_random)
    local stage1b_iter = iterator_builder(stage1b, outpost_random)

    local stage2_iter = iterator_builder(stage2, outpost_random)
    local stage3_iter = iterator_builder(stage3, outpost_random)
    local stage4_iter = iterator_builder(stage4, outpost_random)

    local mini1_iter = iterator_builder(mini1, outpost_random)
    local mini2_iter = iterator_builder(mini2, outpost_random)
    local mini3_iter = iterator_builder(mini3, outpost_random)

    local start_outpost = outpost_builder:do_outpost(thin_walls, on_init)
    start_outpost = b.change_tile(start_outpost, false, true)
    start_outpost = b.change_map_gen_collision_tile(start_outpost, 'water-tile', 'grass-1')

    local start_patch = b.circle(9)
    local start_iron_patch =
        b.resource(
        b.translate(start_patch, -30, -30),
        'iron-ore',
        function()
            return 1500
        end
    )
    local start_copper_patch =
        b.resource(
        b.translate(start_patch, 30, -30),
        'copper-ore',
        function()
            return 1200
        end
    )
    local start_stone_patch =
        b.resource(
        b.translate(start_patch, 30, 30),
        'stone',
        function()
            return 900
        end
    )
    local start_coal_patch =
        b.resource(
        b.translate(start_patch, -30, 30),
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
    water_corner = b.translate(water_corner, -54, -54)

    start_outpost =
        b.any {
        water_corner,
        b.rotate(water_corner, degrees(90)),
        b.rotate(water_corner, degrees(180)),
        b.rotate(water_corner, degrees(270)),
        start_outpost
    }

    local pattern = {}

    for r = 1, grid_number_of_blocks do
        local row = {}
        pattern[r] = row
    end

    pattern[middle][middle] = start_outpost

    local half_total_size = grid_block_size * 0.5 * (grid_number_of_blocks - 1)

    for _, pos in ipairs(stage1a_pos) do
        local r, c = pos[1], pos[2]

        local row = pattern[r]

        local template = stage1a_iter()
        local shape = outpost_builder:do_outpost(template, on_init)

        local x = outpost_random:next_int(-outpost_offset, outpost_offset)
        local y = outpost_random:next_int(-outpost_offset, outpost_offset)
        shape = b.translate(shape, x, y)

        row[c] = shape
    end

    for _, pos in ipairs(stage1b_pos) do
        local r, c = pos[1], pos[2]

        local row = pattern[r]

        local template = stage1b_iter()
        local shape = outpost_builder:do_outpost(template, on_init)

        local x = outpost_random:next_int(-outpost_offset, outpost_offset)
        local y = outpost_random:next_int(-outpost_offset, outpost_offset)
        shape = b.translate(shape, x, y)

        row[c] = shape
    end

    for _, pos in ipairs(stage2_pos) do
        local r, c = pos[1], pos[2]

        local row = pattern[r]

        local template = stage2_iter()
        local shape = outpost_builder:do_outpost(template, on_init)

        local x = outpost_random:next_int(-outpost_offset, outpost_offset)
        local y = outpost_random:next_int(-outpost_offset, outpost_offset)
        shape = b.translate(shape, x, y)

        row[c] = shape
    end

    for r = middle - 3, middle + 3 do
        local row = pattern[r]
        for c = middle - 3, middle + 3 do
            if not row[c] then
                local template = stage3_iter()
                local shape = outpost_builder:do_outpost(template, on_init)

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
                local shape = outpost_builder:do_outpost(template, on_init)

                local x = outpost_random:next_int(-outpost_offset, outpost_offset)
                local y = outpost_random:next_int(-outpost_offset, outpost_offset)
                shape = b.translate(shape, x, y)

                row[c] = shape
            end
        end
    end

    local mini_pattern = {}

    for r = 1, mini_grid_number_of_blocks do
        mini_pattern[r] = {}
    end

    for r = mini_middle, mini_middle do
        local row = mini_pattern[r]
        for c = mini_middle, mini_middle do
            row[c] = b.empty_shape
        end
    end

    for r = mini_middle - 3, mini_middle + 3 do
        local row = mini_pattern[r]
        for c = mini_middle - 3, mini_middle + 3 do
            if not row[c] then
                local template = mini1_iter()
                local shape = outpost_builder:do_outpost(template, on_init)

                local x = outpost_random:next_int(-mini_outpost_offset, mini_outpost_offset)
                local y = outpost_random:next_int(-mini_outpost_offset, mini_outpost_offset)
                shape = b.translate(shape, x, y)

                row[c] = shape
            end
        end
    end

    for r = mini_middle - 5, mini_middle + 5 do
        local row = mini_pattern[r]
        for c = mini_middle - 5, mini_middle + 5 do
            if not row[c] then
                local template = mini2_iter()
                local shape = outpost_builder:do_outpost(template, on_init)

                local x = outpost_random:next_int(-mini_outpost_offset, mini_outpost_offset)
                local y = outpost_random:next_int(-mini_outpost_offset, mini_outpost_offset)
                shape = b.translate(shape, x, y)

                row[c] = shape
            end
        end
    end

    for r = 1, mini_grid_number_of_blocks do
        local row = mini_pattern[r]
        for c = 1, mini_grid_number_of_blocks do
            if not row[c] then
                local template = mini3_iter()
                local shape = outpost_builder:do_outpost(template, on_init)

                local x = outpost_random:next_int(-mini_outpost_offset, mini_outpost_offset)
                local y = outpost_random:next_int(-mini_outpost_offset, mini_outpost_offset)
                shape = b.translate(shape, x, y)

                row[c] = shape
            end
        end
    end

    local outposts =
        b.grid_pattern_no_repeat(pattern, --[[grid_number_of_blocks, grid_number_of_blocks,]] grid_block_size, grid_block_size)
    local mini_outposts =
        b.grid_pattern(
        mini_pattern,
        mini_grid_number_of_blocks,
        mini_grid_number_of_blocks,
        mini_grid_block_size,
        mini_grid_block_size
    )
    local offset = -180 -- (grid_block_size ) * 0.5

    mini_outposts = b.translate(mini_outposts, offset, offset)

    outposts = b.if_else(outposts, mini_outposts)
    --outposts = mini_outposts

    local spawners = {
        'biter-spawner',
        'spitter-spawner'
    }

    local worms = {
        'small-worm-turret',
        'medium-worm-turret',
        'big-worm-turret',
        'behemoth-worm-turret'
    }

    local max_spawner_chance = 1 / 256
    local spawner_chance_factor = 1 / (256 * 512)
    local max_worm_chance = 1 / 64
    local worm_chance_factor = 1 / (40 * 512)

    --local scale_factor = 1 / 32

    local function enemy(_, _, world)
        local wx, wy = world.x, world.y
        local d = math.sqrt(wx * wx + wy * wy)

        --[[ if Perlin.noise(x * scale_factor, y * scale_factor, enemy_seed) < 0 then
        return nil
    end ]]
        local spawner_chance = d - 120

        if spawner_chance > 0 then
            spawner_chance = spawner_chance * spawner_chance_factor
            spawner_chance = math.min(spawner_chance, max_spawner_chance)

            if math.random() < spawner_chance then
                return {name = spawners[math.random(2)]}
            end
        end

        local worm_chance = d - 120

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
                    elseif d < 768 then
                        max_lvl = 3
                        min_lvl = 2
                    else
                        max_lvl = 4
                        min_lvl = 2
                    end
                    local lvl = math.random() ^ (384 / d) * max_lvl
                    lvl = math.ceil(lvl)
                    --local lvl = math.floor(d / 256) + 1
                    lvl = math.clamp(lvl, min_lvl, 4)
                    return {name = worms[lvl]}
                end
            end
        end
    end

    local enemy_shape = b.apply_entity(b.full_shape, enemy)

    local ores_patch = b.circle(13)
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
        shape = b.scale(shape, 0.75)
        shape = b.throttle_world_xy(shape, 1, 5, 1, 5)
        return shape
    end

    local ores = {
        {weight = 275},
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

    local ore_grid = b.grid_pattern_full_overlap(ore_pattern, 35, 35, 56, 56)
    ore_grid = b.choose(b.rectangle(126), b.no_entity, ore_grid)

    local map = b.if_else(outposts, enemy_shape)

    map = b.if_else(map, b.full_shape)

    map = b.translate(map, -half_total_size, -half_total_size)

    map = b.apply_entity(map, ore_grid)

    local market = {
        callback = spawn_callback,
        data = {
            market_name = 'Spawn',
            upgrade_rate = 0.5,
            upgrade_base_cost = 500,
            upgrade_cost_base = 2,
            {
                price = 0,
                stack_limit = 1,
                type= 'airstrike',
                name = 'airstrike_planner',
                name_label = {'command_description.crash_site_airstrike_planner_label', 1},
                sprite = 'virtual-signal/signal-A',
                description = {'command_description.crash_site_airstrike_planner_description', 1, 0, "n/a", "n/a"},
            },
            {
                price = 1000,
                stack_limit = 1,
                type= 'airstrike',
                name = 'airstrike_damage',
                name_label = {'command_description.crash_site_airstrike_count_name_label', 1},
                sprite = 'virtual-signal/signal-A',
                description = {'command_description.crash_site_airstrike_count', 1, 0, "n/a", "n/a"}
            },
            {
                price = 1000,
                stack_limit = 1,
                type = 'airstrike',
                name = 'airstrike_radius',
                name_label = {'command_description.crash_site_airstrike_radius_name_label', 1},
                sprite = 'virtual-signal/signal-A',
                description = {'command_description.crash_site_airstrike_radius', 1, 0, 5}
            },
            {
                price = 0,
                stack_limit = 1,
                type= 'barrage',
                name = 'barrage_planner',
                name_label = {'command_description.crash_site_barrage_planner_label', 1},
                sprite = 'virtual-signal/signal-B',
                description = {'command_description.crash_site_barrage_planner_description', 1, 0, "n/a", "n/a"},
            },
            {
                price = 1000,
                stack_limit = 1,
                type= 'barrage',
                name = 'barrage_damage',
                name_label = {'command_description.crash_site_barrage_count_name_label', 1},
                sprite = 'virtual-signal/signal-B',
                description = {'command_description.crash_site_barrage_count', 1, 0, "n/a", "n/a"}
            },
            {
                price = 1000,
                stack_limit = 1,
                type = 'barrage',
                name = 'barrage_radius',
                name_label = {'command_description.crash_site_barrage_radius_name_label', 1},
                sprite = 'virtual-signal/signal-B',
                description = {'command_description.crash_site_barrage_radius', 1, 0, 25}

            },
            {
                price = 1000,
                stack_limit = 1,
                type = 'rocket_tanks',
                name = 'rocket_tanks_fire_rate',
                name_label = {'command_description.crash_site_rocket_tanks_name_label', 1},
                sprite = 'virtual-signal/signal-R',
                description = {'command_description.crash_site_rocket_tanks_description'}
            },
            {
                price = 0,
                stack_limit = 1,
                type = 'spidertron',
                name = 'spidertron_planner',
                name_label = {'command_description.crash_site_spider_army_decon_label', 1},
                sprite = 'virtual-signal/signal-S',
                description = {'command_description.crash_site_spider_army_decon_description'}
            },
            {name = 'wood', price = 1},
            {name = 'coal', price = 1.25},
            {name = 'stone', price = 2},
            {name = 'iron-plate', price = 2},
            {name = 'copper-plate', price = 2},
            {name = 'steel-plate', price = 10},
            {name = 'raw-fish', price = 4},
            {name = 'automation-science-pack', price = 10},
            {name = 'logistic-science-pack', price = 25},
            {name = 'military-science-pack', price = 50},
            {name = 'chemical-science-pack', price = 75},
            {name = 'production-science-pack', price = 100},
            {name = 'utility-science-pack', price = 125},
            {
                price = 100,
                name = 'player-port',
                name_label = 'Train Immunity (1x use)',
                description = 'Each player port in your inventory will save you from being killed by a train once.'
            }
        }
    }

    local factory = {
        callback = outpost_builder.magic_item_crafting_callback,
        data = {
            output = {min_rate = 0.5 / 60, distance_factor = 0, item = 'coin'}
        }
    }

    local inserter = {
        callback = Token.register(
            function(entity)
                entity.insert({name = 'rocket-fuel', count = 1})
            end
        )
    }

    local chest = {
        callback = outpost_builder.scenario_chest_callback
    }

    local spawn = {
        size = 2,
        [1] = {
            market = market,
            chest = chest,
            [4] = {entity = {name = 'logistic-chest-requester', force = 'player', callback = 'chest'}},
            [29] = {entity = {name = 'market', force = 'neutral', callback = 'market'}},
            [32] = {entity = {name = 'steel-chest', force = 'player', callback = 'chest'}}
        },
        [2] = {
            force = 'player',
            factory = factory,
            inserter = inserter,
            chest = chest,
            [4] = {entity = {name = 'logistic-chest-requester', force = 'player', callback = 'chest'}},
            [25] = {entity = {name = 'burner-inserter', direction = 2, callback = 'inserter'}},
            [27] = {entity = {name = 'electric-furnace', callback = 'factory'}},
        }
    }

    local spawn_shape = outpost_builder.to_shape(spawn, 8, on_init)
    spawn_shape = b.change_tile(spawn_shape, false, 'stone-path')
    spawn_shape = b.change_map_gen_collision_hidden_tile(spawn_shape, 'water-tile', 'grass-1')

    map = b.choose(b.rectangle(16, 16), spawn_shape, map)

    local bounds = config.bounds_shape or b.rectangle(grid_block_size * (grid_number_of_blocks) + 1)
    map = b.choose(bounds, map, b.empty_shape)

    return map
end

local map

Global.register_init(
    {},
    function(tbl)
        game.create_force(cutscene_force_name)

        -- Sprites for the spawn chests. Is there a better place for these?
        rendering.draw_sprite{sprite = "item.poison-capsule", target = {3.5, -8.5}, surface = game.surfaces["redmew"], tint={1, 1, 1, 0.1}}
        rendering.draw_sprite{sprite = "item.explosive-rocket", target = {-4.5, -8.5}, surface = game.surfaces["redmew"], tint={1, 1, 1, 0.1}}

        local surface = game.surfaces[1]
        surface.map_gen_settings = {width = 2, height = 2}
        surface.clear()

        local seed = RS.get_surface().map_gen_settings.seed
        tbl.outpost_seed = outpost_seed or seed
        tbl.ore_seed = ore_seed or seed
    end,
    function(tbl)
        outpost_seed = tbl.outpost_seed
        ore_seed = tbl.ore_seed
        map = init(configuration)
    end
)

local Public = {}

function Public.init(config)
    control(config)

    return function(x, y, world)
        return map(x, y, world)
    end
end

Public.all_outpost_types_active = all_outpost_types_active()

return Public
