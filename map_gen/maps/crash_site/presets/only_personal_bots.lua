local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'
local Event = require 'utils.event'

local config = {
    scenario_name = 'crashsite-only-personal-bots',
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
ScenarioInfo.set_map_name('Crashsite - Only Personal Construction Bots')
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
    - Only personal construction bots are available on this map.
    - Roboport, passive provider chest and storage chest do NOT unlock.
    ]]
)

local active_outpost_types = Scenario.all_outpost_types_active
active_outpost_types['mini_t1_robotics_factory'] = false
config.active_outpost_types = active_outpost_types

Event.on_init(function()
  game.forces.player.technologies['logistic-robotics'].enabled = false
  game.forces.player.technologies['logistic-system'].enabled = false
end)

Event.add(defines.events.on_research_finished,
  function(event)
    if event.research.name ~= 'construction-robotics' then
      return
    end
    game.forces.player.recipes['roboport'].enabled = false
    game.forces.player.recipes['passive-provider-chest'].enabled = false
    game.forces.player.recipes['storage-chest'].enabled = false
  end
)

return Scenario.init(config)
