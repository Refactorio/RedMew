local Color = require 'resources.color_presets'
local type = type
local tonumber = tonumber
local tostring = tostring
local gmatch = string.gmatch
local pairs = pairs
local concat = table.concat
local size = table.size
local sqrt = math.sqrt
local floor = math.floor

local color_key_table = {'r', 'g', 'b', 'a'}

local function raw(input)
    return input
end

local function color_toScalar(input)
    if type(input) ~= 'table' then
        return ''
    end

    local out = {}
    local i = 0
    for _, value in pairs(input) do
        i = i + 1
        out[i] = value
    end

    return concat(out, ' ')
end

--- accepts either a table or a string
--- string must be in an "r g b" or "r g b a" format
--- optionally a preset name may be given instead (from resources/color_presets.lua)
--- table must contain the "r", "g" and "b" keys and may optionally contain an "a" key
--- the output will always be a valid color table for Factorio
local function color_sanitizer(input)
    if input == nil or input == '' then
        return true, nil
    end

    local input_type = type(input)

    if input_type == 'string' then
        local color = Color[input]
        if color and tonumber(input) == nil then
            -- we have some numeric keys in there
            return true, color
        end

        local data = {}
        local index = 0
        for value in gmatch(input, '%S+') do
            index = index + 1
            if index < 5 then
                value = tonumber(value)
                if value == nil or value < 0 or value > 255 then
                    return false, {'redmew_settings_util.color_invalid_string_value'}
                end

                data[color_key_table[index]] = value
            end
        end

        if size(data) < 3 then
            return false, {'redmew_settings_util.color_invalid_string_value'}
        end

        return true, data
    end

    if input_type == 'table' then
        if size(input) > 4 or not input.r or not input.g or not input.b then
            return false, {'redmew_settings_util.color_invalid_table_value'}
        end

        local data = {
            r = input.r,
            g = input.g,
            b = input.b
        }
        if input.a then
            data.a = input.a
        end

        return true, data
    end

    return false, {'redmew_settings_util.invalid_color_value'}
end

--- Contains a set of callables that will attempt to sanitize and transform the input
--- sanitizer = takes any raw input and converts it to the final value used and stored
--- to_string = takes stored input and converts it to its string representation
return {
    fraction = {
        toScalar = raw,
        sanitizer = function(input)
            input = tonumber(input)

            if input == nil then
                return false, {'redmew_settings_util.fraction_invalid_value'}
            end

            if input < 0 then
                input = 0
            end

            if input > 1 then
                input = 1
            end

            return true, input
        end
    },
    string = {
        toScalar = raw,
        sanitizer = function(input)
            if input == nil then
                return true, ''
            end

            local input_type = type(input)
            if input_type == 'string' then
                return true, input
            end

            if input_type == 'number' or input_type == 'boolean' then
                return true, tostring(input)
            end

            return false, {'redmew_settings_util.string_invalid_value'}
        end
    },
    boolean = {
        toScalar = raw,
        sanitizer = function(input)
            local input_type = type(input)

            if input_type == 'boolean' then
                return true, input
            end

            if input_type == 'string' then
                if input == '0' or input == '' or input == 'false' or input == 'no' then
                    return true, false
                end
                if input == '1' or input == 'true' or input == 'yes' then
                    return true, true
                end

                return true, tonumber(input) ~= nil
            end

            if input_type == 'number' then
                return true, input ~= 0
            end

            return false, {'redmew_settings_util.boolean_invalid_value'}
        end
    },
    color = {
        toScalar = color_toScalar,
        sanitizer = color_sanitizer
    },
    chat_color = {
        toScalar = color_toScalar,
        sanitizer = function(input)
            local suc, value = color_sanitizer(input)
            if not suc then
                return false, value
            end

            local r, g, b = value.r, value.g, value.b
            local brightness = sqrt(0.241 * r * r + 0.691 * g * g, 0.068 * b * b)
            brightness = floor(brightness)

            if brightness < 50 then
                return false, {'redmew_settings_util.chat_color_too_dark'}
            end

            return true, value
        end
    }
}
