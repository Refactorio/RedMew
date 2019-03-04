-- If you're looking to configure anything, you want config.lua. Nearly everything in this file is dictated by the config.

-- Info on the data lifecycle and how we use it: https://github.com/Refactorio/RedMew/wiki/The-data-lifecycle
require 'resources.data_stages'
_LIFECYCLE = _STAGE.control -- Control stage

-- Overrides the _G.print function
require 'utils.print_override'

-- Omitting the math library is a very bad idea
require 'utils.math'

-- Global Debug and make sure our version file is registered
Debug = require 'utils.debug'
require 'resources.version'

-- Config and map_loader dictate the map you play and the settings in it
local config = require 'config'
require 'map_gen.shared.map_loader' -- to change the map you're playing, modify map_selection.lua

-- Specific to RedMew hosts, can be disabled safely if not hosting on RedMew servers
require 'features.server'
require 'features.server_commands'

-- Library modules
-- If missing, will cause other feature modules to fail
require 'features.player_create'
require 'features.rank_system'

-- Feature modules
-- Each can be disabled safely
if config.train_saviour.enabled then
    require 'features.train_saviour'
end
if config.infinite_storage_chest.enabled then
    require 'features.infinite_storage_chest'
end
if config.autodeconstruct.enabled then
    require 'features.autodeconstruct'
end
if config.hodor.enabled or config.auto_respond.enabled or config.mentions.enabled then
    require 'features.chat_triggers'
end
if config.corpse_util.enabled then
    require 'features.corpse_util'
end
if config.admin_commands.enabled then
    require 'features.admin_commands'
end
if config.redmew_commands.enabled then
    require 'features.redmew_commands'
end
if config.donator_commands.enabled then
    require 'features.donator_commands'
end
if config.market.enabled then
    require 'features.market'
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
if config.performance.enabled then
    require 'features.performance'
end
if config.hail_hydra.enabled then
    require 'map_gen.shared.hail_hydra'
end
if config.lazy_bastard.enabled then
    require 'features.lazy_bastard'
end
if config.redmew_qol.enabled then
    require 'features.redmew_qol'
end
if config.camera.enabled then
    require 'features.gui.camera'
end
if config.day_night.enabled then
    require 'map_gen.shared.day_night'
end
if config.apocalypse.enabled then
    require 'features.apocalypse'
end
if config.player_onboarding.enabled then
    require 'features.player_onboarding'
end

-- GUIs
-- The order determines the order they appear from left to right.
-- These can be safely disabled if you want less GUI items.
-- Some map presets will add GUI modules themselves.
if config.map_info.enabled then
    require 'features.gui.info'
end
if config.player_list.enabled then
    require 'features.gui.player_list'
end
if config.evolution_progress.enabled then
    require 'features.gui.evolution_progress'
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
if config.rich_text_gui.enabled then
    require 'features.gui.rich_text'
end

-- Debug-only modules
if _DEBUG then
    require 'features.scenario_data_manipulation'
end
-- Needs to be at bottom so tokens are registered last.
if _DUMP_ENV then
    require 'utils.dump_env'
end
if _DEBUG then
    require 'features.gui.debug.command'
end
