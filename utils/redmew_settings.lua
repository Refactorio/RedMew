local Global = require 'utils.global'
local type = type
local error = error
local tonumber = tonumber
local tostring = tostring
local pairs = pairs
local format = string.format

--- Contains a set of callables that will attempt to sanitize and transform the input
local settings_type = {
    fraction = function (input)
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
    end,
    string = function (input)
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
    end,
    boolean = function (input)
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
    end,
}

local settings = {}
local memory = {}

Global.register(memory, function (tbl) memory = tbl end)

local Public = {}

Public.types = {fraction = 'fraction', string = 'string', boolean = 'boolean'}

---Register a specific setting with a sensitization setting type.
---
--- Available setting types:
--- - fraction (number between 0 and 1) in either number or string form
--- - string a string or anything that can be cast to a string
--- - boolean, 1, 0, yes, no, true, false or an empty string for false
---
--- This function must be called in the control stage, i.e. not inside an event.
---
---@param name string
---@param setting_type string
---@param default any
function Public.register(name, setting_type, default, localisation_key)
    if _LIFECYCLE ~= _STAGE.control then
        error(format('You can only register setting names in the control stage, i.e. not inside events. Tried setting "%s" with type "%s".', name, setting_type), 2)
    end

    if settings[name] then
        error(format('Trying to register setting for "%s" while it has already been registered.', name), 2)
    end

    local callback = settings_type[setting_type]
    if not callback then
        error(format('Trying to register setting for "%s" with type "%s" while this type does not exist.', name, setting_type), 2)
    end

    local setting = {
        type = setting_type,
        default = default,
        callback = callback,
        localisation_key = localisation_key,
    }

    settings[name] = setting

    return setting
end

---Validates whether a given value is valid for a given setting.
---@param name string
---@param value any
function Public.validate(name, value)
    local setting = settings[name]
    if not setting then
        return format('Setting "%s" does not exist.', name)
    end

    local success, sanitized_value = setting.callback(value)

    if not success then
        return sanitized_value
    end

    return nil
end

---Sets a setting to a specific value for a player.
---
---In order to get a setting value, it has to be registered via the "register" function.
---
---@param player_index number
---@param name string
---@param value any
function Public.set(player_index, name, value)
    local setting = settings[name]
    if not setting then
        error(format('Setting "%s" does not exist.', name), 2)
    end

    local success, sanitized_value = setting.callback(value)

    if not success then
        error(format('Setting "%s" failed: %s', name, sanitized_value), 2)
    end

    local player_settings = memory[player_index]
    if not player_settings then
        player_settings = {}
        memory[player_index] = player_settings
    end

    player_settings[name] = sanitized_value

    return sanitized_value
end

---Returns the value of a setting for this player.
---
---In order to set a setting value, it has to be registered via the "register" function.
---
---@param player_index number
---@param name string
function Public.get(player_index, name)
    local setting = settings[name]
    if not setting then
        return error(format('Setting "%s" does not exist.', name), 2)
    end

    local player_settings = memory[player_index]
    if not player_settings then
        return setting.default
    end

    local player_setting = player_settings[name]
    return player_setting ~= nil and player_setting or setting.default
end

---Returns a table of all settings for a given player in a key => value setup
---@param player_index number
function Public.all(player_index)
    local player_settings = memory[player_index] or {}
    local output = {}
    for name, data in pairs(settings) do
        output[name] = player_settings[name] or data.default
    end

    return output
end

---Returns the full settings data, note that this is a reference, do not modify
---this data unless you know what you're doing!
function Public.get_setting_metadata()
    return settings
end

return Public
