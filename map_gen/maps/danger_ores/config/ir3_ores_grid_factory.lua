local b = require 'map_gen.shared.builders'
local start_value = b.euclidean_value(0, 0.25)
local value = b.exponential_value(0, 0.07, 1.30)

return {
  {
    name = 'iron-ore',
    ['tiles'] = {
      [1] = 'grass-1',
      [2] = 'grass-2',
      [3] = 'grass-3',
      [4] = 'grass-4',
    },
    ['start'] = start_value,
    ['weight'] = 1,
    ['ratios'] = {
      { resource = b.resource(b.full_shape, 'iron-ore',       value), weight = 75 },
      { resource = b.resource(b.full_shape, 'copper-ore',     value), weight = 13 },
      { resource = b.resource(b.full_shape, 'stone',          value), weight =  7 },
      { resource = b.resource(b.full_shape, 'coal',           value), weight =  5 },
      { resource = b.resource(b.full_shape, 'gold-ore',       value), weight =  2 },
      { resource = b.resource(b.full_shape, 'tin-ore',        value), weight =  5 },
    }
  },
  {
    name = 'copper-ore',
    ['tiles'] = {
      [1] = 'red-desert-0',
      [2] = 'red-desert-1',
      [3] = 'red-desert-2',
      [4] = 'red-desert-3',
    },
    ['start'] = start_value,
    ['weight'] = 1,
    ['ratios'] = {
      { resource = b.resource(b.full_shape, 'iron-ore',       value), weight = 20 },
      { resource = b.resource(b.full_shape, 'copper-ore',     value), weight = 65 },
      { resource = b.resource(b.full_shape, 'stone',          value), weight = 10 },
      { resource = b.resource(b.full_shape, 'coal',           value), weight =  5 },
      { resource = b.resource(b.full_shape, 'gold-ore',       value), weight =  2 },
      { resource = b.resource(b.full_shape, 'tin-ore',        value), weight =  5 },
    }
  },
  {
    name = 'coal',
    ['tiles'] = {
      [1] = 'dirt-1',
      [2] = 'dirt-2',
      [3] = 'dirt-3',
      [4] = 'dirt-4',
      [5] = 'dirt-5',
      [6] = 'dirt-6',
      [7] = 'dirt-7'
    },
    ['start'] = start_value,
    ['weight'] = 1,
    ['ratios'] = {
      { resource = b.resource(b.full_shape, 'iron-ore',       value), weight = 18 },
      { resource = b.resource(b.full_shape, 'copper-ore',     value), weight =  9 },
      { resource = b.resource(b.full_shape, 'stone',          value), weight =  8 },
      { resource = b.resource(b.full_shape, 'coal',           value), weight = 65 },
      { resource = b.resource(b.full_shape, 'gold-ore',       value), weight =  2 },
      { resource = b.resource(b.full_shape, 'tin-ore',        value), weight =  5 },
    }
  },
  {
    name = 'stone',
    ['tiles'] = {
      [1] = 'sand-1',
      [2] = 'sand-2',
      [3] = 'sand-3',
    },
    ['start'] = start_value,
    ['weight'] = 1,
    ['ratios'] = {
      { resource = b.resource(b.full_shape, 'iron-ore',       value), weight =  8 },
      { resource = b.resource(b.full_shape, 'copper-ore',     value), weight =  6 },
      { resource = b.resource(b.full_shape, 'stone',          value), weight = 24 },
      { resource = b.resource(b.full_shape, 'coal',           value), weight =  5 },
      { resource = b.resource(b.full_shape, 'gold-ore',       value), weight = 27 },
      { resource = b.resource(b.full_shape, 'tin-ore',        value), weight = 30 },
    }
  },
}
