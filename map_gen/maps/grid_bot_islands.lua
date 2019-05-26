local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local degrees = require 'utils.math'.degrees
local math = require 'utils.math'
local table = require 'utils.table'
local Perlin = require 'map_gen.shared.perlin_noise'
local ore_seed1 = 1000
local ore_seed2 = ore_seed1 * 2
local enemy_seed = 420420

local Event = require 'utils.event'
local Retailer = require 'features.retailer'

local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none,
        MGSP.grass_only,
        MGSP.enable_water,
        MGSP.enemy_none
    }
)

-- Overwrite default config for biter coin drop chances to give the players some extra coins to spend on logi bots
local market = global.config.market
market.entity_drop_amount = {
    ['biter-spawner'] = {low = 5, high = 15, chance = 1},
    ['spitter-spawner'] = {low = 5, high = 15, chance = 1},
    ['small-worm-turret'] = {low = 2, high = 8, chance = 1},
    ['medium-worm-turret'] = {low = 5, high = 15, chance = 1},
    ['big-worm-turret'] = {low = 10, high = 20, chance = 1},

    -- default is 0
    ['small-biter'] = {low = 1, high = 2, chance = 0.1},
    ['small-spitter'] = {low = 1, high = 2, chance = 0.05},
    ['medium-spitter'] = {low = 1, high = 3, chance = 0.05},
    ['big-spitter'] = {low = 1, high = 3, chance = 0.05},
    ['behemoth-spitter'] = {low = 1, high = 10, chance = 0.05},
    ['medium-biter'] = {low = 1, high = 3, chance = 0.05},
    ['big-biter'] = {low = 1, high = 5, chance = 0.05},
    ['behemoth-biter'] = {low = 1, high = 10, chance = 0.05}
}

-- Setup the scenario map information because everyone gets upset if you don't
local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Grid Bot Islands')
ScenarioInfo.set_map_description('Grid islands with island-based ore mining and deathworld biter settings')
ScenarioInfo.set_map_extra_info('- Mine the islands with your bots\n- Buy more bots and chests from the market\n- Defend from the hordes of biters!!\n- Earn gold from killing worms and nests and mining trees and rocks')

-- Modify the player starting items to kickstart island mining
local player_create = global.config.player_create
player_create.starting_items = {
    {name = 'modular-armor', count = 1},
    {name = 'solar-panel-equipment', count = 7},
    {name = 'battery-equipment', count = 2},
    {name = 'personal-roboport-equipment', count = 2},
    {name = 'construction-robot', count = 25},
    {name = 'iron-gear-wheel', count = 8},
    {name = 'iron-plate', count = 16}
}

-- Begin map layout stuff
local h_track = {
    b.line_x(2),
    b.translate(b.line_x(2), 0, -3),
    b.translate(b.line_x(2), 0, 3),
    b.rectangle(2, 10)
}

h_track = b.any(h_track)
h_track = b.single_x_pattern(h_track, 15)

local v_track = {
    b.line_y(2),
    b.translate(b.line_y(2), -3, 0),
    b.translate(b.line_y(2), 3, 0),
    b.rectangle(10, 2)
}

v_track = b.any(v_track)
v_track = b.single_y_pattern(v_track, 15)

local square = b.rectangle(130, 130)

local ore_square = b.rectangle(20, 20)
local small_ore_square = b.rectangle(18, 18)

local leg = b.rectangle(32, 480)
local head = b.translate(b.oval(32, 64), 0, -64)
local body = b.translate(b.circle(64), 0, 64)

local count = 10
local angle = 360 / count
local list = {head, body}
for i = 1, (count / 2) - 1 do
    local shape = b.rotate(leg, degrees(i * angle))
    table.insert(list, shape)
end

local spider = b.any(list)

-- Change ore values based upon distance from 0,0
local function value(base, mult, pow)
    return function(x, y)
        local d_sq = x * x + y * y
        return base + mult * d_sq ^ (pow / 2) -- d ^ pow
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
    return shape
end

local ores = {
    {transform = non_transform, resource = 'iron-ore', value = value(500, 0.75, 1.1), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(400, 0.75, 1.1), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(250, 0.3, 1.05), weight = 3},
    {transform = non_transform, resource = 'coal', value = value(400, 0.8, 1.075), weight = 5},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(200, 0.3, 1.025), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(60000, 50, 1.025), weight = 6}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in ipairs(ores) do
    ore_t = ore_t + v.weight
    table.insert(total_ore_weights, ore_t)
