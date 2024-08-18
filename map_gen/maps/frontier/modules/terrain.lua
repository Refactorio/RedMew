local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local MGSP = require 'resources.map_gen_settings'
local Noise = require 'map_gen.shared.simplex_noise'
local RS = require 'map_gen.shared.redmew_surface'
local Public = require 'map_gen.maps.frontier.shared.core'
local this = Public.get()
local math_abs = math.abs
local math_clamp = math.clamp
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_random = math.random
local simplex = Noise.d2

local autoplace_controls = {
  ['coal']        = { frequency = 1.1,   richness = 0.6, size = 0.75 },
  ['copper-ore']  = { frequency = 1.2,   richness = 0.6, size = 0.75 },
  ['crude-oil']   = { frequency = 1,     richness = 0.6, size = 0.75 },
  ['enemy-base']  = { frequency = 6,     richness = 0.6, size = 4    },
  ['iron-ore']    = { frequency = 1.135, richness = 0.6, size = 0.85 },
  ['stone']       = { frequency = 1,     richness = 0.6, size = 0.65 },
  ['trees']       = { frequency = 1,     richness = 0.6, size = 1    },
  ['uranium-ore'] = { frequency = 0.5,   richness = 0.6, size = 0.5  },
}
local blacklisted_resources = {
  ['uranium-ore'] = true,
  ['crude-oil'] = true,
}
local noise_weights = {
  { modifier = 0.0042, weight = 1.000 },
  { modifier = 0.0310, weight = 0.080 },
  { modifier = 0.1000, weight = 0.025 },
}
local mixed_ores = { 'iron-ore', 'copper-ore', 'iron-ore', 'stone', 'copper-ore', 'iron-ore', 'copper-ore', 'iron-ore', 'coal', 'iron-ore', 'copper-ore', 'iron-ore', 'stone', 'copper-ore', 'coal'}

if script.active_mods['zombiesextended-core'] then
  autoplace_controls['gold-ore']      = { frequency = 0.5, richness = 0.5, size = 0.5  }
  autoplace_controls['vibranium-ore'] = { frequency = 0.5, richness = 0.5, size = 0.5  }
  blacklisted_resources['gold-ore'] = true
  blacklisted_resources['vibranium-ore'] = true
end

RS.set_map_gen_settings({
  {
    autoplace_controls = autoplace_controls,
    cliff_settings = { name = 'cliff', cliff_elevation_0 = 20, cliff_elevation_interval = 40, richness = 0.8 },
    height = this.height * 32,
    property_expression_names = {
      ['control-setting:aux:frequency:multiplier'] = '1.333333',
      ['control-setting:moisture:bias'] = '-0.250000',
      ['control-setting:moisture:frequency:multiplier'] = '3.000000',
    },
    starting_area = 3,
    terrain_segmentation = 1,
  },
  MGSP.water_none,
})

local Terrain = {}

function Terrain.get_map()
  local map, water, green_water
  local bounds = function(x, y)
    return x > (-this.left_boundary * 32 - 320) and not ((y < -this.height * 16) or (y > this.height * 16))
  end

  water = b.change_tile(bounds, true, 'water')
  water = b.fish(water, 0.075)

  green_water = b.change_tile(bounds, true, 'deepwater-green')

  map = b.choose(function(x) return x < -this.left_boundary * 32 end, water, bounds)
  map = b.choose(function(x) return math_floor(x) == -(this.kraken_distance + this.left_boundary * 32 + 1) end, green_water, map)
  return map
end

function Terrain.noise_pattern(position, seed)
  local noise, d = 0, 0
  for i = 1, #noise_weights do
    local nw = noise_weights[i]
    noise = noise + simplex(position.x * nw.modifier, position.y * nw.modifier, seed) * nw.weight
    d = d + nw.weight
    seed = seed + 10000
  end
  noise = noise / d
  return noise
end

function Terrain.mixed_resources(surface, area)
  local left_top = { x = math_max(area.left_top.x, this.right_boundary * 32), y = area.left_top.y }
  local right_bottom = area.right_bottom
  if left_top.x >= right_bottom.x then
    return
  end

  local seed = surface.map_gen_settings.seed
  local create_entity = surface.create_entity
  local can_place_entity = surface.can_place_entity
  local find_entities_filtered = surface.find_entities_filtered

  local function clear_ore(position)
    for _, resource in pairs(find_entities_filtered{
      position = position,
      type = 'resource'
    }) do
      if blacklisted_resources[resource.name] then
        return false
      end
      resource.destroy()
    end
    return true
  end

  local chunks = math_clamp(math_abs((left_top.x - this.right_boundary * 32) / this.ore_chunk_scale), 1, 100)
  chunks = math_random(chunks, chunks + 4)
  for x = 0, 31 do
    for y = 0, 31 do
      local position = { x = left_top.x + x, y = left_top.y + y }
      if can_place_entity({ name = 'iron-ore', position = position }) then
        local noise = Terrain.noise_pattern(position, seed)
        if math_abs(noise) > 0.67 then
          local idx = math_floor(noise * 25 + math_abs(position.x) * 0.05) % #mixed_ores + 1
          local amount = this.ore_base_quantity * chunks * 5
          if clear_ore(position) then
            create_entity({ name = mixed_ores[idx], position = position, amount = amount })
          end
        end
      end
    end
  end
