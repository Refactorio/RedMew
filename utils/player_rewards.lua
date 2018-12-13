local Global = require 'utils.global'
local Game = require 'utils.game'

local Public = {}
local reward_token = {global.config.player_rewards_token} or {'coin'}

Global.register({
    reward_token = reward_token,
}, function (tbl)
    reward_token = tbl.reward_token
end)

--- Set the item to use for rewards
-- @param reward string - item name to use as reward
-- @return boolean true - indicating success
Public.set_reward = function(reward)
    if global.config.player_rewards_enabled == false then
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
-- @param player player_index number or LuaPlayer table -- the player to reward
-- @param amount number - the amount of reward tokens to give
-- @param message string - an optional message to send to the affected player
-- @return number - indicating how many were inserted or if operation failed
Public.give_reward = function(player, amount, message)
    if global.config.player_rewards_enabled == false then
        return 0
    end
    if type(player) == 'number' then
        player = Game.get_player_by_index(player)
    end
    local reward = {name = reward_token[1], count = amount}
    if not player.can_insert(reward) then
        return 0
    end
    if message then
        player.print(message)
    end
    return player.insert(reward)
end

--- Removes an amount of rewards from the player
-- @param player player_index number or LuaPlayer table -- the player to reward
-- @param amount number - the amount of reward tokens to remove
-- @param message string - an optional message to send to the affected player
-- @return number - indicating how many were removed or if operation failed
Public.remove_reward = function(player, amount, message)
    if global.config.player_rewards_enabled == false then
        return 0
    end
    if type(player) == 'number' then
        player = Game.get_player_by_index(player)
    end
    local unreward = {name = reward_token[1], count = amount}
    if message then
        player.print(message)
    end
    return player.remove_item(unreward)
end

return Public
