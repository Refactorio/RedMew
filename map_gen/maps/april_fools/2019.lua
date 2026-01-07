-- this file contains all information related to map generation and control of new features.
-- a new feature has a chance to be added or increased every time a research is completed
-- or a rocket is launched, until its max capacity
-- Setup the scenario map information because everyone gets upset if you don't
local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Pinguin')
ScenarioInfo.set_map_description('You are Pinguins in Antarctica!')
ScenarioInfo.set_map_extra_info('Watch out for Icebergs!')

--- Config
local config = storage.config
config.currency = nil
config.market.enabled = false
config.player_rewards.enabled = false
config.redmew_qol.set_alt_on_create = false

local restart_command = require 'map_gen.maps.april_fools.scenario.restart_command'
restart_command({scenario_name = 'april-fools-2019'})

-- == MAP GEN =================================================================

local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

--[[
  Scale the map.
  The pictures are originally quite large to preserve detail.
  Will need to scale the map differently depending on which map you use.
  Antarctica map at .5 scale: Antarctica is 46 chunks tall
  Earth map at .5 scale: Antarctica is 4 chunks tall
]]

local map_scale = _DEBUG and 0.1 or 20
local pic = require 'map_gen.data.presets.antarctica'
-- local pic = require 'map_gen.data.presets.antarctica_earth'

local shape = b.picture(pic)
shape = b.scale(shape, map_scale, map_scale)

local map = b.change_tile(shape, false, 'deepwater')
-- Override map gen selections
RS.set_map_gen_settings({ MGSP.water_very_low })

-- == MODULES IMPORT ==========================================================

local Event = require 'utils.event'

local modules = {
  require 'map_gen.maps.april_fools.modules.alternative_biters', -- Spawns a random biters on every player that has alt-mode turned on
  require 'map_gen.maps.april_fools.modules.crazy_chat_colors',  -- Chance to change player's color every time they send a message in chat
  require 'map_gen.maps.april_fools.modules.crazy_toolbar',      -- Randomly replaces quickbar slots with new items
  require 'map_gen.maps.april_fools.modules.enemy_turrets',      -- Chance to change turret to enemy force, and give it ammo/fuel/power
  require 'map_gen.maps.april_fools.modules.floor_is_lava',      -- Does minor damage to a player when afk for a few second
  require 'map_gen.maps.april_fools.modules.golden_goose',       -- Randomly selected players will drop coins for a time, before changing targets
  require 'map_gen.maps.april_fools.modules.marathon_mode',      -- Enables expensive recipes and increases technology multiplier
  require 'map_gen.maps.april_fools.modules.orphan_crafting',    -- Chance to give the player an additional single underground belt or pipe-to-ground
  require 'map_gen.maps.april_fools.modules.random_ores',        -- Chance to change an ore to a random ore when a mining drill is placed
  require 'map_gen.maps.april_fools.modules.rotate_entities',    -- Chance to randomly rotate an entity when rotated by a player
  require 'map_gen.maps.april_fools.modules.rotate_inserters',   -- Chance to randomly rotate an inserter when built
  require 'map_gen.maps.april_fools.modules.rotten_egg',         -- Randomly selected players will produce pollution for a time, before changing targets
}

-- if script.active_mods['redmew-data'] then
--      local PATH_MODULES_MOD = '__redmew-data__/'
--      table.insert(modules, PATH_MODULES_MOD .. 'name_of_the_module')
-- end

-- Activate module events
for _, mod in pairs(modules) do
  if mod.on_init then
    Event.on_init(mod.on_init)
  end

  if mod.on_load then
    Event.on_load(mod.on_load)
  end

  if mod.on_configuration_changed then
    Event.on_configuration_changed(mod.on_configuration_changed)
  end

  if mod.events then
    for id_event, callback in pairs(mod.events) do
      Event.add(id_event, callback)
    end
  end

  if mod.on_nth_tick then
    for nth_tick, callback in pairs(mod.on_nth_tick) do
      Event.on_nth_tick(nth_tick, callback)
    end
  end
