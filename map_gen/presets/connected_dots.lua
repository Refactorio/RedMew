map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local function no_resources(x, y, world_x, world_y, tile, entity)
    local surface = MAP_GEN_SURFACE
    for _, e in ipairs(surface.find_entities_filtered({ type = "resource", area = {{world_x, world_y  }, {world_x + 1, world_y + 1 } } })) do
        e.destroy()
    end

    return tile, entity
end

local function less_resources(x, y, world_x, world_y, tile, entity)
    local surface = MAP_GEN_SURFACE
    for _, e in ipairs(surface.find_entities_filtered({ type = "resource", area = {{world_x, world_y  }, {world_x + 1, world_y + 1 } } })) do
        if e.name == "crude-oil" then
           -- e.amount = .995 * e.amount
        else
            e.amount = 0.33 * e.amount
        end
    end

    return tile, entity
end

local function no_enemies(x, y, world_x, world_y, tile, entity)
    local surface = MAP_GEN_SURFACE
    for _, e in ipairs(surface.find_entities_filtered({ force = "enemy", position = { world_x, world_y } } )) do
        e.destroy()
    end

    return tile, entity
end

local small_dot = circle_builder(96)
local mediumn_dot = circle_builder(128)
local big_dot = circle_builder(160)

local arms = path_builder(48)
arms = change_tile(arms, true, "water")

local arms2 = rotate(arms, degrees(45))

local shape = compound_or{ translate(arms2,480,0), translate(arms2, -480, 0), mediumn_dot, arms }
shape = apply_effect(shape, no_resources)
--shape = apply_effect(shape, less_resources)
shape = apply_effect(shape, no_enemies)


local shape2 = compound_and{ big_dot, invert(small_dot) }
shape2 = choose(big_dot, shape2, compound_or{arms, rotate(arms, degrees(45))})
--shape2 = apply_effect(shape2, less_resources)

local start = apply_effect(mediumn_dot, no_resources)

local iron = circle_builder(16)
iron = translate(iron, 0,-96)
--iron = rotate(iron, degrees(0))
iron = resource_module_builder(iron, "iron-ore", function(x,y) return 700 end)

local copper = circle_builder(12)
copper = translate(copper, 0,-96)
copper = rotate(copper, degrees(72))
copper = resource_module_builder(copper, "copper-ore", function(x,y) return 600 end)

local stone = circle_builder(8)
stone = translate(stone, 0,-96)
stone = rotate(stone, degrees(144))
stone = resource_module_builder(stone, "stone", function(x,y) return 1500 end)

local coal = circle_builder(10)
coal = translate(coal, 0,-96)
coal = rotate(coal, degrees(216))
coal = resource_module_builder(coal, "coal", function(x,y) return 850 end)

local oil = circle_builder(5)
oil = throttle_xy(oil, 1, 3, 1, 3)
oil = translate(oil, 0,-96)
oil = rotate(oil, degrees(288))
oil = resource_module_builder(oil, "crude-oil", function(x,y) return 60000 end)

start = builder_with_resource(mediumn_dot, compound_or{iron, copper, stone, coal, oil})

start = apply_effect(start, no_resources)

local pattern =
{
    {shape, shape2},
    {shape2, shape}
}

local map = grid_pattern_builder(pattern, 2, 2, 480,480)
map = choose(mediumn_dot, start, map)

map = change_map_gen_collision_tile(map,"water-tile", "grass-1")

return map
