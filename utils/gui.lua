local Token = require 'utils.global_token'
local Event = require 'utils.event'

local Gui = {}

global.Gui_data = {}

local click_handlers
local text_changed_handlers
local close_handlers

function Gui.uid_name()
    if _DEBUG then
        -- https://stackoverflow.com/questions/48402876/getting-current-file-name-in-lua
        local filename = debug.getinfo(2, 'S').source:match('^.+/(.+)$'):sub(1, -5)
        return filename .. ',' .. Token.uid()
    else
        return tostring(Token.uid())
    end
end

-- Associates data with the LuaGuiElement. If data is nil then removes the data
function Gui.set_data(element, data)
    global.Gui_data[element.player_index .. ',' .. element.index] = data
end

-- Gets the Associated data with this LuaGuiElement if any.
function Gui.get_data(element)
    return global.Gui_data[element.player_index .. ',' .. element.index]
end

-- Removes data associated with LuaGuiElement and its children recursivly.
function Gui.remove_data_recursivly(element)
    Gui.set_data(element, nil)

    local children = element.children

    if not children then
        return
    end

    for _, child in ipairs(children) do
        if child.valid then
            Gui.remove_data_recursivly(child)
        end
    end
end

local function on_click(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
    event.player = player

    local handler = click_handlers[element.name]
    if not handler then
        return
    end

    handler(event)
end

-- Register a handler for the on_gui_click event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
function Gui.on_click(element_name, handler)
    if not click_handlers then
        click_handlers = {}
        Event.add(defines.events.on_gui_click, on_click)
    end

    click_handlers[element_name] = handler
end

local function on_text_changed(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
    event.player = player

    local handler = text_changed_handlers[element.name]
    if not handler then
        return
    end

    handler(event)
end

-- Register a handler for the on_gui_text_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
function Gui.on_text_changed(element_name, handler)
    if not text_changed_handlers then
        text_changed_handlers = {}
        Event.add(defines.events.on_gui_text_changed, on_text_changed)
    end

    text_changed_handlers[element_name] = handler
end

local function on_close(event)
    -- element is only set on the event for custom gui elements.
    local element = event.element
    if not element or not element.valid then
        return
    end

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
    event.player = player

    local handler = close_handlers[element.name]
    if not handler then
        return
    end

    handler(event)
end

-- Register a handler for the on_gui_closed event for a custom LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
function Gui.on_custom_close(element_name, handler)
    if not close_handlers then
        close_handlers = {}
        Event.add(defines.events.on_gui_closed, on_close)
    end

    close_handlers[element_name] = handler
end

return Gui
