require 'map_gen.maps.quadrants.switch_team'
require 'map_gen.maps.quadrants.restrict_placement'

local b = require('map_gen.shared.builders')
local Retailer = require('features.retailer')
local market_items = require 'resources.market_items'
local RS = require 'map_gen.shared.redmew_surface'
local Event = require 'utils.event'
local ScenarioInfo = require 'features.gui.info'
local Recipes = require 'map_gen.maps.quadrants.enabled_recipes'
local Global = require 'utils.global'

local abs = math.abs
local round = math.round
local redmew_config = global.config

ScenarioInfo.set_map_name('[WIP] Quadrants')
ScenarioInfo.set_map_description('Teamwork based map')
ScenarioInfo.add_map_extra_info([[
- Restricted research
- Restricted recipes
- Restricted teleport between quadrants
]]
)

redmew_config.paint.enabled = false

redmew_config.player_create.starting_items = {
    { name = 'iron-plate', count = 7 },
    { name = 'iron-gear-wheel', count = 3 }
}

redmew_config.player_create.join_messages = {
    'Welcome to this map created by the RedMew team. You can join our discord at: redmew.com/discord',
    'Click the question mark in the top left corner for server information and map details.',
    '----',
    'Quadrants is a different take on a teamwork based map. Be sure to read the map details!',
    '--------'
}

local function spawn_market(surface, force, position)

    position.y = round(position.y - 4)
    position.x = round(position.x)

    local pos = surface.find_non_colliding_position('market', position, 10, 1)

    local market = surface.create_entity({ name = 'market', position = pos })
    market.destructible = false

    Retailer.add_market(pos.x .. 'fish_market' .. pos.y, market)

    if table.size(Retailer.get_items(pos.x .. 'fish_market' .. pos.y)) == 0 then
        for _, prototype in pairs(market_items) do
            Retailer.set_item(pos.x .. 'fish_market' .. pos.y, prototype)
        end
    end

    force.add_chart_tag(surface, { icon = { type = 'item', name = 'coin' }, position = pos, text = 'Market' })
end

local function reset_recipes()
    log('Reset_recipes!')
    for _, force in pairs(game.forces) do
        log(force.name .. " < Force |")
        if (string.find(force.name, 'quadrant')) ~= nil then
            for _, recipe in pairs(force.recipes) do
                log(force.name .. " < Force | Recipe > " .. recipe.name)
                if not (Recipes[force.name].recipe[recipe.name] or Recipes.default.recipe[recipe.name]) then
                    recipe.enabled = false
                end
            end
        end
    end
end

local function on_init()
    local surface = RS.get_surface()

    local q1 = game.create_force('quadrant1')
    q1.set_spawn_position({ 64, -64 }, surface)
    local q2 = game.create_force('quadrant2')
    q2.set_spawn_position({ -64, -64 }, surface)
    local q3 = game.create_force('quadrant3')
    q3.set_spawn_position({ -64, 64 }, surface)
    local q4 = game.create_force('quadrant4')
    q4.set_spawn_position({ 64, 64 }, surface)

    reset_recipes()
    for _, force in pairs(game.forces) do
        if (string.find(force.name, 'quadrant')) ~= nil then
            force.share_chart = true

            if force.name ~= 'quadrant1' then
                force.disable_research()
            end
            for _, friend_force in pairs(forces) do
                if friend_force ~= force then
                    force.set_friend(friend_force, true)
                end
            end
        end
    end
end

local function on_research_finished(event)
    log(event.research.name .. ' researched!')
    if event.research.force ~= game.forces['quadrant1'] then
        log('NOT QUADRANT1!')
        return
    end
    for _, force in pairs(game.forces) do
        if (string.find(force.name, 'quadrant')) ~= nil then
            if force.name ~= 'quadrant1' then
                force.technologies[event.research.name].researched = true
            end
        end
    end
    reset_recipes()
end

