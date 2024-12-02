-- source: https://lua-api.factorio.com/latest/concepts/MapGenSize.html

local sqrt2 = math.sqrt(2)

return {
  none = 0,
  very_low = 1 / 2,
  very_small = 1 / 2,
  very_poor = 1 / 2,
  low = 1 / sqrt2,
  small = 1 / sqrt2,
  poor = 1 / sqrt2,
  normal = 1,
  medium = 1,
  regular = 1,
  high = sqrt2,
  big = sqrt2,
  good = sqrt2,
  very_high = 2,
  very_big = 2,
  very_good = 2,
}