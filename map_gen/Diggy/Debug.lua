-- dependencies

-- this
local Debug = {}

-- private state
local debug = false
local cheats = false

function Debug.enable_debug()
    debug = true
end

function Debug.disable_debug()
    debug = false
end

function Debug.enable_cheats()
    cheats = true
end

function Debug.disable_cheats()
    cheats = true
end

global.message_count = 0

--[[--
    Shows the given message if _DEBUG == true.

    @param message string
]]
function Debug.print(message)
    if type(message) ~= 'string' and type(message) ~= 'number'  and type(message) ~= 'boolean' then message = type(message) end
    global.message_count = global.message_count + 1
    if (debug) then
        game.print('[' .. global.message_count .. '] ' .. tostring(message))
        log('[' .. global.message_count .. '] ' .. tostring(message))
    end
end

--[[--
    Shows the given message if _DEBUG == true for a given position.

    @param x number
    @param y number
    @param message string
]]
function Debug.printPosition(position, message)
    message = message or ''
    if type(message) ~= 'string' and type(message) ~= 'number'  and type(message) ~= 'boolean' then message = type(message) end
    global.message_count = global.message_count + 1
    if (debug) then
        game.print('[' .. global.message_count .. '] {x=' .. position.x .. ', y=' .. position.y .. '} ' .. tostring(message))
    end
end

--[[--
    Executes the given callback if _DIGGY_CHEATS == true.

    @param callback function
]]
function Debug.cheat(callback)
    if (cheats) then
        callback()
    end
end

--[[--
    Prints a colored value on a location.

    @param value between -1 and 1
    @param surface LuaSurface
    @param position Position {x, y}
]]
function Debug.print_grid_value(value, surface, position)
    value = math.max(-1, math.min(1, value))
    local r = value
    local g = 1 - math.abs(value)
    local b = value

    if (r > 0) then
        r = 0
    end

    if (b < 0) then
        b = 0
    end

    r = math.abs(r)

    local color = { r = r, g = g, b = b}

    -- round at precision of 2
    local text = math.floor(100 * value) / 100

    if (0 == text) then
        text = '0.00'
    end

    local text_entity = surface.find_entity('flying-text', position)

    if text_entity then
        text_entity.text = text
        text_entity.color = color

        return
    end

    surface.create_entity{
        name = 'flying-text',
        color = color,
        text = text,
        position = position
    }.active = false
end

return Debug
