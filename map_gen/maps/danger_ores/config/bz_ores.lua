local b = require 'map_gen.shared.builders'
local value = b.exponential_value(0, 0.07, 1.15)
local start_value = b.euclidean_value(0, 0.35)

local function total_weight(tbl)
  local total = 0
  for _, weight in pairs(tbl) do total = total + weight end
  return total
end

local MIN_MIXED_WEIGHT = 1
local MIN_SECTOR_WEIGHT = 2
local TILE_SETS = {
  {
    [1] = 'grass-1',
    [2] = 'grass-2',
    [3] = 'grass-3',
    [4] = 'grass-4',
  },
  {
    [1] = 'red-desert-0',
    [2] = 'red-desert-1',
    [3] = 'red-desert-2',
    [4] = 'red-desert-3',
  },
  {
    [1] = 'dirt-1',
    [2] = 'dirt-2',
    [3] = 'dirt-3',
    [4] = 'dirt-4',
    [5] = 'dirt-5',
    [6] = 'dirt-6',
    [7] = 'dirt-7',
  },
  {
    [1] = 'sand-1',
    [2] = 'sand-2',
    [3] = 'sand-3',
  },
}

if script.active_mods['alien-biomes'] then
  TILE_SETS = require 'map_gen.maps.danger_ores.config.alien_biomes_tile_sets'
end

--[[
  (Estimated resource consumption (in M) to craft 1 Million science of each pack
  obtained by using Factory Planner mod
  source: https://mods.factorio.com/mod/factoryplanner
]]
local estimated_consumption = {
--['crude-oil']       = 300,
--['gas']             =   3,
  ['aluminum-ore']    =  26, -- 16
  ['coal']            =  80,
  ['copper-ore']      =  12,
  ['gold-ore']        =   1,
  ['graphite']        =  37,
  ['iron-ore']        =  47, -- 37 + 10
  ['lead-ore']        =  15, -- 25
  ['rich-copper-ore'] =  20,
  ['salt']            =  15, -- 35
  ['stone']           =  48, -- 51 - 3
  ['tin-ore']         =  19,
  ['titanium-ore']    =  16,
  ['tungsten-ore']    =  10,
  ['uranium-ore']     =   2,
  ['zircon']          =   8,
}

--[[
  Build set of resource. Each sector has weight equal to its estimated consumption.
  Then each sector has 60% of its main resource, while the remaining 40% is split among the other mixed resources,
  in proportion to each resource's expected consumption again.
  A mixed resource can't have less than 1 points of weight.
]]
local resources = {}
local N_SETS = #TILE_SETS
local TOTAL = total_weight(estimated_consumption)

for resource_name, consumption in pairs(estimated_consumption) do

  local mixed_ratios = {}
  for name, weight in pairs(estimated_consumption) do
    local subset = table.deepcopy(estimated_consumption)
    subset[resource_name] = nil
    local w = (name == resource_name) and 60 or math.ceil(weight / total_weight(subset) * 100 * 0.4)
    table.insert(mixed_ratios, { resource = b.resource(b.full_shape, name, value), weight = math.max(MIN_MIXED_WEIGHT, w) })
  end

  table.insert(resources, {
    name   = resource_name,
    tiles  = TILE_SETS[(consumption % N_SETS) + 1],
    start  = start_value,
    weight = math.max(estimated_consumption[resource_name] / TOTAL * 100, MIN_SECTOR_WEIGHT),
    ratios = mixed_ratios
  })
end

return resources
