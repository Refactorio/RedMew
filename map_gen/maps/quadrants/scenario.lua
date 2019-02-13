local b = require('map_gen.shared.builders')
local Event = require 'utils.event'

local abs = math.abs

require 'switch_team'


local function on_init()
    game.forces.player.set_spawn_position({64, -64}, game.surfaces[1])
end

Event.on_init(on_init)

local function quadrants(x, y)
    local abs_x = abs(x) - 0.5
    local abs_y = abs(y) - 0.5

    if (abs_x <= 200 and abs_y <= 200) then
        if game.surfaces[2].get_tile(x, y).collides_with('water-tile') then
            game.surfaces[2].set_tiles({{name="grass-1", position={x, y}}}, true)
        end
        local entities = game.surfaces[2].find_entities({{x-0.5, y-0.5}, {x+0.5, y+0.5}})

        for _, entity in ipairs(entities) do
            if entity.name ~= 'player' then
                entity.destroy()
            end
        end
    end

    if (abs_x >= 112 and abs_x <= 144 and abs_y >= 112 and abs_y <= 144 ) then
        game.surfaces[2].set_tiles({{name="water", position={x, y}}}, true)
    end

    if (abs_x <= 23  or abs_y <= 23) then
        if ((abs_y % 4 == 0) or (abs_x % 4 == 0)) then -- Between quadrants create land
            game.surfaces[2].set_tiles({{name="tutorial-grid", position={x, y}}}, true)
            local entities = game.surfaces[2].find_entities({{x-0.5, y-0.5}, {x+0.5, y+0.5}})

            for _, entity in ipairs(entities) do
                if entity.name ~= 'player' then
                    entity.destroy()
                end
            end
            if (abs_x <= 2 and abs_y <= 2) then --Spawn
                return true
            elseif (abs_x <= 23 and abs_y <= 23) and not (abs_x <= 2 and abs_y <= 2) then -- Around spawn, in between the quadrants
                return false
            elseif ((abs_x <= 1 or abs_x == 8 or abs_x == 9 or abs_x == 16 or abs_x == 17) and abs_y % 4 == 0) or ((abs_y <= 1 or abs_y == 8 or abs_y == 9 or abs_y == 16 or abs_y == 17) and abs_x % 4 == 0) then -- connections
                return true
            end
        end
        return false
    end
    return true
end

local rectangle = b.rectangle(32,32)
local tree_rectangle = b.rectangle(64, 16)
local tree_rectangle_1 = b.throttle_xy(tree_rectangle,1, 3, 1, 3)
local tree_rectangle_2 = b.rotate(tree_rectangle_1, math.pi/2)

local function constant(x)
    return function()
        return x
    end
end

local base_x = 48
local base_y = 48

local start_iron = b.resource(rectangle, 'iron-ore', constant(750))
local start_copper = b.resource(rectangle, 'copper-ore', constant(600))
local start_stone = b.resource(rectangle, 'stone', constant(600))
local start_coal = b.resource(rectangle, 'coal', constant(600))
local start_tree_1 = b.entity(tree_rectangle_1, 'tree-01')
local start_tree_2 = b.entity(tree_rectangle_2, 'tree-01')

start_iron = b.combine({b.translate(start_iron, base_x,base_y), b.translate(start_iron, -base_x,-base_y), b.translate(start_iron, base_x,-base_y), b.translate(start_iron, -base_x,base_y)})

base_x = base_x + 32
start_copper = b.combine({b.translate(start_copper, base_x,base_y), b.translate(start_copper, -base_x,-base_y), b.translate(start_copper, base_x,-base_y), b.translate(start_copper, -base_x,base_y)})

base_y = base_x
start_stone = b.combine({b.translate(start_stone, base_x,base_y), b.translate(start_stone, -base_x,-base_y), b.translate(start_stone, base_x,-base_y), b.translate(start_stone, -base_x,base_y)})

base_x = base_x - 32
start_coal = b.combine({b.translate(start_coal, base_x,base_y), b.translate(start_coal, -base_x,-base_y), b.translate(start_coal, base_x,-base_y), b.translate(start_coal, -base_x,base_y)})


base_x = 64
base_y = 128
start_tree_1 = b.combine({b.translate(start_tree_1, base_x,base_y), b.translate(start_tree_1, -base_x,-base_y), b.translate(start_tree_1, base_x,-base_y), b.translate(start_tree_1, -base_x,base_y)})

base_x = 128
base_y = 64
start_tree_2 = b.combine({b.translate(start_tree_2, base_x,base_y), b.translate(start_tree_2, -base_x,-base_y), b.translate(start_tree_2, base_x,-base_y), b.translate(start_tree_2, -base_x,base_y)})


local map = b.apply_entities(quadrants, {start_iron, start_copper, start_stone, start_coal, start_tree_1, start_tree_2})
return map