require 'config'
require 'utils.utils'
require 'utils.list_utils'
require 'user_groups'
require 'custom_commands'
require 'base_data'
require 'train_station_names'
require 'nuke_control'
require 'follow'
require 'autodeconstruct'
require 'corpse_util'
--require 'infinite_storage_chest'
require 'fish_market'
require 'reactor_meltdown'
require 'map_layout'
require 'bot'
-- GUIs the order determines the order they appear at the top.
require 'info'
require 'player_list'
require 'poll'
require 'tag_group'
require 'tasklist'
require 'blueprint_helper'
require 'paint'
require 'score'
require 'popup'

local Event = require 'utils.event'

local function player_joined(event)
    local player = game.players[event.player_index]
    player.insert {name = 'coin', count = 10}
    player.insert {name = 'iron-gear-wheel', count = 8}
    player.insert {name = 'iron-plate', count = 16}
    player.print('Welcome to our Server. You can join our Discord at: redmew.com/discord')
    player.print('And remember.. Keep Calm And Spaghetti!')    
end

function walkabout(player_name, distance)
    game.player.print('This command moved to /walkabout.')
end

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
local message_weight_sum = 0
for _, w in pairs(hodor_messages) do
    message_weight_sum = message_weight_sum + w[2]
end

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
    -- and indexing game.players with nil is apparently an error.
    local player_index = event.player_index
    if not player_index then
        return
    end

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if message:match('discord') then
        player.print('Did you ask about our discord server?')
        player.print('You can find it here: redmew.com/discord')
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
end

Event.add(defines.events.on_player_created, player_joined)
Event.add(defines.events.on_console_chat, hodor)
Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.players[event.player_index]
        if not player or not player.valid then
            return
        end

        if player.name == 'grilledham' then
            -- pink
            player.color = {r = 0.9290000202716064, g = 0.3860000739097595, b = 0.51399999856948853, a = 0.5}
            player.chat_color = {r = 1, g = 0.51999998092651367, b = 0.63300001621246338, a = 0.5}
        end

        local gui = player.gui
        gui.top.style = 'slot_table_spacing_horizontal_flow'
        gui.left.style = 'slot_table_spacing_vertical_flow'
    end
)

Event.add(
    defines.events.on_console_command,
    function(event)
        local command = event.command
        if command == 'c' or command == 'command' or command == 'silent-command' or command == 'hax' then
            local p_index = event.player_index
            local name
            if p_index then
                name = game.players[event.player_index].name
            else
                name = '<server>'
            end
            local s = table.concat {'[Command] ', name, ' /', command, ' ', event.parameters}
            log(s)
        end
    end
)

global.cheated_items = {}

Event.add(
    defines.events.on_player_crafted_item,
    function(event)
        local pi = event.player_index
        local p = game.players[pi]

        if not p or not p.valid or not p.cheat_mode then
            return
        end

        local cheat_items = global.cheated_items

        local data = cheat_items[pi]
        if not data then
            data = {}
            cheat_items[pi] = data
        end

        local stack = event.item_stack
        local name = stack.name
        local count = data[name] or 0
        data[name] = stack.count + count
    end
)

function print_cheated_items()
    local res = {}
    local players = game.players

    for pi, data in pairs(global.cheated_items) do
        res[players[pi].name] = data
    end

    game.player.print(serpent.block(res))
end
