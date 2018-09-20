-- dependencies
local Event = require 'utils.event'

-- this
local StressMap = {}
local epsilon = 0.01

-- main block
global.stress_map_storage = {}
local defaultValue = 0
local _mt_y = { __index=function(tbl,key) tbl[key] = defaultValue return tbl[key] end}
local _mt_x = {__index=function(tbl,key) tbl[key] = setmetatable({},_mt_y) return rawget(tbl,key) end}

local function set_metatables()
    for _,map in ipairs(global.stress_map_storage) do
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


StressMap.events = {
    --[[--
        When stress at certain position changes
         - position LuaPosition
         - value Number
         - old_value Number
         - surface LuaSurface
    ]]
    on_stress_changed = script.generate_event_name()
}

--[[--
    Adds a fraction to a given location on the stress_map. Returns the new
    fraction value of that position.

    @param stress_map Table of {@see get_stress_map}
    @param position Table with x and y
    @param number fraction

    @return number sum of old fraction + new fraction
]]
function add_fraction(stress_map, position, fraction)

    local x = position.x
    local y = position.y
    local quadrant = 1
    if x < 0 then
      quadrant = quadrant + 1
      x = - x
    end
    if y <  0 then
      quadrant = quadrant + 2
      y = - y
    end


    --magic meta tables!
    local value = stress_map[quadrant][x][y] + fraction

    stress_map[quadrant][x][y] = value

    local surface = game.surfaces[stress_map.surface_index]

    script.raise_event(StressMap.events.on_stress_changed, {old_value = value - fraction, value = value, position = position, surface = surface})

    return value
end


--[[--
    Creates a new stress map if it doesn't exist yet and returns it.

    @param surface LuaSurface
    @return Table with maxed_values_buffer, [1,2,3,4] containing the quadrants
]]
local function get_stress_map(surface)
    if not global.stress_map_storage[surface.index] then

      global.stress_map_storage[surface.index] = {}

      local map = global.stress_map_storage[surface.index]

      map[1] = setmetatable({},_mt_x)
      map[2] = setmetatable({},_mt_x)
      map[3] = setmetatable({},_mt_x)
      map[4] = setmetatable({},_mt_x)

      map["surface_index"] = surface.index

      map.maxed_values_buffer = {}
    end

    return global.stress_map_storage[surface.index]
end


function StressMap.process_maxed_values_buffer(surface, callback)
    if ('table' ~= type(surface) or not surface.name) then
        error('StressMap.process_maxed_values_buffer argument #1 expects a LuaSurface, ' .. type(surface) .. ' given.')
    end
    if ('function' ~= type(callback)) then
        error('StressMap.process_maxed_values_buffer argument #2 expects a callback function, ' .. type(callback) .. ' given.')
    end

    local buffer = {}
    local map = get_stress_map(surface)
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
    @param number fraction to add to the given position on the surface increase or decreasing stress
]]
function StressMap.add(surface, position, fraction)
    if ('table' ~= type(surface) or nil == surface.name) then
        error('StressMap.set argument #1 expects a LuaSurface, ' .. type(surface) .. ' given.')
    end

    if ('table' ~= type(position) or nil == position.x or nil == position.y) then
        error('StressMap.set argument #2 expects a position with x and y, ' .. type(position) .. ' given.')
    end

    local stress_map = get_stress_map(surface)

    local new = add_fraction(stress_map, position, fraction)

    if (new >= 1 - epsilon) then
        table.insert(stress_map.maxed_values_buffer, position)
    end
end

return StressMap
