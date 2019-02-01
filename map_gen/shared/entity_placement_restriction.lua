--[[
    Regulates the placement of entities and their ghosts
    Can be called through public function to provide lists of allowed or banned entities.
    Can also set a logic function to check what is beneath the entity, for example for checking for ores or certain tiles.

    Example of logic function to check if there are ores beneath:
    function logic(surface, area)
        local count = surface.count_entities_filtered {area = area, type = 'resource', limit = 1}
        if count == 0 then
            return true
        end
    end

    Allowed entities: are exempt from the logic check and are never destroyed.
    Banned entities: are always destroyed.

    Maps can hook the on_restricted_entity_destroyed event to generate whatever feedback they deem appropriate
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
        on_restricted_entity_destroyed
        Triggered when an entity is destroyed by this script
        Contains
            name :: defines.events: Identifier of the event
            tick :: uint: Tick the event was generated.
            created_entity :: LuaEntity
            player_index :: uint
            player :: LuaPlayer
            stack :: LuaItemStack
            ghost :: boolean indicating if the entity was a ghost
        ]]
        on_restricted_entity_destroyed = script.generate_event_name()
    }
}

-- Global-registered locals

local allowed_entites = {}
local banned_entites = {}
local primitives = {
    event = nil,
    allowed_ents = nil,
    banned_ents = nil,
    logic = nil
}

Global.register(
    {
        allowed_entites = allowed_entites,
        banned_entites = banned_entites,
        primitives = primitives
    },
    function(tbl)
        allowed_entites = tbl.allowed_entites
        banned_entites = tbl.banned_entites
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

        if primitives.allowed_ents and allowed_entites[name] then
            return
        end

        -- Some entities have a bounding_box area of zero, eg robots.
        local area = entity.bounding_box
        local left_top, right_bottom = area.left_top, area.right_bottom
        if left_top.x == right_bottom.x and left_top.y == right_bottom.y then
            return
        end

        -- Takes the logic function (if provided) and runs it with the surface and area as arguments
        -- this allows the logic function to scan underneath the entity. if true is returned, we exit.
        -- If false, we destroy the entity and return it
        local logic = primitives.logic
        if logic and logic(entity.surface, area) then
            return
        end

        if primitives.banned_ents and not banned_entites[name] and not primitives.allowed_ents then
            return
        end

        local p = Game.get_player_by_index(event.player_index)
        if not p or not p.valid then
            return
        end

        entity.destroy()
        event.item_returned = false
        if not ghost then
            p.insert(event.stack)
            event.item_returned = true
        end
        event.ghost = ghost
        event.player = p
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

--- Sets the function to be used for logic
-- @param logic <function>
function Public.set_logic(logic)
    primitives.logic = logic
end

--- Adds to the list of allowed entities
-- @param ents <table> array of entity strings
function Public.add_allowed(ents)
    primitives.allowed_ents = true
    for _, v in pairs(ents) do
        allowed_entites[v] = true
    end
    if not primitives.event then
        add_event()
    end
end

--- Removes from the list of allowed entities
-- @param ents <table> array of entity strings
function Public.remove_allowed(ents)
    for _, v in pairs(ents) do
        allowed_entites[v] = true
    end
    if table.size(allowed_entites) == 0 then
        primitives.allowed_ents = nil
        if primitives.event and not primitives.banned_ents then
            remove_event()
        end
    end
end

--- Resets the list of banned entities
function Public.reset_allowed()
    table.clear_table(allowed_entites)
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
        banned_entites[v] = true
    end
    if not primitives.event then
        add_event()
    end
end

--- Removes from the list of banned entities
-- @param ents <table> array of entity strings
function Public.remove_banned(ents)
    for _, v in pairs(ents) do
        banned_entites[v] = true
    end
    if table.size(banned_entites) == 0 then
        primitives.banned_ents = nil
        if primitives.event and not primitives.allowed_ents then
            remove_event()
        end
    end
end

--- Resets the list of banned entities
function Public.reset_banned()
    primitives.banned_ents = nil
    table.clear_table(banned_entites)
    if primitives.event and not primitives.allowed_ents then
        remove_event()
    end
end

return Public
