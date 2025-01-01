-- Get random item stacks based off a budget
-- modified by RedRafe
-- source: https://github.com/ComfyFactory/ComfyFactorio/blob/develop/maps/expanse/price_raffle.lua
-- ======================================================= --

-- @usage PriceRaffle
--[[
  get_item_worth(name): int
    name             - string

  is_unlocked(name): bool
    name             - string

  roll_item_stack(remaining_budget, blacklist, value_blacklist): ItemStack | nil
    remaining_budget - the value of the item stack
    blacklist		     - optional list of item names that can not be rolled. example: {["substation"] = true, ["roboport"] = true,}
    value_blacklist  - max value of an item for it to be included

  roll(budget, max_slots, blacklist): table<ItemStack> | nil
    budget		       - the total value of the item stacks combined
    max_slots	       - the maximum amount of item stacks to return
    blacklist		     - optional list of item names that can not be rolled. example: {["substation"] = true, ["roboport"] = true,}
    value_blacklist  - max value of an item for it to be included
]]

local Global = require 'utils.global'
local Event = require 'utils.event'
local table = require 'utils.table'
local Public = {}

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local math_random = math.random
local math_floor = math.floor

local item_worths = {
  ['accumulator'] = 64,
  ['advanced-circuit'] = 16,
  ['arithmetic-combinator'] = 16,
  ['artillery-shell'] = 128,
  ['artillery-turret'] = 8192,
  ['artillery-wagon'] = 16384,
  ['assembling-machine-1'] = 32,
  ['assembling-machine-2'] = 128,
  ['assembling-machine-3'] = 512,
  ['atomic-bomb'] = 16384,
  ['automation-science-pack'] = 4,
  ['battery-equipment'] = 128,
  ['battery-mk2-equipment'] = 2048,
  ['battery'] = 16,
  ['beacon'] = 512,
  ['belt-immunity-equipment'] = 256,
  ['big-electric-pole'] = 64,
  ['boiler'] = 8,
  ['burner-inserter'] = 2,
  ['burner-mining-drill'] = 8,
  ['cannon-shell'] = 8,
  ['car'] = 128,
  ['cargo-landing-pad'] = 2048,
  ['cargo-wagon'] = 256,
  ['centrifuge'] = 2048,
  ['chemical-plant'] = 128,
  ['chemical-science-pack'] = 128,
  ['cliff-explosives'] = 256,
  ['cluster-grenade'] = 64,
  ['coal'] = 1,
  ['combat-shotgun'] = 256,
  ['concrete'] = 4,
  ['constant-combinator'] = 16,
  ['construction-robot'] = 256,
  ['copper-cable'] = 1,
  ['copper-ore'] = 1,
  ['copper-plate'] = 1,
  ['crude-oil-barrel'] = 8,
  ['decider-combinator'] = 16,
  ['defender-capsule'] = 16,
  ['destroyer-capsule'] = 256,
  ['discharge-defense-equipment'] = 2048,
  ['distractor-capsule'] = 128,
  ['efficiency-module-2'] = 512,
  ['efficiency-module-3'] = 2048,
  ['efficiency-module'] = 128,
  ['electric-engine-unit'] = 64,
  ['electric-furnace'] = 256,
  ['electric-mining-drill'] = 32,
  ['electronic-circuit'] = 4,
  ['empty-barrel'] = 4,
  ['energy-shield-equipment'] = 512,
  ['energy-shield-mk2-equipment'] = 4096,
  ['engine-unit'] = 8,
  ['exoskeleton-equipment'] = 1024,
  ['explosive-cannon-shell'] = 16,
  ['explosive-rocket'] = 8,
  ['explosive-uranium-cannon-shell'] = 64,
  ['explosives'] = 4,
  ['express-splitter'] = 256,
  ['express-transport-belt'] = 64,
  ['express-underground-belt'] = 256,
  ['fast-inserter'] = 32,
  ['fast-splitter'] = 64,
  ['fast-transport-belt'] = 16,
  ['fast-underground-belt'] = 64,
  ['firearm-magazine'] = 4,
  ['flamethrower-ammo'] = 32,
  ['flamethrower-turret'] = 2048,
  ['flamethrower'] = 512,
  ['fluid-wagon'] = 256,
  ['flying-robot-frame'] = 128,
  ['fission-reactor-equipment'] = 8192,
  ['gate'] = 16,
  ['grenade'] = 16,
  ['gun-turret'] = 64,
  ['hazard-concrete'] = 4,
  ['heat-exchanger'] = 256,
  ['heat-pipe'] = 128,
  ['heavy-armor'] = 256,
  ['heavy-oil-barrel'] = 16,
  ['inserter'] = 8,
  ['iron-chest'] = 8,
  ['iron-gear-wheel'] = 2,
  ['iron-ore'] = 1,
  ['iron-plate'] = 1,
  ['iron-stick'] = 1,
  ['lab'] = 64,
  ['land-mine'] = 8,
  ['landfill'] = 12,
  ['laser-turret'] = 1024,
  ['light-armor'] = 32,
  ['light-oil-barrel'] = 16,
  ['locomotive'] = 512,
  ['active-provider-chest'] = 256,
  ['buffer-chest'] = 512,
  ['passive-provider-chest'] = 256,
  ['requester-chest'] = 512,
  ['storage-chest'] = 256,
  ['linked-chest'] = 4096,
  ['logistic-robot'] = 256,
  ['logistic-science-pack'] = 16,
  ['long-handed-inserter'] = 16,
  ['low-density-structure'] = 64,
  ['lubricant-barrel'] = 16,
  ['medium-electric-pole'] = 32,
  ['military-science-pack'] = 64,
  ['modular-armor'] = 1024,
  ['night-vision-equipment'] = 256,
  ['nuclear-fuel'] = 1024,
  ['nuclear-reactor'] = 8192,
  ['offshore-pump'] = 16,
  ['oil-refinery'] = 256,
  ['personal-laser-defense-equipment'] = 2048,
  ['personal-roboport-equipment'] = 512,
  ['personal-roboport-mk2-equipment'] = 4096,
  ['petroleum-gas-barrel'] = 16,
  ['piercing-rounds-magazine'] = 8,
  ['piercing-shotgun-shell'] = 16,
  ['pipe-to-ground'] = 15,
  ['pipe'] = 1,
  ['pistol'] = 4,
  ['plastic-bar'] = 8,
  ['poison-capsule'] = 64,
  ['power-armor-mk2'] = 32768,
  ['power-armor'] = 4096,
  ['power-switch'] = 16,
  ['processing-unit'] = 128,
  ['production-science-pack'] = 256,
  ['productivity-module-2'] = 512,
  ['productivity-module-3'] = 2048,
  ['productivity-module'] = 128,
  ['programmable-speaker'] = 32,
  ['pump'] = 32,
  ['pumpjack'] = 64,
  ['radar'] = 32,
  ['rail-chain-signal'] = 16,
  ['rail-signal'] = 16,
  ['rail'] = 8,
  ['refined-concrete'] = 16,
  ['refined-hazard-concrete'] = 16,
  ['repair-pack'] = 8,
  ['roboport'] = 2048,
  ['rocket-fuel'] = 256,
  ['rocket-launcher'] = 128,
  ['rocket-silo'] = 65536,
  ['rocket'] = 8,
  ['satellite'] = 32768,
  ['selector-combinator'] = 16,
  ['shotgun-shell'] = 4,
  ['shotgun'] = 16,
  ['slowdown-capsule'] = 16,
  ['small-electric-pole'] = 4,
  ['small-lamp'] = 16,
  ['solar-panel-equipment'] = 256,
  ['solar-panel'] = 64,
  ['solid-fuel'] = 16,
  ['space-science-pack'] = 512,
  ['speed-module-2'] = 512,
  ['speed-module-3'] = 2048,
  ['speed-module'] = 128,
  ['splitter'] = 16,
  ['bulk-inserter'] = 128,
  ['steam-engine'] = 32,
  ['steam-turbine'] = 256,
  ['steel-chest'] = 64,
  ['steel-furnace'] = 64,
  ['steel-plate'] = 8,
  ['stone'] = 1,
  ['stone-brick'] = 2,
  ['stone-furnace'] = 4,
  ['stone-wall'] = 8,
  ['storage-tank'] = 64,
  ['submachine-gun'] = 32,
  ['substation'] = 256,
  ['sulfur'] = 4,
  ['sulfuric-acid-barrel'] = 16,
  ['tank'] = 4096,
  ['train-stop'] = 64,
  ['transport-belt'] = 4,
  ['underground-belt'] = 16,
  ['uranium-235'] = 1024,
  ['uranium-238'] = 32,
  ['uranium-cannon-shell'] = 64,
  ['uranium-fuel-cell'] = 128,
  ['uranium-ore'] = 4,
  ['uranium-rounds-magazine'] = 64,
  ['utility-science-pack'] = 256,
  ['water-barrel'] = 4,
  ['wooden-chest'] = 4,
}
local item_unlocked = {}
local item_names = {}

