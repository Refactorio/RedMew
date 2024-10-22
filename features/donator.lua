-- This module contains features for donators and the permissions system for donators: who is a donator, what flags they have, adding/modifying donator data, etc.
local Event = require 'utils.event'
local Server = require 'features.server'
local Game = require 'utils.game'
local Token = require 'utils.token'
local table = require 'utils.table'
local Global = require 'utils.global'
local Task = require 'utils.task'
local DonatorPerks = require 'resources.donator_perks'

local concat = table.concat
local remove = table.remove
local set_data = Server.set_data
local random = math.random
local config = storage.config.donator

local donator_data_set = 'donators'
local donators = {} -- global register
local donator_perks_perm = {} -- buffs to the force that will remain even when the donator is offline (T5)
local donator_perks_temp = {} -- buffs to the force that are only applied while the donator is online (T2, T3, T4)
local donator_tiers = {
                        [1] = {name = "[img=item.wood]", count = 0, max = 10}, -- keeps track of how many have been applied so we can limit the amount of donators contributing to buffs
                        [2] = {name = "[img=item.coal]", count = 0, max = 10},
                        [3] = {name = "[img=item.solid-fuel]", count = 0, max = 10},
                        [4] = {name = "[img=item.rocket-fuel]", count = 0, max = 10},
                        [5] = {name = "[img=item.nuclear-fuel]", count = 0, max = 6}
                    }

Global.register(
    {
        donators = donators,
        donator_perks_perm = donator_perks_perm,
        donator_perks_temp = donator_perks_temp,
        donator_tiers = donator_tiers
    },
    function(tbl)
        donators = tbl.donators
        donator_perks_perm = tbl.donator_perks_perm
        donator_perks_temp = tbl.donator_perks_temp
        donator_tiers = tbl.donator_tiers
        config = storage.config.donator
    end
)

local Public = {}

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

--- Prints the donator message with the color returned from the server
local print_after_timeout =
    Token.register(
    function(data)
        local player = data.player
        if not player.valid then
            return
        end

        game.print(data.message, {color = player.chat_color})
    end
)

-- Just in case we want to turn it off mid-game, we can use /sc package.loaded['features.donator'].toggle_perks()
function Public.toggle_perks()
    config.donator_perks.enabled = not config.donator_perks.enabled
    if config.donator_perks.enabled == true then
        game.print("Donator perks now enabled")
        print("Donator perks now enabled") -- prints to server console
    else
        game.print("Donator perks now disabled")
        print("Donator perks now disabled")
    end
end

