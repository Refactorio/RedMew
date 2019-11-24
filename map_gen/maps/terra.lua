local b = require "map_gen.shared.builders"
local Event = require 'utils.event'
local ScenarioInfo = require 'features.gui.info'
local table = require 'utils.table'
local gear = require 'map_gen.data.presets.gear_96by96'
local Random = require 'map_gen.shared.random'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
        --Map info
ScenarioInfo.set_map_name('Terra')
ScenarioInfo.set_map_description('The latest experiments has resulted in infinite gears for infinite factory expansion.')
ScenarioInfo.add_map_extra_info(
    [[
Tar's additional info about gears:

You start off on familiar grounds, but you must obtain robot technology
in order to explore beyond the grid.

    [item=rocket-silo] Regular rocket launch
    [item=personal-roboport-equipment] Lazy starter equipment
    [entity=small-biter] Biter activity high
    [item=landfill] Landfill disabled

Coded with love, but without lua experience: Blame Tar[technology=optics]  for bugs.
     ]])
ScenarioInfo.set_new_info([[
This map! This map is new!

T-A-R will be thankful for any feedback on discord or as PM at the Factorio-Forums]])
--Map generation settings
RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none,
        MGSP.water_none,
      --MGSP.enemy_none,
    }
    )
--[[RS.set_difficulty_settings({{technology_price_multiplier = 1}})                             --Set these on launch
RS.set_map_settings({map_settings})

--Biter settings
local map_settings = {
    pollution = {
        enabled = true
    },
    enemy_evolution = {
        enabled = true,
        time_factor = (0.0000001),
        destroy_factor = (0.0002),
        pollution_factor = (0.0000015)
    },
    enemy_expansion = {
            enabled = true,
            max_expansion_distance = 7,
            friendly_base_influence_radius = 2,
            enemy_building_influence_radius = 2,
            building_coefficient = 0.1,
            other_base_coefficient = 2.0,
            neighbouring_chunk_coefficient = 0.5,
            neighbouring_base_chunk_coefficient = 0.4,
            max_colliding_tiles_coefficient = 0.9,
            settler_group_min_size = 5,
            settler_group_max_size = 20,
            min_expansion_cooldown = 60 * 3600,
            max_expansion_cooldown = 180 * 3600
        }
}]]
--Terraforming
local pic1 = require "map_gen.data.presets.factorio_logo2" --921x153
pic1 = b.decompress(pic1)
local map1file = b.picture(pic1)                                                                                --Logo2
local fillerblock = b.translate(b.rectangle(14,12), 248,2)                                          --land bridge to connect the logo  gear island
--map = b.change_tile(fillerblock, true, "grass-4")
fillerblock = b.change_tile(fillerblock, true, "grass-4")                                               -- same color as picture shade= 'grass-4'
local map1 = b.add(fillerblock, map1file)
map1 = b.scale(map1, 1, 1)
-- Rotated logo's
local map2 = b.rotate (map1, math.pi/2)
--Square minus corner pieces
local shap1 = b.translate(b.rectangle_diamond(26, 24), pic1.height/2,pic1.height/2)
local shap2 = b.rotate((shap1), math.pi/2)
local shap3 = b.rotate((shap2), math.pi/2)
local shap4 = b.rotate((shap3), math.pi/2)
local shap5 = b.invert(b.rectangle(pic1.height+1, pic1.height+1))                       --size is related to ''factorio_logo2"
--Combining using all
local chamfer = b.invert(b.any({shap1, shap2, shap3, shap4, shap5}))                --starter tile is a chamfered square
local corner = chamfer
corner = b.change_tile(corner, true, "grass-4")
--Botland (robo islands)
-- creating shapes
local shape1 = b.translate(b.rectangle(250, 40), 74, 0)                                         --bridge land
local shape2 = b.rotate((shape1), math.pi/2)
local shape3 = b.rotate((shape2), math.pi/2)
local shape4 = b.rotate((shape3), math.pi/2)
local shape5 = b.scale((chamfer), 1.4,1.4)                                                              --scaled up starter tile
--Combining using all
local botland = b.any({shape5, shape1, shape2, shape3, shape4})
--pave the shape
botland = b.scale(botland, 2.2,2.2)
botland = b.change_tile(botland, true, 'lab-dark-2')                                                --replace to  'landfill'  to absorb pollution
local pattern = {
    {corner, map1},
    {map2,botland}
}
local map = b.grid_pattern_overlap(pattern, 2, 2, 499,500)
map = b.scale(map, 1.9,1.9)                                                                                     --Final map scaler#########
-- this sets the tile outside the bounds of the map to water, remove this and it will be void.
map = b.change_tile(map, false, "water")                                                               --"deepwater" shows borders (for debugging purposes)
map = b.fish(map, 0.0025)                                                                                       --So long

