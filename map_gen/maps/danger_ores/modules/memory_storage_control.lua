local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'

if not script.active_mods['deep-storage-unit'] then
  return
end

-- Disable MU tech & drop 4 of them at spawn
Event.on_init(function()
  game.forces.player.technologies['memory-unit'].enabled = false

  local chest = RS.get_surface().create_entity{
    name = 'iron-chest',
    position = {0, 0},
    force = 'player',
    create_build_effect_smoke = true,
    move_stuck_players = true
  }

  chest.insert({ count = 4, name = 'memory-unit'})
end)

-- If a player disconnects with any Memory Storage in its inventory, spill all of it immediately
Event.add(defines.events.on_pre_player_left_game, function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  for _, inv_type in pairs({defines.inventory.character_main, defines.inventory.character_trash}) do
    local inv = player.get_inventory(inv_type)
    local count = inv.get_item_count

    if count('memory-unit') + count('memory-unit-with-tags') > 0 then
      local spill_stack = player.surface and player.surface.spill_item_stack
      local position = player.position

      for i=1, #inv do
        spill_stack(position, inv[i], true, nil, false)
        inv[i].clear()
      end
    end
  end
end)
