--[[
    This module creates a file of just trapped lua errors. It is possible that this module misses errors, therefore it is advised
    that users also verify their server/game logs.
]]
-- Dependencies
local Timestamp = require 'utils.timestamp'

-- Localized functions
local floor = math.floor
local format = string.format
local insert = table.insert
local concat = table.concat
local pcall = pcall

-- Local constants
local minutes_to_ticks = 60 * 60
local hours_to_ticks = 60 * 60 * 60
local ticks_to_minutes = 1 / minutes_to_ticks
local ticks_to_hours = 1 / hours_to_ticks
local warning = '\n\n\n\nTHIS LOG IS NOT ALL-INCLUSIVE AND CAN MISS ERRORS. IF THERE ARE ANY SUSPICIONS OF ERRORS CHECK THE LOGS.\n\n\n\n'

-- Local vars
local Public = {
    server_time = {secs = nil, tick = 0}
}
local first_error = true

--- Copied from utils.core, turns ticks into a human-readable time.
local function format_time(ticks)
    local result = {}

    local hours = floor(ticks * ticks_to_hours)
    if hours > 0 then
        ticks = ticks - hours * hours_to_ticks
        insert(result, hours)
        if hours == 1 then
            insert(result, 'hour')
        else
            insert(result, 'hours')
        end
    end

    local minutes = floor(ticks * ticks_to_minutes)
    insert(result, minutes)
    if minutes == 1 then
        insert(result, 'minute')
    else
        insert(result, 'minutes')
    end

    return concat(result, ' ')
end

local function try_generate_report(str)
    local server_time = Public.server_time.secs

    local server_time_str = '(Server time: unavailable)'
    local file_name = 'redmew_errors.log'
    if server_time then
        server_time_str = format('(Server time: %s)', Timestamp.to_string(server_time))
        file_name = Timestamp.to_date_string(server_time) .. '_' .. file_name
    else
        game.write_file(file_name, '', false, 0)
    end

    if first_error then
        server_time_str = warning .. server_time_str
        first_error = nil
    end

    local tick = 'pre-game'
    if game then
        tick = format_time(game.tick)
    end
    tick = 'Time of error: ' .. tick

    local redmew_version = global.redmew_version or 'Unknown'
    redmew_version = 'RedMew version: ' .. redmew_version

    local output = concat({server_time_str, tick, redmew_version, str, '\n'}, '\n')

    game.write_file(file_name, output, true, 0)
end

--- Takes the given string and generates an entry in the error file.
function Public.generate_error_report(str)
    local success, err = pcall(try_generate_report, str)
    if not success then
        log(err)
    end
end

return Public
