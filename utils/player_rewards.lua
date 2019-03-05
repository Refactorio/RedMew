local Global = require 'utils.global'
local Game = require 'utils.game'
local PlayerStats = require 'features.player_stats'
local Command = require 'utils.command'
local Ranks = require 'resources.ranks'

local format = string.format
local abs = math.abs
local concat = table.concat

local Public = {}
local reward_token = {global.config.player_rewards.token} or {global.config.market.currency} or {'coin'}

Global.register(
    {
        reward_token = reward_token
    },
    function(tbl)
        reward_token = tbl.reward_token
    end
)

--- Returns the single or plural form of the token name
local function get_token_plural(quantity)
    if quantity and quantity > 1 then
        return concat({reward_token[1], 's'})
    else
        return reward_token[1]
    end
end

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

--- Gives reward tokens to the player
-- @param player <number|LuaPlayer>
-- @param amount <number> of reward tokens
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

--- Removes reward tokens from the player
-- @param player <number|LuaPlayer>
-- @param amount <number> of reward tokens
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
        description = {'command_description.reward'},
        arguments = {'target', 'quantity', 'reason'},
        default_values = {reason = false},
        required_rank = Ranks.admin,
        capture_excess_arguments = true,
        allowed_by_server = true,
        allowed_by_player = true
    },
    function(args, player)
        local player_name = 'server'
        if player then
            player_name = player.name
        end

        local target_name = args.target
        local target = game.players[target_name]
        if not target then
            player.print('Target not found.')
            return
        end

        local quantity = tonumber(args.quantity)
        if quantity > 0 then
            Public.give_reward(target, quantity)
            local string = format('%s has rewarded %s with %s %s', player_name, target_name, quantity, get_token_plural(quantity))
            if args.reason then
                string = format('%s for %s', string, args.reason)
            end
            game.print(string)
        elseif quantity < 0 then
            quantity = abs(quantity)
            Public.remove_reward(target, quantity)
            local string = format('%s has punished %s by taking %s %s', player_name, target_name, quantity, get_token_plural(quantity))
            if args.reason then
                string = format('%s for %s', string, args.reason)
            end
            game.print(string)
        else
            Game.player_print(" A reward of 0 is neither a reward nor a punishment, it's just dumb. Try harder.")
        end
    end
)

return Public