end

-- for the main islands. Cut down from original functionality. Hacky.
local pattern = {}
for r = 1, 50 do
    local row = {}
    pattern[r] = row
    for c = 1, 50 do
        row[c] = square
    end
end

-- Make a 50 x 50 grid of ores with randomised ore types
local random_ore = Random.new(ore_seed1, ore_seed2)
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

        local ore_shape = ore_data.transform(small_ore_square)
        local ore = b.resource(ore_shape, ore_data.resource, ore_data.value)

        local shape = ore_square
        shape = b.apply_entity(shape, ore)

        row[c] = shape
    end
end

-- create a mask to place over the ore grid
local mask_square = b.rectangle(60, 60)
mask_square = b.change_tile(mask_square, true, 'sand-1')
local mask_group =
    b.any {
    mask_square,
    b.translate(mask_square, 90, 0),
    b.translate(mask_square, 0, 90),
    b.translate(mask_square, 90, 90)
}
mask_group = b.translate(mask_group, -60, -60)

-- sort out the starting ore patches
local start_patch = b.scale(spider, 0.1, 0.1)
local start_iron_patch =
    b.resource(
    b.translate(start_patch, 64, 0),
    'iron-ore',
    function()
        return 5000
    end
)
local start_copper_patch =
    b.resource(
    b.translate(start_patch, 0, -64),
    'copper-ore',
    function()
        return 5000
    end
)
local start_stone_patch =
    b.resource(
    b.translate(start_patch, -64, 0),
    'stone',
    function()
        return 5000
    end
)
local start_coal_patch =
    b.resource(
    b.translate(start_patch, 0, 64),
    'coal',
    function()
        return 5000
    end
)

local start_resources = b.any({start_iron_patch, start_copper_patch, start_stone_patch, start_coal_patch})
local start = b.apply_entity(b.square_diamond(254), start_resources)

-- Deathworld biters. Rawr!
local worm_names = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret'}
local spawner_names = {'biter-spawner', 'spitter-spawner'}
local factor = 16 / (1024 * 32)
local max_chance = 1 / 4

local scale_factor = 4
local sf = 1 / scale_factor
local m = 1 / 600
local function enemy(x, y, world)
    local d = math.sqrt(world.x * world.x + world.y * world.y)
    if d < 400 then
        return nil
    end

    local threshold = 1 - d * m
    threshold = math.max(threshold, 0.5) -- -0.125)

    x, y = x * sf, y * sf
    if Perlin.noise(x, y, enemy_seed) > threshold then
        if math.random(8) <= 2 then
            local lvl
            if d < 300 then
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
end

-- Put it all together
local map = b.grid_pattern(pattern, 50, 50, 300, 300)
map = b.choose(b.rectangle(300, 300), start, map)

local resource_islands = b.grid_pattern(ore_pattern, 50, 50, 30, 30)
resource_islands = b.change_tile(resource_islands, true, 'sand-1')

local mask_pattern = {
    {mask_group, mask_group, mask_group},
    {mask_group, mask_group, mask_group},
    {mask_group, mask_group, mask_group}
}

local resource_mask = b.grid_pattern(mask_pattern, 3, 3, 300, 300)
resource_mask = b.translate(resource_mask, -130, -130)
resource_islands = b.choose(resource_mask, resource_islands, b.empty_shape)

local paths =
    b.any {
    b.single_y_pattern(h_track, 300),
    b.single_x_pattern(v_track, 300)
}

local sea = b.tile('deepwater')
sea = b.fish(sea, 0.0025)
map = b.apply_entity(map, enemy)

map = b.any {map, paths, resource_islands, sea}

map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')

