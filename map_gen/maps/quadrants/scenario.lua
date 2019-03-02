require 'map_gen.maps.quadrants.switch_team'
require 'map_gen.maps.quadrants.restrict_placement'

local b = require('map_gen.shared.builders')
local Retailer = require('features.retailer')
local market_items = require 'resources.market_items'
local RS = require 'map_gen.shared.redmew_surface'
local Event = require 'utils.event'
local ScenarioInfo = require 'features.gui.info'
local Recipes = require 'map_gen.maps.quadrants.enabled_recipes'
local CompiHandler = require 'map_gen.maps.quadrants.compilatron_handler'
local Token = require 'utils.token'
local Task = require 'utils.task'

local abs = math.abs
local round = math.round
local redmew_config = global.config

ScenarioInfo.set_map_name('Quadrants')
ScenarioInfo.set_map_description('Take control over an area and work together as a region!')
ScenarioInfo.add_map_extra_info(
    [[
This map is split in four quadrants.
Each quadrant has a main objective.

Chat is restricted to your current quadrant.
Use /shout <message> (shortcut: /s <message>) to chat with entire server

The following quadrants exists:
Science and Military, Intermediate and Mining,
Oil and High Tech, Logistics and Transport.

Common for all quadrants:
- Basic manufacturing and power
- Commercial super market present
- Teleportation between quadrants with empty inventory, excluding:
    - Tools
    - Utility Armor
    - Weaponry

Science and Military
- Manages research for the entire region
- Supplies weaponry and security solutions to the entire region

Intermediate and Mining
- Only producer of steel
- High precision workers allowing for circuitry manufacturing
- Area found to have rich amount of minerals

Oil and High Tech
- Facilities for oil processing
- Facilities for nuclear handling
- Leading force in innovating products
- Rocket launch site

Logistics and Transport
- Leading force in logistical solutions
    - Belt based
    - Bot based
    - Train based

Version: pre-v1.0
]]
)

redmew_config.paint.enabled = false
redmew_config.player_create.random_join_message_set = {}

redmew_config.player_create.starting_items = {
    {name = 'iron-plate', count = 7},
    {name = 'iron-gear-wheel', count = 3}
}

redmew_config.player_create.join_messages = {
    'Welcome to this map created by the RedMew team. You can join our discord at: redmew.com/discord',
    'Click the question mark in the top left corner for server information and map details.',
    '----',
    'Quadrants is a new take on a teamwork based map. Be sure to read the map details!',
    'Chat is restricted to your current quadrant.',
    'Use /shout <message> (shortcut: /s <message>) to chat with entire server',
    '--------'
}

redmew_config.hail_hydra.enabled = true

local function spawn_market(surface, force, position)
    position.x = round(position.x)
    position.y = round(position.y - 4)

    local pos = surface.find_non_colliding_position('market', position, 10, 1)

    local market = surface.create_entity({name = 'market', position = pos})
    market.destructible = false

    Retailer.add_market(pos.x .. 'fish_market' .. pos.y, market)

    if table.size(Retailer.get_items(pos.x .. 'fish_market' .. pos.y)) == 0 then
        for _, prototype in pairs(market_items) do
            Retailer.set_item(pos.x .. 'fish_market' .. pos.y, prototype)
        end
    end

    force.add_chart_tag(surface, {icon = {type = 'item', name = 'coin'}, position = pos, text = 'Market'})

    pos = surface.find_non_colliding_position('compilatron', position, 10, 1)

    local compi = surface.create_entity {name = 'compilatron', position = pos, force = game.forces.neutral}

    local quadrant = 'quadrant'
    if pos.x > 0 then
        if pos.y > 0 then
            quadrant = quadrant .. '4'
        else
            quadrant = quadrant .. '1'
        end
    else
        if pos.y > 0 then
            quadrant = quadrant .. '3'
        else
            quadrant = quadrant .. '2'
        end
    end

    CompiHandler.add_compilatron(compi, quadrant)
end

local function reset_recipes()
    for _, force in pairs(game.forces) do
        if (string.find(force.name, 'quadrant')) ~= nil then
            for _, recipe in pairs(force.recipes) do
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
    q1.set_spawn_position({64, -64}, surface)
    local q2 = game.create_force('quadrant2')
    q2.set_spawn_position({-64, -64}, surface)
    local q3 = game.create_force('quadrant3')
    q3.set_spawn_position({-64, 64}, surface)
    local q4 = game.create_force('quadrant4')
    q4.set_spawn_position({64, 64}, surface)

    reset_recipes()
    for _, force in pairs(game.forces) do
        if (string.find(force.name, 'quadrant')) ~= nil then
            force.share_chart = true

            if force.name ~= 'quadrant1' then
                force.disable_research()
            end
            for _, friend_force in pairs(game.forces) do
                if (string.find(friend_force.name, 'quadrant')) ~= nil then
                    if friend_force ~= force then
                        force.set_friend(friend_force, true)
                    end
                end
            end
        end
    end
end

local function on_research_finished(event)
    if event.research.force ~= game.forces['quadrant1'] then
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

local callback_token
local callback

local function spawn_compilatron()
    local pos = game.surfaces[2].find_non_colliding_position('compilatron', {-0.5, -0.5}, 1.5, 0.5)
    local compi = game.surfaces[2].create_entity {name = 'compilatron', position = pos, force = game.forces.neutral}
    CompiHandler.add_compilatron(compi, 'spawn')
    log('ADDED!')
end

