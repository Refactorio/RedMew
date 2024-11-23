local DOC = require 'map_gen.maps.danger_ores.configuration'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Normal Science')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
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
