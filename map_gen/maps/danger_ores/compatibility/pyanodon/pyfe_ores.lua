local b = require 'map_gen.shared.builders'
local start_value = b.euclidean_value(0, 0.20)
local value = b.exponential_value(0, 0.07, 1.18)
local before = function(radius) return b.circle(radius) end
local after = function(radius) return b.invert(b.circle(radius)) end

--[[
  This config uses 'ore_builder_without_gaps' module to generate the ores.
]]

local R_borax   = 32 *  7
local R_molyb   = 32 * 11
local R_niobium = 32 *  9

return {
  {
    name = 'copper-ore',
    ['tiles'] = {
      [1] = 'landfill'
    },
    ['start'] = start_value,
    ['weight'] = 15,
    ['ratios'] = {
      { resource = b.resource(b.full_shape,      'iron-ore',       value), weight = 15 },
      { resource = b.resource(b.full_shape,      'stone',          value), weight = 10 },
      { resource = b.resource(b.full_shape,      'coal',           value), weight = 15 },
      { resource = b.resource(b.full_shape,      'copper-ore',     value), weight = 60 },
    }
  },
  {
    name = 'coal',
    ['tiles'] = {
      [1] = 'landfill'
    },
    ['start'] = start_value,
    ['weight'] = 25,
    ['ratios'] = {
      { resource = b.resource(b.full_shape,      'iron-ore',       value), weight = 18 },
      { resource = b.resource(b.full_shape,      'copper-ore',     value), weight =  9 },
      { resource = b.resource(b.full_shape,      'stone',          value), weight =  8 },
      { resource = b.resource(b.full_shape,      'coal',           value), weight = 65 },
    }
  },
  {
    name = 'iron-ore',
    ['tiles'] = {
      [1] = 'landfill'
    },
    ['start'] = start_value,
    ['weight'] = 25,
    ['ratios'] = {
      { resource = b.resource(b.full_shape,      'copper-ore',     value), weight =  8 },
      { resource = b.resource(b.full_shape,      'stone',          value), weight =  7 },
      { resource = b.resource(b.full_shape,      'coal',           value), weight = 10 },
      { resource = b.resource(b.full_shape,      'iron-ore',       value), weight = 75 },
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
      { resource = b.resource(b.full_shape,      'coal',           value), weight = 15 },
      { resource = b.resource(b.full_shape,      'stone',          value), weight = 50 },
    }
  },
  {
    name = 'molybdenum-ore',
    ['tiles'] = {
      [1] = 'landfill',
    },
    ['start'] = start_value,
    ['weight'] = 2,
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
    ['weight'] = 1,
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
