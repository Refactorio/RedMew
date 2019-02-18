local b = require 'map_gen.shared.builders'
local Perlin = require 'map_gen.shared.perlin_noise'
local Global = require 'utils.global'
local Event = require 'utils.event'
local math = require 'utils.math'
local table = require 'utils.table'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Utils = require 'utils.core'
local RS = require 'map_gen.shared.redmew_surface'
local DayNight = require 'map_gen.shared.day_night'
local ScenarioInfo = require 'features.gui.info'
local Toast = require 'features.gui.toast'
local Retailer = require 'features.retailer'

local MGSP = require 'resources.map_gen_settings'
local market_items = require 'resources.market_items'

local noise = Perlin.noise
local remove = table.remove
local insert = table.insert
local format = string.format

local config = global.config

local tech_cost = 1000
-- Startup bonus
local toast_duration = 15 -- secs
local startup_bonus = 50 -- mining multiplier
local timeout_duration = (20 * 60) / (1000 / tech_cost) -- at 1000x tech cost these are 20 min timeouts meaning the bonuses are gone at 2hr

local evo_multiplier = (1 / tech_cost) * 25

-- Multipliers added as the last number to make it easier to read/understand the deviation from norms
local map_settings = {
    pollution = {
        enabled = false
    },
    enemy_evolution = {
        enabled = true,
        time_factor = (0.000004 * evo_multiplier),
        destroy_factor = (0.002 * evo_multiplier),
        pollution_factor = (0.000015 * evo_multiplier)
    },
    enemy_expansion = {
        enabled = false
    }
}

-- Setup

-- Enable infinite storage chest
config.infinite_storage_chest.enabled = true
config.infinite_storage_chest.cost = 35

-- Enable hydra
config.hail_hydra.enabled = true

config.hail_hydra.hydras = {
    -- spitters
    ['small-spitter'] = {['small-spitter'] = 0.1},
    ['medium-spitter'] = {['small-spitter'] = 0.2, ['medium-spitter'] = 0.1},
    ['big-spitter'] = {['small-spitter'] = 0.3, ['medium-spitter'] = 0.2, ['big-spitter'] = 0.1},
    ['behemoth-spitter'] = {['small-spitter'] = 0.4, ['medium-spitter'] = 0.3, ['big-spitter'] = 0.2, ['behemoth-spitter'] = 0.1},
    -- biters
    ['small-biter'] = {['small-biter'] = 0.2},
    ['medium-biter'] = {['small-biter'] = 0.4, ['medium-biter'] = 0.2},
    ['big-biter'] = {['small-biter'] = 0.6, ['medium-biter'] = 0.4, ['big-biter'] = 0.4},
    ['behemoth-biter'] = {['small-biter'] = 0.8, ['medium-biter'] = 0.6, ['big-biter'] = 0.4, ['behemoth-biter'] = 0.2},
    -- worms
    ['small-worm-turret'] = {['small-biter'] = 2.5, ['medium-biter'] = 0.05},
    ['medium-worm-turret'] = {['small-biter'] = 5, ['medium-biter'] = 2.5, ['big-biter'] = 0.05},
    ['big-worm-turret'] = {['small-biter'] = 10, ['medium-biter'] = 5, ['big-biter'] = 2.5, ['behemoth-biter'] = 0.05}
}

-- Scenario info
local map_extra_info = [[
- There are infinite ores in every direction.
- You have done basic research into how to build a factory.
- The market does not offer what it normally does.
- The biters are plentiful, but seem slow to evolve.
- The sun's position seems unchanging.
]]
ScenarioInfo.set_map_name('The 1000 Yard Stare')
ScenarioInfo.set_map_description('Resources are not an issue as you march your way through the tech tree.')
ScenarioInfo.add_map_extra_info(map_extra_info .. '- Your miners and your hands will work extra hard when you first arrive\nBut they will tire over time.')

-- Redmew surface
RS.set_first_player_position_check_override(true)
RS.set_spawn_island_tile('sand-1')
RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none,
        MGSP.starting_area_very_low,
        MGSP.enemy_very_high,
        MGSP.sand_only
    }
)
RS.set_difficulty_settings({{technology_price_multiplier = tech_cost}})
RS.set_map_settings({map_settings})

