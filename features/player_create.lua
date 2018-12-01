local Game = require 'utils.game'
local Event = require 'utils.event'

local info = require 'features.gui.info'
local join_msgs = require 'resources.join_messages'

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)

    if not player or not player.valid then
        return
    end

    player.insert {name = 'iron-gear-wheel', count = 8}
    player.insert {name = 'iron-plate', count = 16}

    player.print('Welcome to this map created by the RedMew team. You can join our discord at: redmew.com/discord')
    player.print('Click the question mark in the top left corner for server information and map details.')
    player.print(table.get_random_weighted(join_msgs, 1, 2))

    local gui = player.gui
    gui.top.style = 'slot_table_spacing_horizontal_flow'
    gui.left.style = 'slot_table_spacing_vertical_flow'
    if info ~= nil then
        info.show_info({player = player})
    end
end

Event.add(defines.events.on_player_created, player_created)
