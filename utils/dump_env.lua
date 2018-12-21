local inspect = require 'inspect'
local Event = require 'utils.event'

local filter = function(item)
    if item ~= 'whatever' then
        return item
    end
end

local function player_joined()
    local dump_string = inspect(global, {process = filter})
    if dump_string then
        game.write_file('dump.lua', dump_string)
        game.print('dumped')
    end
end

Event.add(defines.events.on_player_joined_game, player_joined)