Event.on_init(on_init)
Event.add(defines.events.on_research_finished, on_research_finished)

local function quadrants(x, y)
    local abs_x = abs(x) - 0.5
    local abs_y = abs(y) - 0.5

    if (abs_x <= 200 and abs_y <= 200) then
        if game.surfaces[2].get_tile(x, y).collides_with('water-tile') then
            game.surfaces[2].set_tiles({ { name = "grass-1", position = { x, y } } }, true)
        end
        local entities = game.surfaces[2].find_entities({ { x - 0.5, y - 0.5 }, { x + 0.5, y + 0.5 } })

        for _, entity in ipairs(entities) do
            if entity.name ~= 'player' then
                entity.destroy()
            end
        end
    end

    if (abs_x == 100) and (abs_y == 100) then
        spawn_market(RS.get_surface(), game.forces.player, { x = x, y = y })
    end

    if (abs_x >= 112 and abs_x <= 144 and abs_y >= 112 and abs_y <= 144) then
        game.surfaces[2].set_tiles({ { name = "water", position = { x, y } } }, true)
    end

    if (abs_x <= 23 or abs_y <= 23) then
        -- Between quadrants create land
        game.surfaces[2].set_tiles({ { name = "tutorial-grid", position = { x, y } } }, true)
        local entities = game.surfaces[2].find_entities({ { x - 0.5, y - 0.5 }, { x + 0.5, y + 0.5 } })

        for _, entity in ipairs(entities) do
            if entity.name ~= 'player' then
                entity.destroy()
            end
        end

        if (abs_x <= 1 and abs_y <= 1) then
            if abs_x == 1 and abs_y == 1 then
                return false
            end
            return true
        end

        if (abs_x <= 23 and abs_y <= 23) then
            -- Around spawn, in between the quadrants
            return false
        end

        if (abs_x < 2 or abs_y < 2) then
            return false
        end

        return true
    end
    return true

end

local rectangle = b.rectangle(32, 32)
local tree_rectangle = b.rectangle(64, 16)
local tree_rectangle_1 = b.throttle_xy(tree_rectangle, 1, 3, 1, 3)
local tree_rectangle_2 = b.rotate(tree_rectangle_1, math.pi / 2)

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

start_iron = b.combine({ b.translate(start_iron, base_x, base_y), b.translate(start_iron, -base_x, -base_y), b.translate(start_iron, base_x, -base_y), b.translate(start_iron, -base_x, base_y) })

base_x = base_x + 32
start_copper = b.combine({ b.translate(start_copper, base_x, base_y), b.translate(start_copper, -base_x, -base_y), b.translate(start_copper, base_x, -base_y), b.translate(start_copper, -base_x, base_y) })

base_y = base_x
start_stone = b.combine({ b.translate(start_stone, base_x, base_y), b.translate(start_stone, -base_x, -base_y), b.translate(start_stone, base_x, -base_y), b.translate(start_stone, -base_x, base_y) })

base_x = base_x - 32
start_coal = b.combine({ b.translate(start_coal, base_x, base_y), b.translate(start_coal, -base_x, -base_y), b.translate(start_coal, base_x, -base_y), b.translate(start_coal, -base_x, base_y) })

base_x = 64
base_y = 128
start_tree_1 = b.combine({ b.translate(start_tree_1, base_x, base_y), b.translate(start_tree_1, -base_x, -base_y), b.translate(start_tree_1, base_x, -base_y), b.translate(start_tree_1, -base_x, base_y) })

base_x = 128
base_y = 64
start_tree_2 = b.combine({ b.translate(start_tree_2, base_x, base_y), b.translate(start_tree_2, -base_x, -base_y), b.translate(start_tree_2, base_x, -base_y), b.translate(start_tree_2, -base_x, base_y) })

local map = b.apply_entities(quadrants, { start_iron, start_copper, start_stone, start_coal, start_tree_1, start_tree_2 })
return map