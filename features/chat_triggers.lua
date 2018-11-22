-- This feature auto-responds to key words or phrases. We use the name/actor Hodor because it is Redmew's beloved discord bot.

local Game = require 'utils.game'
local Event = require 'utils.event'
require 'utils.list_utils'
local Hodor = require 'resources.hodor_messages'

local prefix = '## - '

global.mention_enabled = true

local auto_replies = {
    ['discord'] = {'Did you ask about our discord server?', 'You can find it here: redmew.com/discord'},
    ['patreon'] = {'Did you ask about our patreon?', 'You can find it here: patreon.com/redmew'},
    ['donate'] = {'Did you ask about donating to the server?', 'You can find our patreon here: patreon.com/redmew'},
    ['grief'] = {'To report grief please use the /report function.', 'If no admins are online use #moderation-requests on the discord and make sure the @mention the appropriate role.'}
}

global.naughty_words_enabled = false
global.naughty_words = {
    ['ass'] = true,
    ['bugger'] = true,
    ['butt'] = true,
    ['bum'] = true,
    ['bummer'] = true,
    ['christ'] = true,
    ['crikey'] = true,
    ['darn'] = true,
    ['dam'] = true,
    ['damn'] = true,
    ['dang'] = true,
    ['dagnabit'] = true,
    ['dagnabbit'] = true,
    ['drat'] = true,
    ['fart'] = true,
    ['feck'] = true,
    ['frack'] = true,
    ['freaking'] = true,
    ['frick'] = true,
    ['gay'] = true,
    ['gee'] = true,
    ['geez'] = true,
    ['git'] = true,
    ['god'] = true,
    ['golly'] = true,
    ['gosh'] = true,
    ['heavens'] = true,
    ['heck'] = true,
    ['hell'] = true,
    ['holy'] = true,
    ['jerk'] = true,
    ['jesus'] = true,
    ['petes'] = true,
    ["pete's"] = true,
    ['poo'] = true,
    ['satan'] = true,
    ['willy'] = true,
    ['wee'] = true,
    ['yikes'] = true
}

local function hodor(event)
    local message = event.message:lower()

    if message:match('hodor') then
        game.print('Hodor: ' .. table.get_random_weighted(Hodor, 1, 2))
    end

    -- player_index is nil if the message came from the server,
    -- and indexing Game.players with nil is apparently an error.
    local player_index = event.player_index
    if not player_index then
        return
    end

    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    if not player.admin then
        for trigger, replies in pairs(auto_replies) do
            if message:match(trigger) then
                for _, reply in pairs(replies) do
                    player.print(reply)
                end
            end
        end
    end

    if global.naughty_words_enabled then
        local naughty_words = global.naughty_words
        for word in message:gmatch('%S+') do
            if naughty_words[word] then
                game.print(player.name .. ' this is a Christian Factorio server, no swearing please!')
                break
            end
        end
    end

    -- Gives a sound notification to a mentioned player using #[player-name], [player-name]#, @[player-name], [player-name]@ or to admins with moderator or admin without prefix or postfix
    if global.mention_enabled then
        local missing_player_string
        local not_found = 0
        local cannot_mention = {}
        for w in event.message:gmatch('%S+') do
            local word = w:lower()
            local trimmed_word = string.sub(word, 0, string.len(word)-1)
            local first_char = string.sub(word, 0, 1)
            local last_char = string.sub(word, string.len(word))
            local success = false
            local admin_call = false
            if word == 'admin' or word == 'moderator' or trimmed_word == 'admin' or trimmed_word == 'moderator' then
                admin_call = true
            elseif (first_char ~= '#' and last_char ~= '#') and (first_char ~= '@' and last_char ~= '@') then
                success = true
            end
            if not success then
                for _, p in ipairs(game.connected_players) do
                    local word_front_trim = string.sub(word, 2, string.len(word))
                    local word_back_trim = trimmed_word
                    local word_front_back_trim = string.sub(word_front_trim, 0, string.len(word_front_trim)-1)
                    local word_back_double_trim = string.sub(word_back_trim, 0, string.len(word_back_trim)-1)
                    word = (trimmed_word == 'admin' or trimmed_word == 'moderator') and trimmed_word or word
                    if admin_call and p.admin then
                        p.print(prefix..Game.get_player_by_index(event.player_index).name..' mentioned '..word..'!', {r = 1, g = 1, b = 0, a = 1})
                        p.play_sound{path='utility/new_objective', volume_modifier = 1 }
                        success = true
                    end
                    if not admin_call and (p.name:lower() == word_front_trim or p.name:lower() == word_back_trim or  p.name:lower() == word_back_double_trim or p.name:lower() == word_front_back_trim) then
                        if p.name == player.name then
                            if _DEBUG then
                                player.print(prefix..'Can\'t mention yourself!', {r = 1, g = 0, b = 0, a = 1})
                            end
                            success = true
                            break;
                        end
                        p.print(prefix..Game.get_player_by_index(event.player_index).name..' mentioned you!', {r = 1, g = 1, b = 0, a = 1})
                        p.play_sound{path='utility/new_objective', volume_modifier = 1 }
                        success = true
                        if _DEBUG then
                            player.print(prefix..'Successful mentioned '..p.name, {r = 0, g = 1, b = 0, a = 1})
                        end
                        break;
                    end
                end
            end
            if not success then
                if admin_call then
                    word = 'no '.. word .. 's online!'
                end
                not_found = not_found + 1
                table.insert(cannot_mention, (word .. ', '))
            end
        end
        for _, pname in ipairs(cannot_mention) do
            missing_player_string = missing_player_string~=nil and missing_player_string .. pname or pname
        end
        if missing_player_string ~= nil then
            missing_player_string = string.sub(missing_player_string, 1, (string.len(missing_player_string)-2))
            if not_found > 1 then
                player.print(prefix..'Players not found: ' .. missing_player_string, {r = 1, g = 1, b = 0, a = 1})
            else
                player.print(prefix..'Player not found: ' .. missing_player_string, {r = 1, g = 1, b = 0, a = 1})
            end
        end
    end
end


Event.add(defines.events.on_console_chat, hodor)
