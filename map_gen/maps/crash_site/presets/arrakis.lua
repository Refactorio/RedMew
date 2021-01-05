require 'map_gen.maps.crash_site.features.sandworms'
require 'map_gen.maps.crash_site.features.repair_cars'

local ScenarioInfo = require 'features.gui.info'
local MGSP = require 'resources.map_gen_settings'

local config = {
    scenario_name = 'crashsite-arrakis',
    map_gen_settings = {
        MGSP.sand_only,
        MGSP.water_none,
        MGSP.starting_area_very_low,
        MGSP.ore_oil_none,
        MGSP.enemy_none,
        MGSP.tree_none,
        MGSP.cliff_none,
        {
            property_expression_names = {
                ['control-setting:moisture:bias'] = '-0.500000'
            },
            autoplace_controls = {
                trees = {
                    frequency = 6,
                    richness = 1,
                    size = 0.1666666716337204
                }
            }
        }
    }
}

local Scenario = require 'map_gen.maps.crash_site.scenario'
ScenarioInfo.set_map_name('Crashsite Arrakis')
ScenarioInfo.set_map_description('Capture outposts and defend against the biters. Even drier than desert, sandworms roam the desert and will attack roboports on sight.')
ScenarioInfo.add_map_extra_info(
    [[
    - Arrakis is even drier than crash site Desert.
    - Sandworms are attracted to the vibration caused by roboports and will spawn intermittently to neutralise this threat to their peace.
    - Cars have repair beams.
    - Outposts have enemy turrets defending them.
    - Outposts have loot and provide a steady stream of resources.
    - Outpost markets to purchase items and outpost upgrades.
    - Capturing outposts increases evolution.\n- Reduced damage by all player weapons, turrets, and ammo.
    - Biters have more health and deal more damage.\n- Biters and spitters spawn on death of entities.
    ]]
)

return Scenario.init(config)
