local Token = require 'utils.token'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Styles = require 'resources.styles'
local mod_gui = require '__core__.lualib.mod-gui'
--[[
    player.gui.top.mod_gui_top_frame.mod_gui_inner_frame[element_name]
    player.gui.left.mod_gui_frame_flow[element_name]
]]

local tostring = tostring
local next = next

local gui_element_prefix = "Redmew_"

local Gui = {}

local data = {}
local element_map = {}

Gui.token =
    Global.register(
    {data = data, element_map = element_map},
    function(tbl)
        data = tbl.data
        element_map = tbl.element_map
    end
)

local top_elements = {}
local on_visible_handlers = {}
local on_pre_hidden_handlers = {}

Gui._top_elements = top_elements

function Gui.uid_name()
    return gui_element_prefix .. tostring(Token.uid())
end

-- Associates data with the LuaGuiElement. If data is nil then removes the data
function Gui.set_data(element, value)
    local player_index = element.player_index
    local values = data[player_index]

    if value == nil then
        if not values then
            return
        end

        values[element.index] = nil

        if next(values) == nil then
            data[player_index] = nil
        end
    else
        if not values then
            values = {}
            data[player_index] = values
        end

        values[element.index] = value
    end
end
local set_data = Gui.set_data

-- Gets the Associated data with this LuaGuiElement if any.
function Gui.get_data(element)
    local player_index = element.player_index

    local values = data[player_index]
    if not values then
        return nil
    end

    return values[element.index]
end

---@param element LuaGuiElement
---@param style string|table
function Gui.set_style(element, style)
    if type(style) == 'string' then
        element.style = style
    else
        local element_style = element.style
        for k, v in pairs(style) do
            element_style[k] = v
        end
    end
    return element
end

local remove_data_recursively
-- Removes data associated with LuaGuiElement and its children recursively.
function Gui.remove_data_recursively(element)
    set_data(element, nil)

    local children = element.children

    if not children then
        return
    end

    for _, child in next, children do
        if child.valid then
            remove_data_recursively(child)
        end
    end
end
remove_data_recursively = Gui.remove_data_recursively

local remove_children_data
function Gui.remove_children_data(element)
    local children = element.children

    if not children then
        return
    end

    for _, child in next, children do
        if child.valid then
            set_data(child, nil)
            remove_children_data(child)
        end
    end
end
remove_children_data = Gui.remove_children_data

function Gui.destroy(element)
    remove_data_recursively(element)
    element.destroy()
end

function Gui.clear(element)
    remove_children_data(element)
    element.clear()
end

---@param player LuaPlayer
function Gui.init_gui_style(player)
    local mod_gui_top_frame = Gui.get_top_flow(player).parent
    Gui.set_style(mod_gui_top_frame, { padding = 2 })
end

---@param player LuaPlayer
---@return LuaGuiElement
function Gui.get_top_flow(player)
    return mod_gui.get_button_flow(player)
end

---@param player LuaPlayer
---@param element_name string
---@return LuaGuiElement?
function Gui.get_top_element(player, element_name)
	return Gui.get_top_flow(player)[element_name]
end

---@param player LuaPlayer
---@param child table
---@return LuaGuiElement
function Gui.add_top_element(player, child)
    local flow = Gui.get_top_flow(player)
    local element = flow[child.name]
	if element and element.valid then
        return element
	end
	if (child.type == 'button' or child.type == 'sprite-button') and child.style == nil then
        child.style = Styles.default_top_element.name
        return Gui.set_style(flow.add(child), Styles.default_top_element.style)
    else
        return flow.add(child)
	end
end

---@param player LuaPlayer
function Gui.get_left_flow(player)
    return mod_gui.get_frame_flow(player)
end

---@param player LuaPlayer
---@param element_name string
---@return LuaGuiElement?
function Gui.get_left_element(player, element_name)
    return Gui.get_left_flow(player)[element_name]
end

---@param player LuaPlayer
---@param child table
---@return LuaGuiElement
function Gui.add_left_element(player, child)
    local flow = Gui.get_left_flow(player)
    local element = flow[child.name]
    if element and element.valid then
        return element
    end
    if child.type == 'frame' and child.style == nil then
        return Gui.set_style(flow.add(child), Styles.default_left_element.style)
    else
        return flow.add(child)
    end
end

---@param parent LuaGuiElement
---@param direction? string, default: horizontal
---@return LuaGuiElement
function Gui.add_pusher(parent, direction)
    local pusher = parent.add { type = 'empty-widget' }
    Gui.set_style(pusher, Styles.default_pusher.style)
    pusher.ignored_by_interaction = true
    if direction == 'vertical' then
        pusher.style.vertically_stretchable = true
    else
        pusher.style.horizontally_stretchable = true
    end
    return pusher
end

Gui.add_dragger = function(parent, target)
    local dragger = parent.add { type = 'empty-widget', style = 'draggable_space_header' }
    Gui.set_style(dragger, Styles.default_dragger.style)

    if target then
        dragger.drag_target = target
    end

    return dragger
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

        local player = game.get_player(event.player_index)
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

-- Register a handler for the on_gui_switch_state_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_switch_state_changed = handler_factory(defines.events.on_gui_switch_state_changed)

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
        local player = game.get_player(event.player_index)

        if not player or not player.valid then
            return
        end

        Gui.init_gui_style(player)

        local b = Gui.add_top_element(player, {
            type = 'button',
            name = toggle_button_name,
            caption = '<',
            tooltip = {'gui_util.button_tooltip'}
        })

        Gui.set_style(b, {
            width = 18,
            height = Styles.default_top_element.style.minimal_height,
            left_padding = 0,
            top_padding = 0,
            right_padding = 0,
            bottom_padding = 0,
            font = 'default-small-bold',
        })
    end
)

Gui.on_click(
    toggle_button_name,
    function(event)
        local button = event.element
        local player = event.player
        local top = Gui.get_top_flow(player)

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
        end
    end
)

function Gui.make_close_button(parent, name)
    local button =
        parent.add {
        type = 'button',
        name = name,
        caption = {'common.close_button'},
        style = 'back_button'
    }

    Styles.default_close(button.style)

    return button
end

if _DEBUG then
    local concat = table.concat

    local names = {}
    Gui.names = names

    local matching_path = '^.+__level__/(.+)$'

    function Gui.uid_name()
        local info = debug.getinfo(2, 'Sl')
        local filepath = info.source:match(matching_path):sub(1, -5)
        local line = info.currentline

        local token = gui_element_prefix .. tostring(Token.uid())

        local name = concat {token, ' - ', filepath, ':line:', line}
        names[token] = name

        return token
    end

    function Gui.set_data(element, value)
        local player_index = element.player_index
        local values = data[player_index]

        if value == nil then
            if not values then
                return
            end

            local index = element.index
            values[index] = nil
            element_map[index] = nil

            if next(values) == nil then
                data[player_index] = nil
            end
        else
            if not values then
                values = {}
                data[player_index] = values
            end

            local index = element.index
            values[index] = value
            element_map[index] = element
        end
    end
    set_data = Gui.set_data

    function Gui.data()
        return data
    end

    function Gui.element_map()
        return element_map
    end
end

return Gui
