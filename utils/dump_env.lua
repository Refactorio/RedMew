-- A small debugging tool that writes the contents of _ENV to a file when the game loads.
-- Useful for ensuring you get the same information when loading
-- the reference and desync levels in desync reports.
require 'utils.table'
local Event = require 'utils.event'
local filename = 'env_dump.lua'
local inspect = table.inspect

-- Removes metatables and the package table
local filter = function(item, path)
    if path[#path] ~= inspect.METATABLE and item ~= 'package' then
        return item
    end
end

local function player_joined(event)
    local dump_string = inspect(_ENV, {process = filter})
    if dump_string then
        local s = string.format('tick on join: %s\n%s', event.tick, dump_string)
        game.write_file(filename, s)
        game.print('_ENV dumped into ' .. filename)
    else
        game.print('_ENV not dumped, dump_string was nil')
    end
end

Event.add(defines.events.on_player_joined_game, player_joined)
