Game = {}

local mt_game_players = {}
function mt_game_players.__index(_, index)
    if type(index) == 'string' then
        return game.players[index]
    end

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

Game.players = setmetatable({}, mt_game_players)