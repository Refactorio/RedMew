--local Event = require "utils.event"
local surface = {}

Event.on_init(function()
  surface = game.create_surface("antigrief", {  autoplace_controls = {    coal = {      frequency = "normal",      richness = "normal",      size = "none"    },    ["copper-ore"] = {      frequency = "normal",      richness = "normal",      size = "none"    },    ["crude-oil"] = {      frequency = "normal",      richness = "normal",      size = "none"    },    desert = {      frequency = "normal",      richness = "normal",      size = "none"    },    dirt = {      frequency = "normal",      richness = "normal",      size = "none"    },    ["enemy-base"] = {      frequency = "normal",      richness = "normal",      size = "none"    },    grass = {      frequency = "normal",      richness = "normal",      size = "very-high"    },    ["iron-ore"] = {      frequency = "normal",      richness = "normal",      size = "none"    },    sand = {      frequency = "normal",      richness = "normal",      size = "none"    },    stone = {      frequency = "normal",      richness = "normal",      size = "none"    },    trees = {      frequency = "normal",      richness = "normal",      size = "none"    },    ["uranium-ore"] = {      frequency = "normal",      richness = "normal",      size = "none"    }  },  cliff_settings = {    cliff_elevation_0 = 1024,    cliff_elevation_interval = 10,    name = "cliff"  },  height = 2000000,  peaceful_mode = false,  seed = 3461559752,  starting_area = "very-low",  starting_points = {    {      x = 0,      y = 0    }  },  terrain_segmentation = "normal",  water = "none",  width = 2000000})
  surface.always_day = true
end)

local function place_entity_on_surface(entity, surface, replace, player)
  if entity.surface == surface then return end
  if replace then
    for _,e in pairs(surface.find_entities_filtered{position = entity.position}) do
      e.destroy()
    end
    local new_entity = surface.create_entity{name = entity.name, position = entity.position, force = entity.force, direction = entity.direction}
    if player then
    	new_entity.last_user = player
    end
  else
    if surface.count_entities_filtered{position = entity.position} == 0 then 
      local new_entity = surface.create_entity{name = entity.name, position = entity.position, force = entity.force, direction = entity.direction}
      if player then 
        new_entity.last_user = player
      end
    end  
  end
end

Event.add(defines.events.on_chunk_generated, function(event)
  if event.surface.name == "antigrief" then
    for _,e in pairs(event.surface.find_entities_filtered{area = event.area, force = "neutral"}) do
      if e.type ~= "player" then
        e.destroy()
      end
    end
    local tiles = {}
    for x = event.area.left_top.x, event.area.right_bottom.x do
      for y = event.area.left_top.y, event.area.right_bottom.y do
        table.insert(tiles,{name="lab-dark-2", position = {x,y}})
      end
    end
    event.surface.set_tiles(tiles)
  end
end)

--on_entity_settings_pasted



Event.add(defines.events.on_robot_pre_mined, function(event) 
  if event.entity.force.name == "player" and event.entity.last_user then
    place_entity_on_surface(event.entity, true, surface, event.entity.last_user) 
  end
end)

Event.add(defines.events.on_player_mined_entity, function(event)
  place_entity_on_surface(event.entity, surface, true, event.player_index)
end)

local Module = {}

Module.undo = function(player)
  if type(player) == "nil" or type(player) == "string" then return end --No support for strings!
  if type(player) == "number" then 
    local player = game.players[player]
  end
  for _,e in pairs(surface.find_entities_filtered{}) do
    if e.last_user == player then
      place_entity_on_surface(e, game.surfaces.nauvis, false) 
    end
  end
end

Foo = Module

return Module
