local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local MGSP = require 'resources.map_gen_settings'
local Noise = require 'map_gen.shared.simplex_noise'
local Queue = require 'utils.queue'
local RS = require 'map_gen.shared.redmew_surface'
local Public = require 'map_gen.maps.frontier.shared.core'
local math_abs = math.abs
local math_ceil = math.ceil
local math_clamp = math.clamp
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_random = math.random
local q_size = Queue.size
local q_push = Queue.push
local q_pop  = Queue.pop
local simplex = Noise.d2

local autoplace_controls = {
  ['coal']        = { frequency = 1.3,   richness = 0.7, size = 0.80 },
  ['copper-ore']  = { frequency = 1.4,   richness = 0.7, size = 0.85 },
  ['crude-oil']   = { frequency = 1,     richness = 0.9, size = 0.95 },
  ['enemy-base']  = { frequency = 6,     richness = 0.6, size = 4    },
  ['iron-ore']    = { frequency = 1.6,   richness = 0.8, size = 1.15 },
  ['stone']       = { frequency = 1,     richness = 0.6, size = 0.65 },
  ['trees']       = { frequency = 1,     richness = 0.6, size = 1.2  },
  ['uranium-ore'] = { frequency = 0.5,   richness = 0.6, size = 0.6  },
}
local blacklisted_resources = {
  ['uranium-ore'] = true,
  ['crude-oil'] = true,
}
local noises = {
  ['dungeon_sewer']   = {{ modifier = 0.00055, weight = 1.05  }, { modifier = 0.0062,  weight = 0.024  }, { modifier = 0.0275,  weight = 0.00135 }},
  ['cave_miner_01']   = {{ modifier = 0.002,   weight = 1     }, { modifier = 0.003,   weight = 0.5    }, { modifier = 0.01,    weight = 0.01    }, { modifier = 0.1,     weight = 0.015  }},
  ['oasis']           = {{ modifier = 0.00165, weight = 1.1   }, { modifier = 0.00275, weight = 0.55   }, { modifier = 0.011,   weight = 0.165   }, { modifier = 0.11,    weight = 0.0187 }},
  ['dungeons']        = {{ modifier = 0.0028,  weight = 0.99  }, { modifier = 0.0059,  weight = 0.21   }},
  ['cave_rivers_2']   = {{ modifier = 0.0035,  weight = 0.90  }, { modifier = 0.0088,  weight = 0.15   }, { modifier = 0.051,   weight = 0.011   }},
  ['cave_miner_02']   = {{ modifier = 0.006,   weight = 1     }, { modifier = 0.02,    weight = 0.15   }, { modifier = 0.25,    weight = 0.025   }},
  ['large_caves']     = {{ modifier = 0.055,   weight = 0.045 }, { modifier = 0.11,    weight = 0.042  }, { modifier = 0.00363, weight = 1.05    }, { modifier = 0.01,    weight = 0.23   }},
  ['no_rocks']        = {{ modifier = 0.00495, weight = 0.945 }, { modifier = 0.01665, weight = 0.2475 }, { modifier = 0.0435,  weight = 0.0435  }, { modifier = 0.07968, weight = 0.0315 }},
  ['scrapyard']       = {{ modifier = 0.0055,  weight = 1.1   }, { modifier = 0.011,   weight = 0.385  }, { modifier = 0.055,   weight = 0.253   }, { modifier = 0.11,    weight = 0.121  }},
  ['scrapyard_2']     = {{ modifier = 0.0066,  weight = 1.1   }, { modifier = 0.044,   weight = 0.165  }, { modifier = 0.242,   weight = 0.055   }, { modifier = 0.055,   weight = 0.352  }},
  ['smol_areas']      = {{ modifier = 0.0052,  weight = 0.83  }, { modifier = 0.139,   weight = 0.144  }, { modifier = 0.129,   weight = 0.072   }, { modifier = 0.111,   weight = 0.01   }},
  ['cave_rivers']     = {{ modifier = 0.0053,  weight = 0.71  }, { modifier = 0.0086,  weight = 0.24   }, { modifier = 0.070,   weight = 0.025   }},
  ['small_caves']     = {{ modifier = 0.0066,  weight = 1.1   }, { modifier = 0.044,   weight = 0.165  }, { modifier = 0.242,   weight = 0.055   }},
  ['forest_location'] = {{ modifier = 0.0066,  weight = 1.1   }, { modifier = 0.011,   weight = 0.275  }, { modifier = 0.055,   weight = 0.165   }, { modifier = 0.11,    weight = 0.0825 }},
  ['small_caves_2']   = {{ modifier = 0.0099,  weight = 1.1   }, { modifier = 0.055,   weight = 0.275  }, { modifier = 0.275,   weight = 0.055   }},
  ['forest_density']  = {{ modifier = 0.01,    weight = 1     }, { modifier = 0.05,    weight = 0.5    }, { modifier = 0.1,     weight = 0.025   }},
  ['cave_ponds']      = {{ modifier = 0.014,   weight = 0.77  }, { modifier = 0.18,    weight = 0.085  }},
  ['no_rocks_2']      = {{ modifier = 0.0184,  weight = 1.265 }, { modifier = 0.143,   weight = 0.1045 }},
  ['mixed_ore']       = {{ modifier = 0.0042,  weight = 1.000 }, { modifier = 0.0310,  weight = 0.080  }, { modifier = 0.1000,  weight = 0.025   }},
}
local mixed_ores = { 'iron-ore', 'copper-ore', 'iron-ore', 'stone', 'copper-ore', 'iron-ore', 'copper-ore', 'iron-ore', 'coal', 'iron-ore', 'copper-ore', 'iron-ore', 'stone', 'copper-ore', 'coal'}

