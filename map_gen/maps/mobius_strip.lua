local Event = require 'utils.event'
local degrees = require "utils.math".degrees
local b = require 'map_gen.shared.builders'

local inner_circle = b.invert(b.circle(48))
local outer_circle = b.circle(64)
local square = b.invert(b.rectangle(1000, 1000))
square = b.rotate(square, degrees(45))
square = b.translate(square, math.sqrt(2) * 500, 0)

local circle = b.all({inner_circle, outer_circle, square})

local line1 = b.rectangle(77, 16)
line1 = b.rotate(line1, degrees(45))
line1 = b.translate(line1, 66.5, 12.6875)

local line2 = b.rectangle(45, 16)
line2 = b.rotate(line2, degrees(-45))
line2 = b.translate(line2, 55.5, -23.6875)

--line2 =b.change_tile(line2, true, "water")
local half = b.any({line2, line1, circle})

half = b.translate(half, -79.1875, 0)
local map = b.any({half, b.flip_xy(half)})

map = b.scale(map, 11, 11)

local function research_finished(event)
    local tech = event.research.name
    if tech == 'rocket-silo' then
        game.forces['player'].recipes['rocket-silo'].enabled = false
    end
end

Event.add(defines.events.on_research_finished, research_finished)

local init = false
local function effect(_, _, world, tile)
    if not init then
        init = true
        game.forces['player'].chart(world.surface, {{-32, -32}, {31, 31}})
    end

    if world.x == 0 and world.y == 0 then
        for _, e in ipairs(world.surface.find_entities({{-5, -5}, {5, 5}})) do
            e.destroy()
        end

        local e = world.surface.create_entity({name = 'rocket-silo', position = {0, 0}, force = 'player'})
        e.destructible = false
        e.minable = false
    end

    --[[

    if max_axis_distance(world_x, world_y, -2144, 0) < safe_distance then
    for _, e in ipairs(surface.find_entities_filtered({ force = "enemy", position = { world_x, world_y } } )) do
    e.destroy()
    end
    elseif max_axis_distance(world_x, world_y, 2144, 0) < safe_distance then
    for _, e in ipairs(surface.find_entities_filtered({ force = "enemy", position = { world_x, world_y } } )) do
    e.destroy()
    end
    end

    for _, e in ipairs(surface.find_entities_filtered({ type = "resource", area = {{world_x, world_y  }, {world_x + 1, world_y + 1 } } })) do -- I want to use position but for some reason it doesn't seem to work for ores.
    local dist1 = distance(world_x, world_y, -2144, 0)
    local dist2 = distance(world_x, world_y, 2144, 0)
    local amount = math.min(dist1, dist2)

    local name = e.name
    if name == "iron-ore" then
    amount = 800 + 0.4 * amount
    elseif name == "copper-ore" then
    amount = 700 + 0.35 * amount
    elseif name == "coal" then
    amount = 600 + 0.3 * amount
    elseif name == "stone" then
    amount = 400 + 0.2 * amount
    elseif name == "uranium-ore" then
    amount = 300 + 0.15 * amount
    elseif name == "crude-oil" then
    amount = 50000 + 50 * amount
    end

    e.amount = amount
    end

    --]]
    return tile
end

map = b.apply_effect(map, effect)

local Spawn_Control = require 'map_gen.shared.spawn_control'

Spawn_Control.add_spawn('left', -88, -88)
Spawn_Control.add_spawn('right', 88, 88)

return map
