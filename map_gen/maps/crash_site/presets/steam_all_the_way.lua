local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'
local Event = require 'utils.event'

local config = {
    scenario_name = 'crashsite-steam-all-the-way',
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
ScenarioInfo.set_map_name('Crashsite - Steam all the way')
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
    - Nuclear power is completely disabled.
    - Accumulators and Solar Panels cannot be placed but are still available for other recipes.
    ]]
)

local active_outpost_types = Scenario.all_outpost_types_active
active_outpost_types['mini_t2_energy_factory'] = false
active_outpost_types['medium_power_factory'] = false
active_outpost_types['big_power_factory'] = false
config.active_outpost_types = active_outpost_types

Event.on_init(function()
  game.forces.player.technologies['nuclear-power'].enabled = false
  game.forces.player.technologies['nuclear-fuel-reprocessing'].enabled = false
end)

Event.add(defines.events.on_research_finished,
  function(event)
    if event.research.name ~= 'uranium-processing' then
      return
    end
    game.forces.player.recipes['uranium-fuel-cell'].enabled = false
  end
)

local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
RestrictEntities.add_banned({'solar-panel', 'accumulator'})
local function on_destroy(event)
  local p = event.player
  if p and p.valid then
      p.print('This preset does not allow placing [item=accumulator] or [item=solar-panel].')
  end
end
Event.add(RestrictEntities.events.on_restricted_entity_destroyed, on_destroy)

return Scenario.init(config)
