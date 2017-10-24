--Author: Valansch

local resource_types = {"copper-ore", "iron-ore", "coal", "stone", "uranium-ore", "crude-oil"}

global.portals = {}
--Exmaple Portal:
--{entity : LuaEntity, target_surface : LuaSurfaces}

--Creates autoplace_controls with only one resource type enabled
local function create_resource_setting(resource)
  local settings = game.surfaces[1].map_gen_settings
  for _,type in pairs(resource_types) do
    settings.autoplace_controls[type] = {frequency = "none", size = "none", richness = "none"}
  end
  settings.autoplace_controls[resource] = {frequency = "normal", size = "big", richness = "good"}
  return settings
end
local function init()
  if not game.surfaces[2] then
    for _,type in pairs(resource_types) do
      game.create_surface(type, create_resource_setting(type))
    end
  end
end

function run_combined_module(event)
  init()
end

local function teleport_nearby_players(position, surface, target)
  for _,player in pairs(game.players) do
    if player.connected then
      if player.surface.name == surface.name and distance(position, player.position) < 2 then
        player.teleport(position, target)
      end
    end
  end
end

local function dim_on_tick(event)
  if event.tick % 10 == 0 then
    for _,portal in pairs(global.portals) do
      local network = portal.entity.get_circuit_network(defines.wire_type.green)
      if network then
        if network.get_signal{type="virtual", name="signal-G"} > 0 then
          teleport_nearby_players({x = portal.entity.position.x + 2.5, y = portal.entity.position.y + 2.5}, portal.entity.surface, portal.target_surface)
        end
      end
    end
  end
end

Event.register(defines.events.on_tick, dim_on_tick)
