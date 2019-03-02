-- Rotten Apples - Islands of trees with apple ore patches, infested with worms.
-- Damage modifiers influenced by science progression to increase teamwork by worm difficulty
-- For added difficulty/balance the original playthrough used a modified version of market_items.lua
-- Map by Jayefuu and plague006
-- 2018-11-30

local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local table = require 'utils.table'
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local degrees = math.rad

-- change these to change the pattern.
local seed1 = 20000
local seed2 = seed1 * 2

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none,
        MGSP.enemy_none
    }
)

local military_techs = {
    ['artillery'] = true,
    ['artillery-shell-range-1'] = true,
    ['artillery-shell-speed-1'] = true,
    ['atomic-bomb'] = true,
    ['bullet-damage-1'] = true,
    ['bullet-damage-2'] = true,
    ['bullet-damage-3'] = true,
    ['bullet-damage-4'] = true,
    ['bullet-damage-5'] = true,
    ['bullet-damage-6'] = true,
    ['bullet-damage-7'] = true,
    ['bullet-speed-1'] = true,
    ['bullet-speed-2'] = true,
    ['bullet-speed-3'] = true,
    ['bullet-speed-4'] = true,
    ['bullet-speed-5'] = true,
    ['bullet-speed-6'] = true,
    ['cannon-shell-damage-1'] = true,
    ['cannon-shell-damage-2'] = true,
    ['cannon-shell-damage-3'] = true,
    ['cannon-shell-damage-4'] = true,
    ['cannon-shell-damage-5'] = true,
    ['cannon-shell-damage-6'] = true,
    ['cannon-shell-speed-1'] = true,
    ['cannon-shell-speed-2'] = true,
    ['cannon-shell-speed-3'] = true,
    ['cannon-shell-speed-4'] = true,
    ['cannon-shell-speed-5'] = true,
    ['combat-robot-damage-1'] = true,
    ['combat-robot-damage-2'] = true,
    ['combat-robot-damage-3'] = true,
    ['combat-robot-damage-4'] = true,
    ['combat-robot-damage-5'] = true,
    ['combat-robot-damage-6'] = true,
    ['combat-robotics'] = true,
    ['combat-robotics-2'] = true,
    ['combat-robotics-3'] = true,
    ['discharge-defense-equipment'] = true,
    ['energy-shield-equipment'] = true,
    ['energy-shield-mk2-equipment'] = true,
    ['exoskeleton-equipment'] = true,
    ['explosive-rocketry'] = true,
    ['flamethrower'] = true,
    ['flamethrower-damage-1'] = true,
    ['flamethrower-damage-2'] = true,
    ['flamethrower-damage-3'] = true,
    ['flamethrower-damage-4'] = true,
    ['flamethrower-damage-5'] = true,
    ['flamethrower-damage-6'] = true,
    ['flamethrower-damage-7'] = true,
    ['flammables'] = true,
    ['follower-robot-count-1'] = true,
    ['follower-robot-count-2'] = true,
    ['follower-robot-count-3'] = true,
    ['follower-robot-count-4'] = true,
    ['follower-robot-count-5'] = true,
    ['follower-robot-count-6'] = true,
    ['follower-robot-count-7'] = true,
    ['grenade-damage-1'] = true,
    ['grenade-damage-2'] = true,
    ['grenade-damage-3'] = true,
    ['grenade-damage-4'] = true,
    ['grenade-damage-5'] = true,
    ['grenade-damage-6'] = true,
    ['grenade-damage-7'] = true,
    ['gun-turret-damage-1'] = true,
    ['gun-turret-damage-2'] = true,
    ['gun-turret-damage-3'] = true,
    ['gun-turret-damage-4'] = true,
    ['gun-turret-damage-5'] = true,
    ['gun-turret-damage-6'] = true,
    ['gun-turret-damage-7'] = true,
    ['heavy-armor'] = true,
    ['land-mine'] = true,
    ['laser'] = true,
    ['laser-turret-damage-1'] = true,
    ['laser-turret-damage-2'] = true,
    ['laser-turret-damage-3'] = true,
    ['laser-turret-damage-4'] = true,
    ['laser-turret-damage-5'] = true,
    ['laser-turret-damage-6'] = true,
    ['laser-turret-damage-7'] = true,
    ['laser-turret-damage-8'] = true,
    ['laser-turret-speed-1'] = true,
    ['laser-turret-speed-2'] = true,
    ['laser-turret-speed-3'] = true,
    ['laser-turret-speed-4'] = true,
    ['laser-turret-speed-5'] = true,
    ['laser-turret-speed-6'] = true,
    ['laser-turret-speed-7'] = true,
    ['laser-turrets'] = true,
    ['military'] = true,
    ['military-2'] = true,
    ['military-3'] = true,
    ['military-4'] = true,
    ['modular-armor'] = true,
    ['night-vision-equipment'] = true,
    ['personal-laser-defense-equipment'] = true,
    ['power-armor'] = true,
    ['power-armor-2'] = true,
    ['rocket-damage-1'] = true,
    ['rocket-damage-2'] = true,
    ['rocket-damage-3'] = true,
    ['rocket-damage-4'] = true,
    ['rocket-damage-5'] = true,
    ['rocket-damage-6'] = true,
    ['rocket-damage-7'] = true,
    ['rocket-speed-1'] = true,
    ['rocket-speed-2'] = true,
    ['rocket-speed-3'] = true,
    ['rocket-speed-4'] = true,
    ['rocket-speed-5'] = true,
    ['rocket-speed-6'] = true,
    ['rocket-speed-7'] = true,
    ['rocketry'] = true,
    ['shotgun-shell-damage-1'] = true,
    ['shotgun-shell-damage-2'] = true,
    ['shotgun-shell-damage-3'] = true,
    ['shotgun-shell-damage-4'] = true,
    ['shotgun-shell-damage-5'] = true,
    ['shotgun-shell-damage-6'] = true,
    ['shotgun-shell-damage-7'] = true,
    ['shotgun-shell-speed-1'] = true,
    ['shotgun-shell-speed-2'] = true,
    ['shotgun-shell-speed-3'] = true,
    ['shotgun-shell-speed-4'] = true,
    ['shotgun-shell-speed-5'] = true,
    ['shotgun-shell-speed-6'] = true,
    ['stone-walls'] = true,
    ['tanks'] = true,
    ['turrets'] = true,
    ['uranium-ammo'] = true
}

