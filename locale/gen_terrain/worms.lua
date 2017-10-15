local Thread = require "locale.utils.Thread"

local worms_per_chunk = 50
local small_worm_spawn_distance = 100
local medium_worm_spawn_distance = 150
local big_worm_spawn_distance = 200


worm_names = {"small-worm-turret","medium-worm-turret","big-worm-turret"}
function spawn_worm(params)
  local x = params.x
  local y = params.y
  local lvl = params.lvl
  local worm_id = math.random(1, lvl)
  if game.surfaces[1].can_place_entity{name = worm_names[worm_id], position = {x,y}} then
    if math.sqrt(x*x+y*y) > small_worm_spawn_distance then
      game.surfaces[1].create_entity{name = worm_names[worm_id], position = {x,y}}
    end
  end
end


function run_terrain_module(event)
  local top_left = event.area.left_top
  local distance = math.sqrt(top_left.x*top_left.x+top_left.y*top_left.y)
  if distance > small_worm_spawn_distance - 32 then
    local lvl = 1
    if distance > medium_worm_spawn_distance then lvl = 2 end
    if distance > big_worm_spawn_distance then lvl = 3 end
    for i = 1, worms_per_chunk do
      Thread.queue_action("spawn_worm", {x = top_left.x + math.random(0, 31), y = top_left.y + math.random(0, 31), lvl = lvl})
    end
  end
end
