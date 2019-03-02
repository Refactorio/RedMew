local b = require 'map_gen.shared.builders'
local Generate = require 'map_gen.shared.generate'
local Perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'
local Global = require 'utils.global'
local math = require 'utils.math'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

global.config.lazy_bastard.enabled = true

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

local uranium_scale = 1 / 128
local uranium_threshold = 0.65

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
global.min_pollution = 500

local chunk_list = {index = 1}
local surface

local start_size = start_chunks_half_size * 64

Global.register_init(
    {chunk_list = chunk_list},
    function(tbl)
        local s = RS.get_surface()
        tbl.seed = s.map_gen_settings.seed
        tbl.surface = s
        game.difficulty_settings.technology_price_multiplier = 50
        game.forces.player.technologies.logistics.researched = true
        game.forces.player.technologies.automation.researched = true
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
    end
)

local value = b.euclidean_value

local oil_shape = b.throttle_world_xy(b.full_shape, 1, 7, 1, 7)
local oil_resource = b.resource(oil_shape, 'crude-oil', value(250000, 150))

local uranium_resource = b.resource(b.full_shape, 'uranium-ore', value(200, 1))

local ores = {
    {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 60},
    {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 40},
    {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 5},
    {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 20}
}

local weighted_ores = b.prepare_weighted_array(ores)
local total_ores = weighted_ores.total

local spawn_zone = b.circle(64)

local ore_circle = b.circle(68)
local start_ores = {
    b.resource(ore_circle, 'iron-ore', value(125, 0)),
    b.resource(ore_circle, 'copper-ore', value(125, 0)),
    b.resource(ore_circle, 'coal', value(125, 0)),
    b.resource(ore_circle, 'stone', value(125, 0))
}

local start_segment = b.segment_pattern(start_ores)

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

    local i = math.random() * total_ores
    local index = table.binary_search(weighted_ores, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    local resource = ores[index].resource

    local entity = resource(x, y, world)
    local density_x, density_y = x * density_scale, y * density_scale
    local density_noise = perlin_noise(density_x, density_y, density_seed)

    if density_noise > density_threshold then
        entity.amount = entity.amount * density_multiplier
    end
    entity.enable_tree_removal = false
    return entity
end

local worm_names = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret'}
local spawner_names = {'biter-spawner', 'spitter-spawner'}
local factor = 10 / (768 * 32)
local max_chance = 1 / 6

local scale_factor = 32
local sf = 1 / scale_factor
local m = 1 / 850
local function enemy(x, y, world)
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
        else
            lvl = 3
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
        return 'grass-1'
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

local water = b.circle(8)
water = b.change_tile(water, true, 'water')
water = b.any {b.rectangle(16, 4), b.rectangle(4, 16), water}

local start = b.if_else(water, b.full_shape)
start = b.change_map_gen_collision_tile(start, 'water-tile', 'grass-1')

local map = b.choose(ore_circle, start, water_shape)

map = b.apply_entity(map, ore)
map = b.apply_entity(map, enemy)
map = b.apply_entity(map, tree_shape)
map = b.fish(map, 0.025)

local bounds = b.rectangle(start_size, start_size)

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

    if pollution > global.min_pollution then
        fast_remove(chunk_list, index)

        local area = {left_top = pos, right_bottom = {pos.x + 32, pos.y + 32}}
        local event = {surface = surface, area = area}
        Generate.schedule_chunk(event)
        return
    end

    chunk_list.index = index + 1
end

Event.add(defines.events.on_chunk_generated, on_chunk)
Event.on_nth_tick(1, on_tick)

return map
