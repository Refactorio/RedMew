local Gui = require 'utils.gui'

local gui_names = Gui.names
local type = type
local concat = table.concat
local inspect = table.inspect
local pcall = pcall

local Public = {}

local luaObject = {'{', nil, ", name = '", nil, "'}"}
local luaPlayer = {"{LuaPlayer, name = '", nil, "', index = ", nil, '}'}
local luaEntity = {"{LuaEntity, name = '", nil, "', unit_number = ", nil, '}'}
local luaGuiElement = {"{LuaGuiElement, name = '", nil, "'}"}

local function get_name_safe_inner(obj)
    return obj.name
end

local function get_name_safe(obj)
    local s, r = pcall(get_name_safe_inner, obj)
    if not s then
        return 'nil'
    else
        return r or 'nil'
    end
end

local function inspect_process(item)
    if type(item) ~= 'table' or not item.__self then
        return item
    end

    if not item.valid then
        return '{Invalid LuaObject}'
    end

    local help = item.help
    if not help then
        return '{Invalid LuaObject}'
    end

    local obj_type = help():match('Lua%a+')
    if obj_type == 'LuaPlayer' then
        luaPlayer[2] = item.name or 'nil'
        luaPlayer[4] = item.index or 'nil'

        return concat(luaPlayer)
    elseif obj_type == 'LuaEntity' then
        luaEntity[2] = item.name or 'nil'
        luaEntity[4] = item.unit_number or 'nil'

        return concat(luaEntity)
    elseif obj_type == 'LuaGuiElement' then
        local name = item.name
        luaGuiElement[2] = gui_names[name] or name or 'nil'

        return concat(luaGuiElement)
    else
        luaObject[2] = obj_type
        luaObject[4] = get_name_safe(item)

        return concat(luaObject)
    end
end

local inspect_options = {process = inspect_process}
function Public.dump(data)
    return inspect(data, inspect_options)
end
local dump = Public.dump

function Public.dump_ignore_builder(ignore)
    local function process(item)
        if ignore[item] then
            return nil
        end

        return inspect_process(item)
    end

    local options = {process = process}
    return function(data)
        return inspect(data, options)
    end
end

function Public.dump_function(func)
    local res = {'upvalues:\n'}

    local i = 1
    while true do
        local n, v = debug.getupvalue(func, i)

        if n == nil then
            break
        elseif n ~= '_ENV' then
            res[#res + 1] = n
            res[#res + 1] = ' = '
            res[#res + 1] = dump(v)
            res[#res + 1] = '\n'
        end

        i = i + 1
    end

    return concat(res)
end

return Public
