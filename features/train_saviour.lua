local Event = require 'utils.event'
local Market_items = require 'resources.market_items'
local Global = require 'utils.global'
local Donators = require 'resources.donators'
local UserGroups = require 'features.user_groups'
local Game = require 'utils.game'
local train_perk_flag = Donators.donator_perk_flags.train

local saviour_token_name = 'small-plane' -- item name for what saves players
local saviour_timeout = 180 -- number of ticks players are train immune after getting hit (roughly)

table.insert(
    Market_items,
    {price = {{Market_items.market_item, 100}}, offer = {type = 'nothing', effect_description = 'Train immunity (Single usage) \nSaves you from a train collition \n\nPrice: 100 '..Market_items.market_item..'s'}}
)

local remove_stack = {name = saviour_token_name, count = 1}

local saved_players = {}
Global.register(
    saved_players,
    function(tbl)
        saved_players = tbl
    end
)

local train_names = {
    ['locomotive'] = true,
    ['cargo-wagon'] = true,
    ['fluid-wagon'] = true,
    ['artillery-wagon'] = true
}

local function save_player(player)
    player.character.health = 1

    local pos = player.surface.find_non_colliding_position('player', player.position, 100, 2)
    if not pos then
        return
    end

    player.teleport(pos, player.surface)
end

local function on_pre_death(event)
    local cause = event.cause
    if not cause or not cause.valid then
        return
    end

    if not train_names[cause.name] then
        return
    end

    local player_index = event.player_index
    local player = Game.get_player_by_index(player_index)
    if not player or not player.valid then
        return
    end

    local tick = saved_players[player_index]
    local game_tick = game.tick
    if tick and game_tick - tick <= saviour_timeout then
        save_player(player)
        return
    end

    local player_name = player.name

    if UserGroups.player_has_donator_perk(player_name, train_perk_flag) then
        saved_players[player_index] = game_tick
        save_player(player)

        game.print(player_name .. ' has been saved from a train death as a perk of donating to the server.')

        return
    end

    local saviour_tokens = player.get_item_count(saviour_token_name)
    if saviour_tokens < 1 then
        return
    end

    player.remove_item(remove_stack)
    saved_players[player_index] = game_tick

    save_player(player)

    game.print(
        table.concat {
            player_name,
            ' has been saved from a train death. Their ',
            saviour_token_name,
            ' survival item has been consumed.'
        }
    )
end

Event.add(defines.events.on_pre_player_died, on_pre_death)
