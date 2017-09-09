function walk_distance_on_second()
  local last_positions = global.scenario.variables.player_positions
  local d_x = 0
  local d_y = 0
  for _,v in pairs(game.players) do
    if (v.afk_time < 30 or v.walking_state.walking) and v.vehicle == nil then
      d_x = last_positions[v.name].x - v.position.x
      d_y = last_positions[v.name].y - v.position.y
      global.scenario.variables.player_walk_distances[v.name] = global.scenario.variables.player_walk_distances[v.name] + math.sqrt(d_x*d_x + d_y*d_y)
      global.scenario.variables.player_positions[v.name] = v.position
    end
  end
end

local function get_player_positions()
  local pos = {}
  for _,v in pairs(game.players) do
    pos[v.name] = v.position
  end
  return pos
end

local function init_player_position(event)
  local player = game.players[event.player_index]
  global.scenario.variables.player_positions[player.name] = player.position
  if not global.scenario.variables.player_walk_distances[player.name] then
    global.scenario.variables.player_walk_distances[player.name] = 0
  end
end

Event.register(defines.events.on_player_joined_game, init_player_position)
