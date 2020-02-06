local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local Perlin = require 'map_gen.shared.perlin_noise'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Event = require 'utils.event'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local degrees = require "utils.math".degrees

-- change these to change the pattern.
local ore_seed1 = 30000
local ore_seed2 = 2 * ore_seed1
local enemy_seed = 420420
local loot_seed = 1000

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)
global.config.market.create_standard_market = false

local generator

local ammos = {
    'artillery-shell',
    'biological',
    'bullet',
    'cannon-shell',
    'capsule',
    'combat-robot-beam',
    'combat-robot-laser',
    'electric',
    'flamethrower',
    'grenade',
    'landmine',
    'laser-turret',
    'melee',
    'railgun',
    'rocket',
    'shotgun-shell'
}

local function init_weapon_damage()
    local p_force = game.forces.player

    for _, a in ipairs(ammos) do
        p_force.set_ammo_damage_modifier(a, -0.5)
    end
end

Event.add(
    defines.events.on_research_finished,
    function(event)
        local p_force = game.forces.player
        local r = event.research

        for _, e in ipairs(r.effects) do
            local t = e.type

            if t == 'ammo-damage' then
                local m = e.modifier
                local category = e.ammo_category
                local current_m = p_force.get_ammo_damage_modifier(category)
                p_force.set_ammo_damage_modifier(category, current_m - 0.5 * m)
            elseif t == 'turret-attack' then
                local m = e.modifier
                local category = e.turret_id
                local current_m = p_force.get_turret_attack_modifier(category)
                p_force.set_turret_attack_modifier(category, current_m - 0.5 * m)
            end
        end
    end
)

Global.register_init(
    {},
    function(tbl)
        tbl.generator = game.create_random_generator()
        init_weapon_damage()
    end,
    function(tbl)
        generator = tbl.generator
    end
)

local function square(x, y)
    return x > 0 and y > 0
end

square = b.rotate(square, degrees(-45))
square = b.scale(square, 5 / 12, 1)

local map = b.translate(square, 0, -10)

local sea = b.translate(map, 0, -6)
sea = b.change_tile(sea, true, 'water')
sea = b.fish(sea, 0.075)

map = b.any {map, sea}

local icons = {
    b.picture(require 'map_gen.data.presets.ammo-icon'),
    b.picture(require 'map_gen.data.presets.danger-icon'),
    b.picture(require 'map_gen.data.presets.destroyed-icon'),
    b.picture(require 'map_gen.data.presets.electricity-icon'),
    b.picture(require 'map_gen.data.presets.electricity-icon-unplugged'),
    b.picture(require 'map_gen.data.presets.fluid-icon'),
    b.picture(require 'map_gen.data.presets.fuel-icon'),
    b.picture(require 'map_gen.data.presets.no-building-material-icon'),
    b.picture(require 'map_gen.data.presets.no-storage-space-icon'),
    b.picture(require 'map_gen.data.presets.not-enough-construction-robots-icon'),
    b.picture(require 'map_gen.data.presets.not-enough-repair-packs-icon'),
    b.picture(require 'map_gen.data.presets.recharge-icon'),
    b.picture(require 'map_gen.data.presets.too-far-from-roboport-icon')
}
local icons_count = #icons

local value = b.manhattan_value

local function non_transform(shape)
    return shape
end

local function uranium_transform(shape)
    return b.scale(shape, 0.5)
end

local function oil_transform(shape)
    shape = b.scale(shape, 0.5)
    return b.throttle_world_xy(shape, 1, 4, 1, 4)
end

local function empty_transform()
    return b.empty_shape
end

local ores = {
    {transform = non_transform, resource = 'iron-ore', value = value(500, 0.1), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(400, 0.1), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(250, 0.1), weight = 3},
    {transform = non_transform, resource = 'coal', value = value(400, 0.1), weight = 5},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(200, 0.1), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(100000, 50), weight = 6},
    {transform = empty_transform, weight = 100}
}

local random = Random.new(ore_seed1, ore_seed2)

local total_weights = {}
local t = 0
for _, v in ipairs(ores) do
    t = t + v.weight
    table.insert(total_weights, t)
end

local p_cols = 50
local p_rows = 50
local pattern = {}

