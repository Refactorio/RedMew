require "locale.gen_combined.grilledham_map_gen.map_gen"
require "locale.gen_combined.grilledham_map_gen.builders"

local inner_circle = invert(circle_builder(48))
local outer_circle = circle_builder(64)
local square = invert(rectangle_builder(1000,1000))
square = rotate(square, degrees(45))
square = translate(square, math.sqrt(2) * 500,0)

local circle = compound_and({ inner_circle, outer_circle, square })

local line1 = rectangle_builder(77,16)
line1 = rotate(line1, degrees(45))
line1 = translate(line1,66.5,12.6875)

local line2 = rectangle_builder(45, 16)
local line2 = rotate(line2, degrees(-45))
line2 = translate(line2, 55.5,-23.6875)

--line2 =change_tile(line2, true, "water")

local half = compound_or({ line2,line1,circle})

half = translate(half, -79.1875, 0)
local map = compound_or({ half, flip_xy(half) })

map = scale(map, 11, 11)


local function research_finished(event)
    local tech = event.research.name
    if tech == "rocket-silo" then
        game.forces["player"].recipes["rocket-silo"].enabled = false
    end
end

Event.register(defines.events.on_research_finished, research_finished)

local function max_axis_distance(world_x, world_y, target_x, target_y)
    local x = math.abs(world_x - target_x)
    local y = math.abs(world_y - target_y)

    return math.max(x, y)
end

local function distance(world_x, world_y, target_x, target_y)
    return math.abs(world_x - target_x) + math.abs(world_y - target_y)
end

local init = false
local safe_distance = 480
local function effect(x, y, world_x, world_y, tile, entity)
    local surface = MAP_GEN_SURFACE

    if not init then
        init = true
        game.forces["player"].chart(surface, { {-32, -32}, {31, 31} })
    end

    if world_x == 0 and world_y == 0 then      
        for _, e in ipairs(surface.find_entities({ {-5, -5}, {5, 5} })) do
            e.destroy()
        end        
        
        local e = surface.create_entity({ name = "rocket-silo", position = {0, 0}, force = "player" })
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

    return tile, entity    
end

map = apply_effect(map, effect)

require "spawn_control"
add_spawn("left", -88, -88)
add_spawn("right", 88, 88)

return map
