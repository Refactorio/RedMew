--[[
  Each preset will be similar to:

  grass = autoplace_settings = {
    tile = {
      treat_missing_as_default = false,
      settings = {
        ['grass-1'] = {frequency = 1, size = 1, richness = 1},
        ['grass-2'] = {frequency = 1, size = 1, richness = 1},
        ['grass-3'] = {frequency = 1, size = 1, richness = 1},
        ['grass-4'] = {frequency = 1, size = 1, richness = 1},
      }
    }
  }

  - no water, you will need to add it if wanted
  - tiles not listed tiles will not be placed
]]

local Table = require 'utils.table'
local ab_tiles = require 'resources.alien_biomes.tile_names'

local function make_default_autoplace_settings(tile_table)
  local autoplace_settings = {
    tile = {
      treat_missing_as_default = false,
      settings = {}
    }
  }
  for _, tile_name in pairs(Table.merge(tile_table)) do
    autoplace_settings.tile.settings[tile_name] = {frequency = 1, size = 1, richness = 1}
  end
  return autoplace_settings
end

return {
  -- vanilla
  default = make_default_autoplace_settings{{
    'grass-1', 'grass-2', 'grass-3', 'grass-4',
    'dirt-1', 'dirt-2', 'dirt-3', 'dirt-4', 'dirt-5', 'dirt-6', 'dirt-7',
    'dry-dirt',
    'sand-1', 'sand-2', 'sand-3',
    'red-desert-0', 'red-desert-2', 'red-desert-3', 'red-desert-4',
  }},
  -- Color subsets
  green = make_default_autoplace_settings{
    ab_tiles['vegetation-green-grass'],
    ab_tiles['vegetation-olive-grass'],
    ab_tiles['vegetation-turquioise-grass']
  },
  white = make_default_autoplace_settings{
    ab_tiles['mineral-white-dirt'],
    ab_tiles['mineral-white-sand'],
  },
  grey = make_default_autoplace_settings{
    ab_tiles['mineral-grey-dirt'],
    ab_tiles['mineral-grey-sand'],
  },
  black = make_default_autoplace_settings{
    ab_tiles['mineral-black-dirt'],
    ab_tiles['mineral-black-sand'],
  },
  aubergine = make_default_autoplace_settings{
    ab_tiles['mineral-aubergine-dirt'],
    ab_tiles['mineral-aubergine-sand'],
  },
  purple = make_default_autoplace_settings{
    ab_tiles['mineral-purple-dirt'],
    ab_tiles['mineral-purple-sand'],
  },
  red = make_default_autoplace_settings{
    ab_tiles['mineral-red-dirt'],
    ab_tiles['mineral-red-sand'],
  },
  beige = make_default_autoplace_settings{
    ab_tiles['mineral-beige-dirt'],
    ab_tiles['mineral-beige-sand'],
  },
  brown = make_default_autoplace_settings{
    ab_tiles['mineral-brown-dirt'],
    ab_tiles['mineral-brown-sand'],
  },
  cream = make_default_autoplace_settings{
    ab_tiles['mineral-cream-dirt'],
    ab_tiles['mineral-cream-sand'],
  },
  dustyrose = make_default_autoplace_settings{
    ab_tiles['mineral-dustyrose-dirt'],
    ab_tiles['mineral-dustyrose-sand'],
  },
  tan = make_default_autoplace_settings{
    ab_tiles['mineral-tan-dirt'],
    ab_tiles['mineral-tan-sand'],
  },
  violet = make_default_autoplace_settings{
    ab_tiles['mineral-violet-dirt'],
    ab_tiles['mineral-violet-sand'],
  },

  -- Texture subsets
  grass = make_default_autoplace_settings{
    ab_tiles['vegetation-green-grass'],
    ab_tiles['vegetation-olive-grass'],
    ab_tiles['vegetation-turquioise-grass'],
  },
  snow = make_default_autoplace_settings{
    ab_tiles['frozen-snow'],
  },
  light_sand = make_default_autoplace_settings{
    ab_tiles['mineral-tan-sand'],
    ab_tiles['mineral-beige-sand'],
    ab_tiles['mineral-cream-sand'],
  },
  dark_sand = make_default_autoplace_settings{
    ab_tiles['mineral-black-sand'],
    ab_tiles['mineral-grey-sand'],
  },
  colorful_sand = make_default_autoplace_settings{
    ab_tiles['mineral-brown-sand'],
    ab_tiles['mineral-aubergine-sand'],
    ab_tiles['mineral-purple-sand'],
    ab_tiles['mineral-dustyrose-sand'],
    ab_tiles['mineral-red-sand'],
    ab_tiles['mineral-violet-sand'],
  },
  sand_only = make_default_autoplace_settings{
    -- light sand
    ab_tiles['mineral-tan-sand'],
    ab_tiles['mineral-beige-sand'],
    ab_tiles['mineral-cream-sand'],
    -- dark sand
    ab_tiles['mineral-black-sand'],
    ab_tiles['mineral-grey-sand'],
    -- purple/red sand
    ab_tiles['mineral-brown-sand'],
    ab_tiles['mineral-aubergine-sand'],
    ab_tiles['mineral-purple-sand'],
    ab_tiles['mineral-dustyrose-sand'],
    ab_tiles['mineral-red-sand'],
    ab_tiles['mineral-violet-sand'],
  },
  brown_light_dirt = make_default_autoplace_settings{
    ab_tiles['mineral-beige-dirt'],
    ab_tiles['mineral-cream-dirt'],
    ab_tiles['mineral-tan-dirt'],
  },
  brown_dark_dirt = make_default_autoplace_settings{
    ab_tiles['mineral-brown-dirt'],
    ab_tiles['mineral-dustyrose-dirt'],
    ab_tiles['mineral-tan-dirt'],
  },
  brown_dirt = make_default_autoplace_settings{
    ab_tiles['mineral-beige-dirt'],
    ab_tiles['mineral-cream-dirt'],
    ab_tiles['mineral-tan-dirt'],
    ab_tiles['mineral-brown-dirt'],
    ab_tiles['mineral-dustyrose-dirt'],
  },
  light_grey_dirt = make_default_autoplace_settings{
    ab_tiles['mineral-grey-dirt'],
    ab_tiles['mineral-white-dirt'],
  },
  colorful_dirt = {
    ab_tiles['mineral-brown-dirt'],
    ab_tiles['mineral-aubergine-dirt'],
    ab_tiles['mineral-purple-dirt'],
    ab_tiles['mineral-dustyrose-dirt'],
    ab_tiles['mineral-red-dirt'],
    ab_tiles['mineral-violet-dirt'],
  },
  dirt_only = make_default_autoplace_settings{
    -- light dirt
    ab_tiles['mineral-tan-dirt'],
    ab_tiles['mineral-beige-dirt'],
    ab_tiles['mineral-cream-dirt'],
    -- dark dirt
    ab_tiles['mineral-black-dirt'],
    ab_tiles['mineral-grey-dirt'],
    -- purple/red dirt
    ab_tiles['mineral-brown-dirt'],
    ab_tiles['mineral-aubergine-dirt'],
    ab_tiles['mineral-purple-dirt'],
    ab_tiles['mineral-dustyrose-dirt'],
    ab_tiles['mineral-red-dirt'],
    ab_tiles['mineral-violet-dirt'],
  },
  heat_blue = make_default_autoplace_settings{
    ab_tiles['volcanic-blue-heat'],
  },
  heat_green = make_default_autoplace_settings{
    ab_tiles['volcanic-green-heat'],
  },
  heat_orange = make_default_autoplace_settings{
    ab_tiles['volcanic-orange-heat'],
  },
  heat_purple = make_default_autoplace_settings{
    ab_tiles['volcanic-purple-heat'],
  },

  -- Full biomes
  cold = make_default_autoplace_settings{
    ab_tiles['frozen-snow'],
    ab_tiles['mineral-white-dirt'],
    ab_tiles['mineral-white-sand'],
    ab_tiles['volcanic-blue-heat'],
  },
  hot = make_default_autoplace_settings{
    ab_tiles['mineral-red-dirt'],
    ab_tiles['mineral-red-sand'],
    ab_tiles['vegetation-red-grass'],
    ab_tiles['volcanic-orange-heat'],
  },
  pale = make_default_autoplace_settings{
    ab_tiles['mineral-beige-dirt'],
    ab_tiles['mineral-beige-sand'],
    ab_tiles['mineral-grey-dirt'],
    ab_tiles['mineral-grey-sand'],
    ab_tiles['mineral-white-dirt'],
    ab_tiles['mineral-white-sand'],
  },
  temperate = make_default_autoplace_settings{
    ab_tiles['mineral-tan-dirt'],
    ab_tiles['mineral-tan-sand'],
    ab_tiles['mineral-brown-dirt'],
    ab_tiles['mineral-brown-sand'],
    ab_tiles['mineral-cream-dirt'],
    ab_tiles['mineral-cream-sand'],
    ab_tiles['mineral-dustyrose-dirt'],
    ab_tiles['mineral-dustyrose-sand'],
    ab_tiles['vegetation-green-grass'],
    ab_tiles['vegetation-olive-grass'],
    ab_tiles['vegetation-orange-grass'],
    ab_tiles['vegetation-turquoise-grass'],
    ab_tiles['vegetation-yellow-grass'],
  },
  vegetation = make_default_autoplace_settings{
    ab_tiles['mineral-cream-dirt'],
    ab_tiles['mineral-cream-sand'],
    ab_tiles['mineral-tan-dirt'],
    ab_tiles['mineral-tan-sand'],
    ab_tiles['vegetation-green-grass'],
    ab_tiles['vegetation-olive-grass'],
    ab_tiles['vegetation-orange-grass'],
    ab_tiles['vegetation-turquoise-grass'],
    ab_tiles['vegetation-yellow-grass'],
    ab_tiles['volcanic-green-heat'],
  },
  volcano = make_default_autoplace_settings{
    ab_tiles['mineral-black-dirt'],
    ab_tiles['mineral-black-sand'],
    ab_tiles['mineral-red-dirt'],
    ab_tiles['mineral-red-sand'],
    ab_tiles['vegetation-red-grass'],
    ab_tiles['volcanic-orange-heat'],
  },
  mystic_purple = make_default_autoplace_settings{
    ab_tiles['mineral-aubergine-dirt'],
    ab_tiles['mineral-aubergine-sand'],
    ab_tiles['mineral-purple-dirt'],
    ab_tiles['mineral-purple-sand'],
    ab_tiles['mineral-violet-dirt'],
    ab_tiles['mineral-violet-sand'],
    ab_tiles['vegetation-blue-grass'],
    ab_tiles['vegetation-mauve-grass'],
    ab_tiles['vegetation-purple-grass'],
    ab_tiles['vegetation-violet-grass'],
    ab_tiles['volcanic-blue-heat'],
    ab_tiles['volcanic-purple-heat'],
  },
}
