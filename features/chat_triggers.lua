-- This feature auto-responds to key words or phrases. We use the name/actor Hodor because it is Redmew's beloved discord bot.

local Game = require 'utils.game'
local Event = require 'utils.event'

local prefix = '## - '

global.mention_enabled = true

local hodor_messages = {
    {'Hodor.', 16},
    {'Hodor?', 16},
    {'Hodor!', 16},
    {'Hodor! Hodor! Hodor! Hodor!', 4},
    {'Hodor :(', 4},
    {'Hodor :)', 4},
    {'HOOOODOOOR!', 4},
    {'( ͡° ͜ʖ ͡°)', 1},
    {'☉ ‿ ⚆', 1}
}

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

local message_weight_sum = 0
for _, w in pairs(hodor_messages) do
    message_weight_sum = message_weight_sum + w[2]
end

local function hodor(event)
    local message = event.message:lower()

    if message:match('hodor') then
        local index = math.random(1, message_weight_sum)
        local message_weight_sum = 0
        for _, m in pairs(hodor_messages) do
            message_weight_sum = message_weight_sum + m[2]
            if message_weight_sum >= index then
                game.print('Hodor: ' .. m[1])
                break
            end
        end
    end

    -- player_index is nil if the message came from the server,
    -- and indexing Game.players with nil is apparently an error.
    local player = Game.get_player_by_index(event.player_index)
    local player_index = event.player_index
    if not player_index then
        return
    end

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

    -- Gives a sound notification to a mentioned player using #[player-name]
    if global.mention_enabled then
        local missing_player_string
        local not_found = 0
        local cannot_mention = {}
        for word in event.message:gmatch('#%S+') do
            local lower_word = word:lower()
            local trimmed_word = string.sub(word, 0, string.len(word)-1)
            local success = false
            local admin_call = false
            if lower_word == '#admin' or lower_word == '#moderator' then
                admin_call = true
            end

            for _, p in ipairs(game.connected_players) do
                if admin_call and p.admin then
                    p.print(prefix..Game.get_player_by_index(event.player_index).name..' mentioned '..word..'!', {r = 1, g = 1, b = 0, a = 1})
                    p.play_sound{path='utility/new_objective', volume_modifier = 1 }
                    success = true
                end

                if not admin_call and ('#'..p.name == word or '#'..p.name == trimmed_word) then
                    if p.name == player.name then
                        player.print(prefix..'Can\'t mention yourself!', {r = 1, g = 0, b = 0, a = 1})
                        success = true
                        break;
                    end
                    p.print(prefix..Game.get_player_by_index(event.player_index).name..' mentioned you!', {r = 1, g = 1, b = 0, a = 1})
                    p.play_sound{path='utility/new_objective', volume_modifier = 1 }
                    success = true
                    if _DEBUG then
                        player.print(prefix..'Successful mentioned '..p.name, {r = 0, g = 1, b = 0, a = 1})
                    end
                end
            end
            if not success then
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
