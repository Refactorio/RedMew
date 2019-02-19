-- For more info on the day/night cycle and examples of cycles see: https://github.com/Refactorio/RedMew/wiki/Day-Night-cycle
-- Dependencies
local Event = require 'utils.event'
local math = require 'utils.math'
local RS = require 'map_gen.shared.redmew_surface'

-- Localized global table
local config = global.config.day_night

-- Localized functions
local round = math.round
local format = string.format

-- Constants
local day_night_cycle_keys = {
    'ticks_per_day',
    'dusk',
    'evening',
    'morning',
    'dawn'
}

-- Local vars
local Public = {}

--- Checks that a table is a valid day night cycle.
local function check_cycle_validity(day_night_cycle)
    for _, required_key in pairs(day_night_cycle_keys) do
        if not day_night_cycle[required_key] then
            return false
        end
    end

    if (day_night_cycle['dusk'] > day_night_cycle['evening']) or (day_night_cycle['evening'] > day_night_cycle['morning']) or (day_night_cycle['morning'] > day_night_cycle['dawn']) then
        return false
    else
        return true
    end
end

--- On init, check the config settings
local function init()
    if config.use_day_night_cycle and config.use_fixed_brightness then
        error('Cannot use both a day/night cycle and a fixed brightness')
        return
    elseif config.use_day_night_cycle then
        Public.set_cycle(config.day_night_cycle, RS.get_surface())
    elseif config.use_fixed_brightness then
        Public.set_fixed_brightness(config.fixed_brightness, RS.get_surface())
    end
end

Event.on_init(init)

-- Public functions

--- Sets the day/night cycle according to the table it is given.
-- Can only be called during or after init.
-- @param day_night_cycle <table> containing specific, required keys: ticks_per_day, dusk, evening, morning, dawn
-- @param surface <LuaSurface> to set the day/night cycle of
-- @returns <boolean> true if set properly, nil if not
-- @see Venus::world_settings
function Public.set_cycle(day_night_cycle, surface)
    if not check_cycle_validity(day_night_cycle) then
        error('Provided day/night cycle is invalid')
        return
    end
    if not surface or not surface.valid then
        error('Provided surface is invalid')
        return
    end
    if not Public.unfreeze_daytime then
        error('Time is stuck in a frozen state')
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
-- Can only be called during or after init.
-- @param daylight <number> between 0.15 and 1 representing the percentage of daylight (0.15 brightness is the darkest available)
-- @param surface <LuaSurface> to set the day/night cycle of
-- @return <boolean> true if time is set properly, nil if not
function Public.set_fixed_brightness(daylight, surface)
    if not surface or not surface.valid then
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

    Debug.print(format('breakpoint/surface_daytime: %s/%s', breakpoint, surface.daytime))
    Debug.print(format('brightness/surface_brightness: %s/%s', round(daylight, 2), round((1 - surface.darkness), 2)))

    if round(daylight, 2) == round((1 - surface.darkness), 2) then
        return true
    end
end

--- Unfreezes daytime (usually frozen by set_fixed_brightness)
-- Can only be called during or after init.
-- @param surface <LuaSurface> to unfreeze the day/night cycle of
-- @return <boolean> true if daytime unfrozen, nil if not
function Public.unfreeze_daytime(surface)
    if not surface or not surface.valid then
        log('Provided surface is invalid')
        return
    end
    surface.freeze_daytime = false
    return true
end

return Public
