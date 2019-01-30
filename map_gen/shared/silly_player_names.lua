local table = require 'utils.table'
local Game = require 'utils.game'
local Event = require 'utils.event'
local naming_words = require 'resources.naming_words'
local Utils = require 'utils.core'
local Global = require 'utils.global'
local Rank = require 'features.rank_system'
local ScenarioInfo = require 'features.gui.info'
local Command = require 'utils.command'
local Ranks = require 'resources.ranks'

local format = string.format
local random = math.random

ScenarioInfo.add_map_extra_info('- On this map you will be assigned a silly name.\n' .. '- If you dislike your name you can /name-restore or /name-roll for a new one')

global.silly_regulars = {}
local data_silly_names = {}
data_silly_names.silly_names = {}
data_silly_names.silly_name_store = {}
data_silly_names.silly_names_count = {0}
data_silly_names.silly_name_store = {}
data_silly_names.actual_name = {}

local name_combinations = #naming_words.adverbs * #naming_words.adjectives * 1
local table_size_ceiling = math.min(name_combinations * 0.25, 10000)

Global.register(
    {
        data_silly_names = data_silly_names
    },
    function(tbl)
        data_silly_names = tbl.data_silly_names
    end
)

--- Takes a player's real name, current silly name, and old silly name and adjusts
-- the silly_regulars table accordingly
local function check_regular(real_name, silly_name, old_silly_name)
    if Rank.equal(real_name, Ranks.regular) then
        global.silly_regulars[silly_name] = true
        if old_silly_name then
            global.silly_regulars[old_silly_name] = nil
        end
    end
end

--- Creates name by combining elements from the passed table
-- @param words_table including adverbs, adjectives, and nouns
-- @param player_name string with player's name
-- @returns string with player's silly name
-- TODO: Config option to set the name style
local function create_name(words_table, player_name)
    local adverb, adjective  --, noun
    adverb = words_table[random(#words_table)]
    adjective = words_table[random(#words_table)]
    --noun = words_table[random(#words_table)]
    local name = format('%s_%s_%s', adverb, adjective, player_name)
    return string.gsub(name, "%s+", "_")
end

--- Calls create_name until a unique name is returned
-- @param words_table including adverbs, adjectives, and nouns
-- @param player_name string with player's name
-- @returns string with player's silly name
local function create_unique_name(words_table, player_name)
    local silly_names = data_silly_names.silly_names
    local name = create_name(words_table, player_name)

    while table.contains(silly_names, name) do
        name = create_name(words_table, player_name)
    end
    return name
end

--- Assigns a player a name, stores their old and silly names
-- @param player LuaPlayer, the player to change the name of
local function name_player(player)
    local real_name = data_silly_names.actual_name[player.index] or player.name
    local old_silly_name

    -- If we don't have a player's actual name yet, store it
    if data_silly_names.actual_name[player.index] then
        old_silly_name = player.name
    else
        data_silly_names.actual_name[player.index] = real_name
    end

    -- Because create_unique_name enters a while loop looking for a _unique_ name,
    -- we ensure the table never contains all possible combinations by having a ceiling
    if data_silly_names.silly_names_count[1] > table_size_ceiling then
        table.clear_table(data_silly_names.silly_names, true)
        data_silly_names.silly_names_count[1] = 0
    end

    local name = create_unique_name(naming_words, real_name)
    data_silly_names.silly_names[#data_silly_names.silly_names + 1] = name
    data_silly_names.silly_names_count[1] = data_silly_names.silly_names_count[1] + 1

    local str = format('%s will now be known as: %s', player.name, name)
    game.print(str)
    local admin_str = format('%s (ID: %s)', str, player.index)
    Utils.print_admins(admin_str, nil)
    player.name = name

    -- After they have their name, we need to ensure compatibility with the regulars system
    check_regular(real_name, name, old_silly_name)
end

--- Restores a player's actual name
local function restore_name(data, command_player)
    local player
    if data and data.player_index then
        player = Game.get_player_by_index(data.player_index)
    else
        player = command_player
    end
    local silly_name = player.name
    data_silly_names.silly_name_store[player.index] = player.name
    player.name = data_silly_names.actual_name[player.index]
    if command_player then
        player.print('Your true name has been restored.')
        local str = silly_name .. ' will now be known as: ' .. player.name
        Utils.print_admins(str .. ' (ID: ' .. player.index .. ')', nil)
    end
end

--- Passes _event_ on to name_players
local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if data_silly_names.silly_name_store[event.player_index] then
        player.name = data_silly_names.silly_name_store[event.player_index]
    else
        name_player(player)
    end
end

--- Passes target or player on to name_players
local function name_player_command(args, player)
    local target
    local target_name = args.player

    if target_name then
        target = game.players[target_name]
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
                Game.player_print(table.concat {"Sorry, player '", target_name, "' was not found."})
                return
            end
        end
    else
        -- No param = change self name
        name_player(player)
        return
    end
end

--- Prints the original name of the target
local function check_name(args)
    local current_name = args.player

    local target = game.players[current_name]
    if not target then
        Game.player_print('player ' .. current_name .. ' not found')
        return
    end

    local actual_name = data_silly_names.actual_name[target.index]
    Game.player_print(target.name .. ' is actually: ' .. actual_name)
end

--- Prints the index of the target
local function get_player_id(args)
    local target_name = args.player

    local target = game.players[target_name]
    if not target then
        Game.player_print('player ' .. target_name .. ' not found')
        return
    end

    Game.player_print(format('name: %s -- index: %s', target_name, target.index))
end

Event.add(defines.events.on_player_joined_game, player_joined)
Event.add(defines.events.on_pre_player_left_game, restore_name)

Command.add(
    'name-roll',
    {
        description = 'Assigns you a random, silly name. (Admins can use this command on players)',
        arguments = {'player'},
        default_values = {player = false}
    },
    name_player_command
)

Command.add(
    'name-restore',
    {
        description = 'Removes your fun/silly name and gives you back your actual name.',
    },
    restore_name
)

Command.add(
    'name-check',
    {
        description = 'Check the original name of a player with a silly name',
        arguments = {'player'},
        allowed_by_server = true
    },
    check_name
)

Command.add(
    'get-player-id',
    {
        description = 'Gets the index of a player',
        arguments = {'player'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    get_player_id
)
