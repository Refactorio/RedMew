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

local donator_data_set = 'donators'

local donators = {} -- global register
local bonuses = {} -- global register

Global.register(
    {
        donators = donators,
        bonuses = bonuses
    },
    function(tbl)
        donators = tbl.donators
        bonuses = tbl.bonuses
    end
)

--[[
    TODO:
    [X] static list of different donator levels that the player can have
    [X] player initial items
    [X] add team handcrafting bonus if do.nator level is rocket fuel+
    [X] add team run bonus if donator level is nuclear fuel+
    [X] add get 5 inventory slot bonus for team if level is uranium
    [ ] add 10% discount on coin purchases at market or outpost upgrades
    [X] add extra running bonus on player respawn
    [ ] handling of events if a player donator status changes when they are connected
    [ ] fetch donator status for players when they join
]]


--[[
    player: {
        welcome_messages: string[]
        perk_flags: nil | flags,
        level: number
    }
]]
local Public = {}

--- Checks if a player has a required donator level to perform an action
-- @param player_name <string>
-- @param perk_flag <number>
-- @return boolean
function Public.has_required_donator_level(player_name, perk_flag)
    local d = donators[player_name]
    if not d then return false end
    for level, tier in pairs(DonatorPerks.tiers) do
        -- if the flag is present, then we perform the check
        if tier[perk_flag] then
            if tonumber(level) > d.level then
                -- the level of the perk is higher than the level of the player, so no perms for them
                return false
            end
            -- the player has sufficient level of donator for this
            return true
        end
    end
    return false -- the perk flag was not found so something is broken here
end

--- Checks if a player has a specific donator perk enabled
-- @param player_name <string>
-- @param perk_flag <number>
-- @return <boolean>
function Public.player_has_donator_perk_enabled(player_name, perk_flag)
    local d = donators[player_name]
    if not d then
        return false
    end

    local flags = d.perk_flags
    if not flags then
        return false
    end

    -- if the player doesn't have the required level of donator, we don't care about it being turned on or off
    if not Public.has_required_donator_level(player_name, perk_flag) then return false end 

    -- this is a table of numbers mapping to true or false, depending on what the player l
    return flags[perk_flag] or false
end

--- Prints the donator message with the color returned from the server and gives free fish to the player if they have the rank
local actions_after_timeout =
    Token.register(
    function(data)
        local player = data.player
        if not player.valid then
            return
        end

        if data.message then
            game.print(data.message, player.chat_color)
        end

        -- check if a player has been online for less than 120s (first time joining) and has the initial items perk
        if player.online_time < 90 and Public.player_has_donator_perk_enabled(player.name, DonatorPerks.flags.initial_items) then
            -- add fish + furnaces if the player has the sufficient tier
            local inv = player.get_main_inventory()
            inv.insert{name = "raw-fish", count = 100}
            inv.insert{name = "burner-mining-drill", count = 20}
            inv.insert{name = "stone-furnace", count = 20}
        end
    end
)

--- Re-calculate bonuses for the players
local function recalc_bonuses()
    for _, force in pairs(game.forces) do
        if not bonuses[force.name] then bonuses[force.name] = {} end
        local mining = bonuses[force.name].mining or 0.0
        local crafting = bonuses[force.name].crafting or 0.0
        local running = bonuses[force.name].running or 0.0
        local inventory = bonuses[force.name].inventory or 0.0


        -- change the bonuses of the forces back
        -- removes only bonuses added by this module, so other bonuses should not be affected
        force.manual_mining_speed_modifier = force.manual_mining_speed_modifier - mining
        force.manual_crafting_speed_modifier = force.manual_crafting_speed_modifier - crafting
        force.character_running_speed_modifier = force.character_running_speed_modifier - running
        force.character_inventory_slots_bonus = force.character_inventory_slots_bonus - inventory

        mining = 0.0
        crafting = 0.0
        inventory = 0.0
        running = 0.0

        -- for each player of a tier, the modifier is increased
        for _, player in pairs(force.players) do
            if Public.player_has_donator_perk_enabled(player.name, DonatorPerks.flags.team_mining) then
                mining = math.min(mining + 0.10, 100)
            end
            if Public.player_has_donator_perk_enabled(player.name, DonatorPerks.flags.team_crafting) then
                crafting = math.min(crafting + 0.10, 100)
            end
            if Public.player_has_donator_perk_enabled(player.name, DonatorPerks.flags.team_inventory) then
                inventory = math.min(inventory + 5, 100)
            end
            if Public.player_has_donator_perk_enabled(player.name, DonatorPerks.flags.team_run) then
                running = math.min(running + 0.1, 100)
            end
        end

        -- actually set the modifier values for the force
        force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + mining
        force.manual_crafting_speed_modifier = force.manual_crafting_speed_modifier + crafting
        force.character_running_speed_modifier = force.character_running_speed_modifier + running
        force.character_inventory_slots_bonus = force.character_inventory_slots_bonus + inventory
        
        bonuses[force.name].mining = mining
        bonuses[force.name].crafting = crafting
        bonuses[force.name].running = running
        bonuses[force.name].inventory = inventory
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
        -- player is not a donator, as it is guaranteed that the player is saved in the donator list
        return nil
    end

    local count = d.welcome_messages and  #d.welcome_messages or false
    -- if the player has any messages, then we create the data for it, otherwise it's nil
    local message = count and concat({'*** ', d.welcome_messages[random(count)], ' ***'}) or nil
    Task.set_timeout_in_ticks(60, actions_after_timeout, {player = player, message = message})
    recalc_bonuses()
end

local reduce_player_speed_back =
    Token.register(
    function(data)
        local player = data.player
        if not player.valid then return end
        player.character_running_speed_modifier = player.character_running_speed_modifier - 1
    end
    )
local increase_player_speed =
    Token.register(
    function(data)
        local player = data.player
        if not player.valid then return end
        player.character_running_speed_modifier = player.character_running_speed_modifier + 1
        Task.set_timeout_in_ticks(60*60, reduce_player_speed_back, data)
    end
    )

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

    -- make player faster for 60s by 100% and then reduces it back to before after 60s
    -- this is 10s 1 tick because the player spawns on 10s and factorio has issues
    Task.set_timeout_in_ticks(10*60 + 1, increase_player_speed, {player = player})


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
    recalc_bonuses()
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
            -- for easier editing in the web interface, set perk_flags to nil and they are set here
            if v and v.perk_flags == nil or type(v.perk_flags) ~= "table" then
                v.perk_flags = {}
                for _, perk_name in pairs(DonatorPerks.flags) do
                    v.perk_flags[perk_name] = true
                end
            end
            donators[k] = v
        end
        recalc_bonuses()
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
        -- TODO: recalc the donator for this player only
    end
)

Event.add(defines.events.on_player_joined_game, player_joined)

Event.add(defines.events.on_player_died, player_died)

return Public
