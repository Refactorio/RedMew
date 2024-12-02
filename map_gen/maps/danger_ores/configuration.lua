local B = require 'map_gen.shared.builders'
local H = require 'map_gen.maps.danger_ores.modules.helper'

return {
  scenario_name = 'danger-ore',
  restart_command = {
    enabled = true,
  },
  allowed_entities = {
    enabled = true,
    refund = true,
    types = require 'map_gen.maps.danger_ores.config.vanilla_allowed_entities',
    allowed_entities = {},
    banned_entities = {},
  },
  biter_drops = {
    enabled = true,
  },
  compatibility = {
    aai_loaders = {
      enabled = true,
    },
    early_construction = {
      enabled = true,
    },
    deadlock = {
      enabled = true,
      items = require 'map_gen.maps.danger_ores.compatibility.deadlock.allowed_items',
    },
    redmew_data = {
      enabled = true,
      remove_resource_patches = true,
    }
  },
  container_dump = {
    enabled = true,
    entity_name = 'coal'
  },
  concrete_on_landfill = {
    enabled = true,
    tile = 'blue-refined-concrete',
    refund_tile = 'refined-concrete',
  },
  disable_mining_productivity = {
    enabled = true,
    replace = true, -- replace mining productivity with robot cargo capacity
  },
  map_poll = {
    enabled = true,
  },
  map_gen_settings = {
    enabled = true,
    settings = H.empty_map_settings(),
  },
  prevent_quality_mining = {
    enabled = true,
  },
  rocket_launched = {
    enabled = true,
    win_satellite_count = 1000,
  },
  terraforming = {
    enabled = true,
    start_size = 12 * 32,
    min_pollution = 400,
    max_pollution = 15000,
    pollution_increment = 4,
  },
  technologies = {
    enabled = true,
    unlocks = {
      ['uranium-mining'] = { 'uranium-processing' },
      ['oil-gathering'] = { 'oil-processing', 'coal-liquefaction' },
    },
  },
  game = {
    draw_resource_selection = false,
    technology_price_multiplier = 25,
    manual_mining_speed_modifier = 1,
    always_day = true,
    peaceful_mode = true,
    enemy_evolution = {
      enabled = true,
      time_factor = 0.000007, -- default 0.000004
      destroy_factor = 0.000010, -- default 0.002
      pollution_factor = 0.000000, -- Pollution has no affect on evolution default 0.0000009
    },
    on_init = nil,
  },
  map_config = {
    -- Start area
    spawn_shape = B.circle(64),
    start_ore_shape = B.circle(68),
    -- Ore pattern
    main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores',
    main_ores_shuffle_order = true,
    main_ores_rotate = 30,
    no_resource_patch_shape = B.circle(80),
    resource_patches = require 'map_gen.maps.danger_ores.modules.resource_patches',
    resource_patches_config = require 'map_gen.maps.danger_ores.config.vanilla_resource_patches',
    -- Dense patches
    dense_patches = nil,
    dense_patches_scale = 1 / 48,
    dense_patches_threshold = 0.5,
    dense_patches_multiplier = 50,
    -- Water
    water = require 'map_gen.maps.danger_ores.modules.water',
    water_scale = 1 / 96,
    water_threshold = 0.4,
    deepwater_threshold = 0.45,
    no_water_shape = B.circle(102),
    fish_spawn_rate = 0.025,
    -- Trees
    trees = require 'map_gen.maps.danger_ores.modules.trees',
    trees_scale = 1 / 64,
    trees_threshold = 0.3,
    trees_chance = 0.875,
    -- Enemies
    enemy = require 'map_gen.maps.danger_ores.modules.enemy',
    enemy_factor = 10 / (768 * 32),
    enemy_max_chance = 1 / 6,
    enemy_scale_factor = 32,
    -- Additional parameters
    ore_width = nil,
    spawn_tile = nil,
    post_map_func = nil,
    circle_thickness = nil,
    circle_grow_factor = nil,
    main_ores_split_count = nil,
    main_ores_start_ore_offset = nil,
    main_ore_resource_patches_config = nil,
  },
}
