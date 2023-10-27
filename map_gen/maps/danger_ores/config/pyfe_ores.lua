local b = require 'map_gen.shared.builders'
local start_value = b.euclidean_value(0, 0.20)
local value = b.exponential_value(0, 0.07, 1.18)
local before = function(radius) return b.circle(radius) end
local after = function(radius) return b.invert(b.circle(radius)) end

--[[
  This config uses 'map_without_gaps' module to generate the ores.
  Each sector has a prevalence of ore, some ores require fluid/special miners to mine it,
  which won't be available until later (later) techs. To allow players to still expand and
  buils without fluid-required-ores still being on the ground. the spawn of said ores has
  been moved out of the way after their corrispective radius.
  To still fill the gaps (default ore builder would simply leave gaps, empty tiles, if the
  coordinates of drawn ore's shape didn't return any resource amount), a custom ore builder
  is used in 'map_without_gaps', which pre-evaluates the yield of the drawn ore, and if nil
  (zero) it draws again the previous ore among the ores listed in the 'ratios' field. The
  ore which precedes the special ore which will not spawn until target radius will be the
  choosen one (until better implementation comes around). Thefallback ore is usually the
  main ore of that sector, or one of the designer's choice.
]]

local R_borax   = 32 * 6
local R_molyb   = 32 * 8
local R_niobium = 32 * 8

return {
  {
    name = 'copper-ore',
    ['tiles'] = {
      [1] = 'landfill'
    },
    ['start'] = start_value,
    ['weight'] = 20,
    ['ratios'] = {
      { resource = b.resource(b.full_shape,      'iron-ore',       value), weight = 15 },
      { resource = b.resource(b.full_shape,      'stone',          value), weight = 10 },
      { resource = b.resource(b.full_shape,      'coal',           value), weight =  5 },
      { resource = b.resource(b.full_shape,      'copper-ore',     value), weight = 70 },
      { resource = b.resource(after(R_molyb),    'molybdenum-ore', value), weight =  1 },
    }
  },
  {
    name = 'coal',
    ['tiles'] = {
      [1] = 'landfill'
    },
    ['start'] = start_value,
    ['weight'] = 20,
    ['ratios'] = {
      { resource = b.resource(b.full_shape,      'iron-ore',       value), weight = 18 },
      { resource = b.resource(b.full_shape,      'copper-ore',     value), weight =  9 },
      { resource = b.resource(b.full_shape,      'stone',          value), weight =  8 },
      { resource = b.resource(b.full_shape,      'coal',           value), weight = 65 },
      { resource = b.resource(after(R_molyb),    'molybdenum-ore', value), weight =  1 },
    }
  },
  {
    name = 'iron-ore',
    ['tiles'] = {
      [1] = 'landfill'
    },
    ['start'] = start_value,
    ['weight'] = 20,
    ['ratios'] = {
      { resource = b.resource(b.full_shape,      'copper-ore',     value), weight = 13 },
      { resource = b.resource(b.full_shape,      'stone',          value), weight =  7 },
      { resource = b.resource(b.full_shape,      'coal',           value), weight =  5 },
      { resource = b.resource(b.full_shape,      'iron-ore',       value), weight = 75 },
      { resource = b.resource(after(R_molyb),    'molybdenum-ore', value), weight =  1 },
    }
  },
  {
    name = 'stone',
    ['tiles'] = {
      [1] = 'landfill',
    },
    ['start'] = start_value,
    ['weight'] = 6,
    ['ratios'] = {
      { resource = b.resource(b.full_shape,      'iron-ore',       value), weight = 25 },
      { resource = b.resource(b.full_shape,      'copper-ore',     value), weight = 10 },
      { resource = b.resource(b.full_shape,      'coal',           value), weight =  5 },
      { resource = b.resource(b.full_shape,      'stone',          value), weight = 60 },
      { resource = b.resource(after(R_molyb),    'molybdenum-ore', value), weight =  1 },
    }
  },
  {
    name = 'molybdenum-ore',
    ['tiles'] = {
      [1] = 'landfill',
    },
    ['start'] = start_value,
    ['weight'] = 4,
    ['ratios'] = {
      { resource = b.resource(b.full_shape,      'copper-ore',     value), weight = 15 },
      { resource = b.resource(b.full_shape,      'stone',          value), weight = 10 },
      { resource = b.resource(b.full_shape,      'iron-ore',       value), weight = 20 },
      { resource = b.resource(b.full_shape,      'coal',           value), weight =  5 },
      { resource = b.resource(after(R_molyb),    'molybdenum-ore', value), weight = 50 },
    }
  },
  {
    name = 'borax',
    ['tiles'] = {
      [1] = 'landfill',
    },
    ['start'] = start_value,
    ['weight'] = 6,
    ['ratios'] = {
      { resource = b.resource(before(R_borax),   'coal',           value), weight =  5 },
      { resource = b.resource(before(R_borax),   'stone',          value), weight = 10 },
      { resource = b.resource(before(R_borax),   'copper-ore',     value), weight = 15 },
      { resource = b.resource(before(R_borax),   'iron-ore',       value), weight = 20 },
      { resource = b.resource(after(R_borax),    'borax',          value), weight = 50 },
      { resource = b.resource(after(R_niobium),  'niobium',        value), weight = 50 },
    }
  },
}
