local b = require 'map_gen.shared.builders'
local Generate = require 'map_gen.shared.generate'
local Perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'
local Global = require 'utils.global'
local math = require 'utils.math'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

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
This map is split in four quadrants. Each quadrant has a main resource.
 [item=iron-ore] north east, [item=copper-ore] south west, [item=coal] north west, [item=stone] south east

You may not build the factory on ore patches. Exceptions:
 [item=burner-mining-drill] [item=electric-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=car] [item=tank]
 [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt]  [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt]

The map size is restricted to the pollution generated. A significant amount of
pollution must affect a section of the map before it is revealed. Pollution
does not affect biter evolution.]]
)

ScenarioInfo.set_map_description(
    [[
Clear the ore to expand the base,
focus mining efforts on specific quadrants to ensure
proper material ratios, expand the map with pollution!
]]
)
ScenarioInfo.set_new_info(
    [[
2019-04-24:
 - Stone ore density reduced by 1/2
 - Ore quadrants randomized
 - Increased time factor of biter evolution from 5 to 7
 - Added win conditions (+5% evolution every 5 rockets until 100%, +100 rockets until biters are wiped)

2019-03-30:
 - Uranium ore patch threshold increased slightly
 - Bug fix: Cars and tanks can now be placed onto ore!
 - Starting minimum pollution to expand map set to 650
    View current pollution via Debug Settings [F4] show-pollution-values,
    then open map and turn on pollution via the red box.
 - Starting water at spawn increased from radius 8 to radius 16 circle.

2019-03-27:
 - Ore arranged into quadrants to allow for more controlled resource gathering.
]]
)

require 'map_gen.shared.danger_ore_banned_entities'

global.config.lazy_bastard.enabled = false

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
        MGSP.ore_oil_none,
        MGSP.enemy_none,
        MGSP.cliff_none
    }
)

local perlin_noise = Perlin.noise
local fast_remove = table.fast_remove

Generate.enable_register_events = false

local oil_seed
local uranium_seed
local density_seed
local enemy_seed
local water_seed
local tree_seed

local oil_scale = 1 / 64
local oil_threshold = 0.6

local uranium_scale = 1 / 72
local uranium_threshold = 0.63

local density_scale = 1 / 48
local density_threshold = 0.5
local density_multiplier = 50

local water_scale = 1 / 96
local water_threshold = 0.5
local deepwater_threshold = 0.55

local tree_scale = 1 / 64
local tree_threshold = -0.25
local tree_chance = 0.125

local start_chunks_half_size = 3

local max_pollution = 2500
local pollution_increment = 2
global.min_pollution = 300

local chunk_list = {index = 1}
local surface

local start_size = start_chunks_half_size * 64

local value = b.euclidean_value

local quadrant_config = {
    ['iron-ore'] = {
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 60},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 20}
        }
    },
    ['copper-ore'] = {
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 60},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 20}
        }
    },
    ['coal'] = {
        ['tiles'] = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3',
            [4] = 'dirt-4',
            [5] = 'dirt-5',
            [6] = 'dirt-6',
            [7] = 'dirt-7'
        },
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 40}
        }
    },
    ['stone'] = {
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 30},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 20}
        }
    }
}

local tile_quadrants = {
    [1] = 'stone',
    [2] = 'iron-ore',
    [3] = 'copper-ore',
    [4] = 'coal'
}

local tiles_pos_x_pos_y
local tiles_pos_x_pos_y_count
local tiles_pos_x_neg_y
local tiles_pos_x_neg_y_count
local tiles_neg_x_pos_y
local tiles_neg_x_pos_y_count
local tiles_neg_x_neg_y
local tiles_neg_x_neg_y_count

local ores_pos_x_pos_y
local ores_pos_x_neg_y
local ores_neg_x_pos_y
local ores_neg_x_neg_y

local weighted_ores_pos_x_pos_y
local weighted_ores_pos_x_neg_y
local weighted_ores_neg_x_pos_y
local weighted_ores_neg_x_neg_y

local total_ores_pos_x_pos_y
local total_ores_pos_x_neg_y
local total_ores_neg_x_pos_y
local total_ores_neg_x_neg_y

local ore_circle = b.circle(68)
local start_ores
local start_segment

