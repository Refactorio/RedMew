--[[
  Map gen settings generator supporting Alien Biome's noise levels & autoplace settings

  === Preset Library ===

  A MGS preset is a dictionary of autoplace controls for:
  - aux (Alien Biomes)
  - moisture (Alien Biomes)
  - temperature (Alien Biomes)
  - enemy
  - trees
  - water
  full updated list available at: resources/alien_biomes/biomes.lua

  ** AB.set_preset(data), AB.remove_preset(name), AB.clear_presets()

  === Param Customization ===

  ** AB.override_vanilla_mgs(MapGenSettings)
  Adds aux and moisture parameters to neg generated maps.
    @usage
    local AB = require 'map_gen.shared.alien_biomes'
    AB.override_vanilla_mgs(game.surfaces.redmew.map_gen_settings)

  === Map Gen Settings ===

  ** AB.new_from_existent(config)
  1. Generate a new random MGS based off default preset
    @usage
    local AB = require 'map_gen.shared.alien_biomes'
    local new_mgs = AB.new_from_existent()
  2. Generate a new random MGS based on current surface
    @usage
    local AB = require 'map_gen.shared.alien_biomes'
    local new_mgs = AB.new_from_existent({map_gen_settings = game.surfaces.redmew})

  ** AB.new_from_preset(config)
  1. Generate a new random MGS based off a random preset from the AB library
    @usage
    local AB = require 'map_gen.shared.alien_biomes'
    local new_mgs = AB.new_from_preset()
  2. Generate a new random MGS based on a specific preset from the AB library
    @usage
    local AB = require 'map_gen.shared.alien_biomes'
    local new_mgs = AB.new_from_preset({preset_name = 'volcano'})
]]

require 'util'
require 'utils.table'
local Global = require 'utils.global'
local Biomes = require 'resources.alien_biomes.biomes'

local Public = {}
local _this = {
  presets = Biomes.presets 
}

Global.register(_this, function(tbl) _this = tbl end)

-- === PRESET LIBRARY MANIPULATION ============================================

--- Adds a new preset to the global table
---@param data table<{ name: string, preset: table }>
---@return bool
function Public.set_preset(data)
  if not (data and data.name and data.preset) then
    return false
  end

  _this.presets[data.name] = data.preset
  return _this.presets[data.name] ~= nil
end

--- Remove target preset from the global presets list
---@param name string
---@return bool
function Public.remove_preset(name)
  if not (name and type(name) == 'string') then
    return false
  end

  _this.presets[name] = nil
  return _this.presets[name] ~= nil
end

--- Clears the global table from all presets
---@return bool
function Public.clear_presets()
  for key, _ in pairs(_this.presets) do
    _this.presets[key] = nil
  end
  return table_size(_this.presets) == 0
end

-- === PARAM CUSTOMIZATION ====================================================

local function apply_temperature(mgs)
  local hf, hs = 1, 1
  local cf, cs = 1, 1

  if _LIFECYCLE == _STAGE.init or _LIFECYCLE == _STAGE.runtime then
    hf = hf + 0.5*(math.random()-0.5)
    hs = hs + 0.2*(math.random()-0.5)

    cf = cf + 0.5*(math.random()-0.5)
    cs = cs + 0.2*(math.random()-0.5)
  end

  mgs.autoplace_controls = mgs.autoplace_controls or {}
  mgs.autoplace_controls.hot  = { frequency = hf, size = hs }
  mgs.autoplace_controls.cold = { frequency = cf, size = cs }
end

--- Adds +-25% freq and +-10% bias to Aux autoplace
---@param mgs MapGenSettings
local function apply_aux(mgs)
  local freq, bias = 1, 0

  if _LIFECYCLE == _STAGE.init or _LIFECYCLE == _STAGE.runtime then
    freq = freq + 0.5*(math.random()-0.5)
    bias = bias + 0.2*(math.random()-0.5)
  end

  mgs.property_expression_names = mgs.property_expression_names or {}
  mgs.property_expression_names['control-setting:aux:bias'] = str(bias)
  mgs.property_expression_names['control-setting:aux:frequency'] = str(freq)
end

--- Adds +-25% freq and +-10% bias to Moisture autoplace
---@param mgs MapGenSettings
local function apply_moisture(mgs)
  local freq, bias = 1, 0

  if _LIFECYCLE == _STAGE.init or _LIFECYCLE == _STAGE.runtime then
    freq = freq + 0.5*(math.random()-0.5)
    bias = bias + 0.2*(math.random()-0.5)
  end

  mgs.property_expression_names = mgs.property_expression_names or {}
  mgs.property_expression_names['control-setting:moisture:bias'] = str(bias)
  mgs.property_expression_names['control-setting:moisture:frequency'] = str(freq)
end


--- Adds random aux and moisture to default vanilla MapGenSettings
--- Is safe to call even for vanilla scenarios
---@param mgs MapGenSettings
function Public.override_vanilla_mgs(mgs)
  if not script.active_mods['alien-biomes'] then
    return
  end

  apply_aux(mgs)
  apply_moisture(mgs)
  apply_temperature(mgs)
end

-- === MAP GEN SETTINGS =======================================================

--- Generates a new random map_gen_setting from a given preset. If none is passed, the default one is used instead
--- Is safe to call even for vanilla scenarios
---@param config table
---@field seed? number
---@field map_gen_settings? MapGenSettings
---@return MapGenSettings
function Public.new_from_existent(config)
  config = config or {}
  local mgs = game.default_map_gen_settings

  if config.map_gen_settings then
    mgs = config.map_gen_settings
  end

  if _LIFECYCLE == _STAGE.init or _LIFECYCLE == _STAGE.runtime then
    mgs.seed = config.seed or math.random(4294967295)
  end

  Public.override_vanilla(mgs)

  return mgs
end

--- Generates a random map_gen_setting from the available presets
---- Is safe to call even for vanilla scenarios
--@param config table
---@field seed? number
---@field preset_name? string
---@field map_gen_settings? MapGenSetting
---@return MapGenSettings
function Public.new_from_preset(config)
  config = config or {}
  local mgs = game.default_map_gen_settings
  mgs.seed = config.seed or mgs.seed or 4294967295
  local n_presets = table_size(_this.presets)
  local index = mgs.seed % n_presets + 1

  if config.map_gen_settings then
    mgs = util.merge{mgs, config.map_gen_settings}
  end

  if _LIFECYCLE == _STAGE.init or _LIFECYCLE == _STAGE.runtime then
    mgs.seed = config.seed or math.random(4294967295)
    index = math.random(n_presets)
  end

  if script.active_mods['alien-biomes'] and n_presets > 0 then
    local preset_name = config.preset_name  or table.keys(_this.presets)[index]
    local preset = Biomes.preset_to_mgs(_this.presets[preset_name])
    mgs = util.merge{mgs, preset}
  end

  return mgs
end

-- ============================================================================

return Public
