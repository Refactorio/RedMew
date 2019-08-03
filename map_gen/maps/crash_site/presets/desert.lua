local MGSP = require 'resources.map_gen_settings'

local config = {
    scenario_name = 'crashsite-desert',
    map_gen_settings = {
        MGSP.sand_only,
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
                    frequency = 6,
                    richness = 1,
                    size = 0.1666666716337204
                }
            }
        }
    }
}

local Scenario = require 'map_gen.maps.crash_site.scenario'

return Scenario.init(config)
