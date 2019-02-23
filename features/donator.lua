-- This module contains features for donators and the permissions system for donators: who is a donator, what flags they have, adding/modifying donator data, etc.
local Event = require 'utils.event'
local Server = require 'features.server'
local Game = require 'utils.game'
local Token = require 'utils.token'
local table = require 'utils.table'
local Global = require 'utils.global'
local Task = require 'utils.task'

local concat = table.concat
local remove = table.remove
local set_data = Server.set_data
local random = math.random

local donator_data_set = 'donators'

local donators = {} -- global register

Global.register(
    {
        donators = donators
    },
    function(tbl)
        donators = tbl.donators
    end
)

local Public = {}

--- Prints the donator message with the color returned from the server
local print_after_timeout =
    Token.register(
    function(data)
        local player = data.player
        if not player.valid then
            return
        end

        game.print(data.message, player.chat_color)
    end
)

--- When a player joins, set a 1s timer to retrieve their color before printing their welcome message
local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local d = donators[player.name]
    if not d then
        return nil
    end

    local messages = d.welcome_messages
    if not messages then
        return
    end

    local count = #messages
    if count == 0 then
        return
    end

    local message = messages[random(count)]
    message = concat({'*** ', message, ' ***'})
    Task.set_timeout_in_ticks(60, print_after_timeout, {player = player, message = message})
end

--- Prints a message on donator death
local function player_died(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local d = donators[player.name]
    if not d then
        return nil
    end

    local messages = d.death_messages
    if not messages then
        return
    end

    local count = #messages
    if count == 0 then
        return
    end

    -- Generic: this person has died message
    game.print({'donator.death_message', player.name}, player.chat_color)

    -- Player's selected message
    local message = messages[random(count)]
    message = concat({'*** ', message, ' ***'})
    game.print(message, player.chat_color)
end

--- Returns the table of donators
-- @return <table>
function Public.get_donators_table()
    return donators
end

--- Checks if a player is a donator
-- @param player_name <string>
-- @return <boolean>
function Public.is_donator(player_name)
    return donators[player_name] ~= nil
end

--- Checks if a player has a specific donator perk
-- @param player_name <string>
-- @param perf_flag <number>
-- @return <boolean>
function Public.player_has_donator_perk(player_name, perk_flag)
    local d = donators[player_name]
    if not d then
        return false
    end

    local flags = d.perk_flags
    if not flags then
        return false
    end

    return bit32.band(flags, perk_flag) == perk_flag
end

--- Sets the data for a donator, all existing data for the entry is removed
-- @param player_name <string>
-- @param data <table>
function Public.set_donator_data(player_name, data)
    donators[player_name] = data
    set_data(donator_data_set, player_name, data)
end

--- Changes the data for a donator with any data that is sent, only overwritten data is affected
-- @param player_name <string>
-- @param data <table>
function Public.change_donator_data(player_name, data)
    local d_table = donators[player_name]

    if not d_table then
        return
    end

    for k, v in pairs(data) do
        d_table[k] = v
    end

    set_data(donator_data_set, player_name, donators[player_name])
end

--- Adds a donator message to the appropriate table
-- @param player_name <string>
-- @param table_name <string> the name table to change the message in
-- @param str <string>
function Public.add_donator_message(player_name, table_name, str)
    local d_table = donators[player_name]
    local message_table = d_table[table_name]
    if not message_table then
        message_table = {}
        d_table[table_name] = message_table
    end

    message_table[#message_table + 1] = str
    set_data(donator_data_set, player_name, d_table)
end

--- Deletes the indicated donator message from the appropriate table
-- @param player_name <string>
-- @param table_name <string> the name table to change the message in
-- @param num <number>
-- @return <string|nil> the value that was deleted, nil if nothing to delete
function Public.delete_donator_message(player_name, table_name, num)
    local d_table = donators[player_name]
    local message_table = d_table[table_name]
    if not message_table or not message_table[num] then
        return
    end

    local del_msg = remove(message_table, num)
    set_data(donator_data_set, player_name, d_table)
    return del_msg
end

--- Returns the list of messages from the appropriate table
-- @param player_name <string>
-- @param table_name <string> the name table to change the message in
-- @return <table|nil> an array of strings or nil if no messages
function Public.get_donator_messages(player_name, table_name)
    local d_table = donators[player_name]
    if not d_table then
        return nil
    end

    return d_table[table_name]
end

--- Writes the data called back from the server into the donators table, clearing any previous entries
local sync_donators_callback =
    Token.register(
    function(data)
        table.clear_table(donators)
        for k, v in pairs(data.entries) do
            donators[k] = v
        end
    end
)

--- Signals the server to retrieve the donators data set
function Public.sync_donators()
    Server.try_get_all_data(donator_data_set, sync_donators_callback)
end

--- Prints a list of donators
function Public.print_donators()
    local result = {}

    for k, _ in pairs(donators) do
        result[#result + 1] = k
    end

    result = concat(result, ', ')
    Game.player_print(result)
end

Event.add(
    Server.events.on_server_started,
    function()
        Public.sync_donators()
    end
)

Server.on_data_set_changed(
    donator_data_set,
    function(data)
        donators[data.key] = data.value
    end
)

Event.add(defines.events.on_player_joined_game, player_joined)

Event.add(defines.events.on_player_died, player_died)

return Public
