local function make_variations(name, min, max)
  local tiles = {}
  for i=min, max do
    table.insert(tiles, name .. '-' .. tostring(i))
  end
  return tiles
end

return {
  ['frozen-snow']                = make_variations('frozen-snow',                0, 9),
  ['mineral-aubergine-dirt']     = make_variations('mineral-aubergine-dirt',     1, 6),
  ['mineral-aubergine-sand']     = make_variations('mineral-aubergine-sand',     1, 3),
  ['mineral-beige-dirt']         = make_variations('mineral-beige-dirt',         1, 6),
  ['mineral-beige-sand']         = make_variations('mineral-beige-sand',         1, 3),
  ['mineral-black-dirt']         = make_variations('mineral-black-dirt',         1, 6),
  ['mineral-black-sand']         = make_variations('mineral-black-sand',         1, 3),
  ['mineral-brown-dirt']         = make_variations('mineral-brown-dirt',         1, 6),
  ['mineral-brown-sand']         = make_variations('mineral-brown-sand',         1, 3),
  ['mineral-cream-dirt']         = make_variations('mineral-cream-dirt',         1, 6),
  ['mineral-cream-sand']         = make_variations('mineral-cream-sand',         1, 3),
  ['mineral-dustyrose-dirt']     = make_variations('mineral-dustyrose-dirt',     1, 6),
  ['mineral-dustyrose-sand']     = make_variations('mineral-dustyrose-sand',     1, 3),
  ['mineral-grey-dirt']          = make_variations('mineral-grey-dirt',          1, 6),
  ['mineral-grey-sand']          = make_variations('mineral-grey-sand',          1, 3),
  ['mineral-purple-dirt']        = make_variations('mineral-purple-dirt',        1, 6),
  ['mineral-purple-sand']        = make_variations('mineral-purple-sand',        1, 3),
  ['mineral-red-dirt']           = make_variations('mineral-red-dirt',           1, 6),
  ['mineral-red-sand']           = make_variations('mineral-red-sand',           1, 3),
  ['mineral-tan-dirt']           = make_variations('mineral-tan-dirt',           1, 6),
  ['mineral-tan-sand']           = make_variations('mineral-tan-sand',           1, 3),
  ['mineral-violet-dirt']        = make_variations('mineral-violet-dirt',        1, 6),
  ['mineral-violet-sand']        = make_variations('mineral-violet-sand',        1, 3),
  ['mineral-white-dirt']         = make_variations('mineral-white-dirt',         1, 6),
  ['mineral-white-sand']         = make_variations('mineral-white-sand',         1, 3),
  ['vegetation-blue-grass']      = make_variations('vegetation-blue-grass',      1, 2),
  ['vegetation-green-grass']     = make_variations('vegetation-green-grass',     1, 4),
  ['vegetation-mauve-grass']     = make_variations('vegetation-mauve-grass',     1, 2),
  ['vegetation-olive-grass']     = make_variations('vegetation-olive-grass',     1, 2),
  ['vegetation-orange-grass']    = make_variations('vegetation-orange-grass',    1, 2),
  ['vegetation-purple-grass']    = make_variations('vegetation-purple-grass',    1, 2),
  ['vegetation-red-grass']       = make_variations('vegetation-red-grass',       1, 2),
  ['vegetation-turquoise-grass'] = make_variations('vegetation-turquoise-grass', 1, 2),
  ['vegetation-violet-grass']    = make_variations('vegetation-violet-grass',    1, 2),
  ['vegetation-yellow-grass']    = make_variations('vegetation-yellow-grass',    1, 2),
  ['volcanic-blue-heat']         = make_variations('volcanic-blue-heat',         1, 4),
  ['volcanic-green-heat']        = make_variations('volcanic-green-heat',        1, 4),
  ['volcanic-orange-heat']       = make_variations('volcanic-orange-heat',       1, 4),
  ['volcanic-purple-heat']       = make_variations('volcanic-purple-heat',       1, 4),
}
