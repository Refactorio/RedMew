-- Libraries. Removing these will likely lead to game crashes
require 'config'
require 'utils.utils'
require 'utils.list_utils'
require 'utils.math'

require 'map_gen.shared.perlin_noise'
require 'map_layout'

-- Specific to RedMew hosts, can be disabled safely if not hosting on RedMew servers
Server = require 'server'
ServerCommands = require 'server_commands'

-- Library modules which, if missing, will cause other feature modules to fail
require 'features.base_data'
--require 'features.follow' -- Nothing currently uses anything inside follow
require 'features.player_create'
require 'features.user_groups'

-- Feature modules, each can be disabled
require 'features.autodeconstruct'
require 'features.chat_triggers'
require 'features.corpse_util'
require 'features.donator_messages'
require 'features.train_saviour'
require 'features.fish_market'
require 'features.free_item_logging'
--require 'features.infinite_storage_chest'
require 'features.nuke_control'
require 'features.player_colors'
require 'features.reactor_meltdown'
require 'features.train_station_names'
require 'features.walkabout'

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

local Token = require('utils.global_token')
local data_callback =
    Token.register(
    function(data)
        game.print(serpent.line(data))
    end
)

function get_data(data_set, key)
    Server.try_get_data(data_set, key, data_callback)
end

function get_all_data(data_set, key)
    Server.try_get_all_data(data_set, data_callback)
end

local Event = require('utils.event')
Event.add(
    Server.events.on_server_started,
    function(tbl)
        game.print('on_server_started')
        print('on_server_started')
        game.print(serpent.block(tbl))
        print(serpent.block(tbl))

        Server.try_get_all_data('webtest', data_callback)
    end
)

local data_token =
    Token.register(
    function(data)
        global.data = data.entries
    end
)

function get_data_set(data_set)
    Server.try_get_all_data(data_set, data_token)
end
