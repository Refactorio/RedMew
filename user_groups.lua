global.regulars = require 'resources.regulars'
local Donators = require 'resources.donators'
global.donators = Donators.donators
local Event = require 'utils.event'
local Utils = require 'utils.utils'

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
Module.add_regular = function(player_name)
    local actor = Utils.get_actor()
    if Module.is_regular(player_name) then
        player_print(player_name .. ' is already a regular.')
    else
        if game.players[player_name] then
            player_name = game.players[player_name].name
            game.print(actor .. ' promoted ' .. player_name .. ' to regular.')
            global.regulars[player_name] = true
            update_file()
        else
            player_print(player_name .. ' does not exist.')
        end
    end
end

Module.remove_regular =
    function(player_name)
    local actor = Utils.get_actor()
    if game.players[player_name] then
        player_name = game.players[player_name].name
        if Module.is_regular(player_name) then
            game.print(player_name .. ' was demoted from regular by ' .. actor .. '.')
        end
        global.regulars[player_name] = nil
        global.regulars[player_name:lower()] = nil --backwards compatible
        update_file()
    end
end

Module.print_regulars = function()
    for k, _ in pairs(global.regulars) do
        player_print(k)
    end
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

function Module.is_donator_perk(player_name, perk)
    local d = global.donators[player_name]
    if not d then
        return false
    end

    return bit32.band(d, perk) == perk
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local correctCaseName = game.players[event.player_index].name
        if global.regulars[correctCaseName:lower()] and not global.regulars[correctCaseName] then
            global.regulars[correctCaseName:lower()] = nil
            global.regulars[correctCaseName] = true
            update_file()
        end
    end
)

return Module
