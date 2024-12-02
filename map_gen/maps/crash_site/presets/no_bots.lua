local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'
local Event = require 'utils.event'

local config = {
    scenario_name = 'crashsite-nobots',
    map_gen_settings = {
        MGSP.grass_only,
        MGSP.enable_water,
        MGSP.water_very_low,
        MGSP.starting_area_very_low,
        MGSP.ore_oil_none,
        MGSP.enemy_none,
        MGSP.cliff_none
    }
}

local Scenario = require 'map_gen.maps.crash_site.scenario'
ScenarioInfo.set_map_name('Crashsite - No Bots')
ScenarioInfo.set_map_description('Capture outposts and defend against the biters.')
ScenarioInfo.add_map_extra_info(
    [[
    - Outposts have enemy turrets defending them.
    - Outposts have loot and provide a steady stream of resources.
    - Outpost markets to purchase items and outpost upgrades.
    - Capturing outposts increases evolution.\n- Reduced damage by all player weapons, turrets, and ammo.
    - Biters have more health and deal more damage.
    - Biters and spitters spawn on death of entities.
    - Construction and logistic bots are disabled on this map.
    ]]
)

local active_outpost_types = Scenario.all_outpost_types_active
active_outpost_types['mini_t1_robotics_factory'] = false
config.active_outpost_types = active_outpost_types

Event.on_init(function()
    game.forces.player.technologies['construction-robotics'].enabled = false
    game.forces.player.technologies['logistic-robotics'].enabled = false
    game.forces.player.technologies['logistic-system'].enabled = false
    game.forces.player.technologies['personal-roboport-equipment'].enabled = false
    game.forces.player.technologies['personal-roboport-mk2-equipment'].enabled = false
    game.forces.player.technologies['worker-robots-storage-1'].enabled = false
    game.forces.player.technologies['worker-robots-storage-2'].enabled = false
    game.forces.player.technologies['worker-robots-storage-3'].enabled = false
    game.forces.player.technologies['worker-robots-speed-1'].enabled = false
    game.forces.player.technologies['worker-robots-speed-2'].enabled = false
    game.forces.player.technologies['worker-robots-speed-3'].enabled = false
    game.forces.player.technologies['worker-robots-speed-4'].enabled = false
    game.forces.player.technologies['worker-robots-speed-5'].enabled = false
    game.forces.player.technologies['worker-robots-speed-6'].enabled = false
end)

return Scenario.init(config)
