--[[
  Scenario info: Double Trouble
  2024 revamped version of "Pinguin" scenario from 2019 with several addons.

  Required mods:
  - Alien Biomes v0.7.2
  - RedMew Data  v1.1.0
]]

if not script.active_mods['alien-biomes'] or not (script.active_mods['redmew-data'] and settings.startup.redmew_scenario.value == 'april-fools') then
  error([[
    Missing dependencies. Please check that the following mods have been correctly installed:
    - Alien Biomes >= v0.7.2
    - RedMew Data >= v1.1.0 & scenario setting "April Fools"
  ]])
end

local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Double Trouble')
ScenarioInfo.set_map_description([[
  [font=default-bold]Welcome to [color=blue]Double[/color] [color=red]Trouble[/color]![/font]

  You have crash landed on a winter and adverse planet. There's nothing visible, just... Threats. You take refuge underground to build a new empire, but something goes wrong again...
  In fact... Nothing seems to be going right.

  Have fun in this new adventure. Build the infrastructure underground to return to the surface and escape this planet. Use support pylons to protect the market and avoid collapses underground. Build tunnels to move resources to the surface faster, resist adversities, and achieve victory!

  Good luck, have fun.
  The [color=red]RedMew[/color] team
]])
ScenarioInfo.set_map_extra_info('Watch out for Icebergs!')

--- Config
local Config = storage.config
Config.paint.enabled = false
Config.redmew_surface.enabled = false
Config.currency = 'coin'
Config.market.enabled = false
Config.player_rewards.enabled = true
Config.redmew_qol.set_alt_on_create = false

local restart_command = require 'map_gen.maps.april_fools.scenario.restart_command'
restart_command({scenario_name = 'april-fools-2024', mod_pack = 'april_fools_2024'})

if _DEBUG then
  Config.player_create.starting_items = {
    {name = 'tunnel', count = 10},
    {name = 'iron-plate', count = 26 },
    {name = 'steel-chest', count = 12},
    {name = 'power-armor-mk2', count = 1},
    {name = 'fission-reactor-equipment', count = 4},
    {name = 'personal-roboport-mk2-equipment', count = 4},
    {name = 'battery-mk2-equipment', count = 4},
    {name = 'construction-robot', count = 50},
    {name = 'rocket-launcher', count = 1},
    {name = 'explosive-rocket', count = 200},
    {name = 'dungeon-support', count = 50},
  }
else
  Config.player_create.starting_items = {
    {name = 'burner-mining-drill', count = 4 },
    {name = 'stone-furnace', count = 2},
    {name = 'iron-gear-wheel', count = 3},
    {name = 'electronic-circuit', count = 5},
    {name = 'pistol', count = 1},
    {name = 'firearm-magazine', count = 20},
    {name = 'coal', count = 34},
  }
end

-- == MAP GEN =================================================================

local Event = require 'utils.event'
local ABS = require 'resources.alien_biomes.biomes_settings'
local ABT = require 'resources.alien_biomes.tile_presets'
local Biomes = require 'resources.alien_biomes.biomes'
local mgs = Biomes.preset_to_mgs

require 'map_gen.maps.april_fools.scenario.camera'
require 'map_gen.maps.april_fools.scenario.cave_collapse'
require 'map_gen.maps.april_fools.scenario.entity-restrictions'
require 'map_gen.maps.april_fools.scenario.evolution_control'
require 'map_gen.maps.april_fools.scenario.market'
require 'map_gen.maps.april_fools.scenario.mines'

