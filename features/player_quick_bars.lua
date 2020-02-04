-- This module saves players' action bars between maps
-- Dependencies
local Command = require 'utils.command'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Server = require 'features.server'
local Token = require 'utils.token'
local Color = require 'resources.color_presets'
local Ranks = require 'resources.ranks'

-- Constants
local data_set_name = 'player_quick_bars'
local quickbar_slots = 100

-- Localized globals
local primitives = {
    server_available = nil
}

Global.register(
    {
        primitives = primitives
    },
    function(tbl)
        primitives = tbl.primitives
    end
)

--- Scans all quickbar_slots into a table, then saves that table server-side
local function save_bars(_, player)
    if not primitives.server_available then
        Game.player_print({'common.server_unavailable'}, Color.fail)
        return
    end

    local bars = {}

    for i = 1, quickbar_slots do
        local item_prot = player.get_quick_bar_slot(i)
        if item_prot then
            bars[i] = item_prot.name
        end
    end

    Server.set_data(data_set_name, player.name, bars)
    Game.player_print({'player_quick_bars.save_bars'}, Color.success)
end

--- Returns a valid entity prototype string name or nil.
-- For invalid items, a message will be printed to the player.
local function validate_entry(item, proto_table, player)
    if not item then
        return
    end

    if proto_table[item] then
        return item
    end

    player.print({'player_quick_bars.incompatible_item', item}, Color.warning)
end

--- Sets the quick bars of a player.
local set_bars_callback =
    Token.register(
    function(data)
        local bars = data.value -- will be nil if no data
        if not bars then
            return
        end

        local p_name = data.key
        local player = game.get_player(p_name)
        if not player or not player.valid then
            return
        end

        local item_prototypes = game.item_prototypes
        local item
        for i = 1, quickbar_slots do
            item = validate_entry(bars[i], item_prototypes, player)
            if item then
                player.set_quick_bar_slot(i, item)
            end
        end
    end
)

--- Calls data from the server and sends it to the set_bars_callback
local function load_bars(_, player)
    if not primitives.server_available then
        Game.player_print({'common.server_unavailable'}, Color.fail)
        return
    end

    Server.try_get_data(data_set_name, player.name, set_bars_callback)
    Game.player_print({'player_quick_bars.load_bars'})
end

local player_created =
    Token.register(
    function(event)
        local p = game.get_player(event.player_index)
        if not p or not p.valid then
            return
        end

        Server.try_get_data(data_set_name, p.name, set_bars_callback)
    end
)

--- Registers the event only when the server is available.
local function register_player_create()
    if not primitives.server_available then
        Event.add_removable(defines.events.on_player_created, player_created)
        primitives.server_available = true
    end
end

--- Erases server-side data stored for this player's quickbar_slots
local function delete_bars(_, player)
    if not primitives.server_available then
        Game.player_print({'common.server_unavailable'}, Color.fail)
        return
    end

    Server.set_data(data_set_name, player.name, nil)
    Game.player_print({'player_quick_bars.delete_bars'}, Color.success)
end

-- Events

Event.add(Server.events.on_server_started, register_player_create)

-- Commands

Command.add(
    'quick-bar-save',
    {
        description = {'command_description.quick_bar_save'},
        required_rank = Ranks.regular
    },
    save_bars
)

Command.add(
    'quick-bar-load',
    {
        description = {'command_description.quick_bar_load'},
        required_rank = Ranks.regular
    },
    load_bars
)

Command.add(
    'quick-bar-delete',
    {
        description = {'command_description.quick_bar_delete'},
        required_rank = Ranks.regular
    },
    delete_bars
)