local player_ammo_research_modifiers = {
    ['artillery-shell'] = 0.03,
    ['biological'] = 0.025,
    ['bullet'] = 0.045,
    ['cannon-shell'] = 0.12,
    ['capsule'] = 0,
    ['combat-robot-beam'] = 0.01,
    ['combat-robot-laser'] = 0.01,
    ['electric'] = 0.025,
    ['flamethrower'] = 0.01,
    ['grenade'] = 0.00,
    ['landmine'] = 0.06,
    ['melee'] = 0.025,
    ['rocket'] = 0.08,
    ['shotgun-shell'] = 0.00,
    ['laser-turret'] = 0.12
}

local function modify_damage(force, mult)
    for type, mod in pairs(player_ammo_research_modifiers) do
        local current_m = force.get_ammo_damage_modifier(type)
        if (current_m + (mod * mult)) <= -0.9 then
            force.set_ammo_damage_modifier(type, -0.9)
        else
            force.set_ammo_damage_modifier(type, current_m + (mod * mult))
        end
    end
end

local function research_finished(event)
    local research = event.research
    local force = research.force

    if military_techs[research.name] then
        --increase player damage
        modify_damage(force, 1)
        game.print('Military research complete.... you feel stronger')
    else
        -- decrease player damage
        modify_damage(force, -1.5)
        game.print('Research complete. A feeling of weakness spreads.')
    end

    if string.find(research.name, 'follower%-robot%-count') then
        force.maximum_following_robot_count = force.maximum_following_robot_count + 10
        game.print('Your Plague of robots disperses........')
    end
end

Event.add(defines.events.on_research_finished, research_finished)
-- makes ores richer further from the start
local function value(base, mult, pow)
    return function(x, y)
        local d_sq = x * x + y * y
        return base + mult * d_sq ^ (pow / 2) -- d ^ pow
    end
end

local apple = b.translate(b.circle(20), 0, -90)
local tree = b.picture(require 'map_gen.data.presets.tree')
tree = b.scale(tree, 0.6, 0.6)

local ores = {
    {resource_type = 'iron-ore', value = value(90, 0.25, 1.15)},
    {resource_type = 'copper-ore', value = value(80, 0.2, 1.15)},
    {resource_type = 'stone', value = value(100, 0.2, 1.2)},
    {resource_type = 'coal', value = value(65, 0.15, 1.1)},
    {resource_type = 'uranium-ore', value = value(20, 0.1, 1.075)},
    {resource_type = 'crude-oil', value = value(17500, 25, 1.15)}
}

