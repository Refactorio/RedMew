local Event = require 'utils.event'
local Global = require 'utils.global'

local Game = {}

local players

local function get_player(index)
    local p = game.players[index]
    if not p then
        return nil
    end
    if p.index == index then
        return p
    end

    for k, v in pairs(game.players) do
        if k == index then
            return v
        end
    end
end

Event.add(
    defines.events.on_player_created,
    function(event)
        local p = get_player(event.player_index)
        table.insert(players, p)
    end
)

local mt_players = {}
function mt_players.__index(_, index)
    if type(index) == 'string' then
        return game.players[index]
    end
end

players = setmetatable({}, mt_players)

Global.register(
    players,
    function(tbl)
        players = setmetatable(tbl, mt_players)
        Game.players = players
    end
)

Game.players = players

return Game
