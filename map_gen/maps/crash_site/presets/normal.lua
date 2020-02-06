local MGSP = require 'resources.map_gen_settings'

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

return Scenario.init(config)
