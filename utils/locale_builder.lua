local type = type
local tostring = tostring
local setmetatable = setmetatable
local getmetatable = getmetatable

--- Helper class for concatenating LocalisedStrings / strings.
-- strings and LocalisedStrings can be combined in any order.
-- Multiple calls to add will automatically split the LocalisedStrings into a linked list
-- when needed to prevent exceeding 20 parameter limit imposed by Factorio.
-- However, if you pass in LocalisedStrings that exceeds 20 parameters then it will fail.
--
-- @usage
--  LocaleBuilder = require 'utils.locale_builder'
--
--  local locale_string = LocaleBuilder({'common.fail_no_target', 'player_name'})
--      :add({'', '- a literal string'})
--      :add('- short hand for literal string')
--      :add(3):add(true) -- also works if convertable to string
--
-- Or construct multiple LocalisedStrings in parts and combine them.
-- local part1 = {'', 'part', ' ', 'one'}
-- local part2 = LocaleBuilder('part'):add(' '):add('two')
-- local part3 = LocaleBuilder('part'):add(' '):add('three')
--
-- local result = LocaleBuilder(part1):add(part2):add(part3)
--
-- If you store the LocalisedStrings in global, when you fetch from global you need to restore
-- the metatable to be able to use :add calls. To do that use
-- LocaleBuilder(global.stored_locale_string)
local Public = {}

local add

local function set_tail(self, tail)
    local mt = getmetatable(self)
    mt.tail = tail
end

local function new(obj)
    local mt = {add = add, tail = nil}
    mt.__index = mt

    return setmetatable(obj, mt)
end

local function localise(item)
    local t = type(item)
    if t == 'table' then
        return item
    elseif t == 'string' then
        return {'', item}
    else
        return {'', tostring(item)}
    end
end

function add(self, item)
    if item == nil then
        item = self
        self = nil
    end

    item = localise(item)

    if not self then
        return new(item)
    end

    local tail = self.tail
    if not tail then
        if self[1] == '' then
            tail = self
        else
            tail = {'', self}
            self = new(tail)
            set_tail(self, tail)
        end
    end

    local count = #tail
    if count < 20 then
        tail[count + 1] = item
    else
        local new_tail = {'', item}
        tail[count + 1] = new_tail
        set_tail(self, new_tail)
    end

    return self
end

Public.add = add

function Public.__call(_, item)
    if item == nil then
        item = {''}
    end

    return add(nil, item)
end

function Public.new(item)
    if item == nil then
        item = {''}
    end

    return add(nil, item)
end

setmetatable(Public, Public)

return Public
