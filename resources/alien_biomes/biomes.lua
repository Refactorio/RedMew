local b = require 'resources.alien_biomes.biomes_settings'
local str = tostring

local Public = {}

-- Converts a table of settings from resources/alien_biomes/biome_settings into a valid MapGenSettings
function Public.preset_to_mgs(preset)
  local mgs = {
    autoplace_controls = {},
    property_expression_names = {},
    cliff_settings = {},
  }

  if preset.aux then
    mgs.property_expression_names['control-setting:aux:bias'] = str(preset.aux.aux.bias or 0)
    mgs.property_expression_names['control-setting:aux:frequency'] = str(preset.aux.aux.frequency or 1)
  end

  if preset.moisture then
    mgs.property_expression_names['control-setting:moisture:bias'] = str(preset.moisture.moisture.bias or 0)
    mgs.property_expression_names['control-setting:moisture:frequency'] = str(preset.moisture.moisture.frequency or 1)
  end

  if preset.enemy then
    mgs.autoplace_controls['enemy-base'] = preset.enemy['enemy-base']
  end

  if preset.temperature then
    local t = preset.temperature
    if t.cold then
      mgs.autoplace_controls.cold = t.cold
    end
    if t.hot then
      mgs.autoplace_controls.hot = t.hot
    end
  end

  if preset.water then
    mgs.autoplace_controls.water = preset.water.water
  end

  if preset.trees then
    mgs.autoplace_controls.trees = preset.trees.trees
  end

  for _, k in pairs({'autoplace_controls', 'property_expression_names', 'cliff_settings'}) do
    if table_size(mgs[k]) == 0 then
      mgs[k] = nil
    end
  end

  return mgs
end

Public.presets = {
  default = {
    aux = b.aux.med,
    enemy = b.enemy.high,
    moisture = b.moisture.med,
    temperature = b.temperature.balanced,
    trees = b.trees.high,
    water = b.water.med,
  },
  cloud = {
    aux = b.aux.very_low,
    enemy = b.enemy.none,
    moisture = b.moisture.high,
    temperature = b.temperature.cool,
    trees = b.trees.med,
    water = b.water.high,
  },
  ice = {
    aux = b.aux.med,
    enemy = b.enemy.none,
    moisture = b.moisture.med,
    temperature = b.temperature.frozen,
    trees = b.trees.none,
    water = b.water.low,
  },
  volcano = {
    aux = b.aux.very_low,
    enemy = b.enemy.none,
    moisture = b.moisture.none,
    temperature = b.temperature.volcanic,
    trees = b.trees.none,
    water = b.water.none,
  },
  mountain = {
    aux = b.aux.low,
    enemy = b.enemy.low,
    moisture = b.moisture.low,
    temperature = b.temperature.wild,
    trees = b.trees.none,
    water = b.water.low,
  },
  neptune = {
    aux = b.aux.very_high,
    enemy = b.enemy.none,
    moisture = b.moisture.high,
    temperature = b.temperature.bland,
    trees = b.trees.med,
    water = b.water.max,
  },
  jungle = {
    aux = b.aux.very_low,
    enemy = b.enemy.med,
    moisture = b.moisture.high,
    temperature = b.temperature.bland,
    trees = b.trees.high,
    water = b.water.med,
  },
  canyon = {
    aux = b.aux.low,
    enemy = b.enemy.med,
    moisture = b.moisture.high,
    temperature = b.temperature.hot,
    trees = b.trees.low,
    water = b.water.none,
  },
  desert = {
    aux = b.aux.low,
    enemy = b.enemy.med,
    moisture = b.moisture.low,
    temperature = b.temperature.warm,
    trees = b.trees.low,
    water = b.water.low,
  },
}

return Public