local function chunk_generated()
    Event.remove_removable(defines.events.on_chunk_generated, callback_token)
    Task.set_timeout_in_ticks(300, callback)
end

Event.on_init(on_init)
Event.add(defines.events.on_research_finished, on_research_finished)
--Event.add(defines.events.on_player_joined_game, player_created)
callback_token = Token.register(chunk_generated)
callback = Token.register(spawn_compilatron)

Event.add_removable(defines.events.on_chunk_generated, callback_token)

local function quadrants(x, y)
    local abs_x = abs(x) - 0.5
    local abs_y = abs(y) - 0.5

    if (abs_x <= 200 and abs_y <= 200) then
        if game.surfaces[2].get_tile(x, y).collides_with('water-tile') then
            game.surfaces[2].set_tiles({{name = 'grass-1', position = {x, y}}}, true)
        end
        local entities = game.surfaces[2].find_entities({{x - 0.5, y - 0.5}, {x + 0.5, y + 0.5}})

        for _, entity in ipairs(entities) do
            if entity and entity.valid then
                if entity.name ~= 'player' and entity.name ~= 'compilatron' then
                    entity.destroy()
                end
            end
        end
    end

    if (x < 0 and y < 0) then
        if not (abs_x <= 200 and abs_y <= 200) then
            local resources =
                game.surfaces[2].find_entities_filtered {
                area = {{x - 0.5, y - 0.5}, {x + 0.5, y + 0.5}},
                type = 'resource'
            }
            for _, resource in pairs(resources) do
                if resource.name ~= 'crude-oil' then
                    local amount = b.euclidean_value(1, 0.002)
                    resource.amount = resource.amount * amount(x, y)
                end
            end
        end
    end

    if (abs_x == 100) and (abs_y == 100) then
        spawn_market(RS.get_surface(), game.forces.player, {x = x, y = y})
    end

    if (abs_x >= 112 and abs_x <= 144 and abs_y >= 112 and abs_y <= 144) then
        game.surfaces[2].set_tiles({{name = 'water', position = {x, y}}}, true)
    end

    if (abs_x <= 23 or abs_y <= 23) then
        -- Between quadrants create land
        game.surfaces[2].set_tiles({{name = 'tutorial-grid', position = {x, y}}}, true)
        game.surfaces[2].destroy_decoratives {{x - 0.5, y - 0.5}, {x + 0.5, y + 0.5}}
        local entities = game.surfaces[2].find_entities({{x - 0.5, y - 0.5}, {x + 0.5, y + 0.5}})
        for _, entity in ipairs(entities) do
            if entity and entity.valid then
                if entity.name ~= 'player' then
                    entity.destroy()
                end
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
local tree_rectangle_1 = b.throttle_world_xy(tree_rectangle, 1, 3, 1, 3)
local tree_rectangle_2 = b.rotate(tree_rectangle_1, math.pi / 2)
local oil_rectangle = b.throttle_xy(tree_rectangle, 1, 5, 1, 5)

local function constant(x)
    return function()
        return x
    end
end

local base_x = 48
local base_y = 48

local start_iron = b.resource(rectangle, 'iron-ore', constant(750))
local start_copper = b.resource(rectangle, 'copper-ore', constant(600))
local start_stone = b.resource(rectangle, 'stone', constant(300))
local start_coal = b.resource(rectangle, 'coal', constant(450))
local start_tree_1 = b.entity(tree_rectangle_1, 'tree-01')
local start_oil = b.resource(oil_rectangle, 'crude-oil', b.exponential_value(100000, 0, 1))
local start_tree_2 = b.entity(tree_rectangle_2, 'tree-01')

start_iron =
    b.any(
    {
        b.translate(start_iron, base_x, base_y),
        b.translate(start_iron, -base_x, -base_y),
        b.translate(start_iron, base_x, -base_y),
        b.translate(start_iron, -base_x, base_y)
    }
)

base_x = base_x + 32
start_copper =
    b.any(
    {
        b.translate(start_copper, base_x, base_y),
        b.translate(start_copper, -base_x, -base_y),
        b.translate(start_copper, base_x, -base_y),
        b.translate(start_copper, -base_x, base_y)
    }
)

base_y = base_x
start_stone =
    b.any(
    {
        b.translate(start_stone, base_x, base_y),
        b.translate(start_stone, -base_x, -base_y),
        b.translate(start_stone, base_x, -base_y),
        b.translate(start_stone, -base_x, base_y)
    }
)

base_x = base_x - 32
start_coal =
    b.any(
    {
        b.translate(start_coal, base_x, base_y),
        b.translate(start_coal, -base_x, -base_y),
        b.translate(start_coal, base_x, -base_y),
        b.translate(start_coal, -base_x, base_y)
    }
)

base_x = 64
base_y = 128
start_tree_1 =
    b.any(
    {
        b.translate(start_tree_1, base_x, base_y),
        b.translate(start_tree_1, -base_x, -base_y),
        b.translate(start_tree_1, base_x, -base_y),
        b.translate(start_oil, -base_x, base_y)
    }
)

base_x = 128
base_y = 64
start_tree_2 =
    b.any(
    {
        b.translate(start_tree_2, base_x, base_y),
        b.translate(start_tree_2, -base_x, -base_y),
        b.translate(start_tree_2, base_x, -base_y),
        b.translate(start_tree_2, -base_x, base_y)
    }
)

local map = b.apply_entities(quadrants, {start_iron, start_copper, start_stone, start_coal, start_tree_1, start_tree_2})
return map
