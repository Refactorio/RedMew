local b = require 'map_gen.shared.builders'
require 'map_gen.shared.car_body'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'

local loot = require 'map_gen.shared.loot_items'

ScenarioInfo.set_map_name('Rocky Road')
ScenarioInfo.set_map_description(
    'We want a vanilla map, they said.\nYou might get the vanilla terrain,\nBut not the vanilla character! Enjoy driving yourself crazy with this one :D'
)
ScenarioInfo.add_map_extra_info('Players stuck in cars, day/night cycle modified to make solar a pain.')

RS.set_map_gen_settings(
    {
        MGSP.cliff_high
    }
)

local map = b.full_shape
map = b.apply_entity(map, loot)

return map