if script.active_mods['Krastorio2'] then
  autoplace_controls['imersite']      = { frequency = 2, richness = 0.6, size = 0.75 }
  autoplace_controls['mineral-water'] = { frequency = 2, richness = 0.6, size = 0.75 }
  autoplace_controls['rare-metals']   = { frequency = 2, richness = 0.6, size = 0.85 }
  blacklisted_resources['imersite'] = true
  blacklisted_resources['mineral-water'] = true
  blacklisted_resources['rare-metals'] = true
end
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
    height = Public.get().height * 32,
    property_expression_names = {
      ['control-setting:aux:frequency:multiplier'] = '1.333333',
      ['control-setting:moisture:bias'] = '-0.250000',
      ['control-setting:moisture:frequency:multiplier'] = '3.000000',
    },
    starting_area = 3,
  },
  MGSP.water_none,
})

local Terrain = {}

function Terrain.get_map()
  local map
  local this = Public.get()

  local bounds = function(x, y)
    return x > (-this.left_boundary * 32 - 320) and not ((y < -this.height * 16) or (y > this.height * 16))
  end
  local water = function(x, y)
    if x < -this.left_boundary * 32 then
      return bounds(x, y) and 'water'
    end
  end
  local green_water = function(x, y)
    if math_floor(x) == -(this.kraken_distance + this.left_boundary * 32 + 1) then
      return bounds(x, y) and 'deepwater-green'
    end
  end
  local spawn = function(x, _)
    return x >= -this.left_boundary * 32 and x < this.right_boundary * 32 + 96
  end
  spawn = b.remove_map_gen_entities_by_filter(spawn, { force = 'enemy' })
  local wall_tile = function(x, _)
    if x >= this.right_boundary * 32 - 1 and x <= this.right_boundary * 32 + this.wall_width + 1 then
      return 'concrete'
    elseif x >= this.right_boundary * 32 - 4 and x <= this.right_boundary * 32 + this.wall_width + 4 then
      return 'hazard-concrete-left'
    end
  end
  local wall = function(x, y)
    if x >= this.right_boundary * 32 and x < this.right_boundary * 32 + this.wall_width then
      return {
        name = 'stone-wall',
        position = { x = x , y = y },
        force = 'player',
        move_stuck_players = true,
      }
    end
  end
  wall = b.remove_map_gen_entities_by_filter(wall, { type = {'tree', 'simple-entity', 'cliff' } })

  map = b.add(water, bounds)
  map = b.add(green_water, map)
  map = b.fish(map, 0.075)
  map = b.add(spawn, map)
  map = b.apply_entity(map, wall)
  map = b.overlay_tile_land(map, wall_tile)
  return map
end

function Terrain.noise_pattern(feature, position, seed)
  local noise, d = 0, 0
  local noise_weights = noises[feature]
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
  local this = Public.get()
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
        local noise = Terrain.noise_pattern('mixed_ore', position, seed)
        if math_abs(noise) > 0.77 then
          local idx = math_floor(noise * 25 + math_abs(position.x) * 0.05) % #mixed_ores + 1
          local amount = this.ore_base_quantity * chunks * 35 + math_random(100)
          if clear_ore(position) then
            create_entity({ name = mixed_ores[idx], position = position, amount = amount })
          end
        end
      end
    end
  end
