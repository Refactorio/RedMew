local Global = require 'utils.global'

local Game = {}

local bad_name_players = {}
Global.register(
    bad_name_players,
    function(tbl)
        bad_name_players = tbl
    end
)

--[[
    Due to a bug in the Factorio api the following expression isn't guaranteed to be true.
    game.players[player.index] == player
    get_player_by_index(index) will always return the correct player.
    When looking up players by name or iterating through all players use game.players instead.
]]
function Game.get_player_by_index(index)
    local p = game.players[index]

    if not p then
        return nil
    end
    if p.index == index then
        return p
    end

    p = bad_name_players[index]
    if p then
        return p
    end

    for k, v in pairs(game.players) do
        if k == index then
            bad_name_players[index] = v
            return v
        end
    end
end

return Game