Global.register_init(
    {chunk_list = chunk_list},
    function(tbl)
        local s = RS.get_surface()
        tbl.seed = s.map_gen_settings.seed
        tbl.surface = s
        game.difficulty_settings.technology_price_multiplier = 20
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
        oil_seed = seed
        uranium_seed = seed * 2
        density_seed = seed * 3
        enemy_seed = seed * 4
        water_seed = seed * 5
        tree_seed = seed * 6

        chunk_list = tbl.chunk_list
        surface = tbl.surface

        local random = tbl.random
        random.re_seed(seed)
        table.shuffle_table(tile_quadrants, random)

        tiles_pos_x_pos_y = quadrant_config[tile_quadrants[1]]['tiles']
        tiles_pos_x_pos_y_count = #quadrant_config[tile_quadrants[1]]['tiles']
        tiles_pos_x_neg_y = quadrant_config[tile_quadrants[2]]['tiles']
        tiles_pos_x_neg_y_count = #quadrant_config[tile_quadrants[2]]['tiles']
        tiles_neg_x_pos_y = quadrant_config[tile_quadrants[3]]['tiles']
        tiles_neg_x_pos_y_count = #quadrant_config[tile_quadrants[3]]['tiles']
        tiles_neg_x_neg_y = quadrant_config[tile_quadrants[4]]['tiles']
        tiles_neg_x_neg_y_count = #quadrant_config[tile_quadrants[4]]['tiles']

        ores_pos_x_pos_y = quadrant_config[tile_quadrants[1]]['ratios']
        ores_pos_x_neg_y = quadrant_config[tile_quadrants[2]]['ratios']
        ores_neg_x_pos_y = quadrant_config[tile_quadrants[3]]['ratios']
        ores_neg_x_neg_y = quadrant_config[tile_quadrants[4]]['ratios']

        weighted_ores_pos_x_pos_y = b.prepare_weighted_array(ores_pos_x_pos_y)
        weighted_ores_pos_x_neg_y = b.prepare_weighted_array(ores_pos_x_neg_y)
        weighted_ores_neg_x_pos_y = b.prepare_weighted_array(ores_neg_x_pos_y)
        weighted_ores_neg_x_neg_y = b.prepare_weighted_array(ores_neg_x_neg_y)

        total_ores_pos_x_pos_y = weighted_ores_pos_x_pos_y.total
        total_ores_pos_x_neg_y = weighted_ores_pos_x_neg_y.total
        total_ores_neg_x_pos_y = weighted_ores_neg_x_pos_y.total
        total_ores_neg_x_neg_y = weighted_ores_neg_x_neg_y.total

        start_ores = {
            b.resource(ore_circle, tile_quadrants[2], value(125, 0)),
            b.resource(ore_circle, tile_quadrants[4], value(125, 0)),
            b.resource(ore_circle, tile_quadrants[3], value(125, 0)),
            b.resource(ore_circle, tile_quadrants[1], value(125, 0))
        }

        start_segment = b.segment_pattern(start_ores)
    end
)

local oil_shape = b.throttle_world_xy(b.full_shape, 1, 7, 1, 7)
local oil_resource = b.resource(oil_shape, 'crude-oil', value(250000, 150))

local uranium_resource = b.resource(b.full_shape, 'uranium-ore', value(200, 1))

local spawn_zone = b.circle(64)