end

function Terrain.scale_resource_richness(surface, area)
  local this = Public.get()
  for _, resource in pairs(surface.find_entities_filtered { area = area, type = 'resource' }) do
    if resource.position.x > this.right_boundary * 32 then
      local chunks = math.clamp(math_abs((resource.position.x - this.right_boundary * 32) / this.ore_chunk_scale), 1, 100)
      chunks = math_random(chunks, chunks + 4)
      if resource.prototype.resource_category == 'basic-fluid' then
        resource.amount = this.ore_base_quantity * 800 * chunks
      elseif resource.prototype.resource_category == 'basic-solid' then
        resource.amount = math_min(1+ 0.7 * resource.amount, this.ore_base_quantity * 10 + math_random(100))
      end
    else
      if resource.prototype.resource_category == 'basic-fluid' then
        resource.amount = this.ore_base_quantity * 80000 + math_random(400000)
      elseif resource.prototype.resource_category == 'basic-solid' then
        resource.amount = this.ore_base_quantity * 300 + math_random(400, 1700)
      end
    end
  end
end

function Terrain.rich_rocks(surface, area)
  local this = Public.get()
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
    local rock_name = math_random() < 0.4 and 'huge-rock' or 'big-rock'
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

function Terrain.queue_reveal_map()
  local this = Public.get()
	local chart_queue = this.chart_queue
	-- important to flush the queue upon resetting a map or chunk requests from previous maps could overlap
	Queue.clear(chart_queue)
	local size = math_max(this.left_boundary, this.right_boundary, this.height / 2) * 32 + 96
	for x = 16, size, 32 do
		for y = 16, size, 32 do
			q_push(chart_queue, {{-x, -y}, {-x, -y}})
			q_push(chart_queue, {{ x, -y}, { x, -y}})
			q_push(chart_queue, {{-x,  y}, {-x,  y}})
			q_push(chart_queue, {{ x,  y}, { x,  y}})
		end
	end
end

function Terrain.pop_chunk_request(max_requests)
	max_requests = max_requests or 1
  local this = Public.get()
	local chart_queue = this.chart_queue
	local surface = Public.surface()
	local players = game.forces.player

	while max_requests > 0 and q_size(chart_queue) > 0 do
		players.chart(surface, q_pop(chart_queue))
		max_requests = max_requests - 1
	end
end

function Terrain.reveal_spawn_area()
  local surface = Public.surface()
  surface.request_to_generate_chunks({ x = 0, y = 0 }, 1)
  surface.force_generate_chunk_requests()
end