local iron = b.resource(apple, ores[1].resource_type, ores[1].value)
local copper = b.resource(apple, ores[2].resource_type, ores[2].value)
local stone = b.resource(apple, ores[3].resource_type, ores[3].value)
local coal = b.resource(apple, ores[4].resource_type, ores[4].value)
local uranium = b.resource(apple, ores[5].resource_type, ores[5].value)
local oil = b.resource(b.throttle_world_xy(apple, 1, 8, 1, 8), ores[6].resource_type, ores[6].value)

local worm_names = {
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret'
}

local max_worm_chance = 1 / 128
local worm_chance_factor = 1 / (192 * 512)

local function worms(_, _, world)
    local wx, wy = world.x, world.y
    local d = math.sqrt(wx * wx + wy * wy)

    local worm_chance = d - 128

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
                else
                    max_lvl = 3
                    min_lvl = 2
                end
                local lvl = math.random() ^ (512 / d) * max_lvl
                lvl = math.ceil(lvl)
                lvl = math.clamp(lvl, min_lvl, 3)
                return {name = worm_names[lvl]}
            end
        end
    end
end

local iron_circle = b.apply_entities(apple, {iron, worms})
local copper_circle = b.apply_entities(apple, {copper, worms})
local coal_circle = b.apply_entities(apple, {coal, worms})
local stone_circle = b.apply_entities(apple, {stone, worms})
local oil_circle = b.apply_entities(apple, {oil, worms})
local uranium_circle = b.apply_entities(apple, {uranium, worms})

local start_ores =
    b.any {
    b.rotate(iron_circle, degrees(-25)),
    b.rotate(copper_circle, degrees(25)),
    b.rotate(stone_circle, degrees(-75)),
    b.rotate(coal_circle, degrees(75)),
    tree
}

local ore_group_1 =
    b.any {
    b.rotate(iron_circle, degrees(-25)),
    b.rotate(oil_circle, degrees(-75)),
    b.rotate(coal_circle, degrees(75)),
    tree
}

local ore_group_2 =
    b.any {
    b.rotate(iron_circle, degrees(-25)),
    b.rotate(copper_circle, degrees(25)),
    b.rotate(stone_circle, degrees(-75)),
    b.rotate(uranium_circle, degrees(75)),
    tree
}

local ore_group_3 =
    b.any {
    b.rotate(stone_circle, degrees(-75)),
    b.rotate(iron_circle, degrees(75)),
    tree
}

local ore_group_4 =
    b.any {
    b.rotate(iron_circle, degrees(-75)),
    b.rotate(copper_circle, degrees(25)),
    tree
}

local ore_group_5 =
    b.any {
    b.rotate(iron_circle, degrees(-25)),
    b.rotate(copper_circle, degrees(25)),
    b.rotate(stone_circle, degrees(-75)),
    b.rotate(coal_circle, degrees(75)),
    tree
}

local loops = {
    {ore_group_1, 12},
    {ore_group_2, 12},
    {ore_group_3, 9},
    {ore_group_4, 9},
    {ore_group_5, 4}
}

local Random = require 'map_gen.shared.random'
local random = Random.new(seed1, seed2)

local total_weights = {}
local t = 0
for _, v in ipairs(loops) do
    t = t + v[2]
    table.insert(total_weights, t)
end

local p_cols = 50
local p_rows = 50
local pattern = {}

for c = 1, p_cols do
    local row = {}
    table.insert(pattern, row)
    for r = 1, p_rows do
        if c == 1 and r == 1 then
            table.insert(row, start_ores)
        else
            local i = random:next_int(1, t)

            local index = table.binary_search(total_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end

            local shape = loops[index][1]

            local x = random:next_int(-128, 128)
            local y = random:next_int(-170, 200)

            shape = b.translate(shape, x, y)

            table.insert(row, shape)
        end
    end
end

local map = b.grid_pattern_full_overlap(pattern, p_cols, p_rows, 500, 500)

map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')

local sea = b.change_tile(apple, false, 'water')
sea = b.fish(sea, 0.005)

map = b.if_else(map, sea)
map = b.translate(map, 0, 50)
return map