end

function Terrain.clear_enemies_inside_wall(surface, area)
  if area.right_bottom.x < (this.right_boundary * 32 + 96) then
    for _, entity in pairs(surface.find_entities_filtered { area = area, force = 'enemy' }) do
      entity.destroy()
    end
  end
end

function Terrain.scale_resource_richness(surface, area)
  for _, resource in pairs(surface.find_entities_filtered { area = area, type = 'resource' }) do
    if resource.position.x > this.right_boundary * 32 then
      local chunks = math.clamp(math_abs((resource.position.x - this.right_boundary * 32) / this.ore_chunk_scale), 1, 100)
      chunks = math_random(chunks, chunks + 4)
      if resource.prototype.resource_category == 'basic-fluid' then
        resource.amount = 3000 * 3 * chunks
      elseif resource.prototype.resource_category == 'basic-solid' then
        --resource.amount = this.ore_base_quantity * chunks
        resource.amount = math_min(0.7 * resource.amount, 100 + math_random(100))
      end
    else
      if resource.prototype.resource_category == 'basic-fluid' then
        resource.amount = 800000 + math_random(400000)
      elseif resource.prototype.resource_category == 'basic-solid' then
        resource.amount = 3700 + math_random(1300)
      end
    end
  end
end

function Terrain.rich_rocks(surface, area)
  local left_top = { x = math_max(area.left_top.x, this.right_boundary * 32), y = area.left_top.y }
  local right_bottom = area.right_bottom
  if left_top.x >= right_bottom.x then
    return
  end

  local function place_rock(rock_name)
    local search = surface.find_non_colliding_position
    local place = surface.create_entity

    for _ = 1, 10 do
      local x, y = math_random(1, 31) + math_random(), math_random(1, 31) + math_random()
      local rock_pos = search(rock_name, {left_top.x + x, left_top.y + y}, 4, 0.4)
      if rock_pos then
        local rock = place{
          name = rock_name,
          position = rock_pos,
          direction = math_random(1, 4)
        }
        rock.graphics_variation = math_random(16)
        return
      end
    end
  end

  for _ = 1, this.rock_richness do
    local rock_name = math_random() < 0.4 and 'rock-huge' or 'rock-big'
    place_rock(rock_name)
  end
end

function Terrain.set_silo_tiles(entity)
  local pos = entity.position
  local surface = entity.surface
  surface.request_to_generate_chunks(pos, 1)
  surface.force_generate_chunk_requests()

  local tiles = {}
  for x = -12, 12 do
    for y = -12, 12 do
      tiles[#tiles +1] = { name = 'hazard-concrete-left', position = { pos.x + x, pos.y + y}}
    end
  end
  for x = -8, 8 do
    for y = -8, 8 do
      tiles[#tiles +1] = { name = 'concrete', position = { pos.x + x, pos.y + y}}
    end
  end
  entity.surface.set_tiles(tiles, true)
end

function Terrain.create_wall(x, w)
  local surface = RS.get_surface()
  local area = { { x, -this.height * 16 }, { x + w, this.height * 16 } }
  for _, entity in pairs(surface.find_entities_filtered { area = area, collision_mask = 'player-layer' }) do
    entity.destroy()
  end

  for y = -this.height * 16, this.height * 16 do
    for j = 0, w - 1 do
      local e = surface.create_entity {
        name = 'stone-wall',
        position = { x + j, y },
        force = 'player',
        move_stuck_players = true,
      }
      e.destructible = this.wall_vulnerability
    end
  end

  local tiles = {}
  for j = -4, w - 1 + 4 do
    for y = -this.height * 16, this.height * 16 do
      tiles[#tiles +1] = { name = 'hazard-concrete-left', position = { x = x + j, y = y }}
    end
  end
  for j = -1, w do
    for y = -this.height * 16, this.height * 16 do
      tiles[#tiles +1] = { name = 'concrete', position = { x = x + j, y = y }}
    end
  end
  surface.set_tiles(tiles, true)
end

return Terrain
