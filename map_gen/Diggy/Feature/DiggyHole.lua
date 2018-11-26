--[[-- info
    Provides the ability to "mine" through out-of-map tiles by destroying or
    mining rocks next to it.
]]

-- dependencies
local Event = require 'utils.event'
local Global = require 'utils.global'
local Scanner = require 'map_gen.Diggy.Scanner'
local Template = require 'map_gen.Diggy.Template'
local ScoreTable = require 'map_gen.Diggy.ScoreTable'
local Debug = require 'map_gen.Diggy.Debug'
local CreateParticles = require 'features.create_particles'
local insert = table.insert
local random = math.random
local raise_event = script.raise_event

-- this
local DiggyHole = {}

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

    ScoreTable.set('Robot mining damage', robot_mining.damage)
end

---Triggers a diggy diggy hole for a given sand-rock-big or rock-huge.
---@param entity LuaEntity
local function diggy_hole(entity)
    local tiles = {}
    local rocks = {}
    local surface = entity.surface
    local position = entity.position

    local out_of_map_found = Scanner.scan_around_position(surface, position, 'out-of-map');

    for i = #out_of_map_found, 1, -1 do
        local void_position = out_of_map_found[i]
        tiles[i] = {name = 'dirt-' .. random(1, 7), position = void_position}
        if random() < 0.35 then
            rocks[i] = {name = 'rock-huge', position = void_position}
        else
            rocks[i] = {name = 'sand-rock-big', position = void_position}
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

    for _, tile in pairs(tiles) do
        if (artificial_tiles[tile.old_tile.name]) then
            insert(new_tiles, { name = 'dirt-' .. random(1, 7), position = tile.position})
        end
    end

    Template.insert(surface, new_tiles, {})
end

--[[--
    Registers all event handlers.
]]
function DiggyHole.register(config)
    robot_mining.damage = config.robot_initial_mining_damage
    ScoreTable.set('Robot mining damage', robot_mining.damage)
    ScoreTable.reset('Mine size')

    Event.add(defines.events.on_entity_died, function (event)
        local entity = event.entity
        local name = entity.name
        if name ~= 'sand-rock-big' and name ~= 'rock-huge' then
            return
        end
        diggy_hole(entity)
        if event.cause then
            CreateParticles.destroy_rock(entity.surface.create_entity, 10, entity.position)
        end
    end)

    Event.add(defines.events.on_entity_damaged, function (event)
        local entity = event.entity
        local name = entity.name

        if entity.health ~= 0 then
            return
        end

        if name ~= 'sand-rock-big' and name ~= 'rock-huge' then
            return
        end

        raise_event(defines.events.on_entity_died, {entity = entity, cause = event.cause, force = event.force})
        entity.destroy()
    end)

    Event.add(defines.events.on_robot_mined_entity, function (event)
        local entity = event.entity
        local name = entity.name

        if name ~= 'sand-rock-big' and name ~= 'rock-huge' then
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
            raise_event(defines.events.on_entity_died, {entity = entity, force = force})
            CreateParticles.mine_rock(create_entity, 6, position)
            entity.destroy()
            return
        end
        entity.destroy()

        local rock = create_entity({name = name, position = position})
        CreateParticles.mine_rock(create_entity, 1, position)
        rock.graphics_variation = graphics_variation
        rock.order_deconstruction(force)
        rock.health = health
    end)

    Event.add(defines.events.on_player_mined_entity, function (event)
        local entity = event.entity
        local name = entity.name
        if name ~= 'sand-rock-big' and name ~= 'rock-huge' then
            return
        end

        event.buffer.clear()

        diggy_hole(entity)
        CreateParticles.mine_rock(entity.surface.create_entity, 6, entity.position)
    end)

    Event.add(defines.events.on_robot_mined_tile, function (event)
        on_mined_tile(event.robot.surface, event.tiles)
    end)

    Event.add(defines.events.on_player_mined_tile, function (event)
        on_mined_tile(game.surfaces[event.surface_index], event.tiles)
    end)

    Event.add(Template.events.on_void_removed, function ()
        ScoreTable.increment('Mine size')
    end)

    Event.add(defines.events.on_research_finished, function (event)
        local new_modifier = event.research.force.mining_drill_productivity_bonus * 50 * config.robot_damage_per_mining_prod_level

        if (robot_mining.research_modifier == new_modifier) then
            -- something else was researched
            return
        end

        robot_mining.research_modifier = new_modifier
        update_robot_mining_damage()
    end)

    if config.enable_debug_commands then
        commands.add_command('clear-void', '<left top x> <left top y> <width> <height> <surface index> triggers Template.insert for the given area.', function(cmd)
            local params = {}
            local args = cmd.parameter or ''
            for param in string.gmatch(args, '%S+') do
                table.insert(params, param)
            end

            if (#params ~= 5) then
                game.player.print('/clear-void requires exactly 5 arguments: <left top x> <left top y> <width> <height> <surface index>')
                return
            end

            local left_top_x = tonumber(params[1])
            local left_top_y = tonumber(params[2])
            local width = tonumber(params[3])
            local height = tonumber(params[4])
            local surface_index = params[5]
            local tiles = {}
            local entities = {}

            for x = 0, width do
                for y = 0, height do
                    insert(tiles, {name = 'dirt-' .. random(1, 7), position = {x = x + left_top_x, y = y + left_top_y}})
                end
            end

            Template.insert(game.surfaces[surface_index], tiles, entities)
        end
        )
    end
end

function DiggyHole.on_init()
    game.forces.player.technologies['landfill'].enabled = false
    game.forces.player.technologies['atomic-bomb'].enabled = false
end

return DiggyHole
