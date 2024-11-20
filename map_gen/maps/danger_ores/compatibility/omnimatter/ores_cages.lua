local b = require 'map_gen.shared.builders'
local start_value = b.euclidean_value(10, 0.35)
local value = b.exponential_value(10, 0.06, 1.55)

local function cages(void, width, start, stop, shape)
  local cage_table = {}
  for i = 1, stop/(void+width) +1 do
    local r = i*(void+width)
    table.insert(cage_table, b.subtract(shape(r), shape(r - width)))
  end
  local bounds = b.subtract(shape(start+stop), shape(start))
  return b.all({ b.any(cage_table), bounds })
end

local cage_shape = cages(80*2, 16*2, 40*2, 800*2, b.rectangle) -- "b.circle" can also be used instead of "b.rectangle"

return {
  {
    name = 'omnite',
    ['tiles'] = {
      [1] = 'landfill'
    },
    ['start'] = start_value,
    ['weight'] = 1,
    ['ratios'] = {
      { resource = b.resource(b.invert(cage_shape), 'omnite', value), weight = 100},
    }
  },
  {
    name = 'infinite-omnite',
    ['tiles'] = {
      [1] = 'landfill'
    },
    ['start'] = start_value,
    ['weight'] = 1,
    ['ratios'] = {
      { resource = b.resource(cage_shape, 'infinite-omnite', value), weight = 100},
    }
  },
}
