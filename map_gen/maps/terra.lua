--Terra by T-A-R 2022
local b = require "map_gen.shared.builders"
local Event = require 'utils.event'
local table = require 'utils.table'
local gear = require 'map_gen.data.presets.gear_96by96'
local Random = require 'map_gen.shared.random'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'


local Retailer = require 'features.retailer'
local config = global.config
config.market.create_standard_market = false


--Map info
ScenarioInfo.set_map_name('Terra')
ScenarioInfo.set_map_description('The latest experiments has resulted in infinite gears for infinite factory expansion.')
ScenarioInfo.add_map_extra_info(
    [[
You start off on familiar grounds, but you must use robot technology
in order to explore beyond the grid.
    [item=rocket-silo] Regular rocket launch
    [item=personal-roboport-equipment] Lazy starter equipment and market
    [entity=biter-spawner] Pollution spreads fast
    [entity=small-biter] Biter activity high
    [item=landfill] Landfill disabled
    
Coded with love, but without much lua experience: Blame Tar[technology=optics]  for bugs.
     ]])

--Map generation settings
RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none,
        MGSP.water_none,
    }
    )
--Ore generation: Copy for "void gears' - altered seeds 
    local seed1 = 42900
    local seed2 = 57500
    --11900 --11830
gear = b.decompress(gear)
local gear_big = b.picture(gear)
local gear_medium = b.scale(gear_big, 2 / 3)
local gear_small = b.scale(gear_big, 1 / 3)
local value = b.manhattan_value
local ores = {
    {resource_type = 'iron-ore', value = value(250, 1.5)},
    {resource_type = 'copper-ore', value = value(250, 1.6)},
    {resource_type = 'stone', value = value(250, 1)},
    {resource_type = 'coal', value = value(250, 1)},
    {resource_type = 'uranium-ore', value = value(125, 0.8)},
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
local function sprinkle(shape) -- luacheck: ignore 431
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
    local orepattern = {}
    for _ = 1, p_cols do
        local row = {}
        table.insert(orepattern, row)
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
    return orepattern
end
big_patches = do_patches(big_patches, 256)
big_patches = b.grid_pattern_full_overlap(big_patches, p_cols, p_rows, 256, 256)
medium_patches = do_patches(medium_patches, 192)
medium_patches = b.grid_pattern_full_overlap(medium_patches, p_cols, p_rows, 192, 192)
small_patches = do_patches(small_patches, 128)
small_patches = b.grid_pattern_full_overlap(small_patches, p_cols, p_rows, 128, 128)

--Terraforming
local pic1 = require "map_gen.data.presets.factorio_logo2"
--picture size 921x153
pic1 = b.decompress(pic1)
local map1file = b.picture(pic1)
--connect the gear island to the rest of the logo
local fillerblock = b.translate(b.rectangle(14,12), 248,2)
fillerblock = b.change_tile(fillerblock, true, "grass-4")
local map1 = b.add(fillerblock, map1file)
-- Rotated logo's
local map2 = b.rotate (map1, math.pi/2)
--The shape chamfer is the square with chamfer corners
local shap1 = b.translate(b.rectangle_diamond(26, 24), pic1.height/2,pic1.height/2)
local shap2 = b.rotate((shap1), math.pi/2)
local shap3 = b.rotate((shap2), math.pi/2)
local shap4 = b.rotate((shap3), math.pi/2)
local shap5 = b.invert(b.rectangle(pic1.height+1, pic1.height+1))
--Corner is the shape where players start
local chamfer = b.invert(b.any({shap1, shap2, shap3, shap4, shap5}))
local corner = chamfer
corner = b.change_tile(corner, true, "grass-4")
--Botland adds accespoints to the islands
local shape1 = b.translate(b.rectangle(250, 40), 74, 0)
local shape2 = b.rotate((shape1), math.pi/2)
local shape3 = b.rotate((shape2), math.pi/2)
local shape4 = b.rotate((shape3), math.pi/2)
local shape5 = b.scale((chamfer), 1.4,1.4)
local botland = b.any({shape5, shape1, shape2, shape3, shape4})
botland = b.remove_map_gen_enemies(botland)
botland = b.scale(botland, 2.2,2.2)
botland = b.change_tile(botland, true, 'landfill')
botland = b.remove_map_gen_trees(botland)
botland = b.remove_map_gen_resources(botland)
--Patternize shapes infinitly
local mappattern = {
    {corner, map1},
    {map2,botland}
}
local terra = b.grid_pattern_overlap(mappattern, 2, 2, 499,499)
--creating a shape with the ore pattern, to make ore only appear out of player reach.
local orezone = b.scale((chamfer), 3,3)
orezone = b.remove_map_gen_enemies(orezone)
orezone = b.remove_map_gen_trees(orezone)
orezone = b.change_tile(orezone, true, 'landfill')
local oremask = b.single_pattern(orezone, 998, 998)
oremask = b.translate(oremask, 497, 497)
oremask = b.apply_entities(oremask, {big_patches, medium_patches, small_patches})
local map =b.add(oremask, terra)  
--Final map, scale defines gap between islands and the grid land. Test gaps with large poles, roboports and spidertron.
map = b.scale(map, 1.2,1.2)
map = b.change_tile(map, false, "water")
map = b.fish(map, 0.0025)

local centre =b.circle(17)
map = b.if_else(centre, map)
centre = b.change_map_gen_collision_tile(centre, 'ground-tile', 'stone-path')
-- the coordinates at which the standard market and spawn  will be created
local startx = 0
local starty = 0
 --player
local surface = RS.get_surface()local spawn_position = {x = startx, y = starty-3}
RS.set_spawn_position(spawn_position, surface)


--Starting ores
local start_stone =
    b.resource(
    gear_big,
    'stone',
    function()
        return 800
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
        return 1200
    end
)
local start_iron =
    b.resource(
    gear_big,
    'iron-ore',
    function()
        return 1800
    end
)
local start_segmented = b.segment_pattern({start_stone, start_coal, start_iron, start_copper})
local start_gear = b.apply_entity(gear_big, start_segmented)
start_gear = b.change_tile(start_gear, true, "grass-3")
map = b.if_else(start_gear, map)
map = b.if_else(centre, map)
          
   --Starting equipment
local player_create = global.config.player_create
player_create.starting_items = {
    {name = 'modular-armor', count = 1},
    {name = 'solar-panel-equipment', count = 7},
    {name = 'battery-mk2-equipment', count = 1},
    {name = 'personal-roboport-equipment', count = 1},
    {name = 'construction-robot', count = 10},
    {name = 'exoskeleton-equipment', count = 1},
    {name = 'iron-gear-wheel', count = 8},
    {name = 'iron-plate', count = 40},
    {name = 'copper-plate', count = 20},
    {name = 'coal', count = 5}
}
player_create.join_messages = {
            'Welcome to this map created by the RedMew community. You can join the discord at: redmew.com/discord',
    'Click the question mark in the top left corner for server information and map details.'
}
        --Starting Techs
Event.on_init(
    function()
        surface = RS.get_surface()
        local force = game.forces.player
        force.technologies['automation'].researched = true
        force.technologies['logistics'].researched = true
        force.technologies['landfill'].enabled = false -- disable landfill
           
           -- Set up non-standard market so we can add logistics network things without editing a different file
    global.config.market.create_standard_market = false
    Retailer.set_item('items', {price = 100, name = 'player-port'})
    Retailer.set_item('items', {price = 15, name = 'submachine-gun'})
    Retailer.set_item('items', {price = 250, name = 'combat-shotgun'})
    Retailer.set_item('items', {price = 250, name = 'flamethrower'})
    Retailer.set_item('items', {price = 175, name = 'rocket-launcher'})
    Retailer.set_item('items', {price = 250, name = 'tank-cannon'})
    Retailer.set_item('items', {price = 2500, name = 'artillery-wagon-cannon'})
    Retailer.set_item('items', {price = 1, name = 'firearm-magazine'})
    Retailer.set_item('items', {price = 5, name = 'piercing-rounds-magazine'})
    Retailer.set_item('items', {price = 20, name = 'uranium-rounds-magazine'})
    Retailer.set_item('items', {price = 2, name = 'shotgun-shell'})
    Retailer.set_item('items', {price = 10, name = 'piercing-shotgun-shell'})
    Retailer.set_item('items', {price = 25, name = 'flamethrower-ammo'})
    Retailer.set_item('items', {price = 15, name = 'rocket'})
    Retailer.set_item('items', {price = 25, name = 'explosive-rocket'})
    Retailer.set_item('items', {price = 30, name = 'explosive-cannon-shell'})
    Retailer.set_item('items', {price = 75, name = 'explosive-uranium-cannon-shell'})
    Retailer.set_item('items', {price = 35, name = 'cluster-grenade'})
    Retailer.set_item('items', {price = 35, name = 'poison-capsule'})
    Retailer.set_item('items', {price = 875, name = 'power-armor'})
    Retailer.set_item('items', {price = 2500, name = 'power-armor-mk2'})
    Retailer.set_item('items', {price = 40, name = 'solar-panel-equipment'})
    Retailer.set_item('items', {price = 875, name = 'fusion-reactor-equipment'})
    Retailer.set_item('items', {price = 100, name = 'battery-equipment'})
    Retailer.set_item('items', {price = 625, name = 'battery-mk2-equipment'})
    Retailer.set_item('items', {price = 150, name = 'exoskeleton-equipment'})
    Retailer.set_item('items', {price = 250, name = 'energy-shield-equipment'}) 
    Retailer.set_item('items', {price = 750, name = 'energy-shield-mk2-equipment'}) 
    Retailer.set_item('items', {price = 750, name = 'personal-laser-defense-equipment'})
    Retailer.set_item('items', {price = 250, name = 'personal-roboport-equipment'}) 
    Retailer.set_item('items', {price = 6, name = 'big-electric-pole'})
    Retailer.set_item('items', {price = 25, name = 'substation'})
    Retailer.set_item('items', {price = 10, name = 'construction-robot'})
    Retailer.set_item('items', {price = 2, name = 'logistic-robot'})
    Retailer.set_item('items', {price = 50, name = 'roboport'})
    Retailer.set_item('items', {price = 25, name = 'logistic-chest-active-provider'})
    Retailer.set_item('items', {price = 25, name = 'logistic-chest-passive-provider'})
    Retailer.set_item('items', {price = 25, name = 'logistic-chest-requester'})
    Retailer.set_item('items', {price = 25, name = 'logistic-chest-storage'})
    Retailer.set_item('items', {price = 25, name = 'logistic-chest-buffer'})

    Retailer.set_market_group_label('items', 'Items Market')
    local item_market_1 = surface.create_entity({name = 'market', position = {0, 0}})
    item_market_1.destructible = false
    Retailer.add_market('items', item_market_1)
    
     Retailer.add_market('items', item_market)
   end
)
Event.on_init(on_init)

return map
