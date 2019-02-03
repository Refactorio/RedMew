-- This module stores chunks as they are generated, keeping their left_top coordinate in an arrayed table.
-- An event is raised on each chunk stored that other modules can hook on to.

-- When 0.17 is released, this module should be modified take advantage of the on_chunk_deleted event in order to remove entries from the table

-- Dependencies
local Global = require 'utils.global'
local RS = require 'map_gen.shared.redmew_surface'
local Event = require 'utils.event'
local table = require 'utils.table'

-- Localized functions
local raise_event = script.raise_event
local deep_copy = table.deep_copy

-- Local vars
local surface
local Public = {
    chunk_list = {},
    events = {
        --[[
        on_chunk_registered
        Triggered when a chunk is recorded into the table
        Contains
            name :: defines.events: Identifier of the event
            tick :: uint: Tick the event was generated.
            area :: BoundingBox: Area of the chunk
            surface :: LuaSurface: The surface the chunk is on
            chunk_index :: the index of the chunk in the table
        ]]
        on_chunk_registered = script.generate_event_name()
    }
}

-- Global register
Global.register_init(
    {chunk_list = Public.chunk_list},
    function(tbl)
        tbl.surface = RS.get_surface()
    end,
    function(tbl)
        Public.chunk_list = tbl.chunk_list
        surface = tbl.surface
    end
)

local function on_chunk_generated(event)
    if surface ~= event.surface then
        return
    end

    local chunk_list = Public.chunk_list
    local new_entry_index = #chunk_list + 1

    chunk_list[new_entry_index] = event.area.left_top

    local custom_event = deep_copy(event)
    custom_event.chunk_index = new_entry_index
    raise_event(Public.events.on_chunk_registered, custom_event)
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)

return Public
