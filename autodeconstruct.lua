--Author: Valansch
local function is_depleted(drill)
  local position = drill.position
  local area = {}
  if drill.name == "electric-mining-drill" then
    area = {{position.x - 2, position.y - 2},{position.x + 2, position.y + 2}}
  else
    area = {{position.x - 1, position.y - 1},{position.x + 1, position.y + 1}}
  end
  local count = -1
  for _,resource in pairs(drill.surface.find_entities_filtered{type="resource", area = area}) do
    if resource.name ~= "crude-oil" then
      count = count + 1
    end
  end
  return count == 0
end

local function mark_if_depleted(drill)
  if is_depleted(drill) then
    drill.order_deconstruction(drill.force)
  end
end

local function on_resource_depleted(event)
  if event.entity.name == "uranium-ore" then return nil end
  local area = {{event.entity.position.x-1, event.entity.position.y-1}, {event.entity.position.x+1, event.entity.position.y + 1}}
  local drills = event.entity.surface.find_entities_filtered{area = area, type="mining-drill"}
  for _,drill in pairs(drills) do
    if drill.name ~= "pumpjack" then
      mark_if_depleted(drill)
    end
  end
end

Event.register(defines.events.on_resource_depleted, on_resource_depleted)