local function on_init()
  local spawn = {0, 0}

  -- Above ground
  local islands_preset = Biomes.presets.ice
  islands_preset.water = ABS.water.low
  islands_preset.enemy = ABS.enemy.high
  local islands_mgs = mgs(islands_preset)
  islands_mgs.starting_area = 3
  islands_mgs.autoplace_settings = ABT.cold
  islands_mgs.autoplace_settings.tile.treat_missing_as_default = true
  for tile, _ in pairs(ABT.default.tile.settings) do
    islands_mgs.autoplace_settings.tile.settings[tile] = { frequency = 1, size = 0, richness = 1 }
  end
  for _, resource in pairs({'iron-ore', 'copper-ore', 'stone', 'coal', 'uranium-ore', 'crude-oil'}) do
    islands_mgs.autoplace_controls[resource] = { frequency = 1, richness = 1, size = 0 }
  end
  islands_mgs.autoplace_controls['crude-oil'] = { frequency = 1, richness = 2, size = 1.2 }
  islands_mgs.property_expression_names.elevation = 'elevation_island'
  local islands = game.create_surface('islands', islands_mgs)
  islands.request_to_generate_chunks(spawn, 5)
  islands.force_generate_chunk_requests()
  islands.ticks_per_day = 72000
  islands.localised_name = 'Islands'

  -- Under ground
  local mines_preset = Biomes.presets.volcano
  mines_preset.water = ABS.water.none
  mines_preset.enemy = ABS.enemy.none
  local mines_mgs = mgs(mines_preset)
  mines_mgs.seed = _DEBUG and 309111855 or nil
  mines_mgs.autoplace_settings = ABT.volcano
  for _, tile in pairs({'deepwater', 'deepwater-green', 'water', 'water-green', 'water-mud', 'water-shallow'}) do
    mines_mgs.autoplace_settings.tile.settings[tile] = { frequency = 1, size = 0, richness = 1 }
  end
  for _, resource in pairs({'iron-ore', 'copper-ore', 'stone', 'coal', 'uranium-ore', 'crude-oil'}) do
    mines_mgs.autoplace_controls[resource] = { frequency = 12.0, size = 0.5, richness = 0.08 }
  end
  local mines = game.create_surface('mines', mines_mgs)
  mines.request_to_generate_chunks(spawn, 2)
  mines.force_generate_chunk_requests()
  mines.solar_power_multiplier = 0
  mines.min_brightness = 0.11
  mines.ticks_per_day = 72000
  mines.daytime = 0.42
  mines.freeze_daytime = true
  mines.show_clouds = false
  mines.brightness_visual_weights = {1/0.85, 1/0.85, 1/0.85}
  mines.localised_name = 'Mines'

  game.forces.player.set_surface_hidden('nauvis', true)
  game.forces.player.set_spawn_position(spawn, 'islands')
  game.forces.player.manual_mining_speed_modifier = _DEBUG and 20 or 1.2
end

local function on_player_created(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  local islands = game.surfaces['islands']
  local pos = islands.find_non_colliding_position('character', {0,0}, 20, 1)
  player.teleport(pos, 'islands')
end

Event.on_init(on_init)
Event.add(defines.events.on_player_created, on_player_created)

-- == MODULES IMPORT ==========================================================

local modules = {
  require 'map_gen.maps.april_fools.modules.alternative_biters',  -- Spawns a random biters on every player that has alt-mode turned on
  require 'map_gen.maps.april_fools.modules.auto_build',          -- Randomly selected players will have their cursor items automatically built nearby for a time, before changing targets
  require 'map_gen.maps.april_fools.modules.biter_ores',          -- Biters spawn ores on death, level determines amount
  require 'map_gen.maps.april_fools.modules.crazy_chat_colors',   -- Chance to change player's color every time they send a message in chat
  require 'map_gen.maps.april_fools.modules.crazy_toolbar',       -- Randomly replaces quick-bar slots with new items
  require 'map_gen.maps.april_fools.modules.enemy_turrets',       -- Chance to change turret to enemy force, and give it ammo/fuel/power
  require 'map_gen.maps.april_fools.modules.explosion_scare',     -- Spawns random non-damaging explosions on random players as a jump-scare
  require 'map_gen.maps.april_fools.modules.floor_is_lava',       -- Does minor damage to a player when afk for a few second
  require 'map_gen.maps.april_fools.modules.golden_goose',        -- Randomly selected players will drop coins for a time, before changing targets
  require 'map_gen.maps.april_fools.modules.marathon_mode',       -- Enables expensive recipes and increases technology multiplier
  require 'map_gen.maps.april_fools.modules.meteOres',            -- Meteors fall from the sky, generating ores, and biters
  require 'map_gen.maps.april_fools.modules.orphan_crafting',     -- Chance to give the player an additional single underground belt or pipe-to-ground
  require 'map_gen.maps.april_fools.modules.permanent_factory',   -- Chance to make an entity indestructible
  require 'map_gen.maps.april_fools.modules.random_ores',         -- Chance to change an ore to a random ore when a mining drill is placed
  require 'map_gen.maps.april_fools.modules.rotate_entities',     -- Chance to randomly rotate an entity when rotated by a player
  require 'map_gen.maps.april_fools.modules.rotate_inserters',    -- Chance to randomly rotate an inserter when built
  require 'map_gen.maps.april_fools.modules.rotten_egg',          -- Randomly selected players will produce pollution for a time, before changing targets
  require 'map_gen.maps.april_fools.modules.unorganized_recipes', -- Randomly selected players will have their recipe groups and subgroups disabled, un-organizing their crafting menu
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

local ICEBERG_ENABLE_PERCENTAGE = _DEBUG and 1 or 0.50
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
    required_rank = Ranks.auto_trusted,
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

--return map