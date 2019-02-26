--This is Orange's first map, a tweaked toxic jungle. Credit should go to the original toxic jungle creators, and to those who put up with my github education (and lack thereof).

local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local RecipeLocker = require 'utils.recipe_locker'
local Perlin = require 'map_gen.shared.perlin_noise'
local RS = require 'map_gen.shared.redmew_surface'
local Retailer = require 'features.retailer'
local ScenarioInfo = require 'features.gui.info'

local config = global.config

local enemy_seed = 420420

config.market.create_standard_market = false -- stop standard market from spawning
global.config.hail_hydra.enabled = true

for _, v in pairs(config.market.entity_drop_amount) do
    v.chance = 1
end

ScenarioInfo.set_map_name('Toxic Science Jungle')
ScenarioInfo.set_map_description('March your way through the jungle, and use coins you find to purchase certain science packs at the market.')
ScenarioInfo.add_map_extra_info('-Military, Production, High-Tech science pack crafting disabled.\n-Spend coins at the market to buy packs.\n-Increased coin drops from aliens.\n-Flamethrower technology disabled.')

local map_gen_settings = {
    autoplace_controls = {
        coal = {
            frequency = 'low',
            richness = 'good'
        },
        ['copper-ore'] = {
            frequency = 'high',
            richness = 'good'
        },
        ['iron-ore'] = {
            frequency = 'high',
            richness = 'good'
        },
        stone = {
            richness = 'good'
        },
        ['uranium-ore'] = {
            richness = 'good'
        },
        ['crude-oil'] = {
            richness = 'very-good'
        }
    },
    terrain_segmentation = 'very-high',
    water = 'very-big'
}
RS.set_map_gen_settings({map_gen_settings})
RS.set_map_settings({enemy_expansion = {enabled = true}})

RecipeLocker.lock_recipes(
    {
        'military-science-pack',
        'production-science-pack',
        'utility-science-pack'
    }
)

Event.add(
    defines.events.on_research_finished,
    function(event)
        local r = event.research
        if r.name == 'military-2' then
            game.forces.player.manual_mining_speed_modifier = 0
        end
    end
)

