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

local death_messages = {"Went exploring, and didn't bring a minesweeping kit.","Wandered off, and found that it really is dangerous to go alone.","Found that minesweeper in factorio gives no hints.","And they were only one day away from retirement","Is too old for this s$%t","Ponders the question, 'How might I avoid mines in the future'","Exploded with rage","Thought it was clear, found it was not.","Thought it was clear, was wrong.","Paved the way for expansion!","Sacrificed their body to the greater factory expansion","No longer wonders why nobody else has built here","Just wants to watch the respawn timer window","Like life, mines are unfair, next time bring a helmet","Should’ve thrown a grenade before stepping over there","Is farming the death counter","Fertilized the soil","Found no man's land, also found it applies to them.","Curses the map maker","does not look forward to the death march back to retreive items","Wont be going for a walk again","Really wants a map.",  "Forgot his xray goggles","Rather Forgot to bring x-ray goggles","Learned that the biters defend their territory","Mines 1, Ninja skills 0."}

local function player_died()
  game.print(death_messages[math.random(1, #death_messages)])
end
Event.register(defines.events.on_player_died, player_died)
