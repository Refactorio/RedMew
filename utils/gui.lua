local Token = require 'utils.token'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'

local Gui = {}

local data = {}

Global.register(
    data,
    function(tbl)
        data = tbl
    end
)

local top_elements = {}
local on_visible_handlers = {}
local on_pre_hidden_handlers = {}

function Gui.uid_name()
    return tostring(Token.uid())
end

-- Associates data with the LuaGuiElement. If data is nil then removes the data
function Gui.set_data(element, value)
    data[element.player_index * 0x100000000 + element.index] = value
end

-- Gets the Associated data with this LuaGuiElement if any.
function Gui.get_data(element)
    return data[element.player_index * 0x100000000 + element.index]
end

-- Removes data associated with LuaGuiElement and its children recursively.
function Gui.remove_data_recursively(element)
    Gui.set_data(element, nil)

    local children = element.children

    if not children then
        return
    end

    for _, child in ipairs(children) do
        if child.valid then
            Gui.remove_data_recursively(child)
        end
    end
end

function Gui.remove_children_data(element)
    local children = element.children

    if not children then
        return
    end

    for _, child in ipairs(children) do
        if child.valid then
            Gui.set_data(child, nil)
            Gui.remove_children_data(child)
        end
    end
end

function Gui.destroy(element)
    Gui.remove_data_recursively(element)
    element.destroy()
end

function Gui.clear(element)
    Gui.remove_children_data(element)
    element.clear()
end

local function handler_factory(event_id)
    local handlers

    local function on_event(event)
        local element = event.element
        if not element or not element.valid then
            return
        end

        local handler = handlers[element.name]
        if not handler then
            return
        end

        local player = Game.get_player_by_index(event.player_index)
        if not player or not player.valid then
            return
        end
        event.player = player

        handler(event)
    end

    return function(element_name, handler)
        if not handlers then
            handlers = {}
            Event.add(event_id, on_event)
        end

        handlers[element_name] = handler
    end
end

local function custom_handler_factory(handlers)
    return function(element_name, handler)
        handlers[element_name] = handler
    end
end

local function custom_raise(handlers, element, player)
    local handler = handlers[element.name]
    if not handler then
        return
    end

    handler({element = element, player = player})
end

-- Register a handler for the on_gui_checked_state_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_checked_state_changed = handler_factory(defines.events.on_gui_checked_state_changed)

-- Register a handler for the on_gui_click event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_click = handler_factory(defines.events.on_gui_click)

-- Register a handler for the on_gui_closed event for a custom LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_custom_close = handler_factory(defines.events.on_gui_closed)

-- Register a handler for the on_gui_elem_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_elem_changed = handler_factory(defines.events.on_gui_elem_changed)

-- Register a handler for the on_gui_selection_state_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_selection_state_changed = handler_factory(defines.events.on_gui_selection_state_changed)

-- Register a handler for the on_gui_text_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_text_changed = handler_factory(defines.events.on_gui_text_changed)

-- Register a handler for the on_gui_value_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_value_changed = handler_factory(defines.events.on_gui_value_changed)

-- Register a handler for when the player shows the top LuaGuiElements with element_name.
-- Assuming the element_name has been added with Gui.allow_player_to_toggle_top_element_visibility.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_player_show_top = custom_handler_factory(on_visible_handlers)

-- Register a handler for when the player hides the top LuaGuiElements with element_name.
-- Assuming the element_name has been added with Gui.allow_player_to_toggle_top_element_visibility.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_pre_player_hide_top = custom_handler_factory(on_pre_hidden_handlers)

--- Allows the player to show / hide this element.
-- The element must be part in gui.top.
-- This function must be called in the control stage, i.e not inside an event.
-- @param element_name<string> This name must be globally unique.
function Gui.allow_player_to_toggle_top_element_visibility(element_name)
    if _LIFECYCLE ~= _STAGE.control then
        error('can only be called during the control stage', 2)
    end
    top_elements[#top_elements + 1] = element_name
end

local toggle_button_name = Gui.uid_name()

Event.add(
    defines.events.on_player_created,
    function(event)
        local player = Game.get_player_by_index(event.player_index)

        if not player or not player.valid then
            return
        end

        local b =
            player.gui.top.add {
            type = 'button',
            name = toggle_button_name,
            caption = '<',
            tooltip = {'gui_util.button_tooltip'}
        }
        local style = b.style
        style.width = 18
        style.height = 38
        style.left_padding = 0
        style.top_padding = 0
        style.right_padding = 0
        style.bottom_padding = 0
        style.font = 'default-small-bold'
    end
)

Gui.on_click(
    toggle_button_name,
    function(event)
        local button = event.element
        local player = event.player
        local top = player.gui.top

        if button.caption == '<' then
            for i = 1, #top_elements do
                local name = top_elements[i]
                local ele = top[name]
                if ele and ele.valid then
                    if ele.visible then
                        custom_raise(on_pre_hidden_handlers, ele, player)
                        ele.visible = false
                    end
                end
            end

            button.caption = '>'
            button.style.height = 24
        else
            for i = 1, #top_elements do
                local name = top_elements[i]
                local ele = top[name]
                if ele and ele.valid then
                    if not ele.visible then
                        ele.visible = true
                        custom_raise(on_visible_handlers, ele, player)
                    end
                end
            end

            button.caption = '<'
            button.style.height = 38
        end
    end
)

if _DEBUG then
    local concat = table.concat

    local names = {}
    Gui.names = names

    function Gui.uid_name()
        local info = debug.getinfo(2, 'Sl')
        local filepath = info.source:match('^.+/currently%-playing/(.+)$'):sub(1, -5)
        local line = info.currentline

        local token = tostring(Token.uid())

        local name = concat {token, ' - ', filepath, ':line:', line}
        names[token] = name

        return token
    end
end

return Gui