-- Setup market inventory
config.market.create_standard_market = false
if config.market.enabled then
    local items_to_add = {
        {name = 'modular-armor', stack_limit = 1, player_limit = 1, price = 50},
        {name = 'power-armor', stack_limit = 1, player_limit = 1, price = 2000},
        {name = 'fusion-reactor-equipment', stack_limit = 1, player_limit = 1, price = 300},
        {name = 'energy-shield-equipment', stack_limit = 1, player_limit = 1, price = 350},
        {name = 'defender-capsule', stack_limit = 25, player_limit = 25, price = 1},
        {name = 'distractor-capsule', stack_limit = 50, player_limit = 50, price = 10},
        {name = 'destroyer-capsule', price = 50}
    }
    local items_to_drop = {
        'tank-cannon',
        'tank-machine-gun',
        'artillery-wagon-cannon',
        'artillery-turret',
        'artillery-targeting-remote',
        'defender-capsule',
        'destroyer-capsule',
        'programmable-speaker',
        'personal-laser-defense-equipment'
    }

    -- Remove items_to_drop from marker
    for i = #market_items, 1, -1 do
        local name = market_items[i].name

        if table.array_contains(items_to_drop, name) then
            remove(market_items, i)
        end
    end

    -- Add items_to_add to market
    for i = 1, #items_to_add do
        insert(market_items, items_to_add[i])
    end
end

--- A timeout loop that decreases the mining bonus until < 1 then eliminates it and enables the productivity research
local timeout_token
local function decrease_boost()
    local force = game.forces.player
    force.mining_drill_productivity_bonus = force.mining_drill_productivity_bonus / 2
    force.manual_mining_speed_modifier = force.manual_mining_speed_modifier / 2
    force.manual_crafting_speed_modifier = force.manual_crafting_speed_modifier / 2
    if force.mining_drill_productivity_bonus < 1 then
        force.mining_drill_productivity_bonus = 0
        force.manual_mining_speed_modifier = 0
        force.manual_crafting_speed_modifier = 0
        force.technologies['mining-productivity-1'].enabled = true
        Toast.toast_all_players(toast_duration, 'Your hands and all miners seem to have returned to their normal speeds.')
        Utils.print_admins('The mining and crafting bonuses are finished. Mining productivity research has been unlocked (lol).', nil)
        ScenarioInfo.set_map_extra_info(map_extra_info)
        return
    end
    Toast.toast_all_players(toast_duration, 'Your hands and the miners seem to be slowing.')
    Utils.print_admins(format('The mining bonuses are now only %sx, crafting bonus is %sx', force.mining_drill_productivity_bonus, force.manual_crafting_speed_modifier), nil)
    Task.set_timeout(timeout_duration, timeout_token, nil)
end
timeout_token = Token.register(decrease_boost)

-- Initial techs, setting day_night cycle, placing market
Event.on_init(
    function()
        local force = game.forces.player
        local surface = RS.get_surface()
        local pos = {0, -15}

        -- Techs
        force.technologies['automation'].researched = true
        force.technologies['turrets'].researched = true
        force.technologies['military'].researched = true
        force.technologies['logistics'].researched = true
        if config.redmew_qol.enabled and config.redmew_qol.loaders then
            force.recipes['loader'].enabled = true
        end

        -- DayNight call
        DayNight.set_fixed_brightness(1, RS.get_surface())

        if config.market.enabled then
            config.market.create_standard_market = false
            -- Market creation
            local market = surface.create_entity({name = 'market', position = pos})
            market.destructible = false
            Retailer.add_market('items', market)
            if table.size(Retailer.get_items('items')) == 0 then
                for _, prototype in pairs(market_items) do
                    Retailer.set_item('items', prototype)
                end
            end
            force.add_chart_tag(surface, {icon = {type = 'item', name = config.market.currency}, position = pos, text = 'Market'})
        end

        -- Startup bonus
        force.technologies['mining-productivity-1'].enabled = false
        force.mining_drill_productivity_bonus = startup_bonus
        force.manual_mining_speed_modifier = startup_bonus
        force.manual_crafting_speed_modifier = startup_bonus / 10
        Task.set_timeout(timeout_duration, timeout_token, nil)
    end
)

