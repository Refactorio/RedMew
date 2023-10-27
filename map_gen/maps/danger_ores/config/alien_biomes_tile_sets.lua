local function make_variations(name, min, max)
  local tiles = {}
  local c = min
  for i=1, max do
    tiles[i] = name .. '-' .. tostring(c)
    c = c + 1
  end
  return tiles
end

return {
  make_variations('frozen-snow', 0, 9),
  make_variations('mineral-aubergine-dirt', 1, 6),
  make_variations('mineral-aubergine-sand', 1, 3),
  make_variations('mineral-beige-dirt', 1, 6),
  make_variations('mineral-beige-sand', 1, 3),
  make_variations('mineral-black-dirt', 1, 6),
  make_variations('mineral-black-sand', 1, 3),
  make_variations('mineral-brown-dirt', 1, 6),
  make_variations('mineral-brown-sand', 1, 3),
  make_variations('mineral-cream-dirt', 1, 6),
  make_variations('mineral-cream-sand', 1, 3),
  make_variations('mineral-dustyrose-dirt', 1, 6),
  make_variations('mineral-dustyrose-sand', 1, 3),
  make_variations('mineral-grey-dirt', 1, 6),
  make_variations('mineral-grey-sand', 1, 3),
  make_variations('mineral-purple-dirt', 1, 6),
  make_variations('mineral-purple-sand', 1, 3),
  make_variations('mineral-red-dirt', 1, 6),
  make_variations('mineral-red-sand', 1, 3),
  make_variations('mineral-tan-dirt', 1, 6),
  make_variations('mineral-tan-sand', 1, 3),
  make_variations('mineral-violet-dirt', 1, 6),
  make_variations('mineral-violet-sand', 1, 3),
  make_variations('mineral-white-dirt', 1, 6),
  make_variations('mineral-white-sand', 1, 3),
  make_variations('vegetation-blue-grass', 1, 2),
  make_variations('vegetation-green-grass', 1, 4),
  make_variations('vegetation-mauve-grass', 1, 2),
  make_variations('vegetation-olive-grass', 1, 2),
  make_variations('vegetation-orange-grass', 1, 2),
  make_variations('vegetation-purple-grass', 1, 2),
  make_variations('vegetation-red-grass', 1, 2),
  make_variations('vegetation-turquoise-grass', 1, 2),
  make_variations('vegetation-violet-grass', 1, 2),
  make_variations('vegetation-yellow-grass', 1, 2),
  make_variations('volcanic-blue-heat', 1, 4),
  make_variations('volcanic-green-heat', 1, 4),
  make_variations('volcanic-orange-heat', 1, 4),
  make_variations('volcanic-purple-heat', 1, 4),
}