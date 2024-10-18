local Event = require 'utils.event'

local alert_message = '[color=yellow]Cannot build here![/color]'
local banned_per_surface = {
  islands = {
    ['furnace'] = true,
  },
  mines = {
    ['assembling-machine'] = true,
    ['solar-panel'] = true,
    ['rocket-silo'] = true,
  }
}

local function on_built(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  local surface = entity.surface.name
  local entity_type = entity.prototype.type
  if not (banned_per_surface[surface] and banned_per_surface[surface][entity_type]) then
    return
  end

  local ghost = false
  if entity.name == 'entity-ghost' then
    ghost = true
  end

  entity.destroy()

  local stack = event.stack or event.consumed_items.get_contents()[1]
  local player = game.get_player(event.player_index or 'none')
  local robot = event.robot
  if player and player.valid and not ghost and stack.valid then
    if player.can_insert(stack) then
      player.insert(stack)
      player.print(alert_message)
    end
  elseif robot and robot.valid and not ghost and stack.valid then
    -- FIXME: currenlty not refunding anything when using robots...
    if robot.can_insert(stack) then
      robot.insert(stack)
    end
  end
end

Event.add(defines.events.on_built_entity, on_built)
Event.add(defines.events.on_robot_built_entity, on_built)
