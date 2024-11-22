local Color = require 'resources.color_presets'
local Game = require 'utils.game'
local Performance = require 'features.performance'
local Report = require 'features.report'

-- == ACTIONS =================================================================

local Actions = require 'features.admin_commands'

---@param filename? string
---@param player? LuaPlayer
function Actions.save_game(filename, player)
  filename = filename or 'currently-running'
  game.auto_save(filename)
  Game.player_print('Saving map: _autosave-' .. filename ..'.zip', Color.success, player)
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
  Game.player_print(count .. ' ghost entities removed from all surfaces.', Color.success, player)
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
  Game.player_print(count .. ' speakers removed from all surfaces.', Color.success, player)
end

---@param player? LuaPlayer
function Actions.kill_all_enemy_units(player)
  game.forces.enemy.kill_all_units()
  Game.player_print('All enemy units have been killed.', Color.success, player)
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
  Game.player_print(count .. ' enemies have been killed.', Color.success, player)
end

---@param target_name string
---@param reason? string
---@param admin? LuaPlayer
function Actions.ban_player(target_name, reason, admin)
  local player = game.get_player(target_name)
  if not (player and player.valid) then
    Game.player_print('Could not ban player: ' .. target_name, Color.fail, admin)
    return
  end
  Report.ban_player(player, reason, admin)
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
  target_player.physical_surface.create_entity { name = 'water-splash', position = target_player.physical_position }
  game.print(source_player.name .. ' spanked ' .. target_player.name, {color = Color.warning})
end

---@param player LuaPlayer
function Actions.toggle_blueprint_permissions(player)
  local allowed = true
  local no_blueprints = {
    defines.input_action.import_blueprint,
    defines.input_action.import_blueprint_string,
    defines.input_action.import_blueprints_filtered,
    defines.input_action.import_permissions_string,
    defines.input_action.open_blueprint_library_gui,
    defines.input_action.open_blueprint_record,
    defines.input_action.upgrade_opened_blueprint_by_record,
  }
  local Default = game.permissions.get_group("Default")
  for _, action in pairs(no_blueprints) do
    allowed = allowed and Default.allows_action(action)
  end
  allowed = not allowed
  for _, action in pairs(no_blueprints) do
    Default.set_allows_action(action, allowed)
  end
  local on, off = '[color=blue]ON[/color]', '[color=red]OFF[/color]'
  Game.player_print('Blueprint permissions: ' .. (allowed and on or off), Color.success, player)
end

---@param player LuaPlayer\
function Actions.create_oil_field(player)
  local src = player.physical_position
  local oil = prototypes.entity['crude-oil']
  local try = player.physical_surface and player.physical_surface.can_place_entity
  local create = player.physical_surface and player.physical_surface.create_entity
  if not create or not oil then
    return
  end
  for y = 0, 2 do
    for x = 0, 2 do
      local def = { name = oil, amount = 3e5, position = { x = src.x + x*7 - 7, y = src.y + y*7 - 7 } }
      if try(def) then create(def) end
    end
  end
  Game.player_print('Caution: slippery oil', Color.success, player)
end

---@param player LuaPlayer
function Actions.create_pollution(player)
  player.surface.pollute(player.position, 1e6)
  Game.player_print('Your feet smell like pollution', Color.success, player)
end

-- == SURFACE =================================================================

local Surface = {}

---@param scale number
function Surface.performance_scale_set(scale)
  Performance.set_time_scale(scale)
  local stat_mod = Performance.get_player_stat_modifier()
  game.print({'performance.stat_preamble'})
  game.print({'performance.generic_stat', {'performance.game_speed'}, string.format('%.2f', Performance.get_time_scale())})
  local stat_string = string.format('%.2f', stat_mod)
  game.print({'performance.output_formatter', {'performance.running_speed'}, stat_string, {'performance.manual_mining_speed'}, stat_string, {'performance.manual_crafting_speed'}, stat_string})
end

---@param player LuaPlayer
---@param radius number
function Surface.chart_map(player, radius)
  local position = player.position
  local area = {
    left_top = { x = position.x - radius, y = position.y - radius },
    right_bottom = { x = position.x + radius, y = position.y + radius }
  }
  player.force.chart(player.surface, area)
  Game.player_print('Revealing the area around you...', Color.success, player)
end

---@param player LuaPlayer
function Surface.hide_all(player)
  local surface = player.surface
  local force = player.force
  for chunk in surface.get_chunks() do
    force.unchart_chunk({ x = chunk.x, y = chunk.y }, surface)
  end
  Game.player_print('Hidden all of ' ..surface.name .. ' surface', Color.success, player)
end

---@param player LuaPlayer
function Surface.reveal_all(player)
  player.force.chart_all()
  Game.player_print('Removing the fog from ' .. player.surface.name .. ' surface', Color.success, player)
end

---@param player LuaPlayer
function Surface.rechart_all(player)
  player.force.rechart()
  Game.player_print('Revealing all of ' .. player.surface.name .. ' surface', Color.success, player)
end

-- ============================================================================

return {
  actions = Actions,
  surface = Surface,
}
