local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'
local Event = require 'utils.event'

local config = {
    scenario_name = 'crashsite-raining-bullets',
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
ScenarioInfo.set_map_name('Crashsite - Raining Bullets')
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
    - Laser and other energy based weapon technology has been disabled.
    ]]
)

Event.on_init(function()
  game.forces.player.technologies['laser'].enabled = false
  game.forces.player.technologies['personal-laser-defense-equipment'].enabled = false
  game.forces.player.technologies['discharge-defense-equipment'].enabled = false
  game.forces.player.technologies['laser-turret'].enabled = false
  game.forces.player.technologies['laser-shooting-speed-1'].enabled = false
  game.forces.player.technologies['laser-shooting-speed-2'].enabled = false
  game.forces.player.technologies['laser-shooting-speed-3'].enabled = false
  game.forces.player.technologies['laser-shooting-speed-4'].enabled = false
  game.forces.player.technologies['laser-shooting-speed-5'].enabled = false
  game.forces.player.technologies['laser-shooting-speed-6'].enabled = false
  game.forces.player.technologies['laser-shooting-speed-7'].enabled = false
  game.forces.player.technologies['laser-weapons-damage-1'].enabled = false
  game.forces.player.technologies['laser-weapons-damage-2'].enabled = false
  game.forces.player.technologies['laser-weapons-damage-3'].enabled = false
  game.forces.player.technologies['laser-weapons-damage-4'].enabled = false
  game.forces.player.technologies['laser-weapons-damage-5'].enabled = false
  game.forces.player.technologies['laser-weapons-damage-6'].enabled = false
  game.forces.player.technologies['laser-weapons-damage-7'].enabled = false
  game.forces.player.technologies['distractor'].enabled = false
  game.forces.player.technologies['destroyer'].enabled = false
end)

local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
RestrictEntities.add_banned({'laser-turret'})
local function on_destroy(event)
  local p = event.player
  if p and p.valid then
      p.print('This preset does not allow placing [item=laser-turret].')
  end
end
Event.add(RestrictEntities.events.on_restricted_entity_destroyed, on_destroy)

return Scenario.init(config)
