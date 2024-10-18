local Event = require 'utils.event'
local Perlin = require 'map_gen.shared.perlin_noise'
local AlienEvolutionProgress = require 'utils.alien_evolution_progress'
local Template = require 'map_gen.maps.april_fools.scenario.template'
require 'features.harmful_mining'

local rock_list = Template.diggy_rocks
local rocks = #rock_list
local rock_map = Template.diggy_rocks_map

-- == MAP GEN =================================================================

local starting_radius = 64
local biter_radius = 144
local PRECISION = 10e8

local function inside_radius(x, y, radius)
  return x*x + y*y < radius*radius + 3600 * Perlin.noise(x, y)
end

local function worm_by_distance(x, y, surface)
  local evo = game.forces.enemy.get_evolution_factor(surface) or 0
  local radius = math.sqrt(x*x + y*y)
  local weighted_distance = radius * (evo + 0.45)

  if weighted_distance < 1000 then
    return 'small-worm-turret'
  elseif weighted_distance < 1800 then
    return 'medium-worm-turret'
  elseif weighted_distance < 2600 then
    return 'big-worm-turret'
  else
    return 'behemoth-worm-turret'
  end
end

Event.add(defines.events.on_chunk_generated, function(event)
  local surface = event.surface
  if not (surface and surface.valid and surface.name == 'mines') then
    return
  end

  local area = event.area

  -- remove water
  local tiles = surface.find_tiles_filtered { area = area, name = { 'deepwater', 'deepwater-green', 'water', 'water-green', 'water-mud', 'water-shallow' } }
  local new_tiles = {}
  for _, tile in pairs(tiles) do
    table.insert(new_tiles, { name = 'volcanic-orange-heat-4', position = tile.position })
  end
  surface.set_tiles(new_tiles)

  -- place rocks
  local tx, ty = area.left_top.x, area.left_top.y
  local bx, by = area.right_bottom.x, area.right_bottom.y
  for x = tx, bx do
    for y = ty, by do
      local c = math.random(PRECISION)
      if not inside_radius(x, y, starting_radius) and c > (0.55 * PRECISION) then
        surface.create_entity { name = rock_list[math.random(rocks)], position = { x, y }, raise_built = false, move_stuck_players = true, force = 'neutral'}
      else
        if not inside_radius(x, y, biter_radius) and c < (0.000125 * PRECISION) then
          surface.create_entity { name = worm_by_distance(x, y, surface), position = {x, y}, move_stuck_players = true }
        end
      end
    end
  end
end)

-- == SPAWNERS ================================================================

Event.add(defines.events.on_player_mined_entity, function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  if not rock_map[entity.name] then
    return
  end

  local pos = entity.position

  local c = math.random(PRECISION)
  if c < (0.005 * PRECISION) and not inside_radius(pos.x, pos.y, biter_radius) then
    entity.surface.create_entity {
      name = math.random() > 0.40 and 'biter-spawner' or 'spitter-spawner',
      position = entity.position,
      force = 'enemy',
      target = player.character,
      move_stuck_players = true,
    }
  end
end)

local function give_command(group, target)
  if target and target.valid then
    local command = { type = defines.command.attack, target = target, distraction = defines.distraction.by_damage }
    group.set_command(command)
    group.start_moving()
  else
    local command = { type = defines.command.attack_area, destination = {0, 0}, radius = 32, distraction = defines.distraction.by_damage }
    group.set_command(command)
  end
end

Event.add(defines.events.on_entity_died, function(event)
  local entity = event.entity
  if not entity or not (entity.name == 'biter-spawner' or entity.name == 'spitter-spawner') then
    return
  end

  local surface = entity.surface
  local position = entity.position
  local spawn = entity.surface.create_entity
  local evo = game.forces.enemy.get_evolution_factor(surface)

  local spawner = AlienEvolutionProgress.create_spawner_request(math.ceil(evo * 100 / 4))
  local aliens = AlienEvolutionProgress.get_aliens(spawner, evo)

  local group = surface.create_unit_group { position = position }
  local add_member = group.add_member

  for name, count in pairs(aliens) do
    for i = 1, count do
      local ent = spawn{ name = name, position = position, force = 'enemy', move_stuck_players = true, }
      if ent then
        add_member(ent)
      end
    end
  end

  give_command(group, event.cause)
end)

-- ============================================================================