--Reactors melt down if:
--temperature is above 700°C and health is 0 or they are picked up
--
--a reactors loses (T - 800) * 1 damage per second

global.wastelands = {}
global.last_reactor_warning = 0
local wasteland_duration_seconds = 300

local function damage_per_second(T)
  return (T - 800) * 1
end



local function entity_destroyed(event)
  if event.entity.name == "nuclear-reactor" then
    if event.entity.temperature > 700 then
      event.entity.surface.create_entity{name="atomic-rocket", position=event.entity.position, target=event.entity, speed=1}
    end
  end
end

function spawn_wasteland(surface, position)
    local positions = { 
      {0, 0},
      {0, 12},
      {0, -12},
      {12, 0},
      {-12, 0},
      {-8.5, 8.5},
      {-8.5, -8.5},
      {8.5, -8.5},
      {8.5, 8.5},
      {4, 4},
      {-4, 4},
      {-4, -4},
      {4, -4},
      {13, 7.5},
      {-13, 7.5},
      {-13, -7.5},
      {13, -7.5},
      {7.5, 13},
      {-7.5, 13},
      {-7.5, -13},
      {7.5, -13},
      {0,15},
      {-15,0},
      {15,0},
      {0,-15}
    }
    for _,rel_position in pairs(positions) do
      surface.create_entity{name="poison-capsule", position=position, target={position.x + rel_position[1], position.y + rel_position[2]}, speed=0.4}
    end

end

local function check_reactors()
  for _,surface in pairs(game.surfaces) do
    local last_reactor_warning = global.last_reactor_warning
    for _,reactor in pairs(surface.find_entities_filtered{name = "nuclear-reactor"}) do
     if reactor.temperature > 500 and game.tick - global.last_reactor_warning > 600 then
        game.print(string.format("Warning! Reactor at %s°C", reactor.temperature))
        last_reactor_warning = game.tick
     end
     if reactor.temperature > 800 then
        reactor.health = reactor.health - damage_per_second(reactor.temperature)
        if reactor.health == 0 and (not global.wastelands[reactor.position.x .. "/" .. reactor.position.y]) then
          reactor.surface.create_entity{name="atomic-rocket", position=reactor.position, target=reactor, speed=1}
          spawn_wasteland(reactor.surface, reactor.position)
          global.wastelands[reactor.position.x .. "/" .. reactor.position.y] = {position = reactor.position, surface_id = reactor.surface.index, creation_time = game.tick}
        end
      end
    end
    global.last_reactor_warning = last_reactor_warning
  end
end

local function check_wastelands()
  for index,wl in pairs(global.wastelands) do
    local age = game.tick - wl.creation_time
    if age % 900 == 0 then 
      spawn_wasteland(game.surfaces[wl.surface_id], wl.position)
      if age > wasteland_duration_seconds * 60 - 1 then 
        global.wastelands[index] = nil
        reactors = game.surfaces[wl.surface_id].find_entities_filtered{position = wl.position, name = "nuclear-reactor"}
        if reactors[1] then reactors[1].destroy() end
      end
    end
  end
end

local function on_tick()
  if (game.tick + 7) % 60 == 0 then 
    check_wastelands()
    check_reactors()
  end
end

Event.register(defines.events.on_tick, on_tick)
Event.register(defines.events.on_player_mined_entity, entity_destroyed)
Event.register(defines.events.on_robot_mined_entity, entity_destroyed)
Event.register(defines.events.on_entity_died, entity_destroyed)
