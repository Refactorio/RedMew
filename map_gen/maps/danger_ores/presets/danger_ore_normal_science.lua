local DOC = require 'map_gen.maps.danger_ores.configuration'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Normal Science')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])
ScenarioInfo.set_new_info([[
  2019-04-24:
      - Stone ore density reduced by 1/2
      - Ore quadrants randomized
      - Increased time factor of biter evolution from 5 to 7
      - Added win conditions (+5% evolution every 5 rockets until 100%, +100 rockets until biters are wiped)

  2019-03-30:
      - Uranium ore patch threshold increased slightly
      - Bug fix: Cars and tanks can now be placed onto ore!
      - Starting minimum pollution to expand map set to 650
      View current pollution via Debug Settings [F4] show-pollution-values,
      then open map and turn on pollution via the red box.
      - Starting water at spawn increased from radius 8 to radius 16 circle.

  2019-03-27:
      - Ore arranged into quadrants to allow for more controlled resource gathering.

  2020-09-02:
      - Destroyed chests dump their content as coal ore.

  2020-12-28:
      - Changed win condition. First satellite kills all biters, launch 500 to win the map.

  2021-04-06:
      - Rail signals and train stations now allowed on ore.
]])

Config.hail_hydra.enabled = true
Config.hail_hydra.online_player_scale_enabled = false
Config.hail_hydra.hydras = {
  -- spitters
  ['medium-spitter'] = {
    ['small-worm-turret'] = { min = 0.250, max = 0.50 },
  },
  ['big-spitter'] = {
    ['big-worm-turret']   = { min = 0.250, max = 0.50 },
  },
  ['behemoth-spitter'] = {
    ['big-worm-turret']   = { min = 0.250, max = 0.50 },
  },
  -- biters
  ['medium-biter'] = {
    ['small-worm-turret'] = { min = 0.250, max = 0.50 },
  },
  ['big-biter'] = {
    ['big-worm-turret']   = { min = 0.250, max = 0.50 },
  },
  ['behemoth-biter'] = {
    ['big-worm-turret']   = { min = 0.250, max = 0.50 },
  },
  -- worms
  ['small-worm-turret'] = {
    ['small-biter']       = { min = 0.125, max = 0.25 },
    ['small-spitter']     = { min = 0.125, max = 0.25 },
  },
  ['medium-worm-turret'] = {
    ['medium-biter']      = { min = 0.125, max = 0.25 },
    ['medium-spitter']    = { min = 0.125, max = 0.25 },
  },
  ['big-worm-turret'] = {
    ['big-biter']         = { min = 0.125, max = 0.25 },
    ['big-spitter']       = { min = 0.125, max = 0.25 },
  },
  ['behemoth-worm-turret'] = {
    ['behemoth-biter']    = { min = 0.125, max = 0.25 },
    ['behemoth-spitter']  = { min = 0.125, max = 0.25 },
  },
}

DOC.biter_drops.enabled = false
DOC.game.peaceful_mode = false
DOC.game.technology_price_multiplier = 1
DOC.rocket_launched.win_satellite_count = 5000

return Scenario.register(DOC)
