local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local Server = require 'features.server'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'

return function()
  ShareGlobals.data.biters_disabled = false
  ShareGlobals.data.map_won = false

  local function disable_biters()
    if ShareGlobals.data.biters_disabled then
      return
    end

    ShareGlobals.data.biters_disabled = true
    game.forces.enemy.kill_all_units()
    for _, enemy_entity in pairs(RS.get_surface().find_entities_filtered({ force = 'enemy' })) do
      enemy_entity.destroy()
    end

    local message = table.concat {
      'Launching the first satellite has killed all the biters. ',
      'Build and activate the Intergalactic Transceiver to win the map.',
    }
    game.print({ 'danger_ores.biters_disabled_k2' })
    Server.to_discord_bold(message)
  end

  local function rocket_launched(event)
    if ShareGlobals.data.map_won then
      return
    end

    local entity = event.rocket
    if not entity or not entity.valid or not entity.force == 'player' then
      return
    end

    local pod = entity.cargo_pod
    if not pod or not pod.valid then
      return
    end

    local count = 0
    local qualities = prototypes.quality
    for k = 1, pod.get_max_inventory_index() do
      local inventory = pod.get_inventory(k)
      if inventory then
        local add = inventory.get_item_count
        for tier, _ in pairs(qualities) do
          count = count + add({ name = 'satellite', quality = tier })
        end
      end
    end

    if count == 0 then
      return
    end

    local satellite_count = game.forces.player.get_item_launched('satellite')
    if satellite_count == 0 then
      return
    end
    if satellite_count == 1 then
      disable_biters()
    end
  end

  local function win()
    if ShareGlobals.data.map_won then
      return
    end

    ShareGlobals.data.map_won = true
    local message = 'Congratulations! The map has been won. Restart the map with /restart'
    game.print({ 'danger_ores.win' })
    Server.to_discord_bold(message)
  end

  local function on_transceiver_built(event)
    if event.effect_id ~= 'k2-transciever-activated' then
      return
    end
    win()
  end

  Event.add(defines.events.on_rocket_launched, rocket_launched)
  Event.add(defines.events.on_script_trigger_effect, on_transceiver_built)
end