for _ = 1, p_rows do
    local row = {}
    table.insert(pattern, row)
    for _ = 1, p_cols do
        local shape = icons[random:next_int(1, icons_count)]

        local i = random:next_int(1, t)
        local index = table.binary_search(total_weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        local ore_data = ores[index]
        shape = ore_data.transform(shape)
        local ore = b.resource(shape, ore_data.resource, ore_data.value)

        table.insert(row, ore)
    end
end

local ore_shape = b.project_pattern(pattern, 96, 1.0625, 50, 50)
ore_shape = b.scale(ore_shape, 0.15)

local start_ore = icons[2]
local start_iron = b.resource(start_ore, 'iron-ore', value(600, 0))
local start_copper = b.resource(start_ore, 'copper-ore', value(600, 0))
local start_coal = b.resource(start_ore, 'coal', value(1300, 0))
local start_stone = b.resource(start_ore, 'stone', value(900, 0))

start_ore = b.segment_pattern({start_coal, start_stone, start_copper, start_iron})
start_ore = b.translate(start_ore, 0, 64)

ore_shape = b.choose(b.rectangle(188, 188), start_ore, ore_shape)

local item_pool = {
    {name = 'firearm-magazine', count = 200, weight = 1250},
    {name = 'land-mine', count = 100, weight = 250},
    {name = 'shotgun-shell', count = 200, weight = 1250},
    {name = 'piercing-rounds-magazine', count = 200, weight = 833.3333},
    {name = 'automation-science-pack', count = 200, weight = 100},
    {name = 'logistic-science-pack', count = 200, weight = 100},
    {name = 'grenade', count = 100, weight = 500},
    {name = 'defender-capsule', count = 50, weight = 500},
    {name = 'railgun-dart', count = 100, weight = 500},
    {name = 'piercing-shotgun-shell', count = 200, weight = 312.5},
    {name = 'submachine-gun', count = 1, weight = 166.6667},
    {name = 'shotgun', count = 1, weight = 166.6667},
    {name = 'uranium-rounds-magazine', count = 200, weight = 166.6667},
    {name = 'cannon-shell', count = 100, weight = 166.6667},
    {name = 'rocket', count = 100, weight = 166.6667},
    {name = 'distractor-capsule', count = 25, weight = 166.6667},
    {name = 'railgun', count = 1, weight = 100},
    {name = 'flamethrower-ammo', count = 50, weight = 100},
    {name = 'military-science-pack', count = 200, weight = 100},
    {name = 'chemical-science-pack', count = 200, weight = 100},
    {name = 'explosive-rocket', count = 100, weight = 100},
    {name = 'explosive-cannon-shell', count = 100, weight = 100},
    {name = 'cluster-grenade', count = 100, weight = 100},
    {name = 'poison-capsule', count = 100, weight = 100},
    {name = 'slowdown-capsule', count = 100, weight = 100},
    {name = 'construction-robot', count = 50, weight = 100},
    {name = 'solar-panel-equipment', count = 5, weight = 833.3333},
    {name = 'artillery-targeting-remote', count = 1, weight = 50},
    {name = 'tank-flamethrower', count = 1, weight = 33.3333},
    {name = 'explosive-uranium-cannon-shell', count = 100, weight = 33.3333},
    {name = 'destroyer-capsule', count = 10, weight = 33.3333},
    {name = 'artillery-shell', count = 10, weight = 25},
    {name = 'battery-equipment', count = 5, weight = 25},
    {name = 'night-vision-equipment', count = 2, weight = 25},
    {name = 'exoskeleton-equipment', count = 2, weight = 166.6667},
    {name = 'rocket-launcher', count = 1, weight = 14.2857},
    {name = 'combat-shotgun', count = 1, weight = 10},
    {name = 'flamethrower', count = 1, weight = 10},
    {name = 'tank-cannon', count = 1, weight = 10},
    {name = 'modular-armor', count = 1, weight = 100},
    {name = 'belt-immunity-equipment', count = 1, weight = 10},
    {name = 'personal-roboport-equipment', count = 1, weight = 100},
    {name = 'energy-shield-equipment', count = 2, weight = 100},
    {name = 'personal-laser-defense-equipment', count = 2, weight = 100},
    {name = 'battery-mk2-equipment', count = 1, weight = 40},
    {name = 'tank-machine-gun', count = 1, weight = 3.3333},
    {name = 'power-armor', count = 1, weight = 33.3333},
    {name = 'fusion-reactor-equipment', count = 1, weight = 33.3333},
    {name = 'production-science-pack', count = 200, weight = 100},
    {name = 'utility-science-pack', count = 200, weight = 100},
    {name = 'artillery-turret', count = 1, weight = 2.5},
    {name = 'artillery-wagon-cannon', count = 1, weight = 1},
    {name = 'atomic-bomb', count = 1, weight = 1},
    {name = 'space-science-pack', count = 200, weight = 10}
}

total_weights = {}
t = 0
for _, v in ipairs(item_pool) do
    t = t + v.weight
    table.insert(total_weights, t)
end

local callback =
    Token.register(
    function(entity, data)
        local power = data.power
        generator.re_seed(data.seed)
        local count = generator(3, 8)
        for _ = 1, count do
            local i = generator() ^ power * t

            local index = table.binary_search(total_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end

            local loot = item_pool[index]

            entity.insert(loot)
        end
    end
)

local loot_power = 500
local function loot(x, y)
    local seed = bit32.band(x * 374761393 + y * 668265263 + loot_seed, 4294967295)
    generator.re_seed(seed)
    if generator(8192) ~= 1 then
        return nil
    end

    local d = math.sqrt(x * x + y * y)
    local name
    if d < 600 then
        name = 'car'
    else
        if generator(5) == 1 then
            name = 'tank'
        else
            name = 'car'
        end
    end

    -- neutral stops the biters attacking them.
    local entity = {
        name = name,
        force = 'neutral',
        callback = callback,
        data = {power = loot_power / d, seed = generator(4294967295)}
    }

    return entity
end

local worm_names = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret'}
local spawner_names = {'biter-spawner', 'spitter-spawner'}
local factor = 8 / (1024 * 32)
local max_chance = 1 / 8

local scale_factor = 32
local sf = 1 / scale_factor
local m = 1 / 1000
local function enemy(x, y, world)
    local d = math.sqrt(world.x * world.x + world.y * world.y)

    if d < 300 then
        return nil
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
    end
end

map = b.apply_entity(map, ore_shape)
map = b.apply_entity(map, loot)
map = b.apply_entity(map, enemy)

map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')

return map