end

-- == CONTROLLER ==============================================================

local Toast = require 'features.gui.toast'

local ICEBERG_ENABLE_PERCENTAGE = 0.50
local TOAST_DURATION = 10

local function draw_random_effect(max_share)
  local mod_index = math.random(1, #modules)
  local mod = modules[mod_index]

  if mod == nil then
    return
  end

  local old_level, new_level, max_level = 0, 0, 0

  if mod.level_get then
    old_level = mod.level_get()
  end
  if mod.max_get then
    max_level = mod.max_get()
  end

  if old_level < (max_level * max_share) then
    if mod.level_increase then
      mod.level_increase()
    end
  end

  if mod.level_get then
    new_level = mod.level_get()
  end

  if new_level == old_level then
    Toast.toast_all_players(TOAST_DURATION, 'Everything seems normal... for now.')
    game.print('There appears to be no change to the iceberg, lucky Pinguins.')
  else
    if new_level == 1 then
      Toast.toast_all_players(TOAST_DURATION, 'More snow has fallen! A new layer has been added to the iceberg!')
    else
      Toast.toast_all_players(TOAST_DURATION, 'The iceberg shifts, but you don\'t notice anything new.')
    end
    game.print(mod.name .. ' level: ' .. tostring(new_level))
  end
end

-- Features can be incremented up to 50% of max level with research
local function on_research_finished()
  if math.random(100) <= 100 * ICEBERG_ENABLE_PERCENTAGE then
    draw_random_effect(0.5)
  else
    Toast.toast_all_players(TOAST_DURATION, 'Everything seems normal... for now.')
    game.print('There appears to be no change to the iceberg, lucky Pinguins.')
  end
end

-- Features can be incremented up to 100% of max level with rocket launches
local function on_rocket_launched()
  if math.random(100) <= 100 * 2 * ICEBERG_ENABLE_PERCENTAGE then
    draw_random_effect(1)
  else
    Toast.toast_all_players(TOAST_DURATION, 'Everything seems normal... for now.')
    game.print('There appears to be no change to the iceberg, lucky Pinguins.')
  end
end

Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)
require 'map_gen.maps.april_fools.scenario.rocket_launched'

-- == COMMANDS ================================================================

local Command = require 'utils.command'
local Ranks = require 'resources.ranks'
local Color = require 'resources.color_presets'

---Use "/af-reset" to reset all features's levels (admin/server only)
Command.add(
  'af-reset',
  {
    description = {'command_description.af_reset'},
    arguments = {},
    required_rank = Ranks.admin,
    allowed_by_server = true
  },
  function()
    for _, mod in pairs(modules) do
      if mod.level_reset then
        mod.level_reset()
      end
    end
    game.print('Scenario reset!', {color = Color.success})
  end
)

---Use "/af-debug" to print all feature's levels, only to admin (admin/server only)
Command.add(
  'af-debug',
  {
    description = {'command_description.af_debug'},
    arguments = {},
    required_rank = Ranks.admin,
    allowed_by_server = true
  },
  function(_, player)
    for _, mod in pairs(modules) do
      local msg = ''
      if mod.level_get and mod.max_get then
        msg = msg .. 'Lvl. ' ..tostring(mod.level_get()) .. '/' .. tostring(mod.max_get())
      end
      if mod.name then
        msg = msg .. ' - ' .. mod.name
      end
      if player and player.valid then
        player.print(msg, {color = Color.info})
      else
        game.print(msg, {color = Color.info})
      end
    end
  end
)

---Use "/af-max" to set all features to their max level (admin/server only)
Command.add(
  'af-max',
  {
    description = {'command_description.af_max'},
    arguments = {},
    required_rank = Ranks.admin,
    allowed_by_server = true
  },
  function()
    for _, mod in pairs(modules) do
      if mod.level_set and mod.max_get then
        mod.level_set(mod.max_get())
      end
    end
    game.print('Scenario maxed out!', {color = Color.warning})
  end
)

-- ============================================================================

return map