local function on_init()
    local player_force = game.forces.player
    player_force.technologies['flamethrower'].enabled = false -- disable flamethrower tech
    player_force.manual_mining_speed_modifier = 2 -- increase mining speed, disabled after military 2 research

    Retailer.set_item(
        'items',
        {
            name = 'temporary-running-speed-bonus',
            name_label = 'Temporary running speed bonus',
            type = 'temporary-buff',
            description = 'Increases running speed by one level for a short period',
            sprite = 'technology/exoskeleton-equipment',
            stack_limit = 1,
            price = 10
        }
    )
    Retailer.set_item(
        'items',
        {
            name = 'temporary-mining-speed-bonus',
            name_label = 'Temporary mining speed bonus',
            type = 'temporary-buff',
            description = 'Increases manual mining speed by one level for a short period',
            sprite = 'technology/mining-productivity-1',
            stack_limit = 1,
            price = 10
        }
    )
    Retailer.set_item('items', {price = 2, name = 'raw-fish'})
    Retailer.set_item('items', {price = 25, name = 'military-science-pack'})
    Retailer.set_item('items', {price = 50, name = 'production-science-pack'})
    Retailer.set_item('items', {price = 125, name = 'utility-science-pack'})
    Retailer.set_item('items', {price = 1, name = 'rail'})
    Retailer.set_item('items', {price = 2, name = 'rail-signal'})
    Retailer.set_item('items', {price = 2, name = 'rail-chain-signal'})
    Retailer.set_item('items', {price = 15, name = 'train-stop'})
    Retailer.set_item('items', {price = 75, name = 'locomotive'})
    Retailer.set_item('items', {price = 30, name = 'cargo-wagon'})
    Retailer.set_item('items', {price = 0.95, name = 'red-wire'})
    Retailer.set_item('items', {price = 0.95, name = 'green-wire'})
    Retailer.set_item('items', {price = 3, name = 'decider-combinator'})
    Retailer.set_item('items', {price = 3, name = 'arithmetic-combinator'})
    Retailer.set_item('items', {price = 3, name = 'constant-combinator'})
    Retailer.set_item('items', {price = 7, name = 'programmable-speaker'})
    Retailer.set_item('items', {price = 15, name = 'submachine-gun'})
    Retailer.set_item('items', {price = 15, name = 'shotgun'})
    Retailer.set_item('items', {price = 250, name = 'combat-shotgun'})
    Retailer.set_item('items', {price = 25, name = 'railgun'})
    Retailer.set_item('items', {price = 175, name = 'rocket-launcher'})
    Retailer.set_item('items', {price = 250, name = 'tank-cannon'})
    Retailer.set_item('items', {price = 750, name = 'tank-machine-gun'})
    Retailer.set_item('items', {price = 2500, name = 'artillery-wagon-cannon'})
    Retailer.set_item('items', {price = 1, name = 'firearm-magazine'})
    Retailer.set_item('items', {price = 5, name = 'piercing-rounds-magazine'})
    Retailer.set_item('items', {price = 20, name = 'uranium-rounds-magazine'})
    Retailer.set_item('items', {price = 2, name = 'shotgun-shell'})
    Retailer.set_item('items', {price = 10, name = 'piercing-shotgun-shell'})
    Retailer.set_item('items', {price = 5, name = 'railgun-dart'})
    Retailer.set_item('items', {price = 15, name = 'rocket'})
    Retailer.set_item('items', {price = 25, name = 'explosive-rocket'})
    Retailer.set_item('items', {price = 2500, name = 'atomic-bomb'})
    Retailer.set_item('items', {price = 20, name = 'cannon-shell'})
    Retailer.set_item('items', {price = 30, name = 'explosive-cannon-shell'})
    Retailer.set_item('items', {price = 75, name = 'explosive-uranium-cannon-shell'})
    Retailer.set_item('items', {price = 100, name = 'artillery-shell'})
    Retailer.set_item('items', {price = 3, name = 'land-mine'})
    Retailer.set_item('items', {price = 5, name = 'grenade'})
    Retailer.set_item('items', {price = 35, name = 'cluster-grenade'})
    Retailer.set_item('items', {price = 5, name = 'defender-capsule'})
    Retailer.set_item('items', {price = 75, name = 'destroyer-capsule'})
    Retailer.set_item('items', {price = 35, name = 'poison-capsule'})
    Retailer.set_item('items', {price = 35, name = 'slowdown-capsule'})
    Retailer.set_item('items', {price = 50, name = 'artillery-targeting-remote'})
    Retailer.set_item('items', {price = 1000, name = 'artillery-turret'})
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

    Retailer.set_market_group_label('items', 'Items Market')
    local surface = RS.get_surface()
    local item_market_1 = surface.create_entity({name = 'market', position = {0, 0}})
    item_market_1.destructible = false
    Retailer.add_market('items', item_market_1)
end

Event.on_init(on_init)

-- Map

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

local function tree_shape()
    local tree = trees[math.random(trees_count)]

    return {name = tree}
    --, always_place = true}
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

    if d < 2 then
        return nil
    end

    if d < 100 then
        return tree_shape()
    end

    local threshold = 1 - d * m
    threshold = math.max(threshold, 0.25) -- -0.125)

    x, y = x * sf, y * sf
    if Perlin.noise(x, y, enemy_seed) > threshold then
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
    else
        return tree_shape()
    end
end

local map = b.full_shape

map = b.change_map_gen_tile(map, 'water', 'water-green')
map = b.change_map_gen_tile(map, 'deepwater', 'deepwater-green')

map = b.apply_entity(map, enemy)

return map
