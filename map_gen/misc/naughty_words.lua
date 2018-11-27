local Game = require 'utils.game'
local Event = require 'utils.event'

global.naughty_words = require('resources.naughty_words')

local function admonish_blasphemy(event)
-- player_index is nil if the message came from the server,
    -- and indexing Game.players with nil is apparently an error.
    if not event.player_index then
        return
    end
    local message = event.message:lower()
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local naughty_words = global.naughty_words
    for word in message:gmatch('%S+') do
        if naughty_words[word] then
            game.print(player.name .. ' this is a Christian Factorio server, no swearing please!')
            break
        end
    end
end

Event.add(defines.events.on_console_chat, admonish_blasphemy)
