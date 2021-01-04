local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'

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
ScenarioInfo.set_map_name('Crashsite Desert')
ScenarioInfo.set_map_description('A desert version of Crash Site. Capture outposts and defend against the biters.')
ScenarioInfo.add_map_extra_info(
    '- A desert version of Crash Site, with sandy terrain, scattered oases and few trees\n'
    .. '- Outposts have enemy turrets defending them.\n'
    .. '- Outposts have loot and provide a steady stream of resources.\n'
    .. '- Outpost markets to purchase items and outpost upgrades.\n'
    .. '- Capturing outposts increases evolution.\n'
    .. '- Reduced damage by all player weapons, turrets, and ammo.\n'
    .. '- Biters have more health and deal more damage.\n'
    .. '- Biters and spitters spawn on death of entities.'
)

return Scenario.init(config)
