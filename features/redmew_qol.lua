-- Assorted quality of life improvements that are restricted in scope. Similar to redmew_commands but event-based rather than command-based.

-- This file has each module in 3 parts.
-- The local functions (including at least 1 tokenized function) are located below the "Local functions" comment
-- The functions which register and remove the events (allowing for runtime enabling/disabling of features) are located below the "Event registers" comment
-- Lastly the public get/set functions are located after the "Getters/setters" comment

-- Dependencies
local Token = require 'utils.token'
local Event = require 'utils.event'
local Utils = require 'utils.core'
local Global = require 'utils.global'
local config = global.config.redmew_qol

-- Localized functions
local get_random = table.get_random

-- Local vars
local Public = {}

-- Global registers
local enabled = {}

Global.register(
    {
        enabled = enabled
    },
    function(tbl)
        enabled = tbl.enabled
    end
)

-- Local functions

--- When placed, locomotives will get a random color
local random_train_color =
    Token.register(
    function(event)
        local entity = event.created_entity
        if entity and entity.name == 'locomotive' then
            entity.color = Utils.random_RGB()
        end
    end
)

local function on_init()
    -- Set player force's ghost_time_to_live to an hour. Giving the players ghosts before the research of robots is a nice QOL improvement.
    if config.ghosts_before_research then
        Public.set_ghost_ttl()
    end
end

--- If a newly placed entity is a provider or non-logi chest, set it to only have 1 slot available.
-- If placed from a bp and the bp has restrictions on the chest, it takes priority.
local restrict_chest =
    Token.register(
    function(event)
        local entity = event.created_entity
        if entity and (entity.name == 'logistic-chest-passive-provider' or entity.type == 'container') then
            local chest_inventory = entity.get_inventory(defines.inventory.chest)
            if #chest_inventory + 1 == chest_inventory.getbar() then
                chest_inventory.setbar(2)
            end
        end
    end
)

--- Selects a name from the entity backer name, game.players, and regulars
local function pick_name()
    -- Create a weight table comprised of the backer name, a player's name, and a regular's name
    local random_player = get_random(game.players, true)
    if not random_player then
        return
    end

    local regulars = global.regulars
    local reg
    if table.size(regulars) == 0 then
        reg = nil
    else
        reg = {table.get_random(regulars, false, true), 1}
    end
    local name_table = {
        {false, 8},
        {random_player.name, 1},
        reg
    }
    return table.get_random_weighted(name_table)
end

--- Changes the backer name on an entity that supports having a backer name.
local change_backer_name =
    Token.register(
    function(event)
        local entity = event.created_entity
        if entity and entity.backer_name then
            entity.backer_name = pick_name() or entity.backer_name
        end
    end
)

-- Event registers

local function register_random_train_color()
    if enabled['random_train_color'] then
        return false -- already registered
    end
    enabled['random_train_color'] = true
    Event.add_removable(defines.events.on_built_entity, random_train_color)
    return true
end

local function register_restrict_chest()
    if enabled['restrict_chest'] then
        return false -- already registered
    end
    enabled['restrict_chest'] = true
    Event.add_removable(defines.events.on_built_entity, restrict_chest)
    Event.add_removable(defines.events.on_robot_built_entity, restrict_chest)
    return true
end

local function register_change_backer_name()
    if enabled['change_backer_name'] then
        return false -- already registered
    end
    enabled['change_backer_name'] = true
    Event.add_removable(defines.events.on_built_entity, change_backer_name)
    Event.add_removable(defines.events.on_robot_built_entity, change_backer_name)
    return true
end

Event.on_init(on_init)

-- Public functions

--- Sets a ghost_time_to_live as a quality of life feature: now ghosts
-- are created on death of entities before robot research
-- @param force_name string with name of force
-- @param time number of ticks for ghosts to live
function Public.set_ghost_ttl(force_name, time)
    force_name = force_name or 'player'
    time = time or (30 * 60 * 60)
    game.forces[force_name].ghost_time_to_live = time
end

--- Sets random_train_color on or off.
-- @param enable <boolean> true to toggle on, false for off
-- @return <boolean> Success/failure of command
function Public.set_random_train_color(enable)
    if enable then
        return register_random_train_color()
    end
    Event.remove_removable(defines.events.on_built_entity, random_train_color)
    enabled['random_train_color'] = false
    return true
end

--- Return status of restrict_chest
function Public.get_random_train_color()
    return enabled['random_train_color'] or false
end

--- Sets restrict_chest on or off.
-- @param enable <boolean> true to toggle on, false for off
-- @return <boolean> Success/failure of command
function Public.set_restrict_chest(enable)
    if enable then
        return register_restrict_chest()
    else
        Event.remove_removable(defines.events.on_built_entity, restrict_chest)
        Event.remove_removable(defines.events.on_robot_built_entity, restrict_chest)
        enabled['restrict_chest'] = false
        return true
    end
end

--- Return status of restrict_chest
function Public.get_restrict_chest()
    return enabled['restrict_chest'] or false
end

--- Sets backer_name on or off.
-- @param enable <boolean> true to toggle on, false for off
-- @return <boolean> Success/failure of command
function Public.set_backer_name(enable)
    if enable then
        return register_change_backer_name()
    else
        Event.remove_removable(defines.events.on_built_entity, change_backer_name)
        Event.remove_removable(defines.events.on_robot_built_entity, change_backer_name)
        enabled['change_backer_name'] = false
        return true
    end
end

--- Return status of backer_name
function Public.get_backer_name()
    return enabled['change_backer_name'] or false
end

-- Initial event setup

if config.random_train_color then
    register_random_train_color()
end
if config.restrict_chest then
    register_restrict_chest()
end
if config.backer_name then
    register_change_backer_name()
end

return Public
