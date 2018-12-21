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
function Gui.set_data(element, value)
    data[element.player_index * 0x100000000 + element.index] = value
end

-- Removes data associated with LuaGuiElement and its children recursivly.
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

function Gui.destroy(element)
    Gui.remove_data_recursively(element)
    element.destroy()
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

-- Register a handler for the on_gui_closed event for a custom LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Gui.on_custom_close = handler_factory(defines.events.on_gui_closed)

return Gui
