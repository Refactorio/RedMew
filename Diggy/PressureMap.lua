-- dependencies
local Event = require 'utils.event'

-- this
local PressureMap = {}

-- main block
global.pressure_map_storage = {}
local defaultValue = 1
local _mt_y = { __index=function(tbl,key) tbl[key] = defaultValue return tbl[key] end}
local _mt_x = {__index=function(tbl,key) tbl[key] = setmetatable({},_mt_y) return rawget(tbl,key) end}

local function set_metatables() 
    for _,map in pairs(global.pressure_map_storage) do
        for _,quad in pairs(map) do
            setmetatable(quad,_mt_x)
            for _,stbl in pairs(quad) do
                setmetatable(stbl,_mt_y)
            end
        end
    end
end


Event.on_init(set_metatables)
Event.on_load(set_metatables)


--[[--
    Adds a fraction to a given location on the pressure_map. Returns the new
    fraction value of that position.

    @param pressure_map Table of {@see get_pressure_map}
    @param position Table with x and y
    @param number fraction

    @return number sum of old fraction + new fraction
]]
function add_fraction(pressure_map, position, fraction)

    local map
    if position.x >= 0 then
        if position.y >= 0 then
            map = pressure_map.quadrant1
        else
            map = pressure_map.quadrant4
        end
    else
        if position.y >= 0 then
            map = pressure_map.quadrant2
        else
            map = pressure_map.quadrant3
        end
    end

    --magic meta tables!
    local value = map[position.x][position.y] + fraction

    map[position.x][position.y] = value

    return value
end

--[[--
    Creates a new pressure map if it doesn't exist yet and returns it.

    @param surface LuaSurface
    @return Table with maxed_values_buffer, quadrant1, quadrant2, quadrant3 and quadrant4
]]
local function get_pressure_map(surface)
    if not global.pressure_map_storage[surface.index] then

      global.pressure_map_storage[surface.index] = {}

      local map = global.pressure_map_storage[surface.index]

      map.quadrant1 = setmetatable({},_mt_x)
      map.quadrant2 = setmetatable({},_mt_x)
      map.quadrant3 = setmetatable({},_mt_x)
      map.quadrant4 = setmetatable({},_mt_x)

      map.maxed_values_buffer = {}
    end

    return global.pressure_map_storage[surface.index]
end

function PressureMap.process_maxed_values_buffer(surface, callback)
    if ('table' ~= type(surface) or not surface.name) then
        error('PressureMap.process_maxed_values_buffer argument #1 expects a LuaSurface, ' .. type(surface) .. ' given.')
    end
    if ('function' ~= type(callback)) then
        error('PressureMap.process_maxed_values_buffer argument #2 expects a callback function, ' .. type(callback) .. ' given.')
    end

    local buffer = {}
    local map = get_pressure_map(surface)
    for _, position in pairs(map.maxed_values_buffer) do
        table.insert(buffer, position)
    end

    -- empty before callback to avoid recursion
    map.maxed_values_buffer = {}

    callback(buffer)
end

--[[--
    @param surface LuaSurface
    @param position Position with x and y
    @param number fraction to add to the given position on the surface increase or decreasing pressure
]]
function PressureMap.add(surface, position, fraction)
    if ('table' ~= type(surface) or nil == surface.name) then
        error('PressureMap.set argument #1 expects a LuaSurface, ' .. type(surface) .. ' given.')
    end

    if ('table' ~= type(position) or nil == position.x or nil == position.y) then
        error('PressureMap.set argument #2 expects a position with x and y, ' .. type(position) .. ' given.')
    end

    local pressure_map = get_pressure_map(surface)

    local new = add_fraction(pressure_map, position, fraction)

    if (new >= 1 ) then
        table.insert(pressure_map.maxed_values_buffer, position)
    end
end

return PressureMap
