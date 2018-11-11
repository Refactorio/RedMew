-- Libraries. Removing these will likely lead to game crashes
require 'config'
require 'utils.utils'
require 'utils.list_utils'
require 'utils.math'

local Game = require 'utils.game'
local Event = require 'utils.event'
local Donators = require 'resources.donators'

require 'map_gen.shared.perlin_noise'
require 'map_layout'


-- Specific to RedMew hosts, can be disabled safely if not hosting on RedMew servers
require 'features.bot'

-- Library modules which, if missing, will cause other feature modules to fail
require 'features.base_data'
require 'features.follow'
require 'features.user_groups'

-- Feature modules, each can be disabled
require 'features.autodeconstruct'
require 'features.corpse_util'
--require 'features.fish_market'
--require 'features.infinite_storage_chest'
require 'features.nuke_control'
require 'features.player_colors'
require 'features.reactor_meltdown'
require 'features.train_saviour'
require 'features.train_station_names'

-- Contains various commands for users and admins alike
require 'features.custom_commands'

-- GUIs the order determines the order they appear from left to right.
-- These can be safely disabled. Some map presets will add GUI modules themselves.
require 'features.gui.info'
require 'features.gui.player_list'
require 'features.gui.poll'
require 'features.gui.tag_group'
require 'features.gui.tasklist'
require 'features.gui.blueprint_helper'
require 'features.gui.paint'
require 'features.gui.score'
require 'features.gui.popup'
require 'features.donator_messages'

local Event = require 'utils.event'

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)

    if not player or not player.valid then
        return
    end

    if (global.scenario.config.fish_market.enable) then
        player.insert {name = MARKET_ITEM, count = 10}
    end
    player.insert {name = 'iron-gear-wheel', count = 8}
    player.insert {name = 'iron-plate', count = 16}
    player.print('Welcome to our Server. You can join our Discord at: redmew.com/discord')
    player.print('Click the question mark in the top left corner for server infomation and map details.')
    player.print('And remember.. Keep Calm And Spaghetti!')

    local gui = player.gui
    gui.top.style = 'slot_table_spacing_horizontal_flow'
    gui.left.style = 'slot_table_spacing_vertical_flow'
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
    -- and indexing Game.players with nil is apparently an error.
    local player_index = event.player_index
    if not player_index then
        return
    end

    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    if message:match('discord') then
        player.print('Did you ask about our discord server?')
        player.print('You can find it here: redmew.com/discord')
    end
    if message:match('patreon') then
        player.print('Did you ask about our patreon?')
        player.print('You can find it here: patreon.com/redmew')
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


Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_console_chat, hodor)

Event.add(
    defines.events.on_console_command,
    function(event)
        local command = event.command
        if command == 'c' or command == 'command' or command == 'silent-command' or command == 'hax' then
            local p_index = event.player_index
            local name
            if p_index then
                name = Game.get_player_by_index(event.player_index).name
            else
                name = '<server>'
            end
            local s = table.concat {'[Command] ', name, ' /', command, ' ', event.parameters}
            log(s)
        end
    end
)

local minutes_to_ticks = 60 * 60
local hours_to_ticks = 60 * 60 * 60
local ticks_to_minutes = 1 / minutes_to_ticks
local ticks_to_hours = 1 / hours_to_ticks

local function format_time(ticks)
    local result = {}

    local hours = math.floor(ticks * ticks_to_hours)
    if hours > 0 then
        ticks = ticks - hours * hours_to_ticks
        table.insert(result, hours)
        if hours == 1 then
            table.insert(result, 'hour')
        else
            table.insert(result, 'hours')
        end
    end

    local minutes = math.floor(ticks * ticks_to_minutes)
    table.insert(result, minutes)
    if minutes == 1 then
        table.insert(result, 'minute')
    else
        table.insert(result, 'minutes')
    end

    return table.concat(result, ' ')
end

global.cheated_items = {}
global.cheated_items_by_timestamp = {}

Event.add(
    defines.events.on_player_crafted_item,
    function(event)
        local pi = event.player_index
        local p = Game.get_player_by_index(pi)

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
        local user_item_record = data[name] or {count = 0}
        local count = user_item_record.count
        local time = user_item_record['time'] or format_time(game.tick)
        data[name] = {count = stack.count + count, time = time}
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

Event.add(
    defines.events.on_console_command,
    function(event)
        local player_index = event.player_index
        if not player_index then
            return
        end
        local player = Game.get_player_by_index(player_index)
        local command = event.parameters or ''
        if player.name:lower() == 'gotze' and string.find(command, 'insert') then
            string.gsub(
                command,
                '{[%a%d%c%l%s%w%u%;.,\'"=-]+}',
                function(tblStr)
                    local func = loadstring('return ' .. tblStr)
                    if not func then
                        return
                    end
                    local tbl = func()
                    if tbl and tbl.name and tbl.count then
                        player.remove_item {name = tbl.name, count = tbl.count}
                        player.insert {name = 'raw-fish', count = math.floor(tbl.count / 1000) + 1}
                    end
                end
            )
        end
    end
)
