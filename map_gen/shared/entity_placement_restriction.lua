--[[
    This module restricts the placement of entities and ghosts based on an allowed and banned list,
    as well as by the (optionally) provided function.

    The table of allowed_entities are *always* allowed to be placed.
    The table of banned_entities are *never* allowed to be placed, and are destroyed.

    For anything not in either of those lists, you can use the set_keep_alive_callback function to set a keep_alive_callback function.
    This means you can use any custom logic you want to determine whether an entity should be destroyed or not.
    The callback function is supplied a valid LuaEntity as an argument.
    A return of true indicates the entity should be kept alive, while false or nil indicate it should be destroyed.

    Refunds for items that were placed can be toggled on or off via the enable and disable_refund functions

    Lastly, this module raises 2 events: on_pre_restricted_entity_destroyed and on_restricted_entity_destroyed events.
    They are fully defined below.

    Examples (only the first example will include the require):
    -- A map which allows no roboports:
    local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
    RestrictEntities.add_banned({'roboport'})

    -- A map which allows only belts (for a foot race map, of course)
    -- The function provided does nothing but return nil
    -- every entity will be destroyed except those on the allowed list
    RestrictEntities.add_allowed({'transport-belt'})
    RestrictEntities.set_keep_alive_callback(function() end)

    -- Danger ores (a lot of important code omitted for the sake of a brief example)
    RestrictEntities.add_allowed({belts, power_poles, mining_drills, 'pumpjack'})
    RestrictEntities.set_keep_alive_callback(
        function(entity)
            if entity.surface.count_entities_filtered {area = entity.bounding_box, type = 'resource', limit = 1} == 0 then
                return true
            end
        end
    )
]]
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Token = require 'utils.token'
local table = require 'utils.table'

-- Localized functions
local raise_event = script.raise_event

local Public = {
    events = {
        --[[
        on_pre_restricted_entity_destroyed
        Called before an entity is destroyed by this script
        Contains
            name :: defines.events: Identifier of the event
            tick :: uint: Tick the event was generated.
            player_index :: uint
            created_entity :: LuaEntity
            ghost :: boolean indicating if the entity was a ghost
            stack :: LuaItemStack
        ]]
        on_pre_restricted_entity_destroyed = Event.generate_event_name('on_pre_restricted_entity_destroyed'),
        --[[
        on_restricted_entity_destroyed
        Called when an entity is destroyed by this script
        Contains
            name :: defines.events: Identifier of the event
            tick :: uint: Tick the event was generated.
            player_index :: uint
            player :: LuaPlayer The player who was refunded (optional)
            ghost :: boolean indicating if the entity was a ghost
            item_returned :: boolean indicating if a refund of the item was attempted
        ]]
        on_restricted_entity_destroyed = Event.generate_event_name('on_restricted_entity_destroyed')
    }
}

-- Global-registered locals

local allowed_entities = {}
local banned_entities = {}
local primitives = {
    event = nil, -- if the event is registered or not
    refund = true, -- if we issue a refund or not
    keep_alive_callback = nil -- the function to process entities through
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

--- Token for the on_built event callback, checks if an entity should be destroyed.
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

        if allowed_entities[name] then
            return
        end

        -- Takes the keep_alive_callback function and runs it with the entity as an argument
        -- If true is returned, we exit. If false, we destroy the entity.
        local keep_alive_callback = primitives.keep_alive_callback
        if not banned_entities[name] and keep_alive_callback and keep_alive_callback(entity) then
            return
        end

        local index = event.player_index

        local stack = event.stack
        raise_event(
            Public.events.on_pre_restricted_entity_destroyed,
            {
                player_index = index,
                created_entity = entity,
                ghost = ghost,
                stack = stack
            }
        )

        -- Need to revalidate the entity since we sent it to the raised event
        if entity.valid then
            entity.destroy()
        end

        -- Check if we issue a refund: make sure refund is enabled, make sure we're not refunding a ghost,
        -- and revalidate the stack since we sent it to the raised event
        local player = Game.get_player_by_index(index)
        local item_returned
        if player and player.valid and primitives.refund and not ghost and stack.valid then
            player.insert(stack)
            item_returned = true
        else
            item_returned = false
        end

        raise_event(
            Public.events.on_restricted_entity_destroyed,
            {
                player_index = index,
                player = player,
                ghost = ghost,
                item_returned = item_returned
            }
        )
    end
)

--- Registers and unregisters the event hook
local function check_event_status()
    -- First we check if the event hook is in place or not
    if primitives.event then
        -- If there are no items in either list and no function is present, unhook the event
        if not next(allowed_entities) and not next(banned_entities) and not primitives.keep_alive_callback then
            Event.remove_removable(defines.events.on_built_entity, on_built_token)
            primitives.event = nil
        end
    else
        -- If either of the lists have an entry or there is a function present, hook the event
        if next(allowed_entities) or next(banned_entities) or primitives.keep_alive_callback then
            Event.add_removable(defines.events.on_built_entity, on_built_token)
            primitives.event = true
        end
    end
end

-- Public functions

--- Sets the keep_alive_callback function. This function is used to provide
-- logic on what entities should and should not be destroyed.
-- @param keep_alive_callback <function>
function Public.set_keep_alive_callback(keep_alive_callback)
    if type(keep_alive_callback) ~= 'function' then
        error('Sending a non-funciton')
    end
    primitives.keep_alive_callback = keep_alive_callback
    check_event_status()
end

--- Removes the keep_alive_callback function
function Public.remove_keep_alive_callback()
    primitives.keep_alive_callback = nil
    check_event_status()
end

--- Adds to the list of allowed entities
-- @param ents <table> array of string entity names
function Public.add_allowed(ents)
    for _, v in pairs(ents) do
        allowed_entities[v] = true
    end
    check_event_status()
end

--- Removes from the list of allowed entities
-- @param ents <table> array of string entity names
function Public.remove_allowed(ents)
    for _, v in pairs(ents) do
        allowed_entities[v] = nil
    end
    check_event_status()
end

--- Resets the list of allowed entities
function Public.reset_allowed()
    table.clear_table(allowed_entities)
    check_event_status()
end

--- Adds to the list of banned entities
-- @param ents <table> array of string entity names
function Public.add_banned(ents)
    for _, v in pairs(ents) do
        banned_entities[v] = true
    end
    check_event_status()
end

--- Removes from the list of banned entities
-- @param ents <table> array of string entity names
function Public.remove_banned(ents)
    for _, v in pairs(ents) do
        banned_entities[v] = nil
    end
    check_event_status()
end

--- Resets the list of banned entities
function Public.reset_banned()
    table.clear_table(banned_entities)
    check_event_status()
end

--- Enables the returning of items that are destroyed by this module
function Public.enable_refund()
    primitives.refund = true
end

--- Disables the returning of items that are destroyed by this module
function Public.set_refund()
    primitives.refund = false
end

return Public
