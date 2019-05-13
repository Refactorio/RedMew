local b = require 'map_gen.shared.builders'
local Generate = require 'map_gen.shared.generate'
local Perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'
local Global = require 'utils.global'
local math = require 'utils.math'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local ores_init = require 'map_gen.maps.danger_bobs_ores.ore'

local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ore Quadrants')
ScenarioInfo.set_map_description(
    [[
Clear the ore to expand the base,
focus mining efforts on specific quadrants to ensure
proper material ratios, expand the map with pollution!
]]
)
ScenarioInfo.add_map_extra_info(
    [[
This map is split in 17 sectors. Each sector has a main resource.

You may not build the factory on ore patches. Exceptions:
 [item=burner-mining-drill] [item=electric-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=car] [item=tank]
 [item=basic-transport-belt] [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt] [item=turbo-transport-belt] [item=ultimate-transport-belt] [item=basic-underground-belt] [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt] [item=turbo-underground-belt] [item=ultimate-underground-belt]

The map size is restricted to the pollution generated. A significant amount of
pollution must affect a section of the map before it is revealed. Pollution
does not affect biter evolution.]]
)

ScenarioInfo.set_map_description(
    [[
Clear the ore to expand the base,
focus mining efforts on specific sector to ensure
proper material ratios, expand the map with pollution!
]]
)

require 'map_gen.maps.danger_bobs_ores.banned_entities'

global.config.lazy_bastard.enabled = false

local ores_names = {
    'coal',
    'copper-ore',
    'crude-oil',
    'iron-ore',
    'stone',
    'uranium-ore',
    'bauxite-ore',
    'cobalt-ore',
    'gem-ore',
    'gold-ore',
    'lead-ore',
    'nickel-ore',
    'quartz',
    'rutile-ore',
    'silver-ore',
    'sulfur',
    'tin-ore',
    'tungsten-ore',
    'zinc-ore',
    'thorium-ore'
}
local ore_oil_none = {}
for _, v in ipairs(ores_names) do
    ore_oil_none[v] = {
        frequency = 1,
        richness = 1,
        size = 0
    }
end
ore_oil_none = {autoplace_controls = ore_oil_none}

RS.set_first_player_position_check_override(true)
RS.set_spawn_island_tile('grass-1')
RS.set_map_gen_settings(
    {
        MGSP.grass_only,
        MGSP.enable_water,
        {
            terrain_segmentation = 'normal',
            water = 'normal'
        },
        MGSP.starting_area_very_low,
        ore_oil_none,
        MGSP.enemy_none,
        MGSP.cliff_none
    }
)

Generate.enable_register_events = false

local perlin_noise = Perlin.noise
local fast_remove = table.fast_remove

local spawn_circle = b.circle(96)

local water_scale = 1 / 96
local water_threshold = 0.5
local deepwater_threshold = 0.55
local non_water_zone = b.circle(102)

local tree_scale = 1 / 64
local tree_threshold = -0.25
local tree_chance = 0.125

local start_chunks_half_size = 4

local start_size = start_chunks_half_size * 64

local ores

local pollution_increment = 4
global.min_pollution = 400
global.max_pollution = 20000
global.win_condition_evolution_rocket_maxed = -1
global.win_condition_biters_disabled = false

local enemy_seed
local water_seed
local tree_seed
local chunk_list = {index = 1}
local surface

Global.register_init(
    {chunk_list = chunk_list},
    function(tbl)
        local s = RS.get_surface()
        tbl.seed = s.map_gen_settings.seed
        tbl.surface = s
        game.difficulty_settings.technology_price_multiplier = 5
        game.forces.player.technologies.logistics.researched = true
        game.forces.player.technologies.automation.researched = true
        game.forces.player.technologies['mining-productivity-1'].enabled = false
        game.forces.player.technologies['mining-productivity-2'].enabled = false
        game.forces.player.technologies['mining-productivity-3'].enabled = false
        game.forces.player.technologies['mining-productivity-4'].enabled = false
        game.map_settings.enemy_evolution.time_factor = 0.000007
        game.map_settings.enemy_evolution.destroy_factor = 0.000010
        game.map_settings.enemy_evolution.pollution_factor = 0.000000 -- Pollution has no affect on evolution
        game.draw_resource_selection = false

        tbl.random = game.create_random_generator(tbl.seed)
    end,
    function(tbl)
        local seed = tbl.seed
        enemy_seed = seed * 6
        water_seed = seed * 7
        tree_seed = seed * 8

        chunk_list = tbl.chunk_list
        surface = tbl.surface

        local ores_shapes = ores_init(seed)

        local random = tbl.random
        random.re_seed(seed)
        table.shuffle_table(ores_shapes, random)

        ores = b.segment_weighted_pattern(ores_shapes)
    end
)

local worm_names = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'behemoth-worm-turret'}
local spawner_names = {'biter-spawner', 'spitter-spawner'}
local factor = 10 / (768 * 32)
local max_chance = 1 / 6

local scale_factor = 32
local sf = 1 / scale_factor
local m = 1 / 850

