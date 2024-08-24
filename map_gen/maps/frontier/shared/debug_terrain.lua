local Public = {}
local Debug = require 'map_gen.maps.frontier.shared.debug'
local Noise = require 'map_gen.shared.simplex_noise'
local simplex_noise = Noise.d2

-- add or use noise templates from here
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
}

-- returns a float number between -1 and 1
function Public.get_noise(name, pos, seed)
  local noise = 0
  local d = 0
  for i = 1, #noises[name] do
    local mod = noises[name]
    noise = noise + simplex_noise(pos.x * mod[i].modifier, pos.y * mod[i].modifier, seed) * mod[i].weight
    d = d + mod[i].weight
    seed = seed + seed / seed
  end
  noise = noise / d
  return noise
end

function Public.on_chunk_generated(event)
  local area = event.area
  local right_boundary = 12 * 32
  local left_top = { x = math.max(area.left_top.x, right_boundary), y = area.left_top.y }
  local right_bottom = area.right_bottom
  if left_top.x >= right_bottom.x then
    return
  end

  local x_min = left_top.x
  local surface = event.surface
  local seed = surface.map_gen_settings.seed
  local STEP = 18 * 32
  local limit = right_boundary + STEP
  local noise_id = false

  --if not noise_id and x_min < limit then noise_id = 'cave_ponds' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'smol_areas' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'cave_rivers' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'cave_rivers_2' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'dungeons' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'dungeon_sewer' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'large_caves' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'no_rocks' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'no_rocks_2' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'oasis' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'scrapyard' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'scrapyard_2' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'small_caves' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'small_caves_2' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'forest_location' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'forest_density' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'cave_miner_01' end limit = limit + STEP
  --if not noise_id and x_min < limit then noise_id = 'cave_miner_02' end limit = limit + STEP
  --if not noise_id then return end

  if not noise_id and x_min < limit then noise_id = 'dungeon_sewer' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'cave_miner_01' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'oasis' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'dungeons' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'cave_rivers_2' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'cave_miner_02' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'large_caves' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'no_rocks' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'scrapyard' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'scrapyard_2' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'smol_areas' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'cave_rivers' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'small_caves' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'forest_location' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'small_caves_2' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'forest_density' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'cave_ponds' end limit = limit + STEP
  if not noise_id and x_min < limit then noise_id = 'no_rocks_2' end
  if not noise_id then return end

  local compute_noise = Public.get_noise
  local show_noise = Debug.show_noise_value

  for x = 0, 31 do
    for y = 0, 31 do
      local position = { x = left_top.x + x, y = left_top.y + y }
      local noise = compute_noise(noise_id, position, seed)
      show_noise(surface, position, noise)
    end
  end

  local chunkpos = event.position
  if (chunkpos.x) % 18 == 0 and (chunkpos.y == 1) then
    rendering.draw_text{
      text = noise_id,
      surface = surface,
      target = { x = left_top.x + 16, y = left_top.y + 16},
      target_offset = {x = - 2 * 32, y = 0 },
      scale = 128,
      color = { 255, 255, 255 },
      draw_on_ground = true,
      only_in_alt_mode = true,
    }
  end
end

return Public


--[[
/c local s = game.surfaces.redmew for x = 0, 360, 4 do
  s.request_to_generate_chunks({x = x * 32, y = - 32 *  8}, 4)
  s.request_to_generate_chunks({x = x * 32, y = - 32 *  4}, 4)
  s.request_to_generate_chunks({x = x * 32, y = - 32 *  0}, 4)
  s.request_to_generate_chunks({x = x * 32, y = - 32 * -4}, 4)
  s.request_to_generate_chunks({x = x * 32, y = - 32 * -8}, 4)
end

/c game.player.force.chart(game.player.surface, {{x = 0, y = -600}, {x = 11000, y = 600}})
]]