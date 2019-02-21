--[[
    Create table of tables, each holding the last event of a particular type:
    last_triggers = {
        on_player_joined = {event},
        on_player_left = {event}
    }
]]
local Event = require 'utils.event'
local Global = require 'utils.global'
local table = require 'utils.table'
local Gui = require 'utils.gui'

local format = string.format
local insert = table.insert

local events = defines.events

-- Constants
local events_to_keep = 10

-- Local vars
local Public = {
    name = 'Events'
}
local name_lookup = {}

-- GUI names
local checkbox_name = Gui.uid_name()

-- Global tables
local enabled = {}
local last_events = {}

Global.register(
    {
        enabled = enabled,
        last_events = last_events
    },
    function(tbl)
        enabled = tbl.enabled
        last_events = tbl.last_events
    end
)

-- Local functions
local function event_callback(event)
    local id = event.name
    if not enabled[id] then
        return
    end
    local name = name_lookup[id]

    if not last_events[name] then
        last_events[name] = {}
    end

    insert(last_events[name], 1, event)
    last_events[name][events_to_keep + 1] = nil
    event.name = nil

    local str = format('%s (id = %s): ', name, id)
    for k, v in pairs(event) do
        if type(v) ~= 'table' then
            str = format('%s %s = %s,', str, k, v)
        elseif v.__self then
            str = format('%s %s :: %s', str, k, Debug.object_type(v))
            if v.valid then
                str = format('%s (name = %s),', str, v.name)
            else
                str = str .. ','
            end
        else
            str = format('%s %s = {', str, k)
            for k2, v2 in pairs(v) do
                if type(v2) == 'table' then
                    str = format('%s %s = <table>,', str, k2)
                else
                    str = format('%s %s = %s,', str, k2, v2)
                end
            end
            str = format('%s},', str)
        end
    end
    game.print(str)
    log(str)
end

local function on_gui_checked_state_changed(event)
    local element = event.element
    local name = element.caption
    local id = events[name]
    local state = element.state and true or false
    element.state = state
    if state then
        enabled[id] = true
    else
        enabled[id] = false
    end
end

-- GUI

-- Create a table with events sorted by their names
local grid_builder = {}
for name, id in pairs(events) do
    grid_builder[id] = name
end
grid_builder[#grid_builder + 1] = grid_builder[0]
grid_builder[0] = nil
table.sort(grid_builder)

function Public.show(container)
    local main_frame_flow = container.add({type = 'flow', direction = 'vertical'})
    local scroll_pane = main_frame_flow.add({type = 'scroll-pane'})
    local gui_table = scroll_pane.add({type = 'table', column_count = 3, draw_horizontal_lines = true})

    for _, event_name in pairs(grid_builder) do
        local index = events[event_name]
        gui_table.add({type = 'flow'}).add {
            name = checkbox_name,
            type = 'checkbox',
            state = enabled[index] or false,
            caption = event_name
        }
    end
end

Event.add(events.on_gui_checked_state_changed, on_gui_checked_state_changed)

-- Event registers (TODO: turn to removable hooks.. maybe)
for name, id in pairs(events) do
    name_lookup[id] = name
    Event.add(id, event_callback)
end

return Public