-- Map

-- Constants
local value = 4294967294
local oil_scale = 1 / 64
local oil_threshold = 0.6

local uranium_scale = 1 / 128
local uranium_threshold = 0.65

local density_scale = 1 / 48
local density_threshold = 0.5
local density_multiplier = 50

-- Local Globals
local oil_seed
local uranium_seed
local density_seed

Global.register_init(
    {},
    function(tbl)
        tbl.seed = RS.get_surface().map_gen_settings.seed
    end,
    function(tbl)
        local seed = tbl.seed
        oil_seed = seed
        uranium_seed = seed * 2
        density_seed = seed * 3
    end
)

-- Functions

local function constant(amount)
    return function()
        return amount
    end
end

local oil_shape = b.throttle_world_xy(b.full_shape, 1, 8, 1, 8)
local oil_resource = b.resource(oil_shape, 'crude-oil', constant(value))

local uranium_resource = b.resource(b.full_shape, 'uranium-ore', constant(value))

local ores = {
    {resource = b.resource(b.full_shape, 'iron-ore', constant(value)), weight = 6},
    {resource = b.resource(b.full_shape, 'copper-ore', constant(value)), weight = 4},
    {resource = b.resource(b.full_shape, 'stone', constant(value)), weight = 1},
    {resource = b.resource(b.full_shape, 'coal', constant(value)), weight = 2}
}

local weighted_ores = b.prepare_weighted_array(ores)
local total_ores = weighted_ores.total

local ore_circle = b.circle(12)
local start_ores = {
    b.resource(ore_circle, 'iron-ore', constant(value)),
    b.resource(ore_circle, 'copper-ore', constant(value)),
    b.resource(ore_circle, 'coal', constant(value)),
    b.resource(ore_circle, 'stone', constant(value))
}

local bigger_circle = b.circle(100) -- To exclude water from the start area.
ore_circle =
    b.any {
    ore_circle,
    bigger_circle
}

local start_segment = b.segment_pattern(start_ores)

local function ore(x, y, world)
    local start_ore = start_segment(x, y, world)
    if start_ore then
        return start_ore
    end

    local oil_x, oil_y = x * oil_scale, y * oil_scale

    local oil_noise = noise(oil_x, oil_y, oil_seed)
    if oil_noise > oil_threshold then
        return oil_resource(x, y, world)
    end

    local uranium_x, uranium_y = x * uranium_scale, y * uranium_scale
    local uranium_noise = noise(uranium_x, uranium_y, uranium_seed)
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
    local density_noise = noise(density_x, density_y, density_seed)

    if density_noise > density_threshold then
        entity.amount = entity.amount * density_multiplier
    end
    entity.enable_tree_removal = false
    return entity
end

local worms = {
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret'
}

local max_worm_chance = 1 / 384
local worm_chance_factor = 1 / (192 * 512)

local function enemy(_, _, world)
    local wx, wy = world.x, world.y
    local d = math.sqrt(wx * wx + wy * wy)

    local worm_chance = d - 128

    if worm_chance > 0 then
        worm_chance = worm_chance * worm_chance_factor
        worm_chance = math.min(worm_chance, max_worm_chance)

        if math.random() < worm_chance then
            if d < 384 then
                return {name = 'small-worm-turret'}
            else
                local max_lvl
                local min_lvl
                if d < 768 then
                    max_lvl = 2
                    min_lvl = 1
                else
                    max_lvl = 3
                    min_lvl = 2
                end
                local lvl = math.random() ^ (768 / d) * max_lvl
                lvl = math.ceil(lvl)
                lvl = math.clamp(lvl, min_lvl, 3)
                return {name = worms[lvl]}
            end
        end
    end
end

local water = b.circle(8)
water = b.change_tile(water, true, 'water')
water = b.any {b.rectangle(16, 4), b.rectangle(4, 16), water}

local start = b.if_else(water, b.full_shape)
start = b.change_map_gen_collision_tile(start, 'water-tile', 'grass-1')

local map = b.choose(ore_circle, start, b.full_shape)

map = b.apply_entity(map, ore)
map = b.apply_entity(map, enemy)

return map
