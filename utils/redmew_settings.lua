local Global = require 'utils.global'
local Event = require 'utils.event'
local error = error
local pairs = pairs
local format = string.format
local tostring = tostring
local type = type
local raise_event = script.raise_event

--- Contains a set of callables that will attempt to sanitize and transform the input
local settings_type = require 'resources.setting_types'
local settings = {}
local memory = {}
local missing_setting = {
    data_transformation = {
        toScalar = function(input)
            if type(input) ~= 'table' then
                return input
            end

            return tostring(input)
        end,
        sanitizer = function (input)
            return true, input
        end
    }
}

Global.register(memory, function (tbl) memory = tbl end)

local Public = {}

Public.events = {
    --- Triggered when a setting is set or updated. Old value may be null if never set before
    --- if the value hasn't changed, value_changed = false
    -- Event {
    --        setting_name = setting_name,
    --        old_value = old_value,
    --        new_value = new_value,
    --        player_index = player_index,
    --        value_changed = value_changed
    --    }
    on_setting_set = Event.generate_event_name('on_setting_set'),
}

Public.types = {
    fraction = 'fraction',
    integer = 'integer',
    positive_integer = 'positive_integer',
    string = 'string',
    boolean = 'boolean',
    color = 'color',
    chat_color = 'chat_color'
}

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
---@param localisation_key|table
function Public.register(name, setting_type, default, localisation_key)
    if _LIFECYCLE ~= _STAGE.control then
        error(format('You can only register setting names in the control stage, i.e. not inside events. Tried setting "%s" with type "%s".', name, setting_type), 2)
    end

    if settings[name] then
        error(format('Trying to register setting for "%s" while it has already been registered.', name), 2)
    end

    local data_transformation = settings_type[setting_type]
    if not data_transformation then
        error(format('Trying to register data_transformation for "%s" with type "%s" while this type does not exist.', name, setting_type), 2)
    end

    local setting = {
        type = setting_type,
        default = default,
        data_transformation = data_transformation,
        locale_string = localisation_key and {localisation_key} or name,
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

    local success, sanitized_value = setting.data_transformation.sanitizer(value)

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
        setting = missing_setting
    end

    local data_transformation = setting.data_transformation
    local success, sanitized_value = data_transformation.sanitizer(value)

    if not success then
        error(format('Setting "%s" failed: %s', name, sanitized_value), 2)
    end

    local player_settings = memory[player_index]
    if not player_settings then
        player_settings = {}
        memory[player_index] = player_settings
    end

    local old_value = player_settings[name]
    player_settings[name] = sanitized_value

    raise_event(Public.events.on_setting_set, {
        setting_name = name,
        old_value = old_value,
        new_value = sanitized_value,
        player_index = player_index,
        value_changed = not data_transformation.equals(old_value, sanitized_value)
    })

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
        return nil
    end

    local player_settings = memory[player_index]
    if not player_settings then
        return setting.default
    end

    local player_setting = player_settings[name]
    if player_setting == nil then
        return setting.default
    end

    return player_setting
end

---Returns the string representation of a given value based on a setting name.
---
---@param name string
---@param raw_value any
function Public.toScalar(name, raw_value)
    local setting = settings[name]
    if not setting then
        setting = missing_setting
    end

    return setting.data_transformation.toScalar(raw_value)
end

---Returns a table of all settings for a given player in a key => value setup
---@param player_index number
function Public.all(player_index)
    local player_settings = memory[player_index] or {}
    local output = {}
    for name, data in pairs(settings) do
        local setting_value = player_settings[name]
        if setting_value == nil then
            output[name] = data.default
        else
            output[name] = setting_value
        end
    end

    -- not all settings might be mapped, edge-case is triggered when the
    -- server contains settings that are not known in this instance
    for name, value in pairs(player_settings) do
        if output[name] == nil then
            output[name] = value
        end
    end

    return output
end

---Removes a value for a setting for a given name, giving it the default value.
---
---@param player_index number
---@param name string
function Public.unset(player_index, name)
    local player_settings = memory[player_index]
    if not player_settings then
        player_settings = {}
        memory[player_index] = player_settings
    end

    local old_value = player_settings[name]
    player_settings[name] = nil

    raise_event(Public.events.on_setting_set, {
        setting_name = name,
        old_value = old_value,
        new_value = nil,
        player_index = player_index,
        value_changed = old_value ~= nil
    })
end

---Returns the full settings data, note that this is a reference, do not modify
---this data unless you know what you're doing!
function Public.get_setting_metadata()
    return settings
end

return Public
