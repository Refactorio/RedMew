local Color = require 'resources.color_presets'
local print = print

local Game = {}

--- Returns a valid LuaPlayer if given a number, string, or LuaPlayer. Returns nil otherwise.
---@param obj <number|string|LuaPlayer>
function Game.get_player_from_any(obj)
    local o_type = type(obj)
    local p
    if o_type == 'number' or o_type == 'string' then
        p = game.get_player(obj)
        if p and p.valid then
            return p
        end
    elseif o_type == 'userdata' and obj.valid and obj.is_player() then
        return obj
    end
end

--- Prints to player or console.
---@param msg <string|table> table if locale is used
---@param color <table> defaults to white
---@param player <LuaPlayer?>
function Game.player_print(msg, color, player)
    color = color or Color.white
    player = player or game.player
    if player and player.valid then
        player.print(msg, {color = color})
    else
        print(msg)
    end
end

--- See the docs for LuaPlayer::create_local_flying_text, + surface param
---@param params table
---@field surface LuaSurfaceIdentification will create the text only for those on the same surface
function Game.create_local_flying_text(params)
    local surface_id = params.surface
    if type(surface_id) == 'userdata' then
        surface_id = surface_id.name or surface_id.index
    end
    if not surface_id then
        return
    end
    local surface = game.get_surface(surface_id)
    if not surface then
        return
    end
    for _, player in pairs(game.connected_players) do
        if player.surface_index == surface.index then
            player.create_local_flying_text(params)
        end
    end
end

return Game
