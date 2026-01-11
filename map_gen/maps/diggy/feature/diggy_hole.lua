--[[-- info
    Provides the ability to "mine" through out-of-map tiles by destroying or
    mining rocks next to it.
]]

-- dependencies
local Event = require 'utils.event'
local Global = require 'utils.global'
local Template = require 'map_gen.maps.diggy.template'
local ScoreTracker = require 'utils.score_tracker'
local Command = require 'utils.command'
local CreateParticles = require 'features.create_particles'
local Ranks = require 'resources.ranks'
local Token = require 'utils.token'
local Task = require 'utils.task'
local set_timeout_in_ticks = Task.set_timeout_in_ticks
local random = math.random
local tonumber = tonumber
local pairs = pairs
local is_diggy_rock = Template.is_diggy_rock
local destroy_rock = CreateParticles.destroy_rock
local mine_rock = CreateParticles.mine_rock
local raise_event = script.raise_event
local mine_size_name = 'mine-size'
local ceil = math.ceil

-- this
local DiggyHole = {}
local config

-- keeps track of the buffs for the bot mining mining_efficiency
local robot_mining = {
    damage = 0,
    active_modifier = 0,
    research_modifier = 0,
    delay = 0
}

-- Used in conjunction with set_timeout_in_ticks(robot_mining_delay...  to control bot mining frequency
-- Robot_mining.damage is equal to robot_mining_delay * robot_per_tick_damage
-- So for example if robot_mining delay is doubled, robot_mining.damage gets doubled to compensate.
local metered_bot_mining = Token.register(function(params)
    local entity = params.entity
    local force = params.force
    local health_update = params.health_update
    if entity.valid then
        local health = entity.health
        --If health of entity didn't change during delay apply bot mining damage and re-order order_deconstruction
        --If rock was damaged during the delay the bot gets scared off and stops mining this particular rock.
        if health_update == health - robot_mining.damage then
            entity.health = health_update
            entity.order_deconstruction(force)
        end
    end
end)

Global.register({
    bot_mining_damage = robot_mining,
}, function (tbl)
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

---Triggers a diggy diggy hole for a given big-rock, big-rock or huge-rock.
---@param entity LuaEntity
local function diggy_hole(entity)
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
        out_of_map_found[count + 1] = {x = x - 1, y = y}
    end

    for i = #out_of_map_found, 1, -1 do
        local void_position = out_of_map_found[i]
        tiles[i] = {name = 'dirt-' .. random(1, 7), position = void_position}
        local predicted = random()
        if predicted < 0.2 then
            rocks[i] = {name = 'huge-rock', position = void_position}
        else
            rocks[i] = {name = 'big-rock', position = void_position}
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
            new_tiles[count] = {name = 'dirt-' .. random(1, 7), position = tile.position}
        end
    end

    Template.insert(surface, new_tiles, {})
end

--[[--
    diggy-clear-void is a debugging command that can be used in game to clear void area.  Arguments: left_top_x left_top_y width height surface_index
    Example:  /diggy-clear-void -50 -50 100 100 redmew    This will clear a square area 100 x 100 centered on the spawn point.
    Note: The command will not automatically generate new chunks.
]]
Command.add('diggy-clear-void', {
    description = {'command_description.diggy_clear_void'},
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
            tiles[count] = {name = 'dirt-' .. random(1, 7), position = {x = x + left_top_x, y = y + left_top_y}}
        end
    end

    Template.insert(game.surfaces[arguments.surface_index], tiles, {})
end)

--[[--
    Registers all event handlers.
]]
function DiggyHole.register(cfg)
    ScoreTracker.register(mine_size_name, {'diggy.score_mine_size'}, '[img=tile.out-of-map]')

    local global_to_show = storage.config.score.global_to_show
    global_to_show[#global_to_show + 1] = mine_size_name

    config = cfg
    robot_mining.delay = cfg.robot_mining_delay
    robot_mining.damage = cfg.robot_per_tick_damage * robot_mining.delay

    Event.add(defines.events.on_entity_died, function (event)
        local entity = event.entity
        local name = entity.name
        if not is_diggy_rock(name) then
            return
        end
        if event.loot then
            event.loot.clear()
        end
        diggy_hole(entity)
    end)

    Event.add(defines.events.script_raised_destroy, function (event)
        local entity = event.entity
        local name = entity.name
        if not is_diggy_rock(name) then
            return
        end
        diggy_hole(entity)
    end)

    -- Checks for when a diggy rock is about to die due to damage and destroys it instead
    -- better performance than entity.die() especially when large amounts of rocks are damaged, i.e. due to damaged reactor or nuke
    Event.add(defines.events.on_entity_damaged, function (event)
        local entity = event.entity
        local name = entity.name

        if not is_diggy_rock(name) then
            return
        end

        local cause = event.cause
        local health = entity.health

        -- Diggy rock is destroyed if health is zero or less than 1500 when damaged by a tank (tank buff)
        if health == 0 or (cause and cause.name == "tank" and health < 1500 and event.damage_type.valid and event.damage_type.name ~= 'fire') then
            raise_event(defines.events.script_raised_destroy, {entity = entity, cause = "die_faster"})
            destroy_rock(entity.surface.create_particle, 10, entity.position)
            entity.destroy()
        end
    end)

    Event.add(defines.events.on_robot_mined_entity, function (event)
        local entity = event.entity
        local name = entity.name

        if not is_diggy_rock(name) then
            return
        end

        local health = entity.health
        local health_update = health - robot_mining.damage
        event.buffer.clear()

        local graphics_variation = entity.graphics_variation
        local create_entity = entity.surface.create_entity
        local create_particle = entity.surface.create_particle
        local position = entity.position
        local force = event.robot.force
        local delay = robot_mining.delay

        if health_update < 1 then
            entity.die(force)
            return
        end
        entity.destroy()

        local rock = create_entity({name = name, position = position})
        mine_rock(create_particle, ceil(delay / 2), position)
        rock.graphics_variation = graphics_variation
        rock.health = health
        --Mark replaced rock for de-construction and apply health_update after delay.  Health verified and
        --update applied after delay to help prevent more rapid damage if someone were to spam deconstruction blueprints
        set_timeout_in_ticks(delay, metered_bot_mining, {entity = rock, force = force, health_update = health_update})
    end)

    Event.add(defines.events.on_player_mined_entity, function (event)
        local entity = event.entity
        local name = entity.name
        if not is_diggy_rock(name) then
            return
        end

        event.buffer.clear()

        diggy_hole(entity)
        mine_rock(entity.surface.create_particle, 6, entity.position)
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

function DiggyHole.on_init()
    game.forces.player.technologies['landfill'].enabled = config.allow_landfill_research
    game.forces.player.technologies['atomic-bomb'].enabled = false
end

return DiggyHole
