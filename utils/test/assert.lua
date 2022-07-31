local table = require 'utils.table'
local error = error
local concat = table.concat

local Public = {}

local function append_optional_message(main_message, optional_message)
    if optional_message then
        return concat {main_message, ' - ', optional_message}
    end
    return main_message
end

function Public.equal(a, b, optional_message)
    if a == b then
        return
    end

    local message = {tostring(a), ' ~= ', tostring(b)}
    if optional_message then
        message[#message + 1] = ' - '
        message[#message + 1] = optional_message
    end

    message = concat(message)
    error(message, 2)
end

function Public.is_nil(value, optional_message)
    if value == nil then
        return
    end

    local message = {tostring(value), ' was not nil'}
    if optional_message then
        message[#message + 1] = ' - '
        message[#message + 1] = optional_message
    end

    message = concat(message)
    error(message, 2)
end

function Public.table_equal(a, b)
    -- Todo write own table equal
    if not table.equals(a, b) then
        error('tables not equal', 2)
    end
end

function Public.array_contains(array, item)
    for _, v in pairs(array) do
        if v == item then
            return
        end
    end

    error('array does not contain ' .. _G.dump(item), 2)
end

function Public.is_true(condition, optional_message)
    if not condition then
        error(optional_message or 'condition was not true', 2)
    end
end

function Public.valid(lua_object, optional_message)
    if not lua_object then
        error(append_optional_message('lua_object was nil', optional_message), 2)
    end

    if not lua_object.valid then
        error(append_optional_message('lua_object was not valid', optional_message), 2)
    end
end

function Public.is_lua_object_with_name(lua_object, name, optional_message)
    Public.valid(lua_object, optional_message)

    if lua_object.name ~= name then
        error(append_optional_message("lua_object did not have name '" .. tostring(name) .. "'", optional_message), 2)
    end
end

return Public
