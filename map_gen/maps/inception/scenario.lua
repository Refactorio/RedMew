local Config = require 'config'
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local ScenarioInfo = require 'features.gui.info'

local Maze = require 'map_gen.maps.inception.modules.maze'
local Terrain = require 'map_gen.maps.inception.modules.terrain'

-- == MAP CONFIG ==============================================================

Config.redmew_surface.enabled = false
Config.market.enabled = false
Config.player_rewards.enabled = false
Config.player_shortcuts.enabled = true
Config.dump_offline_inventories.enabled = true

-- == MAP INFO ================================================================

ScenarioInfo.set_map_name('Inception')
ScenarioInfo.set_map_description([[
  An idea is like a virus. Resilient. Highly contagious. And even the smallest seed of an idea can grow. It can grow to define or destroy you.
]])
ScenarioInfo.set_map_extra_info([[
  Prepare to embark on a mind-bending journey through the vast possibilities of automation and ingenuity! In this unique scenario, you awaken in the heart of an intricate labyrinth that twists and turns in a dreamlike reality. With indestructible walls, every corner seemingly leads to new surprises and challenges.

  Your mission is to navigate this complex maze, unlocking the secrets hidden within its depths, and ultimately find your way to freedom. Collect resources, construct powerful factories, and harness advanced technologies as you unravel the mysteries of this dreamlike world. However, beware—the maze is alive with distractions and traps created by the very fabric of the environment.

  Every decision you make will ripple through the labyrinth, shaping your path and determining your fate. Will you conquer the challenges and forge a thriving factory in this maze, or will you become lost in the dreams of Nauvis? The journey begins now—awaken your potential, and let the adventure unfold!
  The [color=red]RedMew[/color] team
]])
ScenarioInfo.set_new_info([[
  2024-11-12:
    - Added inception maze scenario
]])

-- == EVENTS ==================================================================

Event.on_init(function()
  Maze.on_init()
  --Maze.debug_maze(game.surfaces.nauvis, true)
end)

Event.add(defines.events.on_chunk_generated, function(event)
  local surface, area = event.surface, event.area
  if surface ~= RS.get_surface() then
    return
  end
  -- Make maze walls
  if Maze.set_wall_tiles(surface, area) then
    return
  end
  -- Add mixed patches
  Terrain.mixed_resources(surface, area)
  -- Add special tiles
  Terrain.reshape_land(surface, area)
end)

-- ============================================================================
