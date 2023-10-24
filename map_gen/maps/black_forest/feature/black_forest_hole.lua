--[[-- info
    Provides the ability to "mine" through out-of-map tiles by destroying or
    mining rocks next to it.
]]

-- dependencies
local Event = require 'utils.event'
local Global = require 'utils.global'
local Template = require 'map_gen.maps.black_forest.template'
local ScoreTracker = require 'utils.score_tracker'
local Command = require 'utils.command'
local CreateParticles = require 'features.create_particles'
local destroy_tree = CreateParticles.destroy_tree
local Ranks = require 'resources.ranks'
local random = math.random
local tonumber = tonumber
local pairs = pairs
local is_black_forest_tree = Template.is_black_forest_tree
local raise_event = script.raise_event
local mine_size_name = 'mine-size'

-- this
local black_forestHole = {}
local config

-- keeps track of the amount of times per player when they mined with a full inventory in a row
local full_inventory_mining_cache = {}

-- keeps track of the buffs for the bot mining mining_efficiency
local robot_mining = {
    damage = 0,
    active_modifier = 0,
    research_modifier = 0,
}

Global.register({
    full_inventory_mining_cache = full_inventory_mining_cache,
    bot_mining_damage = robot_mining,
}, function (tbl)
    full_inventory_mining_cache = tbl.full_inventory_mining_cache
    robot_mining = tbl.bot_mining_damage
end)

local function update_robot_mining_damage()
    -- remove the current buff
    local old_modifier = robot_mining.damage - robot_mining.active_modifier

    -- update the active modifier
    robot_mining.active_modifier = robot_mining.research_modifier

    -- add the new active modifier to the non-buffed modifier
    robot_mining.damage = old_modifier + robot_mining.active_modifier
end

---Triggers a black_forest black_forest hole for a given sand-rock-big, rock-big or rock-huge.
---@param entity LuaEntity
local function black_forest_hole(entity)
    local tiles = {}
    local rocks = {}
    local surface = entity.surface
    local position = entity.position
    local x = position.x
    local y = position.y
    local get_tile = surface.get_tile
    local out_of_map_found = {}
    local count = 0

    if (get_tile(x, y - 1).name == 'out-of-map') then
        count = count + 1
        out_of_map_found[count] = {x = x, y = y - 1}
    end

    if (get_tile(x + 1, y).name == 'out-of-map') then
        count = count + 1
        out_of_map_found[count] = {x = x + 1, y = y}
    end

    if (get_tile(x, y + 1).name == 'out-of-map') then
        count = count + 1
        out_of_map_found[count] = {x = x, y = y + 1}
    end

    if (get_tile(x - 1, y).name == 'out-of-map') then
        count = count + 1
        out_of_map_found[count] = {x = x - 1, y = y}
    end



    if (get_tile(x - 1, y-1).name == 'out-of-map') then
        count = count + 1
        out_of_map_found[count] = {x = x - 1, y = y-1}
    end
    if (get_tile(x - 1, y+1).name == 'out-of-map') then
        count = count + 1
        out_of_map_found[count] = {x = x - 1, y = y+1}
    end
    if (get_tile(x + 1, y+1).name == 'out-of-map') then
        count = count + 1
        out_of_map_found[count] = {x = x + 1, y = y+1}
    end
    if (get_tile(x + 1, y-1).name == 'out-of-map') then
        out_of_map_found[count + 1] = {x = x + 1, y = y-1}
    end







    for i = #out_of_map_found, 1, -1 do
        local void_position = out_of_map_found[i]
        tiles[i] = {name = 'grass-' .. random(1, 4), position = void_position}
        local predicted = random()
        if predicted < 0.2 then
            rocks[i] = {name = 'tree-01', position = void_position}
        elseif predicted < 0.6 then
            rocks[i] = {name = 'tree-02', position = void_position}
        else
            rocks[i] = {name = 'tree-03', position = void_position}
        end
    end

    Template.insert(surface, tiles, rocks)
end

local artificial_tiles = {
    ['stone-brick'] = true,
    ['stone-path'] = true,
    ['concrete'] = true,
    ['hazard-concrete-left'] = true,
    ['hazard-concrete-right'] = true,
    ['refined-concrete'] = true,
    ['refined-hazard-concrete-left'] = true,
    ['refined-hazard-concrete-right'] = true,
}

