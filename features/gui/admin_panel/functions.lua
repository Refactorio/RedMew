local Report = require 'features.report'

-- == ACTIONS =================================================================

local Actions = require 'features.admin_commands'

---@param filename? string
---@param player? LuaPlayer
function Actions.save_game(filename, player)
  filename = filename or 'currently-running'
  game.auto_save(filename)
  local msg = 'Saving map: _autosave-' .. filename ..'.zip'
  if player and player.valid then
    player.print(msg)
  else
    game.print(msg)
  end
end

---@param player? LuaPlayer
function Actions.remove_all_ghost_entities(player)
  local count = 0
  for _, surface in pairs(game.surfaces) do
    for _, ghost in pairs(surface.find_entities_filtered { type = { 'entity-ghost', 'tile-ghost' }}) do
      ghost.destroy()
      count = count + 1
    end
  end
  local msg = count .. ' blueprints removed from all surfaces.'
  if player and player.valid then
    player.print(msg)
  else
    game.print(msg)
  end
end

---@param player? LuaPlayer
function Actions.destroy_all_speakers(player)
  local count = 0
  for _, surface in pairs(game.surfaces) do
    for _, speaker in pairs(surface.find_entities_filtered { type = 'programmable-speaker' }) do
      if speaker.parameters.playback_globally == true then
        speaker.die('player')
        count = count + 1
      end
    end
  end
  local msg = count .. ' speakers removed from all surfaces.'
  if player and player.valid then
    player.print(msg)
  else
    game.print(msg)
  end
end

---@param player? LuaPlayer
function Actions.kill_all_enemy_units(player)
  game.forces.enemy.kill_all_units()
  local msg = 'All units have been killed.'
  if player and player.valid then
    player.print(msg)
  else
    game.print(msg)
  end
end

---@param player? LuaPlayer
function Actions.kill_all_enemies(player)
  local count = 0
  for _, surface in pairs(game.surfaces) do
    for _, enemy in pairs(surface.find_entities_filtered { force = 'enemy' }) do
      enemy.die('player')
      count = count + 1
    end
  end
  game.forces.enemy.kill_all_units()
  local msg = count .. ' enemies have been killed.'
  if player and player.valid then
    player.print(msg)
  else
    game.print(msg)
  end
end

---@param target_name string
---@param reason? string
---@param admin? LuaPlayer
function Actions.ban_player(target_name, reason, admin)
  local player = game.get_player(target_name)
  if not (player and player.valid) then
    local msg = 'Could not ban player: ' .. target_name
    if admin and admin.valid then
      admin.print(msg)
    else
      game.print(msg)
    end
    return
  end
  Report.ban_player(player, reason)
end

---@param target_player string
---@param source_player LuaPlayer
function Actions.spank(target_name, source_player)
  local target_player = game.get_player(target_name)
  local character = target_player.character
  if not (character and character.valid) then
    return
  end
  if character.health > 5 then
    character.damage(5, 'player')
  end
  target_player.surface.create_entity { name = 'water-splash', position = target_player.position }
  game.print(source_player.name .. ' spanked ' .. target_player.name, {r = 0.98, g = 0.66, b = 0.22})
end

-- == SURFACE =================================================================

local Surface = {}

---@param player LuaPlayer
---@param radius number
function Surface.chart_map(player, radius)
  local position = player.position
  local area = {
    left_top = { x = position.x - radius, y = position.y - radius },
    right_bottom = { x = position.x + radius, y = position.y + radius }
  }
  player.force.chart(player.surface, area)
  player.print('Revealing the area around you...')
end

---@param player LuaPlayer
function Surface.hide_all(player)
  local surface = player.surface
  local force = player.force
  for chunk in surface.get_chunks() do
    force.unchart_chunk({ x = chunk.x, y = chunk.y }, surface)
  end
  player.print('Hidden all of ' ..surface.name .. ' surface' )
end

---@param player LuaPlayer
function Surface.reveal_all(player)
  player.force.chart_all()
  player.print('Removing the from from ' .. player.surface.name .. ' surface')
end

---@param player LuaPlayer
function Surface.rechart_all(player)
  player.force.rechart()
  player.print('Revealing all of ' .. player.surface.name .. ' surface')
end

-- ============================================================================

return {
  actions = Actions,
  surface = Surface,
}