local function ore(x, y, world)
    if spawn_zone(x, y) then
        return
    end

    local start_ore = start_segment(x, y, world)
    if start_ore then
        return start_ore
    end

    local oil_x, oil_y = x * oil_scale, y * oil_scale
    local oil_noise = perlin_noise(oil_x, oil_y, oil_seed)
    if oil_noise > oil_threshold then
        return oil_resource(x, y, world)
    end

    local uranium_x, uranium_y = x * uranium_scale, y * uranium_scale
    local uranium_noise = perlin_noise(uranium_x, uranium_y, uranium_seed)
    if uranium_noise > uranium_threshold then
        return uranium_resource(x, y, world)
    end

    local i
    local index
    local resource

    if x > 0 and y > 0 then
        i = math.random() * total_ores_pos_x_pos_y
        index = table.binary_search(weighted_ores_pos_x_pos_y, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        resource = ores_pos_x_pos_y[index].resource
    elseif x > 0 and y < 0 then
        i = math.random() * total_ores_pos_x_neg_y
        index = table.binary_search(weighted_ores_pos_x_neg_y, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end
        resource = ores_pos_x_neg_y[index].resource
    elseif x < 0 and y > 0 then
        i = math.random() * total_ores_neg_x_pos_y
        index = table.binary_search(weighted_ores_neg_x_pos_y, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end
        resource = ores_neg_x_pos_y[index].resource
    else
        i = math.random() * total_ores_neg_x_neg_y
        index = table.binary_search(weighted_ores_neg_x_neg_y, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        resource = ores_neg_x_neg_y[index].resource
    end

    local entity = resource(x, y, world)
    local density_x, density_y = x * density_scale, y * density_scale
    local density_noise = perlin_noise(density_x, density_y, density_seed)

    if density_noise > density_threshold then
        entity.amount = entity.amount * density_multiplier
    end
    entity.enable_tree_removal = false
    return entity
end

local worm_names = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'behemoth-worm-turret'}
local spawner_names = {'biter-spawner', 'spitter-spawner'}
local factor = 10 / (768 * 32)
local max_chance = 1 / 6

local scale_factor = 32
local sf = 1 / scale_factor
local m = 1 / 850

global.win_condition_evolution_rocket_maxed = -1
global.win_condition_biters_disabled = false

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
    local water_noise = perlin_noise(x * water_scale, y * water_scale, water_seed)
    if water_noise >= deepwater_threshold then
        return 'deepwater'
    elseif water_noise >= water_threshold then
        return 'water'
    else
        -- Control the tiles at X quadrant
        if x > 31 and y > 31 then
            -- southeast
            return tiles_pos_x_pos_y[math.ceil(math.random(tiles_pos_x_pos_y_count))]
        elseif x > 0 and y < 31 and y > 0 then
            -- southeast to northeast
            if math.random(100) < 50 + y * 2 then
                return tiles_pos_x_pos_y[math.ceil(math.random(tiles_pos_x_pos_y_count))]
            else
                return tiles_pos_x_neg_y[math.ceil(math.random(tiles_pos_x_neg_y_count))]
            end
        elseif x > 0 and y >= 0 then
            -- southeast to southwest
            if math.random(100) < 50 + x * 2 then
                return tiles_pos_x_pos_y[math.ceil(math.random(tiles_pos_x_pos_y_count))]
            else
                return tiles_neg_x_pos_y[math.ceil(math.random(tiles_neg_x_pos_y_count))]
            end
        elseif x > 31 and y < -31 then
            -- northeast
            return tiles_pos_x_neg_y[math.ceil(math.random(tiles_pos_x_neg_y_count))]
        elseif x > 0 and x < 31 and y <= 0 then
            -- northeast to northwest
            if math.random(100) < 50 + x * 2 then
                return tiles_pos_x_neg_y[math.ceil(math.random(tiles_pos_x_neg_y_count))]
            else
                return tiles_neg_x_neg_y[math.ceil(math.random(tiles_neg_x_neg_y_count))]
            end
        elseif x > 0 and y < 0 then
            -- northeast to southeast
            if math.random(100) < 50 - y * 2 then
                return tiles_pos_x_neg_y[math.ceil(math.random(tiles_pos_x_neg_y_count))]
            else
                return tiles_pos_x_pos_y[math.ceil(math.random(tiles_pos_x_pos_y_count))]
            end
        elseif x < -31 and y < -31 then
            -- northwest
            return tiles_neg_x_neg_y[math.ceil(math.random(tiles_neg_x_neg_y_count))]
        elseif x > -31 and x < 0 and y <= 0 then
            -- northwest to northeast
            if math.random(100) < 50 - x * 2 then
                return tiles_neg_x_neg_y[math.ceil(math.random(tiles_neg_x_neg_y_count))]
            else
                return tiles_pos_x_neg_y[math.ceil(math.random(tiles_pos_x_neg_y_count))]
            end
        elseif x < 0 and y > -31 and y < 0 then
            -- northwest to southwest
            if math.random(100) < (50 - y * 2) then
                return tiles_neg_x_neg_y[math.ceil(math.random(tiles_neg_x_neg_y_count))]
            else
                return tiles_neg_x_pos_y[math.ceil(math.random(tiles_neg_x_pos_y_count))]
            end
        elseif x < -31 and y > 31 then
            -- southwest
            return tiles_neg_x_pos_y[math.ceil(math.random(tiles_neg_x_pos_y_count))]
        elseif x < 0 and y > 0 and y < 32 then
            -- southwest to northwest
            if math.random(100) < (50 + y * 2) then
                return tiles_neg_x_pos_y[math.ceil(math.random(tiles_neg_x_pos_y_count))]
            else
                return tiles_neg_x_neg_y[math.ceil(math.random(tiles_neg_x_neg_y_count))]
            end
        elseif x < 0 and y > 0 then
            -- southwest to southeast
            if math.random(100) < 50 - x * 2 then
                return tiles_neg_x_pos_y[math.ceil(math.random(tiles_neg_x_pos_y_count))]
            else
                return tiles_pos_x_pos_y[math.ceil(math.random(tiles_pos_x_pos_y_count))]
            end
        end
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

local start = b.if_else(water, b.full_shape)
start = b.change_map_gen_collision_tile(start, 'water-tile', 'grass-1')

local map = b.choose(ore_circle, start, water_shape)

map = b.apply_entity(map, ore)
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
        if global.win_condition_evolution_rocket_maxed > 0 and satellite_count >= (global.win_condition_evolution_rocket_maxed + 100) then
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

        if current_min_pollution < max_pollution then
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
