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

local function to_valid_rgba_table(input_table)
    local output = {
        r = input_table.r or input_table[1] or 0,
        g = input_table.g or input_table[2] or 0,
        b = input_table.b or input_table[3] or 0,
        a = input_table.a or input_table[4],
    }

    if output.r <= 1 and output.g <= 1 and output.b <= 1 and (output.a and output.a <= 1 or not output.a) then
        output.r = floor(output.r * 255)
        output.g = floor(output.g * 255)
        output.b = floor(output.b * 255)

        if output.a and output.a <= 1 then
            output.a = floor(output.a * 255)
        end
    end

    return output
end

local function raw(input)
    return input
end

local function equals_by_value(a, b)
    return a == b
end

local function equals_by_table_values(a, b)
    if type(a) ~= 'table' or type(b) ~= 'table' then
        return a == b
    end

    if size(a) ~= size(b) then
        return false
    end

    for index, value in pairs(a) do
        local value_b = b[index]
        if value_b == nil or value ~= value_b then
            return false
        end
    end

    for index, value in pairs(b) do
        local value_a = a[index]
        if value_a == nil or value ~= value_a then
            return false
        end
    end

    return true
end

local function color_to_scalar(input)
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
        local color = Color[input:match('^%s*(.-)%s*$'):gsub(' ', '_')]
        if color then
            return true, to_valid_rgba_table(color)
        end

        local data = {}
        local index = 0
        for value in gmatch(input, '%S+') do
            index = index + 1
            if index < 5 then
                value = tonumber(value)
                if value == nil then
                    return false, {'redmew_settings_util.color_invalid_string_value'}
                end
                if value < 0 then
                    value = 0
                end
                if value > 255 then
                    value = 255
                end

                data[color_key_table[index]] = value
            end
        end

        if size(data) < 3 then
            return false, {'redmew_settings_util.color_invalid_string_value'}
        end

        return true, to_valid_rgba_table(data)
    end

    if input_type == 'table' then
        local table_size = size(input)
        if table_size < 3 or table_size > 4 then
            return false, {'redmew_settings_util.color_invalid_table_value'}
        end

        return true, to_valid_rgba_table({
                r = input.r,
                g = input.g,
                b = input.b,
                a = input.a,
            })
    end

    return false, {'redmew_settings_util.invalid_color_value'}
end

--- Contains a set of callables that will attempt to sanitize and transform the input
--- sanitizer = takes any raw input and converts it to the final value used and stored
--- to_string = takes stored input and converts it to its string representation
return {
    fraction = {
        equals = equals_by_value,
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
    integer = {
        equals = equals_by_value,
        toScalar = raw,
        sanitizer = function(input)
            input = tonumber(input)

            if input == nil then
                return false, {'redmew_settings_util.integer_invalid_value'}
            end

            return true, floor(input)
        end
    },
    positive_integer = {
        equals = equals_by_value,
        toScalar = raw,
        sanitizer = function(input)
            input = tonumber(input)

            if input == nil or input <= 0 then
                return false, {'redmew_settings_util.integer_invalid_value'}
            end

            return true, floor(input)
        end
    },
    string = {
        equals = equals_by_value,
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
        equals = equals_by_value,
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
        equals = equals_by_table_values,
        toScalar = color_to_scalar,
        sanitizer = color_sanitizer
    },
    chat_color = {
        equals = equals_by_table_values,
        toScalar = color_to_scalar,
        sanitizer = function(input)
            local suc, value = color_sanitizer(input)
            if not suc then
                return false, value
            end

            if not value then
                return true, nil
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