local centre =b.circle(18)
--local centre = b.rectangle(5,5)
--local centre = b.scale(chamfer, 0.08,0.08)
map = b.if_else(centre, map)
centre = b.change_map_gen_collision_tile(centre, 'ground-tile', 'stone-path')
-- the coordinates at which the standard market and spawn  will be created
local startx = 0
local starty = 0
    --market
global.config.market.standard_market_location = {x = startx, y = starty}
 --player
--local function on_init()
local surface = RS.get_surface()local spawn_position = {x = startx, y = starty-3}
RS.set_spawn_position(spawn_position, surface)
--end
   --Ore generation                                                                                                     -- Copy for "void gears' - altered seeds to create nice starting area - reduced amount of ore patches
    local seed1 = 1410                                                                                               -- random seeds (ore gears)         --6666
    local seed2 = 12900                                                                                             --9999
gear = b.decompress(gear)
local gear_big = b.picture(gear)
local gear_medium = b.scale(gear_big, 2 / 3)
local gear_small = b.scale(gear_big, 1 / 3)
local value = b.manhattan_value
local ores = {
    {resource_type = 'iron-ore', value = value(250, 1.5)},
    {resource_type = 'copper-ore', value = value(250, 1.5)},
    {resource_type = 'stone', value = value(250, 1)},
    {resource_type = 'coal', value = value(250, 1)},
    {resource_type = 'uranium-ore', value = value(125, 1)},
    {resource_type = 'crude-oil', value = value(50000, 250)}
}
local function striped(shape) -- luacheck: ignore 431
    return function(x, y, world)
        if not shape(x, y) then
            return nil
        end

        local t = (world.x + world.y) % 4 + 1
        local ore = ores[t]

        return {
            name = ore.resource_type,
            position = {world.x, world.y},
            amount = 3 * ore.value(world.x, world.y)
        }
    end
end
local function sprinkle(shape) -- luacheck: ignore 43
    return function(x, y, world)
        if not shape(x, y) then
            return nil
        end
        local t = math.random(1, 4)
        local ore = ores[t]
        return {
            name = ore.resource_type,
            position = {world.x, world.y},
            amount = 3 * ore.value(world.x, world.y)
        }
    end
end
local function radial(shape, radius) -- luacheck: ignore 431
    local stone_r_sq = radius * 0.3025 -- radius * 0.55
    local coal_r_sq = radius * 0.4225 -- radius * 0.65
    local copper_r_sq = radius * 0.64 -- radius * 0.8
    return function(x, y, world)
        if not shape(x, y) then
            return nil
        end
        local d_sq = x * x + y * y

        local ore
        if d_sq < stone_r_sq then
            ore = ores[4]
        elseif d_sq < coal_r_sq then
            ore = ores[3]
        elseif d_sq < copper_r_sq then
            ore = ores[2]
        else
            ore = ores[1]
        end
        return {
            name = ore.resource_type,
            position = {world.x, world.y},
            amount = 3 * ore.value(world.x, world.y)
        }
    end
