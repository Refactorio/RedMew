local Thread = require "locale.utils.Thread"

local mines_factor = 4


--Do not change this:
mines_factor = 16384 / mines_factor
function spawn_row(params)
  local x = params.x
  local y = params.y
  local magic_number = math.floor(mines_factor / params.distance) + 1
  for i = 0, 31 do
    if math.random(1, magic_number) == 1 then
      game.surfaces[1].create_entity{name = "land-mine", position = {x + i,y}, force = "enemy"}
    end
  end
end

function run_terrain_module(event)
  local distance = math.sqrt(event.area.left_top.x*event.area.left_top.x+event.area.left_top.y*event.area.left_top.y)
  if distance > 100 then
    for i = 0, 31 do
      Thread.queue_action("spawn_row", {x = event.area.left_top.x, y = event.area.left_top.y + i, distance = distance})
    end
  end
end
