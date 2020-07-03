local MGSP = require 'resources.map_gen_settings'

local config = {
    scenario_name = 'crashsite-forest',
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
        MGSP.cliff_none,
        {
            property_expression_names = {
                ['control-setting:moisture:bias'] = '-0.500000'
            },
            autoplace_controls = {
                trees = {
                    frequency = 10,
                    richness = 100,
                    size = 10
                }
            }
        }
    }
}

local Scenario = require 'map_gen.maps.crash_site.scenario'

return Scenario.init(config)