local function on_mined_tile(surface, tiles)
    local new_tiles = {}
    local count = 0
    for _, tile in pairs(tiles) do
        if (artificial_tiles[tile.old_tile.name]) then
            count = count + 1
            new_tiles[count] = {name = 'grass-' .. random(1, 4), position = tile.position}
        end
    end

    Template.insert(surface, new_tiles, {})
end
Command.add('black_forest-clear-void', {
    description = {'command_description.black_forest_clear_void'},
    arguments = {'left_top_x', 'left_top_y', 'width', 'height', 'surface_index'},
    debug_only = true,
    required_rank = Ranks.admin,
}, function(arguments)
    local left_top_x = tonumber(arguments.left_top_x)
    local left_top_y = tonumber(arguments.left_top_y)
    local width = tonumber(arguments.width)
    local height = tonumber(arguments.height)
    local tiles = {}
    local count = 0
    for x = 0, width do
        for y = 0, height do
            count = count + 1
            tiles[count] = {name = 'grass-' .. random(1, 4), position = {x = x + left_top_x, y = y + left_top_y}}
        end
    end

    Template.insert(game.surfaces[arguments.surface_index], tiles, {})
end)

--[[--
    Registers all event handlers.
]]
function black_forestHole.register(cfg)
    ScoreTracker.register(mine_size_name, {'black_forest.score_mine_size'}, '[img=tile.out-of-map]')

    local global_to_show = global.config.score.global_to_show
    global_to_show[#global_to_show + 1] = mine_size_name

    config = cfg
    robot_mining.damage = cfg.robot_initial_mining_damage

    Event.add(defines.events.on_entity_died, function (event)
        local entity = event.entity
        local name = entity.name
        if not is_black_forest_tree(name) then
            return
        end
        if event.loot then
            event.loot.clear()
        end
        black_forest_hole(entity)

    end)

    Event.add(defines.events.script_raised_destroy, function (event)
        local entity = event.entity
        local name = entity.name
        if not is_black_forest_tree(name) then
            return
        end
        black_forest_hole(entity)
    end)

    Event.add(defines.events.on_entity_damaged, function (event)
        local entity = event.entity
        local name = entity.name

        if entity.health ~= 0 then
            return
        end

        if not is_black_forest_tree(name) then
            return
        end
        destroy_tree(entity.surface.create_particle, 10, entity.position)
        entity.destroy{raise_destroy = true}
    end)

    Event.add(defines.events.on_robot_mined_entity, function (event)
        local entity = event.entity
        local name = entity.name

        if not is_black_forest_tree(name) then
            return
        end

        local health = entity.health
        health = health - robot_mining.damage
        event.buffer.clear()

        local graphics_variation = entity.graphics_variation
        local create_entity = entity.surface.create_entity
        local position = entity.position
        local force = event.robot.force

        if health < 1 then
            entity.die(force)
            return
        end
        entity.destroy()

        local rock = create_entity({name = name, position = position})
        rock.graphics_variation = graphics_variation
        rock.order_deconstruction(force)
        rock.health = health
    end)

    Event.add(defines.events.on_player_mined_entity, function (event)
        local entity = event.entity
        local name = entity.name
        if not is_black_forest_tree(name) then
            return
        end

        --event.buffer.clear()

        black_forest_hole(entity)
    end)

    Event.add(defines.events.on_robot_mined_tile, function (event)
        on_mined_tile(event.robot.surface, event.tiles)
    end)

    Event.add(defines.events.on_player_mined_tile, function (event)
        on_mined_tile(game.surfaces[event.surface_index], event.tiles)
    end)

    Event.add(Template.events.on_void_removed, function ()
        ScoreTracker.change_for_global(mine_size_name, 1)
    end)

    local robot_damage_per_mining_prod_level = cfg.robot_damage_per_mining_prod_level
    Event.add(defines.events.on_research_finished, function (event)
        local new_modifier = event.research.force.mining_drill_productivity_bonus * 50 * robot_damage_per_mining_prod_level

        if (robot_mining.research_modifier == new_modifier) then
            -- something else was researched
            return
        end

        robot_mining.research_modifier = new_modifier
        update_robot_mining_damage()
    end)
end

function black_forestHole.on_init()
    game.forces.player.technologies['landfill'].enabled = config.allow_landfill_research
    game.forces.player.technologies['atomic-bomb'].enabled = false
end

return black_forestHole