--- When a player joins, set a 1s timer to retrieve their color before printing their welcome message
local function player_joined(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local d = donators[player.name]
    if not d then
        return nil
    end

    local perk_flag = d.perk_flags
    if perk_flag < 2 then
        return
    end

    if Public.player_has_donator_perk(player.name, DonatorPerks.welcome_msg) then
        local messages = d.welcome_messages
        if messages then
            local count = #messages
            if count ~= 0 and count then
                local message = messages[random(count)]
                message = concat({'*** ', message, ' ***'})
                Task.set_timeout_in_ticks(60, print_after_timeout, {player = player, message = message})
            end
        end
    end

    if not config.donator_perks.enabled then
        return
    end

    local mining_flag = Public.player_has_donator_perk(player.name, DonatorPerks.team_mining)
    local crafting_flag = Public.player_has_donator_perk(player.name, DonatorPerks.team_crafting)
    local running_flag = Public.player_has_donator_perk(player.name, DonatorPerks.team_run)
    local inventory_flag = Public.player_has_donator_perk(player.name, DonatorPerks.team_inventory)

    if not mining_flag and not crafting_flag and not running_flag and not inventory_flag then
        return
   end

    -- Update team perks
    if not donator_perks_temp[player.name] then -- check they're not already in donator_perks_temp table, this keeps track of bonuses that are added and removed as players join and leave
        local donator_perk_msg = concat({"Donator Tier: ",donator_tiers[d.patreon_tier].name, ". Team bonuses applied for ", player.name,": "})
        if mining_flag and donator_tiers[2].count < donator_tiers[2].max then  -- Apply tier 2 (Coal) reward: +10 % team manual mining bonus per online tier 2+ donator
            player.force.manual_mining_speed_modifier = player.force.manual_mining_speed_modifier + 0.1
            donator_tiers[2].count = donator_tiers[2].count + 1
            donator_perk_msg = concat({donator_perk_msg, "+10% hand mining. "})
        end
        if crafting_flag and donator_tiers[3].count < donator_tiers[3].max then  -- Apply tier 3 (Solid Fuel) reward: + 10 % team manual crafting bonus per online tier 3+ donator
            player.force.manual_crafting_speed_modifier = player.force.manual_crafting_speed_modifier + 0.1
            donator_tiers[3].count = donator_tiers[3].count + 1
            donator_perk_msg = concat({donator_perk_msg, "+10% hand crafting. "})
        end
        if running_flag and donator_tiers[4].count < donator_tiers[4].max  then  -- Apply Tier 4 (Rocket Fuel) reward: + 10 % team running speed bonus per online tier 4+ donator
            player.force.character_running_speed_modifier = player.force.character_running_speed_modifier + 0.1
            donator_tiers[4].count = donator_tiers[4].count + 1
            donator_perk_msg = concat({donator_perk_msg, "+10% run speed. "})
        end
        donator_perks_temp[player.name] = perk_flag
        if inventory_flag and not donator_perks_perm[player.name] and donator_tiers[5].count < donator_tiers[5].max  then
            player.force.character_inventory_slots_bonus = player.force.character_inventory_slots_bonus + 5
            donator_tiers[5].count = donator_tiers[5].count + 1
            donator_perk_msg = concat({donator_perk_msg, "+5 inventory slots. "})
            donator_perks_perm[player.name] = true
        elseif donator_perks_perm[player.name] then -- for if they're already in the table. We don't want to apply the perk again but we do want to append the perk to the message.
            donator_perk_msg = concat({donator_perk_msg, "+5 inventory slots. "})
        end
        donator_perk_msg = donator_perk_msg .. " Use /perks to see bonuses."
        Task.set_timeout_in_ticks(80, print_after_timeout, {player = player, message = donator_perk_msg})
    end
end

local function player_left(event)
    local player = game.get_player(event.player_index)

    if not player or not player.valid or not config.donator_perks.enabled then
        return
    end

    local d = donators[player.name]
    if not donator_perks_temp[player.name] and not d then
        return
    end

    local mining_flag = Public.player_has_donator_perk(player.name, DonatorPerks.team_mining)
    local crafting_flag = Public.player_has_donator_perk(player.name, DonatorPerks.team_crafting)
    local running_flag = Public.player_has_donator_perk(player.name, DonatorPerks.team_run)

   -- To do: What happens if an admin changes the players donator status or flags while they're online?
    if not mining_flag and not crafting_flag and not running_flag then
        return
    end

    if donator_perks_temp[player.name] then
        if mining_flag then
            if player.force.manual_mining_speed_modifier  >= 0.1 then
                player.force.manual_mining_speed_modifier = player.force.manual_mining_speed_modifier - 0.1
            else
                player.force.manual_mining_speed_modifier =  0
            end
            donator_tiers[2].count = donator_tiers[2].count - 1
        end
        if crafting_flag then
            if player.force.manual_crafting_speed_modifier >= 0.1 then
                player.force.manual_crafting_speed_modifier = player.force.manual_crafting_speed_modifier - 0.1
            else
                player.force.manual_crafting_speed_modifier = 0
            end
            donator_tiers[3].count = donator_tiers[4].count - 1
        end
        if running_flag and player.force.character_running_speed_modifier >= 0.1  then
            if player.force.character_running_speed_modifier >= 0.1 then
                player.force.character_running_speed_modifier = player.force.character_running_speed_modifier - 0.1
            else
                player.force.character_running_speed_modifier = 0
            end
            donator_tiers[4].count = donator_tiers[4].count - 1
        end
        donator_perks_temp[player.name] = nil -- remove them from the table
    end

end

--- Prints a message on donator death
local function player_died(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local d = donators[player.name]
    if not d then
        return nil
    end

    if not Public.player_has_donator_perk(player.name, DonatorPerks.death_msg) then
        return
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
    game.print({'donator.death_message', player.name}, {color = player.chat_color})

    -- Player's selected message
    local message = messages[random(count)]
    message = concat({'*** ', message, ' ***'})
    game.print(message, {color = player.chat_color})
end

local reset_run_speed =
    Token.register(
    function(player)
        if not player.valid then
            return
        end
        player.character_running_speed_modifier = player.character_running_speed_modifier - 1
    end
)

local function player_respawned(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid or not config.donator_perks.enabled then
        return
    end

    local d = donators[player.name]
    if not d then
        return nil
    end

    local respawn_flag = Public.player_has_donator_perk(player.name, DonatorPerks.respawn_boost)
    if not respawn_flag then
        return
    end

    player.character_running_speed_modifier = player.character_running_speed_modifier + 1
    Task.set_timeout_in_ticks(30*60, reset_run_speed, player)
end

--- Returns the table of donators
-- @return <table>
function Public.get_donators_table()
    return donators
end

--- Returns the table of active perks
-- @return <table>
function Public.get_donator_perks_table()
    return donator_tiers
end

--- Checks if a player is a donator
-- @param player_name <string>
-- @return <boolean>
function Public.is_donator(player_name)
    return donators[player_name] ~= nil
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

Event.add(defines.events.on_player_left_game, player_left)

Event.add(defines.events.on_player_died, player_died)

Event.add(defines.events.on_player_respawned, player_respawned)

return Public
