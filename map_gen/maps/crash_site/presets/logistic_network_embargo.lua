local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'
local Event = require 'utils.event'

local config = {
    scenario_name = 'crashsite-logistic-network-embargo',
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
ScenarioInfo.set_map_name('Crashsite - Logistic Network Embargo')
ScenarioInfo.set_map_description('Capture outposts and defend against the biters.')
ScenarioInfo.add_map_extra_info(
    [[
    - Outposts have enemy turrets defending them.
    - Outposts have loot and provide a steady stream of resources.
    - Outpost markets to purchase items and outpost upgrades.
    - Capturing outposts increases evolution.
    - Reduced damage by all player weapons, turrets, and ammo.
    - Biters have more health and deal more damage.
    - Biters and spitters spawn on death of entities.
    - Active provider, buffer and requester chests are not avaliable.
    ]]
)

local active_outpost_types = Scenario.all_outpost_types_active
active_outpost_types['mini_t1_robotics_factory'] = false
config.active_outpost_types = active_outpost_types

Event.on_init(function()
  game.forces.player.technologies['logistic-system'].enabled = false
end)

return Scenario.init(config)
