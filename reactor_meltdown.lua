--Reactors melt down if:
--temperature is at 1000°C and health is 0 or reactor is picked up
--
--a reactors loses 2 damage per second at 1000°C

local Event = require "utils.event"

global.wastelands = {}
global.reactors = {}
local wasteland_duration_seconds = 300

local function entity_destroyed(event)
  if event.entity.name == "nuclear-reactor" then
    local reactor = event.entity
    if event.entity.temperature > 700 then
      reactor.surface.create_entity{name="atomic-rocket", position=reactor.position, target=reactor, speed=1}
      spawn_wasteland(reactor.surface, reactor.position)
      global.wastelands[reactor.position.x .. "/" .. reactor.position.y] = {position = reactor.position, surface_id = reactor.surface.index, creation_time = game.tick}
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

local function alert(reactor)
  for _,p in pairs(game.players) do
    p.add_custom_alert(reactor, {type="item", name="nuclear-reactor"}, string.format("Reactor at %s°C", math.floor(reactor.temperature)), true)
  end
end

local function check_reactors()
  for _,surface in pairs(game.surfaces) do
    for i,reactor in pairs(global.reactors) do
      if reactor.valid then
        if reactor.temperature > 800 then
          alert(reactor)
        end
        if reactor.temperature == 1000 then
          reactor.force = "enemy"
          reactor.destructible = false
          reactor.health = 0
          reactor.surface.create_entity{name="atomic-rocket", position=reactor.position, target=reactor, speed=1}
          spawn_wasteland(reactor.surface, reactor.position)
          global.wastelands[reactor.position.x .. "/" .. reactor.position.y] = {position = reactor.position, surface_id = reactor.surface.index, creation_time = game.tick}
          table.remove(global.reactors, i)
        else
          reactor.health = 500 - (reactor.temperature - 800) * 2.5
        end
      else
        table.remove(global.reactors, i)
      end
    end
    global.last_reactor_warning = last_reactor_warning
  end
end

local function check_wastelands()
  for index,wl in pairs(global.wastelands) do
    local age = game.tick - wl.creation_time
    wl.last_checked = wl.last_checked or 0
    if (game.tick - wl.last_checked) > 899 then
      wl.last_checked = game.tick
      spawn_wasteland(game.surfaces[wl.surface_id], wl.position)
      if age > wasteland_duration_seconds * 60 - 1 then
        global.wastelands[index] = nil
        reactors = game.surfaces[wl.surface_id].find_entities_filtered{position = wl.position, name = "nuclear-reactor"}
        if reactors[1] then reactors[1].destroy() end
      end
    end
  end
end

global.reactors_enabled = true
local function on_tick()
  if global.reactors_enabled then
    check_wastelands()
    check_reactors()
  end
end

local function entity_build(event)
  if event.created_entity.valid and event.created_entity.name == "nuclear-reactor" then
    table.insert(global.reactors, event.created_entity)
  end
end

Event.on_nth_tick(60, on_tick)
Event.add(defines.events.on_player_mined_entity, entity_destroyed)
Event.add(defines.events.on_robot_mined_entity, entity_destroyed)
Event.add(defines.events.on_entity_died, entity_destroyed)
Event.add(defines.events.on_built_entity, entity_build)
Event.add(defines.events.on_robot_built_entity, entity_build)