local function enemy(x, y, world)
    if global.win_condition_biters_disabled == true then
        return nil
    end

    local d = math.sqrt(world.x * world.x + world.y * world.y)

    if d < 64 then
        return nil
    end

    local threshold = 1 - d * m
    threshold = math.max(threshold, 0.35)

    x, y = x * sf, y * sf
    if perlin_noise(x, y, enemy_seed) <= threshold then
        return
    end

    if math.random(8) == 1 then
        local lvl
        if d < 400 then
            lvl = 1
        elseif d < 650 then
            lvl = 2
        elseif d < 900 then
            lvl = 3
        else
            lvl = 4
        end

        local chance = math.min(max_chance, d * factor)

        if math.random() < chance then
            local worm_id
            if d > 1000 then
                local power = 1000 / d
                worm_id = math.ceil((math.random() ^ power) * lvl)
            else
                worm_id = math.random(lvl)
            end
            return {name = worm_names[worm_id]}
        end
    else
        local chance = math.min(max_chance, d * factor)
        if math.random() < chance then
            local spawner_id = math.random(2)
            return {name = spawner_names[spawner_id]}
        end
    end
end

local function water_shape(x, y)
    if non_water_zone(x, y) then
        return false
    end

    local water_noise = perlin_noise(x * water_scale, y * water_scale, water_seed)
    if water_noise >= deepwater_threshold then
        return 'deepwater'
    elseif water_noise >= water_threshold then
        return 'water'
    else
        return false
    end
end

local trees = {
    'tree-01',
    'tree-02',
    'tree-02-red',
    'tree-03',
    'tree-04',
    'tree-05',
    'tree-06',
    'tree-06-brown',
    'tree-07',
    'tree-08',
    'tree-08-brown',
    'tree-08-red',
    'tree-09',
    'tree-09-brown',
    'tree-09-red'
}

local trees_count = #trees

local function tree_shape(x, y)
    local tree_noise = perlin_noise(x * tree_scale, y * tree_scale, tree_seed)
    if tree_noise > tree_threshold or math.random() > tree_chance then
        return nil
    end

    return {name = trees[math.random(trees_count)]}
end

local water = b.circle(16)
water = b.change_tile(water, true, 'water')
water = b.any {b.rectangle(32, 4), b.rectangle(4, 32), water}

local start = b.if_else(water, spawn_circle)
start = b.change_map_gen_collision_tile(start, 'water-tile', 'grass-1')

local function ores_shape(x, y, world)
    return ores(x, y, world)
end

local map = b.any {start, water_shape, ores_shape}
map = b.apply_entity(map, enemy)
map = b.apply_entity(map, tree_shape)
map = b.fish(map, 0.025)

local bounds = b.rectangle(start_size, start_size)

local function rocket_launched(event)
    local entity = event.rocket

    if not entity or not entity.valid or not entity.force == 'player' then
        return
    end

    local inventory = entity.get_inventory(defines.inventory.rocket)
    if not inventory or not inventory.valid then
        return
    end

    local satellite_count = game.forces.player.get_item_launched('satellite')
    if satellite_count == 0 then
        return
    end

    -- Increase enemy_evolution
    local current_evolution = game.forces.enemy.evolution_factor
    local message

    if global.win_condition_biters_disabled == false then
        if (satellite_count % 5) == 0 and global.win_condition_evolution_rocket_maxed == -1 then
            message =
                'Continued launching of satellites has angered the local biter population, evolution increasing...'
            game.print(message)

            current_evolution = current_evolution + 0.05
        end

        if current_evolution >= 1 and global.win_condition_evolution_rocket_maxed == -1 then
            current_evolution = 1
            global.win_condition_evolution_rocket_maxed = satellite_count

            message =
                'Biters at maximum evolution! Protect the base for an additional 100 rockets to wipe them out forever.'
            game.print(message)
        end

        game.forces.enemy.evolution_factor = current_evolution
        if
            global.win_condition_evolution_rocket_maxed > 0 and
                satellite_count >= (global.win_condition_evolution_rocket_maxed + 100)
         then
            message = 'Congratulations! Biters have been wiped from the map!'
            game.print(message)

            global.win_condition_biters_disabled = true

            for key, enemy_entity in pairs(surface.find_entities_filtered({force = 'enemy'})) do
                enemy_entity.destroy()
            end
        end
    end
end

local function on_chunk(event)
    if surface ~= event.surface then
        return
    end

    local left_top = event.area.left_top
    local x, y = left_top.x, left_top.y

    if bounds(x + 0.5, y + 0.5) then
        Generate.do_chunk(event)
    else
        local tiles = {}
        for x1 = x, x + 31 do
            for y1 = y, y + 31 do
                tiles[#tiles + 1] = {name = 'out-of-map', position = {x1, y1}}
            end
        end
        surface.set_tiles(tiles, true)

        chunk_list[#chunk_list + 1] = left_top
    end
end

local function on_tick()
    local index = chunk_list.index

    if index > #chunk_list then
        chunk_list.index = 1
        return
    end

    local pos = chunk_list[index]
    local pollution = surface.get_pollution(pos)

    local current_min_pollution = global.min_pollution

    if pollution > current_min_pollution then
        fast_remove(chunk_list, index)

        local area = {left_top = pos, right_bottom = {pos.x + 32, pos.y + 32}}
        local event = {surface = surface, area = area}
        Generate.schedule_chunk(event)

        if current_min_pollution < global.max_pollution then
            global.min_pollution = current_min_pollution + pollution_increment
        end

        return
    end

    chunk_list.index = index + 1
end

Event.add(defines.events.on_chunk_generated, on_chunk)
Event.add(defines.events.on_rocket_launched, rocket_launched)
Event.on_nth_tick(1, on_tick)

return map
