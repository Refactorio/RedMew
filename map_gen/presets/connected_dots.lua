map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local b = require "map_gen.shared.builders"

local function no_resources(x, y, world, tile)
    for _, e in ipairs(world.surface.find_entities_filtered({type = "resource", area = {{world.x, world.y}, {world.x + 1, world.y + 1}}})) do
        e.destroy()
    end
    
    return tile
end

local function less_resources(x, y, world, tile)
    for _, e in ipairs(world.surface.find_entities_filtered({type = "resource", area = {{world.x, world.y}, {world.x + 1, world.y + 1}}})) do
        if e.name == "crude-oil" then
            -- e.amount = .995 * e.amount
            else
            e.amount = 0.33 * e.amount
        end
    end
    
    return tile
end

local function no_enemies(x, y, world, tile)
    for _, e in ipairs(world.surface.find_entities_filtered({force = "enemy", position = {world.x, world.y}})) do
        e.destroy()
    end
    
    return tile
end

local small_dot = b.circle(96)
local mediumn_dot = b.circle(128)
local big_dot = b.circle(160)

local arms = b.path(48)
arms = b.change_tile(arms, true, "water")

local arms2 = b.rotate(arms, degrees(45))

local shape = b.any{b.translate(arms2, 480, 0), b.translate(arms2, -480, 0), mediumn_dot, arms}
shape = b.apply_effect(shape, no_resources)
--shape = b.apply_effect(shape, less_resources)
shape = b.apply_effect(shape, no_enemies)


local shape2 = b.all{big_dot, b.invert(small_dot)}
shape2 = b.choose(big_dot, shape2, b.any{arms, b.rotate(arms, degrees(45))})
--shape2 = b.apply_effect(shape2, less_resources)
local start = b.apply_effect(mediumn_dot, no_resources)

local iron = b.circle(16)
iron = b.translate(iron, 0, -96)
--iron = b.rotate(iron, degrees(0))
iron = b.resource(iron, "iron-ore", function(x, y) return 700 end)

local copper = b.circle(12)
copper = b.translate(copper, 0, -96)
copper = b.rotate(copper, degrees(72))
copper = b.resource(copper, "copper-ore", function(x, y) return 600 end)

local stone = b.circle(8)
stone = b.translate(stone, 0, -96)
stone = b.rotate(stone, degrees(144))
stone = b.resource(stone, "stone", function(x, y) return 1500 end)

local coal = b.circle(10)
coal = b.translate(coal, 0, -96)
coal = b.rotate(coal, degrees(216))
coal = b.resource(coal, "coal", function(x, y) return 850 end)

local oil = b.circle(5)
oil = b.throttle_xy(oil, 1, 3, 1, 3)
oil = b.translate(oil, 0, -96)
oil = b.rotate(oil, degrees(288))
oil = b.resource(oil, "crude-oil", function(x, y) return 60000 end)

start = b.apply_entity(mediumn_dot, b.any{iron, copper, stone, coal, oil})

start = b.apply_effect(start, no_resources)

local pattern =
    {
        {shape, shape2},
        {shape2, shape}
    }

local map = b.grid_pattern(pattern, 2, 2, 480, 480)
map = b.choose(mediumn_dot, start, map)

map = b.change_map_gen_collision_tile(map, "water-tile", "grass-1")

return map
