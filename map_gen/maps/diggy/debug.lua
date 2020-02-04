-- dependencies
local BaseDebug = require 'utils.debug'
local Color = require 'resources.color_presets'

local min = math.min
local max = math.max
local floor = math.floor
local abs = math.abs

-- this
local Debug = {}

local default_base_color = Color.white
local default_delta_color = Color.black

---@deprecated use 'utils.debug'.print instead
function Debug.print(message)
    BaseDebug.print(message)
end

---@deprecated use 'utils.debug'.print_position instead
function Debug.print_position(position, message)
    BaseDebug.print_position(position, message)
end

---@deprecated use 'utils.debug'.cheat instead
function Debug.cheat(callback)
    BaseDebug.cheat(callback)
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
    local color = default_base_color
    local text = value

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
    @param offset float position offset
    @param immutable bool if immutable, only set, never do a surface lookup, values never change
    @param color_value float How far along the range of values of colors the value is to be displayed
    @param base_color {r,g,b} The color for the text to be if color_value is 0
    @param delta_color {r,g,b} The amount to correct the base_color if color_value is 1
    @param under_bound {r,g,b} The color to be used if color_value < 0
    @param over_bound {r,g,b} The color to be used if color_value > 1
]]
function Debug.print_colored_grid_value(value, surface, position, offset, immutable,
        color_value, base_color, delta_color, under_bound, over_bound)
    local is_string = type(value) == 'string'
    -- default values:
    local color = base_color or default_base_color
    local d_color = delta_color or default_delta_color
    local u_color = under_bound or color
    local o_color = over_bound or color

    if (color_value < 0) then
        color = u_color
    elseif (color_value > 1) then
        color = o_color
    else
        color = {
            r = color.r + color_value * d_color.r,
            g = color.g + color_value * d_color.g,
            b = color.b + color_value * d_color.b
        }
    end

    local text = value

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
