-- Charge your armor equipment from nearby accumulators!
-- made by Hanakocz
-- modified by RedRafe
-- source: https://github.com/ComfyFactory/ComfyFactorio/blob/develop/modules/charging_station.lua
-- ======================================================= --

local Color = require 'resources.color_presets'
local Global = require 'utils.global'

local this = {
  radius = 13
}
Global.register(this, function(tbl) this = tbl end)

local Public = {}

local function discharge_accumulators(surface, position, force, power_needs)
  local accumulators = surface.find_entities_filtered {
    type = 'accumulator',
    force = force,
    position = position,
    radius = this.radius,
  }
  local power_drained = 0
  power_needs = power_needs * 1
  for _, accu in pairs(accumulators) do
    if accu.valid then
      if accu.energy > 3000000 and power_needs > 0 then
        if power_needs >= 2000000 then
          power_drained = power_drained + 2000000
          accu.energy = accu.energy - 2000000
          power_needs = power_needs - 2000000
        else
          power_drained = power_drained + power_needs
          accu.energy = accu.energy - power_needs
        end
      elseif power_needs <= 0 then
        break
      end
    end
  end
  return power_drained / 1
end

function Public.recharge(player)
  if not player.character then
    player.print({'battery_charge.err_no_character'}, {color = Color.warning})
    return
  end
  local armor_inventory = player.get_inventory(defines.inventory.character_armor)
  if not armor_inventory.valid then
    player.print({'battery_charge.err_no_armor'}, {color = Color.warning})
    return
  end
  local armor = armor_inventory[1]
  if not armor.valid_for_read then
    player.print({'battery_charge.err_no_armor'}, {color = Color.warning})
    return
  end
  local grid = armor.grid
  if not grid or not grid.valid then
    player.print({'battery_charge.err_no_armor'}, {color = Color.warning})
    return
  end

  local entities = player.physical_surface.find_entities_filtered {
    type = 'accumulator',
    force = player.force,
    position = player.physical_position,
    radius = this.radius,
  }
  if not entities or not next(entities) then
    player.print({'battery_charge.err_no_accumulators'}, {color = Color.warning})
    return
  end

  local equip = grid.equipment
  for _, piece in pairs(equip) do
    if piece.valid and piece.generator_power == 0 then
      local energy_needs = piece.max_energy - piece.energy
      if energy_needs > 0 then
        local energy = discharge_accumulators(player.physical_surface, player.physical_position, player.force, energy_needs)
        if energy > 0 then
          if piece.energy + energy >= piece.max_energy then
            piece.energy = piece.max_energy
          else
            piece.energy = piece.energy + energy
          end
        end
      end
    end
  end
end

function Public.radius(value)
  this.radius = value or 13
end

return Public
