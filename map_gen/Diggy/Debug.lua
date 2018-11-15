-- dependencies
local min = math.min
local max = math.max
local floor = math.floor
local abs = math.abs

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
    Shows the given message if debug is enabled.

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
    Shows the given message with serpent enabled, if debug is enabled.

    @param message string
]]
function Debug.print_serpent(message)
    Debug.print(serpent.line(message))
end

--[[--
    Shows the given message if _DEBUG == true for a given position.

    @param x number
    @param y number
    @param message string
]]
function Debug.print_position(position, message)
    message = message or ''
    if type(message) ~= 'string' and type(message) ~= 'number'  and type(message) ~= 'boolean' then message = type(message) end
    global.message_count = global.message_count + 1
    if (debug) then
        game.print('[' .. global.message_count .. '] {x=' .. position.x .. ', y=' .. position.y .. '} ' .. tostring(message))
    end
end

--[[--
    Executes the given callback if cheating is enabled.

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
    @param scale float
    @param offset float
    @param immutable bool if immutable, only set, never do a surface lookup, values never change
]]
function Debug.print_grid_value(value, surface, position, scale, offset, immutable)
    local is_string = type(value) == 'string'
    local color = {r = 1, g = 1, b = 1}
    text = value

    if type(immutable) ~= 'boolean' then
        immutable = false
    end
    
    if not is_string then
        scale = scale or 1
        offset = offset or 0
        position = {x = position.x + offset, y = position.y + offset}
        local r = max(1, value) / scale
        local g = 1 - abs(value) / scale
        local b = min(1, value) / scale

        if (r > 0) then
            r = 0
        end

        if (b < 0) then
            b = 0
        end

        if (g < 0) then
            g = 0
        end

        r = abs(r)

        color = { r = r, g = g, b = b}

        -- round at precision of 2
        text = floor(100 * value) * 0.01

        if (0 == text) then
            text = '0.00'
        end
    end

    if not immutable then
        local text_entity = surface.find_entity('flying-text', position)

        if text_entity then
            text_entity.text = text
            text_entity.color = color
            return
        end
    end

    surface.create_entity{
        name = 'flying-text',
        color = color,
        text = text,
        position = position
    }.active = false
end

--[[--
    Prints a colored value on a location. When given a color_value and a delta_color,
    will change the color of the text from the base to base + value * delta. This will
    make the color of the text range from 'base_color' to 'base_color + delta_color'
    as the color_value ranges from 0 to 1

    @param value of number to be displayed
    @param surface LuaSurface
    @param position Position {x, y}
    @param scale float
    @param offset float position offset
    @param immutable bool if immutable, only set, never do a surface lookup, values never change
    @param color_value float How far along the range of values of colors the value is to be displayed
    @param base_color {r,g,b} The color for the text to be if color_value is 0
    @param delta_color {r,g,b} The amount to correct the base_color if color_value is 1
    @param under_bound {r,g,b} The color to be used if color_value < 0
    @param over_bound {r,g,b} The color to be used if color_value > 1
]]
function Debug.print_colored_grid_value(value, surface, position, scale, offset, immutable,
        color_value, base_color, delta_color, under_bound, over_bound)
    local is_string = type(value) == 'string'
    -- default values:
    local color = base_color or {r = 1, g = 1, b = 1}
    local d_color = delta_color or {r = 0, g = 0, b = 0}
    local u_color = under_bound or color
    local o_color = over_bound or color
    
    if (color_value < 0) then
        color = u_color
    elseif (color_value > 1) then
        color = o_color
    else
        color = { r = color.r + color_value * d_color.r,
                  g = color.g + color_value * d_color.g,
                  b = color.b + color_value * d_color.b }
    end
    
    text = value

    if type(immutable) ~= 'boolean' then
        immutable = false
    end

    if not is_string then
        offset = offset or 0
        position = {x = position.x + offset, y = position.y + offset}

        -- round at precision of 2
        text = floor(100 * value) * 0.01

        if (0 == text) then
            text = '0.00'
        end
    end

    if not immutable then
        local text_entity = surface.find_entity('flying-text', position)

        if text_entity then
            text_entity.text = text
            text_entity.color = color
            return
        end
    end

    surface.create_entity{
        name = 'flying-text',
        color = color,
        text = text,
        position = position
    }.active = false
end

return Debug