_G.item_unlocked_data =  item_unlocked

Global.register({
    item_unlocked = item_unlocked,
    item_names = item_names,
  },
  function(tbl)
    item_unlocked = tbl.item_unlocked
    item_names = tbl.item_names
  end)

function Public.get_item_worth(name)
  return item_worths[name] or 0
end

function Public.is_unlocked(name)
  return item_unlocked[name] ~= nil
end

function Public.set_unlocked(name, unlocked, value)
  if unlocked then
    item_unlocked[name] = value or item_worths[name] or 64
    if not table.contains(item_names, name) then
      table_insert(item_names, name)
    end
  else
    item_unlocked[name] = nil
    table.remove_element(item_names, name)
  end
end

local function get_raffle_keys()
  local raffle_keys = {}
  for i = 1, #item_names do
    raffle_keys[i] = i
  end
  table_shuffle_table(raffle_keys)
  return raffle_keys
end

function Public.roll_item_stack(remaining_budget, blacklist, value_blacklist)
  if remaining_budget <= 0 then
    return
  end

  local raffle_keys = get_raffle_keys()
  local item_name = false
  local item_worth = 0
  for _, index in pairs(raffle_keys) do
    item_name = item_names[index]
    item_worth = item_unlocked[item_name]
    if not blacklist[item_name] and item_worth <= remaining_budget and item_worth <= value_blacklist then
      break
    end
  end

  local stack_size = prototypes.item[item_name].stack_size * 32

  local item_count = 1

  for c = 1, math_random(1, stack_size) do
    local price = c * item_worth
    if price <= remaining_budget then
      item_count = c
    else
      break
    end
  end

  return { name = item_name, count = item_count }
