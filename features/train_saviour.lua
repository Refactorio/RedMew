local Event = require 'utils.event'
local market_items = require 'resources.market_items'
local Global = require 'utils.global'
local DonatorPerks = require 'resources.donator_perks'
local Donator = require 'features.donator'
local Task = require 'utils.task'
local Token = require 'utils.token'
local train_perk_flag = DonatorPerks.train

local saviour_token_name = 'simple-entity-with-owner' -- item name for what saves players
local saviour_entity_token_name = 'simple-entity-with-owner' -- entity name for the saviour_token_name, or nil if the item cannot be placed.
local saviour_timeout = 180 -- number of ticks players are train immune after getting hit (roughly)

table.insert(market_items, 3, {
    price = 100,
    name = saviour_token_name,
    name_label = 'Train Immunity (1x use)',
    description = 'Each ' .. saviour_token_name .. ' in your inventory will save you from being killed by a train once.'
})

local remove_stack = {name = saviour_token_name, count = 1}
local saved_players = {}

Global.register(saved_players, function(tbl)
    saved_players = tbl
end)

local train_types = {['locomotive'] = true, ['cargo-wagon'] = true, ['fluid-wagon'] = true, ['artillery-wagon'] = true}

local function save_player(player)
    player.character.health = 1

    local pos = player.physical_surface.find_non_colliding_position('character', player.physical_position, 100, 2)
    if not pos then
        return
    end

    player.teleport(pos, player.physical_surface)
end

local function on_pre_death(event)
    local cause = event.cause
    if not cause or not cause.valid then
        return
    end

    if not train_types[cause.type] then
        return
    end

    local player_index = event.player_index
    local player = game.get_player(player_index)
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

    if Donator.player_has_donator_perk(player_name, train_perk_flag) then
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
    game.print(player_name .. ' has been saved from a train death. One of their Train Immunity items has been consumed.')
end

--- Cleans the players cursor to prevent from spamming saviour_entity_token_name
-- Somehow required to have a 1 tick delay before cleaning the players cursor
local delay_clear_cursor = Token.register(function(param)
    param.player.clear_cursor()
end)

local function built_entity(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local name = entity.name
    local ghost = false
    if name == 'entity-ghost' then
        name = entity.ghost_name
        ghost = true
    end

    if name ~= saviour_entity_token_name then
        return
    end

    local index = event.player_index
    local player = game.get_player(index)
    if player and player.valid and not ghost then
        for _, stack in pairs(event.consumed_items.get_contents()) do
            player.insert(stack)
        end
        entity.destroy()
    end

    Task.set_timeout_in_ticks(1, delay_clear_cursor, {player = player})
end

Event.add(defines.events.on_pre_player_died, on_pre_death)
Event.add(defines.events.on_built_entity, built_entity)
