-- Libraries. Removing these will likely lead to game crashes
require 'config'
require 'utils.utils'
require 'utils.list_utils'
require 'utils.math'

require 'map_gen.shared.perlin_noise'
require 'map_layout'

-- Specific to RedMew hosts, can be disabled safely if not hosting on RedMew servers
require 'server'
require 'server_commands'

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
