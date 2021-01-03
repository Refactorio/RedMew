local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'

local config = {
    scenario_name = 'crashsite',
    map_gen_settings = {
        MGSP.grass_only,
        MGSP.enable_water,
        {
            terrain_segmentation = 6,
            water = 0.25
        },
        MGSP.starting_area_very_low,
        MGSP.ore_oil_none,
        MGSP.enemy_none,
        MGSP.cliff_none
    }
}

local Scenario = require 'map_gen.maps.crash_site.scenario'
ScenarioInfo.set_map_name('Crashsite')
ScenarioInfo.set_map_description('Capture outposts and defend against the biters.')
ScenarioInfo.add_map_extra_info(
    '- Outposts have enemy turrets defending them.\n- Outposts have loot and provide a steady stream of resources.\n- Outpost markets to purchase items and outpost upgrades.\n- Capturing outposts increases evolution.\n- Reduced damage by all player weapons, turrets, and ammo.\n- Biters have more health and deal more damage.\n- Biters and spitters spawn on death of entities.'
)

return Scenario.init(config)
