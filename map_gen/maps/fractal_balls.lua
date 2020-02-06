local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local degrees = require "utils.math".degrees
local ScenarioInfo = require 'features.gui.info'
local Event = require 'utils.event'

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,    -- Comment this if you want to enable vanilla ore generation in some of the rings.
        MGSP.cliff_none,
        MGSP.water_none
    }
)

ScenarioInfo.set_map_name('Fractal Balls')
ScenarioInfo.set_map_description(
    [[
Circular groups of ore islands linked by paths arranged in a fractal,
expanding pattern.
]]
)
ScenarioInfo.add_map_extra_info(
    [[
A space limited start leads players to explore larger and larger rings of
biter infested map.

Each ore patch upon its own island must be belted out to a production area
or loaded on to trains.

This map encourages use of trains similar to RSO due to the spread out nature of
the ores, with islands only accessible by bots encouraging the player to revisit
exhausted ore areas later in the game to extract more resources.
]]
)

ScenarioInfo.set_new_info(
    [[
2019-09-11 - Jayefuu
- Updated map descriptions
- Disabled landfill to prevent cheating
- Added config example to disable vanilla ores. Balances map better if the rings aren't full of ore.
]]
)

local function value(base, mult)
    return function(x, y)
        return mult * (math.abs(x) + math.abs(y)) + base
    end
end

-- bot_islands_flag true if you want to add islands of ores only reachable by robots
local bot_islands_flag = true

local arm1 = b.translate(b.rectangle(2, 3), 0, -5)
local arm2 = b.translate(b.rectangle(6, 2), 0, 22)

local inner = b.circle(22)
local outer = b.circle(24)
local ring = b.all {outer, b.invert(inner)}

local arms = b.any {arm1, arm2}
arms = b.translate(arms, 0, -16)
arms =
    b.any {
    arms,
    b.rotate(arms, degrees(120)),
    b.rotate(arms, degrees(-120))
}
local frame = b.any {arms, ring}

local ball = b.circle(8)

local iron = b.resource(b.circle(6), 'iron-ore', value(1000, 1))
local copper = b.resource(b.circle(6), 'copper-ore', value(800, 0.8))
local stone = b.resource(b.circle(4), 'stone', value(500, .5))
local coal = b.resource(b.circle(6), 'coal', value(600, 0.6))
local uranium = b.resource(b.circle(4), 'uranium-ore', value(400, 1))
local oil = b.resource(b.throttle_world_xy(b.circle(6), 1, 4, 1, 4), 'crude-oil', value(100000, 50))

--[[ local iron_ball = b.change_map_gen_collision_tile(b.apply_entity(ball, iron), 'water-tile', 'grass-1')
local copper_ball = b.change_map_gen_collision_tile(b.apply_entity(ball, copper), 'water-tile', 'grass-1')
local stone_ball = b.change_map_gen_collision_tile(b.apply_entity(ball, stone), 'water-tile', 'grass-1')
local coal_ball = b.change_map_gen_collision_tile(b.apply_entity(ball, coal), 'water-tile', 'grass-1')
local uranium_ball = b.change_map_gen_collision_tile(b.apply_entity(ball, uranium), 'water-tile', 'grass-1')
local oil_ball = b.change_map_gen_collision_tile(b.apply_entity(ball, oil), 'water-tile', 'grass-1') ]]
local iron_ball = b.apply_entity(ball, iron)
local copper_ball = b.apply_entity(ball, copper)
local stone_ball = b.apply_entity(ball, stone)
local coal_ball = b.apply_entity(ball, coal)
local uranium_ball = b.apply_entity(ball, uranium)
local oil_ball = b.apply_entity(ball, oil)

local balls1 =
    b.any {
    b.translate(iron_ball, 0, -12),
    b.rotate(b.translate(copper_ball, 0, -12), degrees(120)),
    b.rotate(b.translate(coal_ball, 0, -12), degrees(-120)),
    frame
}
--shape = b.rotate(shape, degrees(rot))
balls1 = b.rotate(balls1, degrees(180))
balls1 = b.choose(outer, balls1, b.empty_shape)
balls1 = b.translate(balls1, 0, -36)

local balls2 =
    b.any {
    b.translate(iron_ball, 0, -12),
    b.rotate(b.translate(copper_ball, 0, -12), degrees(120)),
    b.rotate(b.translate(stone_ball, 0, -12), degrees(-120)),
    frame
}
balls2 = b.rotate(balls2, degrees(180))
balls2 = b.choose(outer, balls2, b.empty_shape)
balls2 = b.translate(balls2, 0, -36)
balls2 = b.rotate(balls2, degrees(120))

local balls3 =
    b.any {
    b.translate(iron_ball, 0, -12),
    b.rotate(b.translate(uranium_ball, 0, -12), degrees(120)),
    b.rotate(b.translate(oil_ball, 0, -12), degrees(-120)),
    frame
}
balls3 = b.rotate(balls3, degrees(180))
balls3 = b.choose(outer, balls3, b.empty_shape)
balls3 = b.translate(balls3, 0, -36)
balls3 = b.rotate(balls3, degrees(-120))

local balls4 =
    b.any {
    balls1,
    balls2,
    balls3,
    b.scale(frame, 3, 3)
}
balls4 = b.rotate(balls4, degrees(180))

if bot_islands_flag == true then
    balls4 =
        b.any {
        balls4,
        b.translate(iron_ball, 0, 0),
        b.rotate(b.translate(coal_ball, 0, -40), degrees(120)),
        b.rotate(b.translate(iron_ball, 0, -40), degrees(-120)),
        b.translate(copper_ball, 0, -40)
    }
end

balls4 = b.remove_map_gen_resources(balls4)
balls4 = b.choose(b.scale(outer, 3, 3), balls4, b.empty_shape)

local function make_ball(shape, sf)
    local s1 = b.translate(shape, 0, -12 * sf)
    shape =
        b.any {
        s1,
        b.rotate(s1, degrees(120)),
        b.rotate(s1, degrees(-120)),
        b.scale(frame, sf, sf)
    }
    shape = b.rotate(shape, degrees(180))

    local bound = b.scale(outer, sf, sf)

    return b.choose(bound, shape, b.empty_shape)
end

local ratio = 24 / 8
local map = balls4
local total_sf = 1 * ratio * ratio
for i = 1, 6 do
    map = make_ball(map, total_sf)
    total_sf = ratio * total_sf
end

map = b.translate(map, 0, -19669)
map = b.scale(map, 2, 2)

map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')
map = b.change_tile(map, false, 'water')
map = b.fish(map, 0.0025)

-- Disable landfill technology
local function on_init()
    local player_force = game.forces.player
    player_force.technologies['landfill'].enabled = false           -- disable landfill
end
Event.on_init(on_init)

return map
