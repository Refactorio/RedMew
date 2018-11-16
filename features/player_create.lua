local Game = require 'utils.game'
local Event = require 'utils.event'

local info = require 'features.gui.info'

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

    player.print('Trouble chatting? Change the keybinding in:')
    player.print('Options -> Controls -> Toggle Lua console')

    local gui = player.gui
    gui.top.style = 'slot_table_spacing_horizontal_flow'
    gui.left.style = 'slot_table_spacing_vertical_flow'
    if info ~= nil then
        info.show_info({player = player})
    end
end

Event.add(defines.events.on_player_created, player_created)
