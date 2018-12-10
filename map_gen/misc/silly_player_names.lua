require 'utils.table'
local Game = require 'utils.game'
local Event = require 'utils.event'
local naming_words = require 'resources.naming_words'
local Utils = require 'utils.core'
local Global = require 'utils.global'

local data_silly_names = {}
data_silly_names.silly_names = {}
data_silly_names.silly_name_store = {}
data_silly_names.silly_names_count = {0}
data_silly_names.silly_name_store = {}
data_silly_names.actual_name = {}

local name_combinations = #naming_words.adverbs * #naming_words.adjectives * 1

Global.register(
    {
        data_silly_names = data_silly_names
    },
    function(tbl)
        data_silly_names = tbl.data_silly_names
    end
)

--- Creates name by combining elements from the passed table
-- @param1 table including adverbs, adjectives, and nouns
-- @returns name as a string
local function create_name(words_table, player_name)
    local adverb, adjective--, noun
    adverb = table.get_random(words_table.adverbs, true)
    adjective = table.get_random(words_table.adjectives, true)
    --noun = table.get_random(words_table.nouns, true)
    return adverb .. '_' .. adjective .. '_' .. player_name
end

--- Calls create_name until a unique name is returned
-- @param1 table including adverbs, adjectives, and nouns
-- @returns name as a string
local function create_unique_name(words_table, player_name)
    local silly_names = data_silly_names.silly_names
    local name = create_name(words_table, player_name)

    while table.contains(silly_names, name) do
        name = create_name(words_table, player_name)
    end
    return name
end

--- Assigns a player a name, stores their old and silly names
-- @param1 Takes a LuaPlayer
local function name_player(player)
    local passed_name = player.name
    -- Store a player's original name in case they want it back.
    if data_silly_names.actual_name[player.index] then
        passed_name = data_silly_names.actual_name[player.index]
    else
        data_silly_names.actual_name[player.index] = passed_name
    end

    -- Because create_unique_name enters a while loop looking for a unique name, ensure we never get stuck.
    local ceiling = math.min(name_combinations * 0.25, 10000)
    if data_silly_names.silly_names_count[1] > ceiling then
        data_silly_names.silly_names = {}
        data_silly_names.silly_names_count[1] = 0
    end

    local name = create_unique_name(naming_words, passed_name)

    data_silly_names.silly_names[#data_silly_names.silly_names + 1] = name
    data_silly_names.silly_names_count[1] = data_silly_names.silly_names_count[1] + 1
    local str = player.name .. ' will now be known as: ' .. name
    game.print(str)
    Utils.print_admins(str .. ' (ID: ' .. player.index .. ')', false)
    player.name = name
end

--- Restores a player's actual name
local function restore_name(data)
    local player
    if data.player_index then
        player = Game.get_player_by_index(data.player_index)
    else
        player = game.player
    end
    local silly_name = player.name
    data_silly_names.silly_name_store[player.index] = player.name
    player.name = data_silly_names.actual_name[player.index]
    if data.name == 'name-restore' then
        player.print('Your true name has been restored.')
        local str = silly_name .. ' will now be known as: ' .. player.name
        Utils.print_admins(str .. ' (ID: ' .. player.index .. ')', false)
    end
end

--- Passes _event_ on to name_players
local function on_player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if data_silly_names.silly_name_store[event.player_index] then
        player.name = data_silly_names.silly_name_store[event.player_index]
    else
        name_player(player)
    end
end

--- Passes target or player on to name_players
local function name_player_command(cmd)
    local player = game.player
    local param = cmd.parameter
    local target

    if param then
        target = game.players[param]
        if player and not player.admin then
            -- Yes param, yes player, no admin/server = fail, non-admins, non-server cannot use command on others
            Game.player_print("Sorry you don't have permission to use the roll-name command on other players.")
            return
        else
            -- Yes param, yes admin/server = check target
            if target then
                -- Yes param, yes admin/server, yes target = change name
                name_player(target)
                return
            else
                -- Yes param, yes admin/server, no target = fail, wrong player name
                Game.player_print(table.concat {"Sorry, player '", param, "' was not found."})
                return
            end
        end
    else
        -- No param = check if server
        if not player then
            -- No param, no player = server trying to change its name
            Game.player_print('The server cannot change its name')
            return
        end
        -- No param, not server = change self name
        name_player(player)
        return
    end
end

--- Prints the original name of the target
local function check_name(cmd)
    local current_name = cmd.parameter
    if not current_name then
        Game.player_print('Usage: /name-check <player>')
        return
    end

    local target = game.players[current_name]
    if not target then
        Game.player_print('player ' .. current_name .. ' not found')
        return
    end

    local actual_name = data_silly_names.actual_name[target.index]
    Game.player_print(target.name .. ' is actually: ' .. actual_name)
end

--- Prints the index of the target
local function get_player_id(cmd)
    local player = game.player
    -- Check if the player can run the command
    if player and not player.admin then
        Utils.cant_run(cmd.name)
        return
    end
    -- Check if the target is valid
    local target_name = cmd['parameter']
    if not target_name then
        Game.player_print('Usage: /get-player-id <player>')
        return
    end
    local target_index = game.players[target_name].index
    Game.player_print(target_name .. ' -- ' .. target_index)
end

Event.add(defines.events.on_player_joined_game, on_player_joined)
Event.add(defines.events.on_pre_player_left_game, restore_name)

commands.add_command('name-roll', 'Assigns you a random, silly name', name_player_command)
commands.add_command('name-restore', 'Removes your fun/silly name and gives you back your actual name', restore_name)
commands.add_command('name-check', '<silly_player_name> Check the original name of a player with a silly name', check_name)
commands.add_command('get-player-id', 'Gets the ID of a player (Admin only)', get_player_id)
