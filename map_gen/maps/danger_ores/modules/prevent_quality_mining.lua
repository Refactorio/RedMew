--[[
  This module prevents all but the normal quality drills from being built on top of resources

  Quality miners (rare-mining-drill, legendary-mining-drill...) do not increase mining speed or radius with quality,
    but have less resource drain on the patch (a legendary mining drill takes a lot more to drain a patch,
    similar to mining productivity)

    Mining quality ores using quality modules inside mining drills is still possible
]]
local Event = require 'utils.event'

local function on_built(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  local e_type = entity.type
  if entity.name == 'entity-ghost' then
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
  entity.destroy()
end

Event.add(defines.events.on_built_entity, on_built)
Event.add(defines.events.on_robot_built_entity, on_built)
