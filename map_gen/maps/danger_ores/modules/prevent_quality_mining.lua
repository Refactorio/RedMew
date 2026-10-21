--[[
  This module prevents all but the normal quality drills from being built on top of resources

  Quality miners (rare-mining-drill, legendary-mining-drill...) do not increase mining speed or radius with quality,
    but have less resource drain on the patch (a legendary mining drill takes a lot more to drain a patch,
    similar to mining productivity)

    Mining quality ores using quality modules inside mining drills is still possible
]]
local Event = require 'utils.event'

-- The area a drill (or its ghost) mines, which reaches past the drill itself.
local function get_mining_area(entity, ghost)
  if not ghost then
    return entity.mining_area
  end
  local radius = entity.ghost_prototype.get_mining_drill_radius(entity.quality)
  local position = entity.position
  return { { position.x - radius, position.y - radius }, { position.x + radius, position.y + radius } }
end

-- Hands the drill back, at its quality, to the robot or player that built it, or drops it where
-- it stood if they have no room.
local function refund(entity, event)
  local items = entity.prototype.items_to_place_this
  local stack = items and items[1]
  if not stack then
    return
  end
  stack = { name = stack.name, count = stack.count, quality = entity.quality }

  local index = event.player_index
  local actor = event.robot or (index and game.get_player(index))
  if actor and actor.valid and actor.can_insert(stack) then
    actor.insert(stack)
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
  if entity.surface.count_entities_filtered { area = get_mining_area(entity, ghost), type = 'resource', limit = 1 } == 0 then
    return
  end

  local index = event.player_index
  local player = index and game.get_player(index)
  if player and player.valid then
    player.print('Only [quality=normal] drills can be built on top of resources!')
  end
  if not ghost then
    refund(entity, event)
  end
  entity.destroy()
end

Event.add(defines.events.on_built_entity, on_built)
Event.add(defines.events.on_robot_built_entity, on_built)
