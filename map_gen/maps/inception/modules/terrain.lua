local math = require 'utils.math'
local configuration = require 'map_gen.maps.inception.configuration'.terrain
local Noise = require 'map_gen.shared.simplex_noise'
local simplex = Noise.d2

local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local math_floor = math.floor
local math_random = math.random
local math_clamp = math.clamp

local BLACKLISTED_RESOURCES = configuration.blacklisted_resources
local BOUNDARY = 32 * configuration.boundary
local MIXED_ORES = configuration.mixed_ores
local NOISE_THRESHOLD = configuration.noise_threshold
local ORE_BASE_QUANTITY = configuration.ore_base_quantity
local ORE_CHUNK_SCALE = 32 * configuration.ore_chunk_scale
local NOISES = {
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

local Terrain = {}

local noise_pattern = function(feature, position, seed)
  local noise, d = 0, 0
  local noise_weights = NOISES[feature]
  for i = 1, #noise_weights do
    local nw = noise_weights[i]
    noise = noise + simplex(position.x * nw.modifier, position.y * nw.modifier, seed) * nw.weight
    d = d + nw.weight
    seed = seed + 10000
  end
  noise = noise / d
  return noise
end

Terrain.reshape_land = function(surface, area)
  if not configuration.enabled then
    return
  end

  local left_top = area.left_top
  local right_bottom = area.right_bottom

  local seed = surface.map_gen_settings.seed
  local count_entities = surface.count_entities_filtered

  local function is_ore(position)
    return count_entities { position = { x = position.x + 0.5, y = position.y + 0.5 }, type = 'resource', limit = 1 } > 0
  end

  local function do_tile(x, y)
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
        return { name = 'acid-refined-concrete', position = p }
      end
      if not is_ore(p) then
        return { name = 'green-refined-concrete', position = p }
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
        return { name = 'brown-refined-concrete', position = p }
      end
    end

    -- Chasms2
    if small_caves < -0.54 and cave_ponds < -0.5 then
      if not is_ore(p) then
        return { name = 'black-refined-concrete', position = p }
      end
    end
  end

  local tiles = {}
  for x = 0, math_min(right_bottom.x - left_top.x, 31) do
    for y = 0, 31 do
      local tile = do_tile(left_top.x + x, left_top.y + y)
      if tile then
        tiles[#tiles + 1] = tile
      end
    end
  end
  surface.set_tiles(tiles, true)
end

Terrain.mixed_resources = function(surface, area)
  if not configuration.enabled then
    return
  end

  local left_top = area.left_top
  local right_bottom = area.right_bottom

  local seed = surface.map_gen_settings.seed
  local create_entity = surface.create_entity
  local can_place_entity = surface.can_place_entity
  local find_entities_filtered = surface.find_entities_filtered

  local function clear_ore(position)
    for _, resource in pairs(find_entities_filtered { position = position, type = 'resource' }) do
      if BLACKLISTED_RESOURCES[resource.name] then
        return false
      end
      resource.destroy()
    end
    return true
  end

  local distance = math_max(math_abs(left_top.y), math_abs(right_bottom.y), math_abs(left_top.x), math_abs(right_bottom.x))
  local chunks = math_clamp(math_abs((distance - BOUNDARY) / ORE_CHUNK_SCALE), 1, 100)
  chunks = math_random(chunks, chunks + 4)
  for x = 0, 31 do
    for y = 0, 31 do
      local position = { x = left_top.x + x, y = left_top.y + y }
      if can_place_entity({ name = 'iron-ore', position = position }) then
        local noise = noise_pattern('mixed_ore', position, seed)
        if math_abs(noise) > NOISE_THRESHOLD then
          local idx = math_floor(noise * 25 + math_abs(position.x) * 0.05) % #MIXED_ORES + 1
          local amount = ORE_BASE_QUANTITY * chunks * 35 + math_random(100)
          if clear_ore(position) then
            create_entity({ name = MIXED_ORES[idx], position = position, amount = amount })
          end
        end
      end
    end
  end
end

return Terrain
