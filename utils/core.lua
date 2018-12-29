-- Dependencies
local Game = require 'utils.game'

-- localized functions
local random = math.random

-- local constants
local prefix = '## - '
local minutes_to_ticks = 60 * 60
local hours_to_ticks = 60 * 60 * 60
local ticks_to_minutes = 1 / minutes_to_ticks
local ticks_to_hours = 1 / hours_to_ticks

-- local vars
local Module = {}

--- Measures distance between pos1 and pos2
function Module.distance(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    return math.sqrt(dx * dx + dy * dy)
end

--- Takes msg and prints it to all players except provided player
function Module.print_except(msg, player)
    for _, p in pairs(game.connected_players) do
        if p ~= player then
            p.print(msg)
        end
    end
end

--- Prints a message to all online admins
--@param1 The message to print, as a string
--@param2 The source of the message, as a string, LuaPlayer, or nil.
function Module.print_admins(msg, source)
    local source_name
    local chat_color
    if source then
        if type(source) == 'string' then
            source_name = source
            chat_color = game.players[source].chat_color
        else
            source_name = source.name
            chat_color = source.chat_color
        end
    else
        source_name = 'Server'
        chat_color = {r = 255, g = 255, b = 255}
    end
    local formatted_msg = string.format('%s(ADMIN) %s: %s', prefix, source_name, msg) -- to the server
    print(formatted_msg)
    for _, p in pairs(game.connected_players) do
        if p.admin then
            p.print(formatted_msg, chat_color)
        end
    end
end

--- Returns a valid string with the name of the actor of a command.
function Module.get_actor()
    if game.player then
        return game.player.name
    end
    return '<server>'
end

function Module.cast_bool(var)
    if var then
        return true
    else
        return false
    end
end

function Module.find_entities_by_last_user(player, surface, filters)
    if type(player) == 'string' or not player then
        error("bad argument #1 to '" .. debug.getinfo(1, 'n').name .. "' (number or LuaPlayer expected, got " .. type(player) .. ')', 1)
        return
    end
    if type(surface) ~= 'table' and type(surface) ~= 'number' then
        error("bad argument #2 to '" .. debug.getinfo(1, 'n').name .. "' (number or LuaSurface expected, got " .. type(surface) .. ')', 1)
        return
    end
    local entities = {}
    local filter = filters or {}
    if type(surface) == 'number' then
        surface = game.surfaces[surface]
    end
    if type(player) == 'number' then
        player = Game.get_player_by_index(player)
    end
    filter.force = player.force.name
    for _, e in pairs(surface.find_entities_filtered(filter)) do
        if e.last_user == player then
            table.insert(entities, e)
        end
    end
    return entities
end

function Module.ternary(c, t, f)
    if c then
        return t
    else
        return f
    end
end

--- Takes a time in ticks and returns a string with the time in format "x hour(s) x minute(s)"
function Module.format_time(ticks)
    local result = {}

    local hours = math.floor(ticks * ticks_to_hours)
    if hours > 0 then
        ticks = ticks - hours * hours_to_ticks
        table.insert(result, hours)
        if hours == 1 then
            table.insert(result, 'hour')
        else
            table.insert(result, 'hours')
        end
    end

    local minutes = math.floor(ticks * ticks_to_minutes)
    table.insert(result, minutes)
    if minutes == 1 then
        table.insert(result, 'minute')
    else
        table.insert(result, 'minutes')
    end

    return table.concat(result, ' ')
end

--- Prints a message letting the player know they cannot run a command
-- @param name string name of the command
function Module.cant_run(name)
    Game.player_print("Can't run command (" .. name .. ') - insufficient permission.')
end

--- Logs the use of a command and its user
-- @param actor string with the actor's name (usually acquired by calling get_actor)
-- @param command the command's name as table element
-- @param parameters the command's parameters as a table (optional)
function Module.log_command(actor, command, parameters)
    local action = table.concat {'[Admin-Command] ', actor, ' used: ', command}
    if parameters then
        action = table.concat {action, ' ', parameters}
    end
    log(action)
end

function Module.comma_value(n) -- credit http://richard.warburton.it
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

--- Asserts the argument is one of type arg_types
-- @param arg the variable to check
-- @param arg_types the type as a table of sings
-- @return boolean
function Module.verify_mult_types(arg, arg_types)
    for _, arg_type in pairs(arg_types) do
        if type(arg) == arg_type then
            return true
        end
    end
    return false
end

--- Returns a random RGB color as a table
function Module.random_RGB()
    return {r = random(0, 255), g = random(0, 255), b = random(0, 255)}
end

-- add utility functions that exist in base factorio/util
require 'util'

--- Moves a position according to the parameters given
-- Notice: only accepts cardinal directions as direction
-- @param position <table> table containing a map position
-- @param direction <defines.direction> north, east, south, west
-- @param distance <number>
-- @return <table> modified position
Module.move_position = util.moveposition


--- Takes a direction and gives you the opposite
-- @param direction <defines.direction> north, east, south, west, northeast, northwest, southeast, southwest
-- @return <number> representing the direction
Module.opposite_direction = util.oppositedirection

--- Takes the string of a module and returns whether is it available or not
-- @param name <string> the name of the module (ex. 'utils.core')
-- @return <boolean>
Module.is_module_available = util.ismoduleavailable

return Module
