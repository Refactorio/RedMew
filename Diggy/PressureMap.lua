-- dependencies

-- this
local PressureMap = {}

global.pressure_map_storage = {}

-- private state
local pressure_map_storage = global.pressure_map_storage

--[[--
    Adds a fraction to a given location on the pressure_map. Returns the new
    fraction value of that position.

    @param pressure_map Table of {@see get_pressure_map}
    @param position Table with x and y
    @param number fraction

    @return number sum of old fraction + new fraction
]]
local function add_fraction(pressure_map, position, fraction)
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

    if (not map[position.x]) then
        map[position.x] = {[position.y] = fraction}
        return fraction
    end

    if (not map[position.x][position.y]) then
        map[position.x][position.y] = fraction
        return fraction
    end

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
    if (nil == pressure_map_storage[surface.name]) then
        pressure_map_storage[surface.name] = {
            -- contains all coordinates that are at max pressure until cleared.
            maxed_values_buffer = {},

            -- map with coordinates, stored as [x][y] = fraction.
            quadrant1 = {},
            quadrant2 = {},
            quadrant3 = {},
            quadrant4 = {},
        }
    end

    return pressure_map_storage[surface.name]
end

function PressureMap.process_maxed_values_buffer(surface, callback)
    if ('table' ~= type(surface) or nil == surface.name) then
        error('PressureMap.process_maxed_values_buffer argument #1 expects a LuaSurface, ' .. type(surface) .. ' given.')
    end
    if ('function' ~= type(callback)) then
        error('PressureMap.process_maxed_values_buffer argument #2 expects a callback function, ' .. type(callback) .. ' given.')
    end

    local buffer = get_pressure_map(surface).maxed_values_buffer

    for _, position in pairs(buffer) do
        callback({x = position.x, y = position.y})
    end

    buffer = {}
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
        error('PressureMap.set argument #2 expects a position with x and y, ' .. type(surface) .. ' given.')
    end

    local pressure_map = get_pressure_map(surface)

    local new = add_fraction(pressure_map, position, fraction)
    require 'Diggy.Debug'.print(position.x .. ',' .. position.y .. ' :: ' .. fraction .. ' --> ' .. new)

    if (new >= 1 ) then
        require 'Diggy.Debug'.print(position.x .. ',' .. position.y .. ' :: ADDING TO BUFFER ' .. new)
        table.insert(pressure_map.maxed_values_buffer, position)
    end
end

return PressureMap