end

local function roll_item_stacks(remaining_budget, max_slots, blacklist, value_blacklist)
  local item_stack_set = {}
  local item_stack_set_worth = 0

  for i = 1, max_slots do
    if remaining_budget <= 0 then
      break
    end
    local item_stack = Public.roll_item_stack(remaining_budget, blacklist, value_blacklist)
    item_stack_set[i] = item_stack
    remaining_budget = remaining_budget - item_stack.count * item_unlocked[item_stack.name]
    item_stack_set_worth = item_stack_set_worth + item_stack.count * item_unlocked[item_stack.name]
  end

  return item_stack_set, item_stack_set_worth
end

function Public.roll(budget, max_slots, blacklist, value_blacklist)
  if not budget then
    return
  end
  if not max_slots then
    return
  end

  local b, vb
  if not blacklist then
    b = {}
  else
    b = blacklist
  end
  if not value_blacklist then
    vb = 65536
  else
    vb = value_blacklist
  end

  budget = math_floor(budget)
  if budget == 0 then
    return
  end

  local final_stack_set
  local final_stack_set_worth = 0

  for _ = 1, 5 do
    local item_stack_set, item_stack_set_worth = roll_item_stacks(budget, max_slots, b, vb)
    if item_stack_set_worth > final_stack_set_worth or item_stack_set_worth == budget then
      final_stack_set = item_stack_set
      final_stack_set_worth = item_stack_set_worth
    end
  end
  return final_stack_set
end

local function add_recipe_products(recipe)
  if not (recipe and recipe.enabled) then
    return
  end

  for _, product in pairs(recipe.products) do
    local name = product.name
    if product.type == 'fluid' then
      name = name .. '-barrel'
    end

    if prototypes.item[name] ~= nil then
      item_unlocked[name] = item_worths[name]
      if item_unlocked[name] ~= nil then
        table_insert(item_names, name)
      end
    end
  end
end

function Public.get_unlocked_item_names()
  return item_names
end

function Public.get_unlocked_item_values()
  return item_unlocked
end

function Public.get_items_worth()
  return item_worths
end

Event.on_init(function()
  for _, recipe in pairs(game.forces.player.recipes) do
    add_recipe_products(recipe)
  end

  for _, name in pairs({
    'coal',
    'copper-ore',
    'fish',
    'iron-ore',
    'stone',
    'wood',
  }) do
    item_unlocked[name] = item_worths[name]
    if item_unlocked[name] ~= nil then
      table_insert(item_names, name)
    end
  end
end)

Event.add(defines.events.on_research_finished, function(event)
  local technology = event.research
  if technology.force.name ~= 'player' then
    return
  end

  for _, effect in pairs(technology.prototype.effects or {}) do
    if effect.recipe then
      add_recipe_products(game.forces.player.recipes[effect.recipe])
    end
  end

  if technology.name == 'space-science-pack' then
    item_unlocked['space-science-pack'] = item_worths['space-science-pack']
  end
end)

return Public
