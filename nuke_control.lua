

local function allowed_to_nuke(player)
  return player.admin or is_mod(player.name) or is_regular(player.name) or ((player.online_time / 216000) > global.scenario.config.nuke_min_time_hours)
end


local function ammo_changed(event)
  local player = game.players[event.player_index]
    if allowed_to_nuke(player) then return end
  local nukes = player.remove_item({name="atomic-bomb", count=1000})
  if nukes > 0 then
    game.print(player.name .. " tried to use a nuke, but instead dropped it on his foot.")
    player.character.health = 0
  end
end


local function on_player_deconstructed_area(event)
  local player = game.players[event.player_index]
    if allowed_to_nuke(player) then return end
    local nukes = player.remove_item({name="deconstruction-planner", count=1000})
    game.print(player.name .. " tried to deconstruct something, but instead deconstructed himself.")
    player.character.health = 0
    for _,entity in pairs(game.players[event.player_index].surface.find_entities_filtered{area = event.area}) do
      if entity.to_be_deconstructed(game.players[event.player_index].force) then
        entity.cancel_deconstruction(game.players[event.player_index].force)
      end
    end
end

local init = true
local function on_player_mined_item(event)
  if init then
    game.forces.enemy.research_all_technologies() --avoids losing logstics slot configuration on force toggle
    init = false
  end
  if event.entity.force.name ~= "enemy" and event.entity.force.name ~= "neutral" and event.entity.name ~= "entity-ghost" then
    local entity_name = event.entity.name
    if entity_name == "pipe-to-ground" then entity_name = "pipe" end
    local ghost = game.surfaces[1].create_entity{name = "entity-ghost", position = event.entity.position, inner_name = entity_name, expires = false, force = "enemy", direction = event.entity.direction}
    ghost.last_user = event.player_index
  end
end

Event.register(defines.events.on_player_ammo_inventory_changed, ammo_changed)
Event.register(defines.events.on_player_deconstructed_area, on_player_deconstructed_area)
--Event.register(defines.events.on_player_mined_entity, on_player_mined_item)
