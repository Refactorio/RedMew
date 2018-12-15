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
if config.auto_deconstruct.enabled then
    require 'features.autodeconstruct'
end
if config.hodor.enabled or config.auto_respond.enabled or config.mentions.enabled then
    require 'features.chat_triggers'
end
require 'features.corpse_util'
require 'features.custom_commands'
require 'features.donator_messages'
require 'features.train_saviour'
if config.fish_market.enabled then
    require 'features.fish_market'
end
require 'features.free_item_logging'
if config.nuke_control.enabled then
    require 'features.nuke_control'
end
require 'features.player_colors'
if config.reactor_meltdown.enabled then
    require 'features.reactor_meltdown'
end
require 'features.train_station_names'
require 'features.walkabout'

if global.config.performance.enabled then
    require 'features.performance'
end

if global.config.hail_hydra.enabled then
    require 'features.hail_hydra'
end

-- GUIs the order determines the order they appear from left to right.
-- These can be safely disabled if you want less GUI items.
-- Some map presets will add GUI modules themselves.
require 'features.gui.info'
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
require 'features.gui.popup'
require 'features.gui.camera'
