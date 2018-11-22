local Module = {}
local Game = require 'utils.game'
local prefix = '## - '

Module.distance = function(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    return math.sqrt(dx * dx + dy * dy)
end

Module.print_except = function(msg, player)
    for _, p in pairs(game.players) do
        if p.connected and p ~= player then
            p.print(msg)
        end
    end
end

-- Takes a LuaPlayer or string as source
Module.print_admins = function(msg, source)
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
    print(string.format('%s(ADMIN) %s: %s', prefix, source_name, msg)) -- to the server
    for _, p in pairs(game.connected_players) do
        if p.admin then
            p.print(string.format('%s(ADMIN) %s: %s', prefix, source_name, msg), chat_color)
        end
    end
end

Module.get_actor = function()
    if game.player then
        return game.player.name
    end
    return '<server>'
end

Module.cast_bool = function(var)
    if var then
        return true
    else
        return false
    end
end

Module.find_entities_by_last_user = function(player, surface, filters)
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

Module.ternary = function(c, t, f)
    if c then
        return t
    else
        return f
    end
end

local minutes_to_ticks = 60 * 60
local hours_to_ticks = 60 * 60 * 60
local ticks_to_minutes = 1 / minutes_to_ticks
local ticks_to_hours = 1 / hours_to_ticks
Module.format_time = function(ticks)
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

Module.cant_run = function(name)
    Game.player_print("Can't run command (" .. name .. ') - insufficient permission.')
end

Module.log_command = function(user, command, parameters)
    local name

    -- We can use a LuaPlayer or a string (ex. "Server").
    if type(user) == 'string' then
        name = user
    else
        name = user.name
    end
    local action = table.concat {'[Admin-Command] ', name, ' used: ', command}
    if parameters then
        action = table.concat {'[Admin-Command] ', name, ' used: ', command, ' ', parameters}
    end
    log(action)
end

Module.comma_value = function(n) -- credit http://richard.warburton.it
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

return Module
