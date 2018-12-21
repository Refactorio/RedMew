-- Map layout and config dictate the map you play and the settings in it
require 'config'

-- Library modules which, if missing, will cause other feature modules to fail
require 'features.player_create'

-- GUIs the order determines the order they appear from left to right.
-- These can be safely disabled if you want less GUI items.
-- Some map presets will add GUI modules themselves.
require 'features.gui.info'
if _DUMP_ENV then
    require 'utils.dump_env'
end
