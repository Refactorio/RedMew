local Event = require "utils.event"


Event.on_init(function()
  global.ag_surface=game.create_surface("antigrief",{autoplace_controls={coal={frequency="normal",richness="normal",size="none"},["copper-ore"]={frequency="normal",richness="normal",size="none"},["crude-oil"]={frequency="normal",richness="normal",size="none"},desert={frequency="normal",richness="normal",size="none"},dirt={frequency="normal",richness="normal",size="none"},["enemy-base"]={frequency="normal",richness="normal",size="none"},grass={frequency="normal",richness="normal",size="very-high"},["iron-ore"]={frequency="normal",richness="normal",size="none"},sand={frequency="normal",richness="normal",size="none"},stone={frequency="normal",richness="normal",size="none"},trees={frequency="normal",richness="normal",size="none"},["uranium-ore"]={frequency="normal",richness="normal",size="none"}},cliff_settings={cliff_elevation_0=1024,cliff_elevation_interval=10,name="cliff"},height=2000000,peaceful_mode=false,seed=3461559752,starting_area="very-low",starting_points={{x=0,y=0}},terrain_segmentation="normal",water="none",width=2000000})
  global.ag_surface.always_day = true

end)


local function place_entity_on_surface(entity, surface, replace, player)
  local new_entity = nil
  for _,e in pairs(surface.find_entities_filtered{position = entity.position}) do
    if replace or e.type == "entity-ghost" then
      e.destroy()
    end
  end
  if (replace or surface.count_entities_filtered{position = entity.position} == 0) then
    new_entity = surface.create_entity{name = entity.name, position = entity.position, force = entity.force, direction = entity.direction}
    if player and new_entity then
      new_entity.last_user = player
    end
  end
  return new_entity
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

Event.add(defines.events.on_robot_pre_mined, function(event)
  if event.entity.force.name == "player" and event.entity.last_user then
    place_entity_on_surface(event.entity, global.ag_surface, true, event.entity.last_user)
  end
end)

Event.add(defines.events.on_entity_died, function(event)
  --is a player on the same force as the destroyed object
  if event.entity and event.entity.force.name == "player" and event.cause and
    event.cause.force == event.entity.force and event.cause.type == "player" then
      local new_entity = place_entity_on_surface(event.entity, global.ag_surface, true, event.cause.player)
      if new_entity and event.entity.type == "container" then
        local items = event.entity.get_inventory(defines.inventory.chest).get_contents()
        if items then
          for item, n in pairs(items) do
            new_entity.insert{name = item, count = n}
          end
        end
      end
  end
end)
Event.add(defines.events.on_player_mined_entity, function(event)
  place_entity_on_surface(event.entity, global.ag_surface, true, event.player_index)
end)

local Module = {}

Module.undo = function(player)
  local player = player
  if type(player) == "nil" or type(player) == "string" then return --No support for strings!
  elseif type(player) == "number" then player = game.players[player] end
  for _,e in pairs(global.ag_surface.find_entities_filtered{}) do
    if e.last_user == player then
      --Place removed entity IF no collision is detected
      local new_entity = place_entity_on_surface(e, game.surfaces.nauvis, false)
      --Transfere items
      if new_entity and e.type == "container" then
        local items = e.get_inventory(defines.inventory.chest).get_contents()
        if items then
          for item, n in pairs(items) do
            new_entity.insert{name = item, count = n}
          end
        end
      end
    end
  end

  --Remove all items from all surfaces that player placed an entity
  for _,surface in pairs(game.surfaces) do
    for _,e in pairs(global.ag_surface.find_entities_filtered{force = player.force}) do
      if e.last_user == player then
        e.destroy()
      end
    end
  end
end

Module.antigrief_surface_tp = function()
  if game.player then
    if game.player.surface == global.ag_surface then
      game.player.teleport(game.player.position, game.surfaces.nauvis)
    else
      game.player.teleport(game.player.position, global.ag_surface)
    end
  end
end

return Module
