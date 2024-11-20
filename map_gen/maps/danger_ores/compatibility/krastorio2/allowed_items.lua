local items = {
  -- raws
  'coal',
  'compact-raw-rare-metals',
  'copper-ore',
  'iron-ore',
  'raw-imersite',
  'raw-rare-metals',
  'stone',
  'uranium-ore',
  'wood',
  -- processed
  'coke',
  'enriched-copper',
  'enriched-iron',
  'enriched-rare-metals',
  'fluoride',
  'imersite-crystal',
  'imersite-powder',
  'lithium-chloride',
  'lithium',
  'quartz',
  'sand',
  'silicon',
  'solid-fuel',
  'sulfur',
  'yellowcake',
  -- plates
  'copper-plate',
  'glass',
  'imersium-plate',
  'iron-plate',
  'plastic-bar',
  'rare-metals',
  'steel-plate',
  'stone-brick',
  -- intermediates
  'electronic-components',
  'electronic-circuit',
  'advanced-circuit',
  'processing-unit',
}

local allowed_recipes = {}

for _, k in pairs(items) do
  allowed_recipes[k] = true
end

return allowed_recipes