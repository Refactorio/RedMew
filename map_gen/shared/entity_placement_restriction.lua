--[[
    Regulates the placement of entities and their ghosts
    Can be called through public function to provide lists of allowed or banned entities.
    Can also set a keep_alive_callback function to check what is beneath the entity, for example for checking for ores or certain tiles.

    Example of keep_alive_callback function to check if there are ores beneath:
    function keep_alive_callback (surface, area)
        local count = surface.count_entities_filtered {area = area, type = 'resource', limit = 1}
        if count == 0 then
            return true
        end
    end

    Allowed entities: are exempt from the keep_alive_callback check and are never destroyed.
    Banned entities: are always destroyed.

    Maps can hook the on_pre_restricted_entity_destroyed and on_restricted_entity_destroyed events.
]]
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Token = require 'utils.token'
local table = require 'utils.table'

-- Localized functions
local raise_event = script.raise_event
local deep_copy = table.deep_copy

local Public = {
    events = {
        --[[
        on_pre_restricted_entity_destroyed
        Called before an entity is destroyed by this script
        Contains
            name :: defines.events: Identifier of the event
            tick :: uint: Tick the event was generated.
            created_entity :: LuaEntity
            player_index :: uint
            player :: LuaPlayer
            stack :: LuaItemStack
            ghost :: boolean indicating if the entity was a ghost
        ]]
        on_pre_restricted_entity_destroyed = script.generate_event_name(),
        --[[
        on_restricted_entity_destroyed
        Called when an entity is destroyed by this script
        Contains
            name :: defines.events: Identifier of the event
            tick :: uint: Tick the event was generated.
            player_index :: uint
            player :: LuaPlayer
            ghost :: boolean indicating if the entity was a ghost
            item_returned :: boolean indicating if the item was returned by this module
        ]]
        on_restricted_entity_destroyed = script.generate_event_name()
    }
}

-- Global-registered locals

local allowed_entities = {}
local banned_entities = {}
local primitives = {
    event = nil,
    allowed_ents = nil,
    banned_ents = nil,
    keep_alive_callback = nil
}

Global.register(
    {
        allowed_entities = allowed_entities,
        banned_entities = banned_entities,
        primitives = primitives
    },
    function(tbl)
        allowed_entities = tbl.allowed_entities
        banned_entities = tbl.banned_entities
        primitives = tbl.primitives
    end
)

-- Local functions

--- Token for on_built callback, checks if an entity should be destroyed.
local on_built_token =
    Token.register(
    function(event)
        local entity = event.created_entity
        if not entity or not entity.valid then
            return
        end

        local name = entity.name
        if name == 'tile-ghost' then
            return
        end

        local ghost = false
        if name == 'entity-ghost' then
            name = entity.ghost_name
            ghost = true
        end

        if primitives.allowed_ents and allowed_entities[name] then
            return
        end

        -- Takes the keep_alive_callback function (if provided) and runs it with the entity as an argument
        -- If true is returned, we exit. If false, we destroy the entity and return the itemstack to the player (if possible)
        local keep_alive_callback = primitives.keep_alive_callback
        if not banned_entities[name] and keep_alive_callback and keep_alive_callback(entity) then
            return
        end

        local p = Game.get_player_by_index(event.player_index)
        if not p or not p.valid then
            return
        end

        event.ghost = ghost
        event.player = p
        raise_event(Public.events.on_pre_restricted_entity_destroyed, deep_copy(event)) -- use deepcopy so that any potential writes to `event` aren't passed backwards

        -- Need to revalidate the entity since we sent it via the event
        if entity.valid then
            entity.destroy()
        end

        -- Need to revalidate the stack since we sent it via the event
        local stack = event.stack
        event.item_returned = false
        if not ghost and stack.valid then
            p.insert(stack)
            event.item_returned = true
        end

        event.stack = nil
        event.created_entity = nil
        raise_event(Public.events.on_restricted_entity_destroyed, event)
    end
)

--- Adds the event hook for on_built_entity
local function add_event()
    if not primitives.event then
        Event.add_removable(defines.events.on_built_entity, on_built_token)
        primitives.event = true
    end
end

--- Removes the event hook for on_built_entity
local function remove_event()
    if primitives.event then
        Event.remove_removable(defines.events.on_built_entity, on_built_token)
        primitives.event = nil
    end
end

-- Public functions

--- Sets the function to be used for keep_alive_callback
-- @param keep_alive_callback <function>
function Public.set_keep_alive_callback(keep_alive_callback)
    primitives.keep_alive_callback = keep_alive_callback
end

--- Adds to the list of allowed entities
-- @param ents <table> array of entity strings
function Public.add_allowed(ents)
    primitives.allowed_ents = true
    for _, v in pairs(ents) do
        allowed_entities[v] = true
    end
    if not primitives.event then
        add_event()
    end
end

--- Removes from the list of allowed entities
-- @param ents <table> array of entity strings
function Public.remove_allowed(ents)
    for _, v in pairs(ents) do
        allowed_entities[v] = nil
    end
    if table.size(allowed_entities) == 0 then
        primitives.allowed_ents = nil
        if primitives.event and not primitives.banned_ents then
            remove_event()
        end
    end
end

--- Resets the list of banned entities
function Public.reset_allowed()
    table.clear_table(allowed_entities)
    primitives.allowed_ents = nil
    if primitives.event and not primitives.banned_ents then
        remove_event()
    end
end

--- Adds to the list of banned entities
-- @param ents <table> array of entity strings
function Public.add_banned(ents)
    primitives.banned_ents = true
    for _, v in pairs(ents) do
        banned_entities[v] = true
    end
    if not primitives.event then
        add_event()
    end
end

--- Removes from the list of banned entities
-- @param ents <table> array of entity strings
function Public.remove_banned(ents)
    for _, v in pairs(ents) do
        banned_entities[v] = nil
    end
    if table.size(banned_entities) == 0 then
        primitives.banned_ents = nil
        if primitives.event and not primitives.allowed_ents then
            remove_event()
        end
    end
end

--- Resets the list of banned entities
function Public.reset_banned()
    primitives.banned_ents = nil
    table.clear_table(banned_entities)
    if primitives.event and not primitives.allowed_ents then
        remove_event()
    end
end

return Public