local function on_init()
    local surface = RS.get_surface()
    local player_force = game.forces.player
    local enemy_force = game.forces.enemy
    player_force.technologies['landfill'].enabled = false -- disable landfill
    --enemy_force.set_ammo_damage_modifier('melee', 1) -- +100% biter damage
    enemy_force.set_ammo_damage_modifier('biological', 1) -- +100% spitter/worm damage
    game.map_settings.enemy_expansion.enabled = true

    -- Set up non-standard market so we can add logistics network things without editing a different file
    global.config.market.create_standard_market = false
    Retailer.set_item('items', {price = 2, name = 'raw-fish'})
    Retailer.set_item('items', {price = 1, name = 'rail'})
    Retailer.set_item('items', {price = 2, name = 'rail-signal'})
    Retailer.set_item('items', {price = 2, name = 'rail-chain-signal'})
    Retailer.set_item('items', {price = 15, name = 'train-stop'})
    Retailer.set_item('items', {price = 75, name = 'locomotive'})
    Retailer.set_item('items', {price = 30, name = 'cargo-wagon'})
    Retailer.set_item('items', {price = 15, name = 'submachine-gun'})
    Retailer.set_item('items', {price = 15, name = 'shotgun'})
    Retailer.set_item('items', {price = 250, name = 'combat-shotgun'})
    Retailer.set_item('items', {price = 25, name = 'railgun'})
    Retailer.set_item('items', {price = 250, name = 'flamethrower'})
    Retailer.set_item('items', {price = 175, name = 'rocket-launcher'})
    Retailer.set_item('items', {price = 250, name = 'tank-cannon'})
    Retailer.set_item('items', {price = 75, name = 'tank-flamethrower'})
    Retailer.set_item('items', {price = 1, name = 'firearm-magazine'})
    Retailer.set_item('items', {price = 5, name = 'piercing-rounds-magazine'})
    Retailer.set_item('items', {price = 20, name = 'uranium-rounds-magazine'})
    Retailer.set_item('items', {price = 2, name = 'shotgun-shell'})
    Retailer.set_item('items', {price = 10, name = 'piercing-shotgun-shell'})
    Retailer.set_item('items', {price = 5, name = 'railgun-dart'})
    Retailer.set_item('items', {price = 25, name = 'flamethrower-ammo'})
    Retailer.set_item('items', {price = 15, name = 'rocket'})
    Retailer.set_item('items', {price = 25, name = 'explosive-rocket'})
    Retailer.set_item('items', {price = 20, name = 'cannon-shell'})
    Retailer.set_item('items', {price = 30, name = 'explosive-cannon-shell'})
    Retailer.set_item('items', {price = 75, name = 'explosive-uranium-cannon-shell'})
    Retailer.set_item('items', {price = 3, name = 'land-mine'})
    Retailer.set_item('items', {price = 5, name = 'grenade'})
    Retailer.set_item('items', {price = 35, name = 'cluster-grenade'})
    Retailer.set_item('items', {price = 5, name = 'defender-capsule'})
    Retailer.set_item('items', {price = 75, name = 'destroyer-capsule'})
    Retailer.set_item('items', {price = 35, name = 'poison-capsule'})
    Retailer.set_item('items', {price = 350, name = 'modular-armor'})
    Retailer.set_item('items', {price = 875, name = 'power-armor'})
    Retailer.set_item('items', {price = 40, name = 'solar-panel-equipment'})
    Retailer.set_item('items', {price = 875, name = 'fusion-reactor-equipment'})
    Retailer.set_item('items', {price = 100, name = 'battery-equipment'})
    Retailer.set_item('items', {price = 625, name = 'battery-mk2-equipment'})
    Retailer.set_item('items', {price = 250, name = 'belt-immunity-equipment'})
    Retailer.set_item('items', {price = 100, name = 'night-vision-equipment'})
    Retailer.set_item('items', {price = 150, name = 'exoskeleton-equipment'})
    Retailer.set_item('items', {price = 250, name = 'personal-roboport-equipment'})
    Retailer.set_item('items', {price = 10, name = 'construction-robot'})
    Retailer.set_item('items', {price = 2, name = 'logistic-robot'})
    Retailer.set_item('items', {price = 75, name = 'roboport'})
    Retailer.set_item('items', {price = 50, name = 'logistic-chest-active-provider'})
    Retailer.set_item('items', {price = 50, name = 'logistic-chest-passive-provider'})
    Retailer.set_item('items', {price = 50, name = 'logistic-chest-requester'})
    Retailer.set_item('items', {price = 50, name = 'logistic-chest-storage'})
    Retailer.set_item('items', {price = 6, name = 'big-electric-pole'})
    Retailer.set_item('items', {price = 3, name = 'medium-electric-pole'})
    Retailer.set_item('items', {price = 50, name = 'substation'})

    Retailer.set_market_group_label('items', 'Items Market')
    local item_market_1 = surface.create_entity({name = 'market', position = {0, 0}})
    item_market_1.destructible = false
    Retailer.add_market('items', item_market_1)
end
Event.on_init(on_init)

return map
