local Event = require 'utils.event'
local Global = require 'utils.global'
local RS = require 'map_gen.shared.redmew_surface'

local Public = {}

Public.events = {
  on_game_started  = Event.generate_event_name('on_game_started'),
  on_game_finished = Event.generate_event_name('on_game_finished'),
}

Public.scores = {
  rocket_launches = { name = 'rockets-launches-frontier', tooltip = {'frontier.rockets_to_launch'}, sprite = '[img=item.rocket-silo]' },
  shop_funds      = { name = 'shop-funds-frontier',       tooltip = {'frontier.shop_funds'},        sprite = '[img=item.coin]' },
}

Public.ESCAPE_PLAYER = false
Public.VALUE_7_PACKS = 451
Public.PROD_PENALTY = 1.2 * 1.4^5

local this = {
  rounds = 0,
  -- Map gen
  silo_starting_x = 1700,

  height = 36,              -- in chunks, height of the ribbon world
  left_boundary = 8,        -- in chunks, distance to water body
  right_boundary = 11,      -- in chunks, distance to wall/biter presence
  wall_width = 5,           -- in tiles
  wall_vulnerability = true,
  rock_richness = 1,        -- how many rocks/chunk

  ore_base_quantity = 11,   -- base ore quantity, everything is scaled up from this
  ore_chunk_scale = 32 * 20,-- sets how fast the ore will increase from spawn, lower = faster

  -- Kraken handling
  kraken_distance = 25,     -- where the kraken lives past the left boundary
  kraken_contributors = {}, -- list of players eaten by kraken
  death_contributions = {}, -- list of all players deaths

  -- Satellites to win
  rockets_to_win = 1,
  rockets_launched = 0,
  rockets_per_death = 0,    -- how many extra launch needed for each death
  scenario_finished = false,

  -- Loot chests
  loot_budget = 48,
  loot_richness = 1,

  -- Rocket silo position management
  x = 0,
  y = 0,
  rocket_silo = nil,
  move_buffer = 0,
  rocket_step = 500,        -- rocket/tiles ratio
  min_step = 500,           -- minimum tiles to move
  max_distance = 100000,    -- maximum x distance of rocket silo

  -- Enemy data
  invincible = {},
  target_entities = {},
  unit_groups = {},

  -- Lobby
  lobby_enabled = false,

  -- Debug
  _DEBUG_AI = false,
  _DEBUG_SHOP = false,

  -- Markets
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
  spawn_shop_players_in_gui_view = {},
  spawn_shop_gui_refresh_scheduled = {},
  spawn_shop_upgrades = {},
}

Global.register_init(
  this,
  function() this.surface = RS.get_surface() end,
  function(tbl) this = tbl end
)

function Public.get()
  return this
end

return Public
