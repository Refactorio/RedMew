local Event = require 'utils.event'
local table = require 'utils.table'
local Gui = require 'utils.gui'
local Model = require 'features.gui.debug.model'

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
local filter_name = Gui.uid_name()
local clear_filter_name = Gui.uid_name()

-- global tables
local enabled = {}
local last_events = {}
global.debug_event_view = {
    enabled = enabled,
    last_events = last_events,
    filter = ''
}

function Public.on_open_debug()
    local tbl = global.debug_event_view
    if tbl then
        enabled = tbl.enabled
        last_events = tbl.last_events
    else
        enabled = {}
        last_events = {}

        global.debug_event_view = {
            enabled = enabled,
            last_events = last_events
        }
    end

    Public.on_open_debug = nil
end

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

    local str = format('%s (id = %s): %s', name, id, Model.dump(event))
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
for name, _ in pairs(events) do
    grid_builder[#grid_builder + 1] = name
end

table.sort(grid_builder)

local function redraw_event_table(gui_table, filter)
    for _, event_name in pairs(grid_builder) do
        if filter == '' or event_name:find(filter) then
            local index = events[event_name]
            gui_table.add({type = 'flow'}).add {
                name = checkbox_name,
                type = 'checkbox',
                state = enabled[index] or false,
                caption = event_name
            }
        end
    end
end

function Public.show(container)
    local filter = global.debug_event_view.filter

    local main_frame_flow = container.add({type = 'flow', direction = 'vertical'})

    local filter_flow = main_frame_flow.add({type = 'flow', direction = 'horizontal'})
    filter_flow.add({type = 'label', caption = 'filter'})
    local filter_textfield = filter_flow.add({type = 'textfield', name = filter_name, text = filter})
    local clear_button = filter_flow.add({type = 'button', name = clear_filter_name, caption = 'clear'})

    local scroll_pane = main_frame_flow.add({type = 'scroll-pane'})
    local gui_table = scroll_pane.add({type = 'table', column_count = 3, draw_horizontal_lines = true})

    Gui.set_data(filter_textfield, gui_table)
    Gui.set_data(clear_button, {gui_table = gui_table, filter_textfield = filter_textfield})

    redraw_event_table(gui_table, filter)
end

Gui.on_checked_state_changed(checkbox_name, on_gui_checked_state_changed)

Gui.on_text_changed(
    filter_name,
    function(event)
        local element = event.element
        local gui_table = Gui.get_data(element)

        local filter = element.text:gsub(' ', '_')

        global.debug_event_view.filter = filter
        element.text = filter

        gui_table.clear()
        redraw_event_table(gui_table, filter)
    end
)

Gui.on_click(
    clear_filter_name,
    function(event)
        local element = event.element
        local data = Gui.get_data(element)
        local filter_textfield = data.filter_textfield
        local gui_table = data.gui_table

        filter_textfield.text = ''
        global.debug_event_view.filter = ''

        gui_table.clear()
        redraw_event_table(gui_table, '')
    end
)

-- Event registers (TODO: turn to removable hooks.. maybe)
for name, id in pairs(events) do
    name_lookup[id] = name
    Event.add(id, event_callback)
end

return Public
