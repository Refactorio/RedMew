local Global = require 'utils.global'
local Color = require 'resources.color_presets'
local print = print

local Game = {}

local bad_name_players = {}
Global.register(
    bad_name_players,
    function(tbl)
        bad_name_players = tbl
    end
)

--- Returns a valid LuaPlayer if given a number, string, or LuaPlayer. Returns nil otherwise.
-- obj <number|string|LuaPlayer>
function Game.get_player_from_any(obj)
    local o_type = type(obj)
    local p
    if o_type == 'number' or o_type == 'string' then
        p = game.get_player(obj)
        if p and p.valid then
            return p
        end
    elseif o_type == 'table' and obj.valid and obj.is_player() then
        return obj
    end
end

--- Prints to player or console.
-- @param msg <string|table> table if locale is used
-- @param color <table> defaults to white
function Game.player_print(msg, color)
    color = color or Color.white
    local player = game.player
    if player then
        player.print(msg, color)
    else
        print(msg)
    end
end

--[[
    @param Position String to display at
    @param text <string|table> table if locale is used
    @param color table in {r = 0~1, g = 0~1, b = 0~1}, defaults to white.
    @param surface LuaSurface

    @return the created entity
]]
function Game.print_floating_text(surface, position, text, color)
    color = color or Color.white

    return surface.create_entity {
        name = 'tutorial-flying-text',
        color = color,
        text = text,
        position = position
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
    local player = game.get_player(player_index)
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
