local Event = require 'utils.event'
local Server = require 'features.server'
local Game = require 'utils.game'
local Token = require 'utils.token'
local table = require 'utils.table'
local Global = require 'utils.global'
local Task = require 'utils.task'

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

    local message = d.welcome_messages
    if not message then
        return
    end

    message = table.concat({'*** ', message, ' ***'})
    Task.set_timeout_in_ticks(60, print_after_timeout, {player = player, message = message})
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

--- Sets the data for a donator
-- @param player_name <string>
-- @param data <table> a table containing perk_flags and welcome_messages
-- @return <string|nil>
function Public.set_donator(player_name, data)
    donators[player_name] = data
    Server.set_data('donators', player_name, data)
end

--- Clears the player_ranks table and merges the entries into it
local sync_donators_callback =
    Token.register(
    function(data)
        table.clear_table(donators)
        table.merge({donators, data.entries})
    end
)

--- Signals the server to retrieve the donators data set
function Public.sync_donators()
    Server.try_get_all_data('donators', sync_donators_callback)
end

--- Prints a list of donators
function Public.print_donators()
    local result = {}

    for k, _ in pairs(global.donators) do
        table.insert(result, k)
    end

    result = table.concat(result, ', ')
    Game.player_print(result)
end

Event.add(
    Server.events.on_server_started,
    function()
        Public.sync_donators()
    end
)

Server.on_data_set_changed(
    'donators',
    function(data)
        global.donators[data.key] = data.value
    end
)



Event.add(defines.events.on_player_joined_game, player_joined)

return Public
