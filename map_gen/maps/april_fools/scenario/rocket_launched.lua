local Event = require 'utils.event'
local Rocket = require 'utils.rocket'
local Server = require 'features.server'
local ShareGlobals = require 'map_gen.maps.april_fools.scenario.shared_globals'

ShareGlobals.data.map_won = false

local win_satellite_count = 100

_G.rocket_launched_win_data = {
  extra_rockets = win_satellite_count
}

local function disable_biters()
  game.forces.enemy.kill_all_units()
  for _, surface in pairs(game.surfaces) do
    for _, enemy_entity in pairs(surface.find_entities_filtered({ force = 'enemy' })) do
      enemy_entity.destroy()
    end
  end

  local message = 'Launching the last satellite has killed all the biters!'
  game.print(message)
  Server.to_discord_bold(message)
end

local function win()
  if ShareGlobals.data.map_won then
    return
  end

  ShareGlobals.data.map_won = true
  local message = 'Congratulations! The map has been won. Restart the map with /restart'
  game.print(message)
  Server.to_discord_bold(message)
end

local function print_satellite_message(count)
  local remaining_count = win_satellite_count - count
  if remaining_count <= 0 then
    return
  end

  local message = table.concat { 'Launch another ', remaining_count, ' satellites to win the map.' }
  game.print(message)
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

  if 0 == Rocket.count_rocket_contents(entity.cargo_pod, { name = 'satellite' }) then
    return
  end

  local satellite_count = Rocket.get_item_launched({ name = 'satellite' })
  if satellite_count == win_satellite_count then
    disable_biters()
    win()
    return
  end

  if (satellite_count % 50) == 0 then
    print_satellite_message(satellite_count)
  end
end

Event.add(defines.events.on_rocket_launched, rocket_launched)