end
local big_patches = {
    {b.no_entity, 220},
    {b.resource(gear_big, ores[1].resource_type, ores[1].value), 20},
    {b.resource(gear_big, ores[2].resource_type, ores[2].value), 12},
    {b.resource(gear_big, ores[3].resource_type, ores[3].value), 4},
    {b.resource(gear_big, ores[4].resource_type, ores[4].value), 6},
    {b.resource(gear_big, ores[5].resource_type, ores[5].value), 2},
    {b.resource(b.throttle_world_xy(gear_big, 1, 8, 1, 8), ores[6].resource_type, ores[6].value), 6},
    {striped(gear_big), 1},
    {sprinkle(gear_big), 1},
    {radial(gear_big, 48), 1}
}
big_patches[#big_patches + 1] = {
    b.segment_pattern({big_patches[2][1], big_patches[3][1], big_patches[4][1], big_patches[5][1]}),
    1
}
local medium_patches = {
    {b.no_entity, 150},
    {b.resource(gear_medium, ores[1].resource_type, ores[1].value), 20},
    {b.resource(gear_medium, ores[2].resource_type, ores[2].value), 12},
    {b.resource(gear_medium, ores[3].resource_type, ores[3].value), 4},
    {b.resource(gear_medium, ores[4].resource_type, ores[4].value), 6},
    {b.resource(gear_medium, ores[5].resource_type, ores[5].value), 2},
    {b.resource(b.throttle_world_xy(gear_medium, 1, 8, 1, 8), ores[6].resource_type, ores[6].value), 6},
    {striped(gear_medium), 1},
    {sprinkle(gear_medium), 1},
    {radial(gear_medium, 32), 1}
}
medium_patches[#medium_patches + 1] = {
    b.segment_pattern({medium_patches[2][1], medium_patches[3][1], medium_patches[4][1], medium_patches[5][1]}),
    1
}
local small_patches = {
    {b.no_entity, 85},
    {b.resource(gear_small, ores[1].resource_type, value(350, 2)), 20},
    {b.resource(gear_small, ores[2].resource_type, value(350, 2)), 12},
    {b.resource(gear_small, ores[3].resource_type, value(350, 2)), 4},
    {b.resource(gear_small, ores[4].resource_type, value(350, 2)), 6},
    {b.resource(gear_small, ores[5].resource_type, value(250, 2)), 2},
    {b.resource(b.throttle_world_xy(gear_small, 1, 4, 1, 4), ores[6].resource_type, ores[6].value), 6},
    {striped(gear_small), 1},
    {sprinkle(gear_small), 1},
    {radial(gear_small, 16), 1}
}
small_patches[#small_patches + 1] = {
    b.segment_pattern({small_patches[2][1], small_patches[3][1], small_patches[4][1], small_patches[5][1]}),
    1
}
local random = Random.new(seed1, seed2)
local p_cols = 50
local p_rows = 50
local function do_patches(patches, offset)
    local total_weights = {}
    local t = 0
    for _, v in ipairs(patches) do
        t = t + v[2]
        table.insert(total_weights, t)
    end
    local pattern = {}
    for _ = 1, p_cols do
        local row = {}
        table.insert(pattern, row)
        for _ = 1, p_rows do
            local i = random:next_int(1, t)
            local index = table.binary_search(total_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end
            local shape = patches[index][1] -- luacheck: ignore 431
            local x = random:next_int(-offset, offset)
            local y = random:next_int(-offset, offset)
            shape = b.translate(shape, x, y)
            table.insert(row, shape)
        end
    end
    return pattern
end
big_patches = do_patches(big_patches, 192)                                                                                  --96           increased numbers to reduce generated patches
big_patches = b.grid_pattern_full_overlap(big_patches, p_cols, p_rows, 192, 192)
medium_patches = do_patches(medium_patches, 128)                                                                 --64
medium_patches = b.grid_pattern_full_overlap(medium_patches, p_cols, p_rows, 128, 128)
small_patches = do_patches(small_patches, 128)                                                                          --32
small_patches = b.grid_pattern_full_overlap(small_patches, p_cols, p_rows, 64, 64)

--map = b.apply_entity(map, small_patches)
map = b.apply_entities(map, {big_patches, medium_patches, small_patches})

local start_stone =
    b.resource(
    gear_big,
    'stone',
    function()
        return 400
    end
)
local start_coal =
    b.resource(
    gear_big,
    'coal',
    function()
        return 800
    end
)
local start_copper =
    b.resource(
    gear_big,
    'copper-ore',
    function()
        return 800
    end
)
local start_iron =
    b.resource(
    gear_big,
    'iron-ore',
    function()
        return 1600
    end
)
local start_segmented = b.segment_pattern({start_stone, start_coal, start_copper, start_iron})
local start_gear = b.apply_entity(gear_big, start_segmented)                                                                       
start_gear = b.change_tile(start_gear, true, "grass-3")
map = b.if_else(start_gear, map)
map = b.if_else(centre, map)        
        --Starting equipment
local player_create = global.config.player_create
player_create.starting_items = {
 --   {name = 'power-armor', count = 1},                                                                --Small biters cant bite this
 --   {name = 'fusion-reactor-equipment', count = 1},                                            --and modular wont with this combined with legs
    {name = 'modular-armor', count = 1},
    {name = 'solar-panel-equipment', count = 7},
    {name = 'battery-mk2-equipment', count = 1},
    {name = 'personal-roboport-equipment', count = 1},
    {name = 'construction-robot', count = 10},
    {name = 'exoskeleton-equipment', count = 1},
    {name = 'iron-gear-wheel', count = 8},
    {name = 'iron-plate', count = 40},
    {name = 'copper-plate', count = 20},
    {name = 'car', count = 1},
    {name = 'coal', count = 5}
}
player_create.join_messages = {
            'Welcome to this map created by the RedMew community. You can join the discord at: redmew.com/discord',
            'Click the question mark in the top left corner for server information and map details.'
}
        --Starting Techs


Event.on_init(
    function()
local force = game.forces.player
        force.technologies['automation'].researched = true
        force.technologies['logistics'].researched = true
        force.technologies['landfill'].enabled = false -- disable landfill
   end
)


return map
