local Event = require 'utils.event'
local Game = require 'utils.game'
local Utils = require 'utils.core'
local Module = {}

global.player_spawns = {} -- player_index to spawn_name
global.spawns = {} -- spawn_name to x, y, player_online_count

Module.add_spawn = function(name, x, y)
    if type(name) ~= 'string' then
        game.print('name must be a string')
        return
    end

    if type(x) ~= 'number' then
        game.print('x must be a number')
        return
    end

    if type(y) ~= 'number' then
        game.print('y must be a number')
        return
    end

    global.spawns[name] = {x = x, y = y, count = 0}
end

local function get_min_count_spawn_name()
    local min = 1000000
    local min_spawn = nil

    for name, t in pairs(global.spawns) do
        local count = t.count
        if min > count then
            min = count
            min_spawn = name
        end
    end

    return min_spawn
end

local function player_joined_game(event)
    local index = event.player_index
    local spawn_name = global.player_spawns[index]

    -- player already has a spawn.
    if spawn_name then
        local spawn = global.spawns[spawn_name]
        local count = spawn.count
        spawn.count = count + 1
        return
    end

    spawn_name = get_min_count_spawn_name()

    if not spawn_name then
        return
    end

    local spawn = global.spawns[spawn_name]
    global.player_spawns[index] = spawn_name
    Game.get_player_by_index(index).teleport(spawn)

    local count = spawn.count
    spawn.count = count + 1
end

local function player_left_game(event)
    local index = event.player_index
    local spawn_name = global.player_spawns[index]
    local spawn = global.spawns[spawn_name]

    if not spawn then
        return
    end

    local count = spawn.count
    spawn.count = count - 1
end

local function player_respawned(event)
    local index = event.player_index
    local spawn_name = global.player_spawns[index]
    local spawn = global.spawns[spawn_name]

    if not spawn then
        return
    end

    Game.get_player_by_index(index).teleport(spawn)
end

local function tp_spawn(player_name, spawn_name)
    local player = Game.get_player_by_index(player_name)
    if not player then
        player_name = player_name or ''
        game.player.print('player ' .. player_name .. ' does not exist.')
        return
    end

    local spawn = global.spawns[spawn_name]
    if not spawn then
        spawn_name = spawn_name or ''
        game.player.print('spawn ' .. spawn_name .. ' does not exist.')
        return
    end

    player.teleport(spawn)
end

local function change_spawn(player_name, spawn_name)
    local new_spawn = global.spawns[spawn_name]

    if not new_spawn then
        spawn_name = spawn_name or ''
        game.player.print('spawn ' .. spawn_name .. ' does not exist.')
        return
    end

    local player = Game.get_player_by_index(player_name)

    if not player then
        player_name = player_name or ''
        game.player.print('player ' .. player_name .. ' does not exist.')
        return
    end

    local index = player.index
    local old_spawn_name = global.player_spawns[index]
    local old_spawn = global.spawns[old_spawn_name]

    if old_spawn then
        local count = old_spawn.count
        old_spawn.count = count - 1
    end

    local count = new_spawn.count
    new_spawn.count = count + 1

    global.player_spawns[index] = spawn_name

    game.player.print(player_name .. ' spawn moved to ' .. spawn_name)
end

local function print_spawns()
    for name, spawn in pairs(global.spawns) do
        game.player.print(string.format('%s: (%d, %d), player count = %d', name, spawn.x, spawn.y, spawn.count))
    end
end

local function print_players_for_spawn(target_spawn_name)
    if not global.spawns[target_spawn_name] then
        target_spawn_name = target_spawn_name or ''
        game.player.print('spawn ' .. target_spawn_name .. ' does not exist.')
        return
    end

    local str = ''
    for index, spawn_name in pairs(global.player_spawns) do
        if target_spawn_name == spawn_name then
            local player = Game.get_player_by_index(index)
            if player.connected then
                str = str .. player.name .. ', '
            end
        end
    end

    if str == '' then
        str = 'no players'
    end
    game.player.print(str)
end

local function tp_spawn_command(cmd)
    if not game.player.admin then
        Utils.cant_run(cmd.name)
        return
    end

    local params = cmd.parameter
    if type(params) ~= 'string' then
        game.player.print('Command failed. Usage: /tpspawn <player>, <spawn_name>')
        return
    end

    local ps = {}
    for p in params:gmatch('%S+') do
        table.insert(ps, p)
    end

    if #ps == 1 then
        tp_spawn(game.player.name, ps[1])
    else
        tp_spawn(ps[1], ps[2])
    end
end

local function change_spawn_command(cmd)
    if not game.player.admin then
        Utils.cant_run(cmd.name)
        return
    end

    local params = cmd.parameter
    if type(params) ~= 'string' then
        game.player.print('Command failed. Usage: /changespawn <player>, <spawn_name>')
        return
    end

    local ps = {}
    for p in params:gmatch('%S+') do
        table.insert(ps, p)
    end

    change_spawn(ps[1], ps[2])
end

local function print_spawns_command(cmd)
    if not game.player.admin then
        Utils.cant_run(cmd.name)
        return
    end

    print_spawns()
end

local function print_players_for_spawn_command(cmd)
    if not game.player.admin then
        Utils.cant_run(cmd.name)
        return
    end

    local params = cmd.parameter
    if type(params) ~= 'string' then
        game.player.print('Command failed. Usage: /playersforspawn <spawn_name>')
        return
    end

    local ps = {}
    for p in params:gmatch('%S+') do
        table.insert(ps, p)
    end

    print_players_for_spawn(ps[1])
end

Event.add(defines.events.on_player_joined_game, player_joined_game)
Event.add(defines.events.on_player_left_game, player_left_game)
Event.add(defines.events.on_player_respawned, player_respawned)

commands.add_command('tpspawn', '<player> <spawn_name> teleports a player to the spawn point (Admins only)', tp_spawn_command) -- luacheck: ignore
commands.add_command('changespawn', '<player> <spawn_name> changes the spawn point for a player (Admins only)', change_spawn_command) -- luacheck: ignore
commands.add_command('printspawns', 'prints info on all spawn points (Admins only)', print_spawns_command) -- luacheck: ignore
commands.add_command('printplayersforspawn', '<spawn_name> prints all the connected players for a spawn (Admins only)', print_players_for_spawn_command) -- luacheck: ignore

return Module
