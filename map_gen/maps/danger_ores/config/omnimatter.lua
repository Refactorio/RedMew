local b = require 'map_gen.shared.builders'
local start_value = b.euclidean_value(0, 0.35)
local value = b.exponential_value(0, 0.06, 1.55)

return {
  {
    name = 'omnite',
    ['tiles'] = {
      [1] = 'red-desert-0',
      [2] = 'red-desert-1',
      [3] = 'red-desert-2',
      [4] = 'red-desert-3',
      [5] = 'dirt-1',
      [6] = 'dirt-2',
      [7] = 'dirt-3',
      [8] = 'dirt-4',
      [9] = 'dirt-5',
      [10] = 'dirt-6',
      [11] = 'dirt-7',
      [12] = 'grass-1',
      [13] = 'grass-2',
      [14] = 'grass-3',
      [15] = 'grass-4',
      [16] = 'sand-1',
      [17] = 'sand-2',
      [18] = 'sand-3',
    },
    ['start'] = start_value,
    ['weight'] = 1,
    ['ratios'] = {
      {resource = b.resource(b.full_shape, 'omnite', value), weight = 100},
    }
  },
}
