-- For more info on the day/night cycle and examples of cycles see: https://github.com/Refactorio/RedMew/wiki/Day-Night-cycle
-- This module can be used in multiple ways: Public.fixed_brightness or Public.day_night_cycle can be set and this module will
-- set the brightness/cycle alternatively the set_cycle or set_fixed_brightness functions can be called to set cycle or brightness.
local Debug = require 'utils.debug'
local RS = require 'map_gen.shared.redmew_surface'
local Event = require 'utils.event'

local Public = {}
Public.fixed_brightness = nil

local day_night_cycle_keys = {
    'ticks_per_day',
    'dusk',
    'evening',
    'morning',
    'dawn'
}

Public.day_night_cycle = {
    ['ticks_per_day'] = 25000,
    ['dusk'] = 0.25,
    ['evening'] = 0.45,
    ['morning'] = 0.55,
    ['dawn'] = 0.75
}

--- Checks that a table has a valid day night cycle.
local function check_cycle_validity(day_night_cycle)
    for _, required_key in pairs(day_night_cycle_keys) do
        if not day_night_cycle[required_key] then
            return false
        end
    end

    if (day_night_cycle['dusk'] > day_night_cycle['evening']) or
    (day_night_cycle['evening'] > day_night_cycle['morning']) or
    (day_night_cycle['morning'] > day_night_cycle['dawn']) then
        return false
    else
        return true
    end
end

--- Sets the day/night cycle according to the table it is given.
-- @param day_night_cycle table containing keys: ticks_per_day, dusk, evening, morning, dawn
-- @param surface the LuaSurface to set the day/night cycle of
-- @returns boolean true if set properly
-- @see Venus::world_settings
Public.set_cycle = function(day_night_cycle, surface)
    if not check_cycle_validity(day_night_cycle) then
        error('Provided day/night cycle is invalid')
        return
    end
    if not surface.valid then
        error('Provided surface is invalid')
        return
    end
    if not Public.unfreeze_daytime then
        error('Time is frozen')
        return
    end

    surface.ticks_per_day = day_night_cycle.ticks_per_day
    surface.dusk = 0
    surface.evening = 0.001
    surface.morning = 0.002
    surface.dawn = day_night_cycle.dawn
    surface.morning = day_night_cycle.morning
    surface.evening = day_night_cycle.evening
    surface.dusk = day_night_cycle.dusk
    return true
end

--- Sets the brightness to a fixed level
-- @param daylight number between 0.15 and 1 representing the percentage of daylight (0.15 brightness is the darkest available)
-- @param surface the LuaSurface to set the day/night cycle of
-- @return boolean true if time is set properly
Public.set_fixed_brightness = function(daylight, surface)
    if not surface.valid then
        error('Provided surface is invalid')
        return
    end
    if daylight < 0.15 then
        error('Daylight set too low. 0.15 is the darkest available.')
        return
    elseif daylight > 1 then
        error('Daylight set too high. 1.00 is the lightest available.')
        return
    end

    -- Do some algebra to find the correct point in the daytime to freeze
    local brightness_slope = math.calculate_slope(surface.morning, 0.0, surface.dawn, 1)
    local y_intercept = math.calculate_y_intercept(surface.morning, 0.0, brightness_slope)
    local breakpoint = (daylight - y_intercept) / brightness_slope
    -- Set the daytime to the point we just calculated
    surface.daytime = breakpoint
    -- Freeze the day/night cycle
    surface.freeze_daytime = true

    Debug.print('breakpoint/surface_daytime: ' .. breakpoint .. '/' .. surface.daytime)
    Debug.print('brightness/surface_brightness: ' .. math.round(daylight, 2) .. '/' .. math.round((1 - surface.darkness), 2))

    if math.round(daylight, 2) == math.round((1 - surface.darkness), 2) then
        return true
    end
end

--- Unfreezes daytime (usually frozen by set_fixed_brightness)
-- @param surface the LuaSurface to unfreeze the day/night cycle of
-- @return boolean true if daytime unfrozen
Public.unfreeze_daytime = function(surface)
    if not surface.valid then
        error('Provided surface is invalid')
        return
    end
    surface.freeze_daytime = false
    return true
end

local function init()
    if Public.fixed_brightness then
        Public.set_fixed_brightness(Public.fixed_brightness, RS.get_surface())
    else
        Public.set_cycle(Public.day_night_cycle, RS.get_surface())
    end
end

Event.on_init(init)

return Public
