local Global = require 'utils.global'
local random = math.random

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

function Game.player_print(str)
    if game.player then
        game.player.print(str)
    else
        print(str)
    end
end

--[[
    @param Position String to display at
    @param text String to display
    @param color table in {r = 0~1, g = 0~1, b = 0~1}, defaults to white.
    @param surface LuaSurface

    @return the created entity
]]
function Game.print_floating_text(surface, position, text, color)
    color = color or {r = 1, g = 1, b = 1}

    return surface.create_entity {
        name = 'tutorial-flying-text',
        color = color,
        text = text,
        position = position,
    }
end

--[[
    Creates a floating text entity at the player location with the specified color in {r, g, b} format.
    Example: "+10 iron" or "-10 coins"

    @param text String to display
    @param color table in {r = 0~1, g = 0~1, b = 0~1}, defaults to white.

    @return the created entity
]]

function Game.print_player_floating_text_position(player_index, text, color, x_offset, y_offset)
    local player = Game.get_player_by_index(player_index)
    if not player or not player.valid then
        return
    end

    local position = player.position
    return Game.print_floating_text(player.surface, {x = position.x + x_offset, y = position.y + y_offset}, text, color)
end

function Game.print_player_floating_text(player_index, text, color)
    Game.print_player_floating_text_position(player_index, text, color, 0, -1.5)
end

return Game
