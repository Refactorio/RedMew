-- This module saves players' logistic requests slots between maps
-- Dependencies

--TODO: Rewrite, feature deprecated for 2.0
--[[
local Command = require 'utils.command'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Server = require 'features.server'
local Token = require 'utils.token'
local Color = require 'resources.color_presets'
local Ranks = require 'resources.ranks'

-- Constants
local data_set_name = 'player_logistic_requests'
local logistic_slots = 100

-- Localized globals
local primitives = {
    server_available = nil
}
local initialized_players = {}
local initialized_forces = {}

Global.register(
    {
        primitives = primitives,
        initialized_players = initialized_players,
        initialized_forces = initialized_forces
    },
    function(tbl)
        primitives = tbl.primitives
        initialized_players = tbl.initialized_players
        initialized_forces = tbl.initialized_forces
    end
)

--- Scans all player's logistic request slots into a table, then saves that table server-side
local function save_bars(_, player)
    if not primitives.server_available then
        Game.player_print({'common.server_unavailable'}, Color.fail)
        return
    end

    -- Player's force doesn't have logistics
    local force = player.force
    if not (force and force.character_logistic_requests) then
        Game.player_print({'player_logistic_requests.logistics_not_available'}, Color.fail)
        return
    end

    local bars = {}

    for i = 1, logistic_slots do
        local item_prot = player.get_personal_logistic_slot(i)
        if item_prot and item_prot.name then
            bars[i] = item_prot
        end
    end

    Server.set_data(data_set_name, player.name, bars)
    Game.player_print({'player_logistic_requests.save_bars'}, Color.success)
end

--- Returns a valid entity prototype string name or nil.
-- For invalid items, a message will be printed to the player.
local function validate_entry(item, proto_table, player)
    if not (item and item.name) then
        return
    end

    if proto_table[item.name] then
        return item
    end

    player.print({'player_logistic_requests.incompatible_item', item.name}, {color = Color.warning})
end

--- Sets the logistic request slots of a player.
local set_bars_callback =
    Token.register(
    function(data)
        local bars = data.value -- will be nil if no data
        if not bars then
            return
        end

        -- Invalid player
        local p_name = data.key
        local player = game.get_player(p_name)
        if not (player and player.valid )then
            return
        end

        local item_prototypes = prototypes.item
        local item
        for i = 1, logistic_slots do
            item = validate_entry(bars[i], item_prototypes, player)
            if item then
                player.set_personal_logistic_slot(i, item) -- false if personal logistics are not researched yet.
            end
        end

        initialized_players[player.name] = true
    end
)

--- Calls data from the server and sends it to the set_bars_callback
local function load_bars(_, player)
    if not primitives.server_available then
        Game.player_print({'common.server_unavailable'}, Color.fail)
        return
    end

    -- Player's force doesn't have logistics
    local force = player.force
    if not (force and force.character_logistic_requests) then
        Game.player_print({'player_logistic_requests.logistics_not_available'}, Color.fail)
        return
    end

    Server.try_get_data(data_set_name, player.name, set_bars_callback)
    Game.player_print({'player_logistic_requests.load_bars'})
end

-- Auto loads all logistic requests for players joining after logistics has been researched
local player_joined_game =
    Token.register(
    function(event)
        -- Invalid player
        local player = game.get_player(event.player_index)
        if not (player and player.valid) then
            return
        end

        -- Player already initialized
        if initialized_players[player.name] then
            return
        end

        -- Player's force doesn't have logistics
        local force = player.force
        if not (force and force.character_logistic_requests) then
            return
        end

        Server.try_get_data(data_set_name, player.name, set_bars_callback)
    end
)

--- Auto loads all logistic requests for connected players when logistics gets researched
local research_finished =
    Token.register(
    function(event)
        -- Invalid tech
        local tech = event.research
        if not (tech and tech.valid) then
            return
        end

        -- Already init. or logistics not available
        local force = tech.force
        if not force or initialized_forces[force.name] or not force.character_logistic_requests then
            return
        end

        for _, player in pairs(force.connected_players) do
            if player and player.valid and player.character and player.character.valid then
                if not initialized_players[player.name] then
                    Server.try_get_data(data_set_name, player.name, set_bars_callback)
                end
            end
        end

        initialized_forces[force.name] = true
    end
)

--- Registers the event only when the server is available.
local function register_server_start_events()
    if not primitives.server_available then
        Event.add_removable(defines.events.on_player_joined_game, player_joined_game)
        Event.add_removable(defines.events.on_research_finished, research_finished)
        primitives.server_available = true
    end
end

--- Erases server-side data stored for this player's logistic requests slots
local function delete_bars(_, player)
    if not primitives.server_available then
        Game.player_print({'common.server_unavailable'}, Color.fail)
        return
    end

    Server.set_data(data_set_name, player.name, nil)
    Game.player_print({'player_logistic_requests.delete_bars'}, Color.success)
end

-- Events
Event.add(Server.events.on_server_started, register_server_start_events)

-- Commands

Command.add(
    'logistic-requests-save',
    {
        description = {'command_description.logistic_requests_save'},
        required_rank = Ranks.regular
    },
    save_bars
)

Command.add(
    'logistic-requests-load',
    {
        description = {'command_description.logistic_requests_load'},
        required_rank = Ranks.regular
    },
    load_bars
)

Command.add(
    'logistic-requests-delete',
    {
        description = {'command_description.logistic_requests_delete'},
        required_rank = Ranks.regular
    },
    delete_bars
)
]]