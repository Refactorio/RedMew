local Event = require 'utils.event'
local Utils = require 'utils.utils'
local Server = require 'server'
local Donators = require 'resources.donators'
local Game = require 'utils.game'
local Token = require 'utils.global_token'

global.regulars = {}
global.donators = Donators.donators

local Module = {}

Module.is_regular =
    function(player_name)
    return Utils.cast_bool(global.regulars[player_name] or global.regulars[player_name:lower()]) --to make it backwards compatible
end

Module.add_regular = function(player_name)
    local actor = Utils.get_actor()

    if (Module.is_regular(player_name)) then
        Game.player_print(player_name .. ' is already a regular.')
    else
        global.regulars[player_name] = true
        Server.set_data('regulars', player_name, true)
        game.print(actor .. ' promoted ' .. player_name .. ' to regular.')
    end
end

Module.remove_regular = function(player_name)
    local actor = Utils.get_actor()

    if (Module.is_regular(player_name)) then
        global.regulars[player_name] = nil
        Server.set_data('regulars', player_name, nil)
        game.print(player_name .. ' was demoted from regular by ' .. actor .. '.')
    else
        Game.player_print(player_name .. ' is not a regular.')
    end
end

local sync_regulars_callback =
    Token.register(
    function(data)
        global.regulars = data.entries
    end
)

function Module.sync_regulars()
    Server.try_get_all_data('regulars', sync_regulars_callback)
end

Module.print_regulars = function()
    local result = {}
    for k, _ in pairs(global.regulars) do
        table.insert(result, k)
    end

    result = table.concat(result, ', ')
    game.print(result)
end

function Module.get_rank(player)
    if player.admin then
        return 'Admin'
    elseif Module.is_regular(player.name) then
        return 'Regular'
    else
        return 'Guest'
    end
end

function Module.is_donator(player_name)
    return global.donators[player_name] ~= nil
end

function Module.player_has_donator_perk(player_name, perk_flag)
    local d = global.donators[player_name]
    if not d then
        return false
    end

    local flags = d.perk_flags
    if not flags then
        return false
    end

    return bit32.band(flags, perk_flag) == perk_flag
end

function Module.get_donator_welcome_message(player_name)
    local d = global.donators[player_name]
    if not d then
        return nil
    end

    return d.welcome_messages
end

function Module.set_donator(player_name, data)
    global.donators[player_name] = data
    Server.set_data('donators', player_name, data)
end

local sync_donators_callback =
    Token.register(
    function(data)
        global.donators = data.entries
    end
)

function Module.sync_donators()
    Server.try_get_all_data('donators', sync_donators_callback)
end

function Module.print_donators()
    local result = {}

    for k, _ in pairs(global.donators) do
        table.insert(result, k)
    end

    result = table.concat(result, ', ')
    game.print(result)
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local correctCaseName = Game.get_player_by_index(event.player_index).name
        local lowerCaseName = correctCaseName:lower()
        if correctCaseName ~= lowerCaseName and global.regulars[lowerCaseName] then
            global.regulars[lowerCaseName] = nil
            global.regulars[correctCaseName] = true
            Server.set_data('regulars', lowerCaseName, nil)
            Server.set_data('regulars', correctCaseName, true)
        end
    end
)

Event.add(
    Server.events.on_server_started,
    function()
        Module.sync_regulars()
        Module.sync_donators()
    end
)

Server.on_data_set_changed(
    'regulars',
    function(data)
        global.regulars[data.key] = data.value
    end
)

Server.on_data_set_changed(
    'donators',
    function(data)
        global.donators[data.key] = data.value
    end
)

return Module
