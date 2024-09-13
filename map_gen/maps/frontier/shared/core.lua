local Event = require 'utils.event'
local Global = require 'utils.global'
local Queue = require 'utils.queue'
local RS = require 'map_gen.shared.redmew_surface'
local ScoreTracker = require 'utils.score_tracker'

local SECOND = 60
local MINUTE = SECOND * 60
local math_random = math.random

local Public = {}

Public.events = {
  on_game_started  = Event.generate_event_name('on_game_started'),
  on_game_finished = Event.generate_event_name('on_game_finished'),
}

Public.scores = {
  rocket_launches = { name = 'rockets-launches-frontier', tooltip = {'frontier.rockets_to_launch'}, sprite = '[img=item.rocket-silo]' },
  shop_funds      = { name = 'shop-funds-frontier',       tooltip = {'frontier.shop_funds'},        sprite = '[img=item.coin]' },
}

Public.restart_mode = {
  none = 1,
  reset = 2,
  restart = 3,
  switch = 4,
}

Public.ESCAPE_PLAYER = false
Public.VALUE_7_PACKS = 451
Public.PROD_PENALTY = 1.2 * 1.4^5

local this = {
  rounds = 0,
  server_commands = {
    restarting = false,
    mode = Public.restart_mode.reset,
    switch_map = {
      name = nil,
      mod_pack = nil,
    }
  },
  -- Map gen
  chart_queue = Queue.new(),
  height = 36,              -- in chunks, height of the ribbon world
  left_boundary = 8,        -- in chunks, distance to water body
  right_boundary = 11,      -- in chunks, distance to wall/biter presence
  wall_width = 5,           -- in tiles
  rock_richness = 1,        -- how many rocks/chunk
  ore_base_quantity = 11,   -- base ore quantity, everything is scaled up from this
  ore_chunk_scale = 32 * 20,-- sets how fast the ore will increase from spawn, lower = faster

  -- Kraken handling
  kraken_distance = 25,     -- where the kraken lives past the left boundary
  kraken_contributors = {}, -- list of players eaten by kraken
  death_contributions = {}, -- list of all players deaths

  -- Rocket silo position management
  x = 0,
  y = 0,
  rocket_silo = nil,
  silo_starting_x = 1700,
  move_buffer = 0,
  rocket_step = 500,        -- rocket/tiles ratio
  min_step = 500,           -- minimum tiles to move
  max_distance = 100000,    -- maximum x distance of rocket silo
  rockets_to_win = 1,
  rockets_launched = 0,
  rockets_per_death = 0,    -- how many extra launch needed for each death
  scenario_finished = false,

  -- Enemy data
  spawn_enemy_outpost = false,
  spawn_enemy_wave = false,
  invincible = {},
  target_entities = {},
  unit_groups = {},

  -- Lobby
  lobby_enabled = false,

  -- Debug
  _DEBUG_AI = false,
  _DEBUG_SHOP = false,
  _DEBUG_NOISE = false,

  -- Markets
  loot_budget = 48,
  loot_richness = 1,
  banned_items = {
    ['rocket-silo'] = true,
    ['space-science-pack'] = true,
    ['atomic-bomb'] = true,
    ['spidertron'] = true,
    ['tank'] = true
  },

  -- Spawn shop
  spawn_shop = nil,
  spawn_shop_funds = 0,
  spawn_shop_upgrades = {},
  spawn_shop_cooldown = {},
}

Global.register(this, function(tbl) this = tbl end)

function Public.get(key)
  if key then
    return this[key]
  end
  return this
end

function Public.set(key, value)
  this[key] = value
end

function Public.surface()
  return RS.get_surface()
end

function Public.reset()
  local ms = game.map_settings
  ms.enemy_expansion.friendly_base_influence_radius = 0
  ms.enemy_expansion.min_expansion_cooldown = SECOND * 30
  ms.enemy_expansion.max_expansion_cooldown = MINUTE * 4
  ms.enemy_expansion.max_expansion_distance = 5
  ms.enemy_evolution.destroy_factor = 0.0001
  ms.enemy_evolution.time_factor = 0.000004 -- default: 0.000004, dw: 0.000015
  ms.pollution.ageing = 1 -- default: 1, dw: 0.5
  ms.pollution.diffusion_ratio = 0.02 -- default: 0.02, dw: 0.04
  ms.pollution.enemy_attack_pollution_consumption_modifier = 1 -- default: 1, dw: 0.5

  this.rounds = this.rounds + 1
  this.kraken_contributors = {}
  this.death_contributions = {}
  this.rockets_to_win = 12 + math_random(12) + this.rounds
  this.rockets_launched = 0
  this.scenario_finished = false
  this.x = 0
  this.y = 0
  this.rocket_silo = nil
  this.move_buffer = 0
  this.invincible = {}
  this.target_entities = {}
  this.unit_groups = {}
  this.spawn_shop_funds = 1
  this.spawn_shop_upgrades = {}
  this.spawn_shop_cooldown = {}

  if _DEBUG then
    this.silo_starting_x = 30
    this.rockets_to_win = 2
    this.spawn_shop_funds = 3
  end

  for _, force in pairs(game.forces) do
    force.reset()
    force.reset_evolution()
  end

  game.speed = 1
  game.reset_game_state()
  game.reset_time_played()

  ScoreTracker.reset()
  ScoreTracker.set_for_global(Public.scores.rocket_launches.name, this.rockets_to_win)
  ScoreTracker.set_for_global(Public.scores.shop_funds.name, this.spawn_shop_funds)

  if script.active_mods['Krastorio2'] then
    if remote.interfaces['redmew-data'] and remote.interfaces['redmew-data']['set_spawn_x'] then
      remote.call( 'redmew-data', 'set_spawn_x', this.right_boundary * 32 + 96 )
    end
  end
end

return Public
