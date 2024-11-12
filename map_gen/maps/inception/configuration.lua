return {
  maze = {
    enabled = true,
    size = 50,          -- in chunks
    wall_thickness = 1, -- in chunks
    cell_size = 5,      -- must be an odd number
  },
  terrain = {
    enabled = true,
    boundary = 11,          -- in chunks
    noise_threshold = 0.77, -- must be (0, 1)
    ore_base_quantity = 11, -- base richness
    ore_chunk_scale = 30,   -- in chunks
    mixed_ores = {
      'iron-ore',
      'copper-ore',
      'iron-ore',
      'stone',
      'copper-ore',
      'iron-ore',
      'copper-ore',
      'iron-ore',
      'coal',
      'iron-ore',
      'copper-ore',
      'iron-ore',
      'stone',
      'copper-ore',
      'coal',
    },
    blacklisted_resources = {
      ['uranium-ore'] = true,
      ['crude-oil'] = true,
    },
  }
}