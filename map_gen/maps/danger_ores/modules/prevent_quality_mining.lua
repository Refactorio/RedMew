--[[
  This module prevents all but the normal quality drills from being built on top of resources

  Quality miners (rare-mining-drill, legendary-mining-drill...) do not increase mining speed or radius with quality,
    but have less resource drain on the patch (a legendary mining drill takes a lot more to drain a patch,
    similar to mining productivity)

    Mining quality ores using quality modules inside mining drills is still possible
]]
local Event = require 'utils.event'
local RobotRefund = require 'map_gen.shared.robot_refund'

-- Hands the drill back, at its quality, to whoever built it: the robot's cargo, so it takes it back
-- to storage, or the player. A player with no room gets it dropped where it stood, marked for
-- deconstruction so robots take it back.
local function refund(entity, player, robot)
  local items = entity.prototype.items_to_place_this
  local stack = items and items[1]
  if not stack then
    return
  end
  stack = { name = stack.name, count = stack.count, quality = entity.quality }

  if robot and robot.valid then
    RobotRefund.refund(robot, stack, entity.surface, entity.position, entity.force)
    return
  end
  if player and player.valid and player.can_insert(stack) then
    player.insert(stack)
    return
  end
  entity.surface.spill_item_stack { position = entity.position, stack = stack, enable_looted = true, force = entity.force }
end

local function on_built(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  local e_type = entity.type
  local ghost = entity.name == 'entity-ghost'
  if ghost then
    e_type = entity.ghost_type
  end
  if e_type ~= 'mining-drill' then
    return
  end
  if entity.quality.level < 1 then
    return
  end

  local index = event.player_index
  local player = index and game.get_player(index)
  if player and player.valid then
    player.print('Only [quality=normal] drills can be built on top of resources!')
  end
  if not ghost then
    refund(entity, player, event.robot)
  end
  entity.destroy()
end

Event.add(defines.events.on_built_entity, on_built)
Event.add(defines.events.on_robot_built_entity, on_built)
