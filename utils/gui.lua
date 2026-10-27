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
-- where each player last left each floating side panel: [player index][panel name]
local panel_locations = {}
-- side panels each player has floating rather than docked: [player index][panel name] = true
local floating_panels = {}

Gui.token =
    Global.register(
    {data = data, element_map = element_map, panel_locations = panel_locations, floating_panels = floating_panels},
    function(tbl)
        data = tbl.data
        element_map = tbl.element_map
        panel_locations = tbl.panel_locations
        floating_panels = tbl.floating_panels
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

--- Adds a title bar to a window in player.gui.screen: its caption, if it has one, and a space to
--- drag the window by, and with close_button_name, an X with that name at the end. A window with a
--- Close button of its own gives its X the same name, so one click handler serves both.
---@param frame LuaGuiElement
---@param caption LocalisedString?
---@param close_button_name? string
---@return LuaGuiElement title_bar
---@return LuaGuiElement? close_button
function Gui.add_title_bar(frame, caption, close_button_name)
    local title_bar = frame.add { type = 'flow', direction = 'horizontal', style = 'frame_header_flow' }
    Gui.set_style(title_bar, Styles.default_title_bar.style)

    if caption then
        local title = title_bar.add { type = 'label', caption = caption, style = 'frame_title' }
        title.drag_target = frame
    end

    local dragger = Gui.add_dragger(title_bar, frame)
    Gui.set_style(dragger, { height = 24 })

    local close_button
    if close_button_name then
        close_button = title_bar.add {
            type = 'sprite-button',
            name = close_button_name,
            sprite = 'utility/close',
            clicked_sprite = 'utility/close_black',
            style = 'close_button',
            tooltip = { 'gui.close-instruction' }
        }
    end

    return title_bar, close_button
end

--- Adds a window to player.gui.screen, with a title bar to drag it by (see Gui.add_title_bar).
--- Like Factorio's own windows, it opens in the middle of the screen every time. Find it again
--- with player.gui.screen[spec.name].
---@param player LuaPlayer
---@param spec { name: string?, caption: LocalisedString?, close_button_name: string?, direction: string? }
---@return LuaGuiElement frame
---@return LuaGuiElement? close_button
function Gui.add_window(player, spec)
    local frame = player.gui.screen.add { type = 'frame', name = spec.name, direction = spec.direction or 'vertical' }
    frame.auto_center = true

    local _, close_button = Gui.add_title_bar(frame, spec.caption, spec.close_button_name)
    return frame, close_button
end

local function handler_factory(event_id)
    local handlers = {}
    local registered = false

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
        if not registered then
            registered = true
            Event.add(event_id, on_event)
        end

        handlers[element_name] = handler
    end, handlers
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
local click_handlers
Gui.on_click, click_handlers = handler_factory(defines.events.on_gui_click)

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

-- Register a handler for the on_gui_confirmed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_confirmed = handler_factory(defines.events.on_gui_confirmed)

-- Register a handler for the on_gui_hover event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_hover = handler_factory(defines.events.on_gui_hover)

-- Register a handler for the on_gui_inventory_action event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_inventory_action = handler_factory(defines.events.on_gui_inventory_action)

-- Register a handler for the on_gui_leave event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_leave = handler_factory(defines.events.on_gui_leave)

-- Register a handler for the on_gui_location_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_location_changed = handler_factory(defines.events.on_gui_location_changed)

-- Register a handler for the on_gui_selected_tab_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_selected_tab_changed = handler_factory(defines.events.on_gui_selected_tab_changed)

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

Event.add(defines.events.on_player_created, function(event)
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
end)

Event.add(defines.events.on_player_removed, function(event)
    data[event.player_index] = nil
    panel_locations[event.player_index] = nil
    floating_panels[event.player_index] = nil
end)

-- How much of a floating panel must be on the screen for it to reopen where it was left, in
-- pixels at the player's UI scale: enough of the header to drag it back.
local panel_on_screen_margin = 64

--- Where the player last left a floating panel, or nil if it was never moved or that spot is now
--- off their screen (they changed resolution or UI scale since).
local function saved_panel_location(player, name)
    local locations = panel_locations[player.index]
    local location = locations and locations[name]
    if not location then
        return nil
    end

    local resolution = player.display_resolution
    local margin = panel_on_screen_margin * player.display_scale
    if location.x < 0 or location.y < 0 or location.x > resolution.width - margin or location.y > resolution.height - margin then
        return nil
    end
    return location
end

-- Remembers where a player drags a floating panel, for the next time it opens. Windows open in the
-- middle every time, like Factorio's own; a floating panel is part of the player's screen layout.
local function remember_panel_location(event)
    local element = event.element
    if not (element and element.valid) or not element.tags.redmew_floating_panel then
        return
    end

    local player_index = event.player_index
    local locations = panel_locations[player_index]
    if not locations then
        locations = {}
        panel_locations[player_index] = locations
    end
    local location = element.location
    locations[element.name] = { x = location.x, y = location.y }
end
Event.add(defines.events.on_gui_location_changed, remember_panel_location)

local panel_pin_button_name = Gui.uid_name()

local function is_panel_floating(player, name)
    local panels = floating_panels[player.index]
    return panels ~= nil and panels[name] == true
end

--- Adds a side panel: docked in the left column under the top buttons, or, once the player has
--- floated it with the pin in its header, a window they can drag anywhere (see Gui.add_window).
--- A docked panel closes from its top button, so only a floating one has an X; the X and the pin
--- both go through the click handler of toggle_name, the panel's top button, which must open the
--- panel when it is closed and close it when it is open. A panel with buttons of its own in the
--- header adds them in add_header_buttons(header), which puts them before the pin. Find it again
--- with Gui.get_panel.
--- title_width caps the title's width, so a longer translation can't push the header's buttons out
--- of a panel with a fixed width. deep puts the content in a dark inner frame, which numbers read
--- better on. With side_dragger, a floating panel is dragged by a strip down its right side rather
--- than by a space in its header, so the header keeps its width.
---@param player LuaPlayer
---@param spec { name: string, caption: LocalisedString, toggle_name: string, width: 'narrow'|'wide'|'minimap'|nil, add_header_buttons: fun(header: LuaGuiElement)?, title_width: number?, deep: boolean?, side_dragger: boolean? }
---@return LuaGuiElement frame
---@return LuaGuiElement content the padded inner frame to add the panel's elements to
function Gui.add_panel(player, spec)
    local name = spec.name
    local floating = is_panel_floating(player, name)

    -- with a side dragger, the header and content go in a column beside the strip
    local side_dragger = floating and spec.side_dragger

    local frame
    if floating then
        frame = player.gui.screen.add { type = 'frame', name = name, direction = side_dragger and 'horizontal' or 'vertical' }
        local location = saved_panel_location(player, name)
        if location then
            frame.location = location
        else
            frame.auto_center = true
        end
    else
        frame = Gui.get_left_flow(player).add { type = 'frame', name = name, direction = 'vertical' }
    end
    frame.tags = { redmew_panel = true, redmew_floating_panel = floating or nil, toggle_name = spec.toggle_name }
    if spec.width then
        Gui.set_style(frame, { width = Styles.panel_width[spec.width] })
    else
        -- the header's pusher would stretch the panel across the column under the top buttons,
        -- as wide as the top bar: a panel without a width is as wide as its contents
        Gui.set_style(frame, { horizontally_stretchable = false })
    end

    local body = frame
    if side_dragger then
        body = frame.add { type = 'flow', direction = 'vertical' }
    end

    local header = body.add { type = 'flow', direction = 'horizontal', style = 'frame_header_flow' }
    Gui.set_style(header, Styles.default_title_bar.style)

    local title = header.add { type = 'label', caption = spec.caption, style = 'frame_title' }
    if spec.title_width then
        Gui.set_style(title, { maximal_width = spec.title_width })
    end
    if floating then
        title.drag_target = frame
    end
    if floating and not side_dragger then
        local dragger = Gui.add_dragger(header, frame)
        Gui.set_style(dragger, { height = 24 })
    else
        Gui.add_pusher(header)
    end

    if spec.add_header_buttons then
        spec.add_header_buttons(header)
    end

    header.add {
        type = 'sprite-button',
        name = panel_pin_button_name,
        sprite = 'utility/track_button_white',
        hovered_sprite = 'utility/track_button',
        clicked_sprite = 'utility/track_button',
        style = 'frame_action_button',
        toggled = not floating,
        tooltip = { floating and 'gui_util.panel_dock_tooltip' or 'gui_util.panel_float_tooltip' }
    }

    if floating then
        header.add {
            type = 'sprite-button',
            name = spec.toggle_name,
            sprite = 'utility/close',
            clicked_sprite = 'utility/close_black',
            style = 'close_button',
            tooltip = { 'gui.close-instruction' }
        }
    end

    local content = body.add { type = 'frame', style = spec.deep and 'inside_deep_frame' or 'inside_shallow_frame', direction = 'vertical' }
    Gui.set_style(content, { padding = 8 })

    if side_dragger then
        local dragger = frame.add { type = 'empty-widget', style = 'draggable_space' }
        Gui.set_style(dragger, { vertically_stretchable = true, width = 8, margin = 0, left_margin = 8 })
        dragger.drag_target = frame
    end

    return frame, content
end

--- The side panel named `name` (see Gui.add_panel), docked or floating, or nil if it isn't open.
---@param player LuaPlayer
---@param name string
---@return LuaGuiElement?
function Gui.get_panel(player, name)
    local frame = Gui.get_left_flow(player)[name]
    if frame and frame.valid then
        return frame
    end
    frame = player.gui.screen[name]
    if frame and frame.valid and frame.tags.redmew_panel then
        return frame
    end
    return nil
end

-- The pin floats a docked panel or docks a floating one: the panel's own top button handler
-- closes it, and opens it again where it now belongs.
Gui.on_click(panel_pin_button_name, function(event)
    local player = event.player
    local frame = event.element.parent
    while not frame.tags.redmew_panel do
        frame = frame.parent
    end
    local name = frame.name
    local toggle_name = frame.tags.toggle_name
    local toggle = toggle_name and click_handlers[toggle_name]
    if not toggle then
        return
    end

    local button = Gui.get_top_element(player, toggle_name)
    local toggle_event = { name = event.name, tick = event.tick, player_index = player.index, player = player, element = button }

    toggle(toggle_event)

    local panels = floating_panels[player.index]
    if not panels then
        panels = {}
        floating_panels[player.index] = panels
    end
    panels[name] = not panels[name] or nil

    toggle(toggle_event)
    if button and button.valid then
        button.toggled = true
    end
end)

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

    function Gui.panel_locations()
        return panel_locations
    end

    function Gui.floating_panels()
        return floating_panels
    end
end

-- Mod compatibility
Gui.allow_player_to_toggle_top_element_visibility('fp_button_toggle_interface') -- Factory Planner
Gui.allow_player_to_toggle_top_element_visibility('informatron_overhead')       -- Informatron
Gui.allow_player_to_toggle_top_element_visibility('py_open_wiki')               -- Pyanodon
Gui.allow_player_to_toggle_top_element_visibility('se-overhead_explorer')       -- Space Exploration
Gui.allow_player_to_toggle_top_element_visibility('se-overhead_interstellar')   -- Space Exploration

return Gui
