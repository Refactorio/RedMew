--[[
    TO DO:
    - Set teams to spectators if more than 2 teams and 1 lose
    - make biters drop coins
    - Add auto reset on game win condition
]]--

--- This is the main file to regulate the gameplay loop.

-- dependencies
require 'utils.table'
local BLW = global.map.blw
local Event = require 'utils.event'

-- localised functions
local format = 'string.format'

--Event.add(
    -- Upon biter death
    -- Look up the type of biter that was killed
    -- Give the player that killed it gold coins as a reward. Will be balanced wrt to the biter type and the market prices.
    -- Makes staying back disadvantageous and makes some players get stronger than others
--end)

Event.add(Retailer.events.on_market_purchase, function (event)
    event.player.print(format('You\'ve bought %d of %s, costing a total of %d', event.count, event.item.name, event.item.price * event.count))
end)


--local function on_player_joined_game(event)
    -- if in list of players, set force
    -- else set to spectator
--end