function Terrain.block_tile_placement(event)
  local this = Public.get()
  local surface = game.get_surface(event.surface_index)
  if surface.name ~= Public.surface().name then
    return
  end
  local left = -(this.kraken_distance + this.left_boundary * 32)
  local tiles = {}
  for _, tile in pairs(event.tiles) do
    if tile.position.x <= left then
      tiles[#tiles + 1] = { name = tile.old_tile.name, position = tile.position }
    end
  end
  if #tiles > 0 then
    surface.set_tiles(tiles, true)
  end
end

function Terrain.reshape_land(surface, area)
  local this = Public.get()
  local right_boundary = this.right_boundary * 32 + this.wall_width + 4
  local left_top = { x = math_max(area.left_top.x, -this.left_boundary * 32), y = area.left_top.y }
  local right_bottom = area.right_bottom
  if left_top.x >= right_bottom.x then
    return
  end

  local seed = surface.map_gen_settings.seed
  local count_entities = surface.count_entities_filtered
  local noise_pattern = Terrain.noise_pattern

  local function is_ore(position)
    return count_entities{
      position = { x = position.x + 0.5, y = position.y + 0.5 },
      type = 'resource',
      limit = 1,
    } > 0
  end

  local function do_tile(x, y)
    if math_abs(y) > this.height * 16 then
      return
    end
    if math_abs(x) < 16 and math_abs(y) < 16 then
      return
    end
    if math_abs(x - this.x) < 16 and math_abs(y - this.y) < 16 then
      return
    end

    local p = { x = x, y = y }
    local cave_rivers = noise_pattern('cave_rivers', p, seed)
    local no_rocks = noise_pattern('no_rocks', p, seed)
    local cave_ponds = noise_pattern('cave_ponds', p, 2 * seed)
    local small_caves = noise_pattern('dungeons', p, 2 * seed)

    -- Chasms
    if cave_ponds < 0.110 and cave_ponds > 0.112 then
      if small_caves > 0.5 or small_caves < -0.5 then
        return { name = 'out-of-map', position = p }
      end
    end

    -- Rivers
    if cave_rivers < 0.044 and cave_rivers > -0.072 then
      if cave_ponds > 0.1 then
        if not is_ore(p) then
          return { name = 'water-shallow', position = p }
        else
          return { name = 'cyan-refined-concrete', position = p }
        end
      end
    end

    -- Water Ponds
    if cave_ponds > 0.6 then
      if cave_ponds > 0.74 then
        return { name = x < right_boundary and 'acid-refined-concrete' or 'orange-refined-concrete', position = p }
      end
      if not is_ore(p) then
        return { name = x < right_boundary and 'green-refined-concrete' or 'red-refined-concrete', position = p }
      else
        return { name = 'cyan-refined-concrete', position = p }
      end
    end

    if cave_ponds > 0.622 then
      if cave_ponds > 0.542 then
        if cave_rivers > -0.302 then
          return { name = 'refined-hazard-concrete-right', position = p }
        end
      end
    end

    -- Worm oil
    if no_rocks < 0.029 and no_rocks > -0.245 then
      if small_caves > 0.081 then
        return { name = x < right_boundary and 'brown-refined-concrete' or 'black-refined-concrete', position = p }
      end
    end

    -- Chasms2
    if small_caves < -0.54 and cave_ponds < -0.5 then
      if not is_ore(p) then
        return { name = 'out-of-map', position = p }
      end
    end
  end

  local tiles = {}
  for x = 0, math_min(right_bottom.x - left_top.x, 31) do
    for y = 0, 31 do
      local tile = do_tile(left_top.x + x, left_top.y + y)
      if tile then tiles[#tiles +1] = tile end
    end
  end
  surface.set_tiles(tiles, true)
end

function Terrain.clear_area(args)
  if not (args.position and args.surface) then
    return
  end
  local surface = args.surface
  local position = args.position

  surface.request_to_generate_chunks({ x = position.x, y = position.x }, math_ceil((args.radius or args.size or 32) / 32))
  surface.force_generate_chunk_requests()

  if args.name then
    local cb = prototypes.entity[args.name].collision_box
    local area = {
      left_top = {
        x = position.x - cb.left_top.x,
        y = position.y - cb.left_top.y,
      },
      right_bottom = {
        x = position.x + cb.right_bottom.x,
        y = position.y + cb.right_bottom.y,
      }
    }
    for _, e in pairs(surface.find_entities_filtered{ area = area, collision_mask = {'player', 'object'}}) do
      e.destroy()
    end
    local tiles = {}
    for _, t in pairs(surface.find_tiles_filtered{ area = area }) do
      if t.collides_with('item') then
        tiles[#tiles +1] = { name = 'nuclear-ground', position = t.position }
      end
    end
    surface.set_tiles(tiles, true)
    return true
  elseif args.radius then
    for _, e in pairs(surface.find_entities_filtered{ position = position, radius = args.radius, collision_mask = {'player', 'object'}}) do
      e.destroy()
    end
    local tiles = {}
    for _, t in pairs(surface.find_tiles_filtered{ position = position, radius = args.radius }) do
      if t.collides_with('item') then
        tiles[#tiles +1] = { name = 'nuclear-ground', position = t.position }
      end
    end
    surface.set_tiles(tiles, true)
    return true
  elseif args.size then
    local size = args.size
    local area = {
      left_top = {
        x = position.x - size,
        y = position.y - size,
      },
      right_bottom = {
        x = position.x + size,
        y = position.y + size,
      }
    }
    for _, e in pairs(surface.find_entities_filtered{ area = area, collision_mask = {'player', 'object'}}) do
      e.destroy()
    end
    local tiles = {}
    for _, t in pairs(surface.find_tiles_filtered{ area = area }) do
      if t.collides_with('item') then
        tiles[#tiles +1] = { name = 'nuclear-ground', position = t.position }
      end
    end
    surface.set_tiles(tiles, true)
    return true
  end
end

function Terrain.prepare_next_surface()
  Public.get().lobby_enabled = true
  game.print({'frontier.map_setup'})

  local surface = Public.surface()
  surface.clear(true)
  local mgs = table.deepcopy(surface.map_gen_settings)
  mgs.seed = mgs.seed + 1e4
  surface.map_gen_settings = mgs
end

return Terrain
