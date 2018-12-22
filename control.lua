-- Omitting the math library is a very bad idea
require 'utils.math'

-- Map layout and config dictate the map you play and the settings in it
local config = require 'config'
require 'map_layout'

-- Specific to RedMew hosts, can be disabled safely if not hosting on RedMew servers
require 'features.server'
require 'features.server_commands'

-- Library modules which, if missing, will cause other feature modules to fail
require 'features.player_create'
require 'features.user_groups'

-- Feature modules, each can be disabled safely
if config.autodeconstruct.enabled then
    require 'features.autodeconstruct'
end
if config.hodor.enabled or config.auto_respond.enabled or config.mentions.enabled then
    require 'features.chat_triggers'
end
if config.corpse_util.enabled then
    require 'features.corpse_util'
end
if config.custom_commands.enabled then
    require 'features.custom_commands'
end
if config.donator_messages.enabled then
    require 'features.donator_messages'
end
if config.train_saviour.enabled then
    require 'features.train_saviour'
end
if config.fish_market.enabled then
    require 'features.fish_market'
end
if config.free_item_logging.enabled then
    require 'features.free_item_logging'
end
if config.nuke_control.enabled then
    require 'features.nuke_control'
end
if config.player_colors.enabled then
    require 'features.player_colors'
end
if config.reactor_meltdown.enabled then
    require 'features.reactor_meltdown'
end
if config.train_station_names.enabled then
    require 'features.train_station_names'
end
if config.walkabout.enabled then
    require 'features.walkabout'
end
if global.config.performance.enabled then
    require 'features.performance'
end
if global.config.hail_hydra.enabled then
    require 'features.hail_hydra'
end

-- GUIs the order determines the order they appear from left to right.
-- These can be safely disabled if you want less GUI items.
-- Some map presets will add GUI modules themselves.
if config.map_info.enabled then
    require 'features.gui.info'
end
if config.player_list.enabled then
    require 'features.gui.player_list'
end
if config.poll.enabled then
    require 'features.gui.poll'
end
if config.tag_group.enabled then
    require 'features.gui.tag_group'
end
if config.tasklist.enabled then
    require 'features.gui.tasklist'
end
if config.blueprint_helper.enabled then
    require 'features.gui.blueprint_helper'
end
if config.paint.enabled then
    require 'features.gui.paint'
end
if config.score.enabled then
    require 'features.gui.score'
end
if config.popup.enabled then
    require 'features.gui.popup'
end
if config.camera.enabled then
    require 'features.gui.camera'
end
