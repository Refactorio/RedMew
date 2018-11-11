-- Libraries. Removing these will likely lead to game crashes
require 'config'
require 'utils.utils'
require 'utils.list_utils'
require 'utils.math'

local Game = require 'utils.game'
local Event = require 'utils.event'

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
require 'features.chat_triggers'
require 'features.corpse_util'
require 'features.donator_messages'
require 'features.fish_market'
require 'features.free_item_logging'
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

Event.add(defines.events.on_player_created, player_created)
