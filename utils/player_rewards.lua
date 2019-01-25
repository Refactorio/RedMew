local Global = require 'utils.global'
local Game = require 'utils.game'
local PlayerStats = require 'features.player_stats'
local Command = require 'utils.command'
local format = string.format

local Public = {}
local reward_token = {global.config.player_rewards.token} or {global.config.market.currency} or {'coin'}

Global.register(
    {
        reward_token = reward_token
    },
    function(tbl)
        reward_token = tbl.reward_token
    end,
    'player_rewards'
)

--- Set the item to use for rewards
-- @param reward string - item name to use as reward
-- @return boolean true - indicating success
Public.set_reward = function(reward)
    if global.config.player_rewards.enabled == false then
        return false
    end

    reward_token[1] = reward
    return true
end

--- Returns the name of the reward item
Public.get_reward = function()
    return reward_token[1]
end

--- Gives the player the quantity of reward
-- @param player <number|LuaPlayer> the player to reward
-- @param amount <number> the amount of reward tokens to remove
-- @param message <string> an optional message to send to the affected player
-- @return <number> indicating how many were inserted or if operation failed
Public.give_reward = function(player, amount, message)
    if global.config.player_rewards.enabled == false then
        return 0
    end

    local player_index
    if type(player) == 'number' then
        player_index = player
        player = Game.get_player_by_index(player)
    else
        player_index = player.index
    end
    local reward = {name = reward_token[1], count = amount}
    if not player.can_insert(reward) then
        return 0
    end
    if message then
        player.print(message)
    end
    local coin_difference = player.insert(reward)
    if reward_token[1] == 'coin' then
        PlayerStats.change_coin_earned(player_index, coin_difference)
    end
    return coin_difference
end

--- Removes an amount of rewards from the player
-- @param player <number|LuaPlayer> the player to reward
-- @param amount <number> the amount of reward tokens to remove
-- @param message <string> an optional message to send to the affected player
-- @return <number> indicating how many were removed or if operation failed
Public.remove_reward = function(player, amount, message)
    if global.config.player_rewards.enabled == false then
        return 0
    end

    local player_index
    if type(player) == 'number' then
        player_index = player
        player = Game.get_player_by_index(player)
    else
        player_index = player.index
    end
    local unreward = {name = reward_token[1], count = amount}
    if message then
        player.print(message)
    end
    local coin_difference = player.remove_item(unreward)
    if reward_token[1] == 'coin' then
        PlayerStats.change_coin_earned(player_index, -coin_difference)
    end
    return coin_difference
end

Command.add(
    'reward',
    {
        description = 'Gives a reward to a target player',
        arguments = {'target', 'quantity', 'reason'},
        default_values = {reason = false},
        admin_only = true,
        capture_excess_arguments = true,
        allowed_by_server = true,
        allowed_by_player = true
    },
    function(args, player)
        local player_name = 'server'
        if player then
            player_name = player.name
        end

        local target = game.players[args.target]
        local target_name
        if target then
            target_name = args.target
        else
            player.print('Target not found.')
            return
        end

        Public.give_reward(target, args.quantity)
        local string = format('%s has rewarded %s with %s %s', player_name, target_name, args.quantity, reward_token[1])
        if args.reason then
            string = format('%s for %s', string, args.reason)
        end
        game.print(string)
    end
)

return Public
