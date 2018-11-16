local Event = require 'utils.event'
local Utils = require 'utils.utils'
local Server = require 'server'
local Donators = require 'resources.donators'

global.regulars = {}
global.donators = Donators.donators
global.donator_welcome_messages = {}
local Game = require 'utils.game'

local Module = {}

local function update_file()
    local data = {'{\n'}
    for player_name, _ in pairs(global.regulars) do
        table.insert(data, '["')
        table.insert(data, player_name)
        table.insert(data, '"] = true,\n')
    end
    table.insert(data, '}')

    game.write_file('regulars.lua', table.concat(data), false, 0)
end

Module.is_regular =
    function(player_name)
    return Utils.cast_bool(global.regulars[player_name] or global.regulars[player_name:lower()]) --to make it backwards compatible
end

Module.add_regular =
    function(player_name)
    local actor = Utils.get_actor()
    if Module.is_regular(player_name) then
        Game.player_print(player_name .. ' is already a regular.')
    else
        if game.players[player_name] then
            player_name = game.players[player_name].name
            game.print(actor .. ' promoted ' .. player_name .. ' to regular.')
            global.regulars[player_name] = true
            update_file()
        else
            Game.player_print(player_name .. ' does not exist.')
        end
    end ]]
    global.regulars[player_name] = true
    game.print(actor .. ' promoted ' .. player_name .. ' to regular.')
    Server.regular_promote(player_name, actor)
end

Module.remove_regular =
    function(player_name)
    local actor = Utils.get_actor()
    --[[ if game.players[player_name] then
        player_name = game.players[player_name].name
        if Module.is_regular(player_name) then
            game.print(player_name .. ' was demoted from regular by ' .. actor .. '.')
        end
        global.regulars[player_name] = nil
        global.regulars[player_name:lower()] = nil --backwards compatible
        update_file()
    end ]]
    global.regulars[player_name] = nil
    game.print(player_name .. ' was demoted from regular by ' .. actor .. '.')
    Server.regular_deomote(player_name, actor)
end

function Module.server_add_regular(player_name)
    global.regulars[player_name] = true
end

function Module.server_remove_regular(player_name)
    global.regulars[player_name] = nil
end

function Module.sync_regulars(names)
    local r = {}
    for _, name in ipairs(names) do
        r[name] = true
    end

    global.regulars = r
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
    return global.donators[player_name]
end

function Module.player_has_donator_perk(player_name, perk_flag)
    local d = global.donators[player_name]
    if not d then
        return false
    end

    return bit32.band(d, perk_flag) == perk_flag
end

function Module.get_donator_welcome_message(player_name)
    return global.donator_welcome_messages[player_name]
end

function Module.set_donator(player_name, perks)
    global.donators[player_name] = perks
    Server.donator_set(player_name, perks)
end

function Module.sync_donators(donators, messages)
    global.donators = donators
    global.donator_welcome_messages = messages
end

function Module.server_set_donator(player_name, perks)
    global.donators[player_name] = perks
end

function Module.print_donators()
    local result = {}
    for k, v in pairs(global.donators) do
        table.insert(result, k)
        table.insert(result, ' : ')
        table.insert(result, v)
        table.insert(result, ', ')
    end
    table.remove(result)

    result = table.concat(result)
    game.print(result)
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local correctCaseName = Game.get_player_by_index(event.player_index).name
        if global.regulars[correctCaseName:lower()] and not global.regulars[correctCaseName] then
            global.regulars[correctCaseName:lower()] = nil
            global.regulars[correctCaseName] = true
            update_file()
        end
    end
)

return Module
