

function allowed_to_nuke(player)
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

    --Make them think they arent noticed
    print_except(player.name .. " tried to deconstruct something, but instead deconstructed himself.", player)
    player.print("Only regulars can mark things for deconstruction.")

    player.character.health = 0
    local entities = player.surface.find_entities_filtered{area = event.area, force = player.force}
    if #entities > 1000 then
      print_admins("Warning! " .. player.name .. " just tried to deconstruct " .. tostring(#entities) .. " entities!")
    end
    for _,entity in pairs(entities) do
      if entity.valid and entity.to_be_deconstructed(game.players[event.player_index].force) then
        entity.cancel_deconstruction(game.players[event.player_index].force)
      end
    end
end

local function log_on_player_mined_entity(str, event)
  game.write_file("on_player_mined_entity_debug", game.tick .. " (" .. game.players[event.player_index].name  .. ") " .. str .. "\n", true, 0)
end

global.on_player_mined_item_enabled = true
global.on_player_mined_item_init = true

local function on_player_mined_item(event)
  log_on_player_mined_entity("nuke_control.on_player_mined_item: entry", event)
  if global.on_player_mined_item_enabled then
    log_on_player_mined_entity("nuke_control.on_player_mined_item: enabled", event)
    if global.on_player_mined_item_init then
      log_on_player_mined_entity("nuke_control.on_player_mined_item: init", event)
      game.forces.enemy.research_all_technologies() --avoids losing logstics slot configuration on force toggle
      global.on_player_mined_item_init = false
    end
    local entity = event.entity
    if entity.valid and entity.force.name ~= "enemy" and entity.force.name ~= "neutral" and entity.name ~= "entity-ghost" and entity.type ~= "logistic-robot" and entity.type ~= "construction-robot" then
      log_on_player_mined_entity("nuke_control.on_player_mined_item: in body", event)
      local entity_name = entity.name
      if entity_name == "pipe-to-ground" then entity_name = "pipe" end
      log_on_player_mined_entity("nuke_control.on_player_mined_item: before ghost placement", event)
      local ghost = event.entity.surface.create_entity{name = "entity-ghost", position = event.entity.position, inner_name = entity_name, expires = false, force = "enemy", direction = event.entity.direction}
      log_on_player_mined_entity("nuke_control.on_player_mined_item: ghost placed", event)
      ghost.last_user = event.player_index
      log_on_player_mined_entity("nuke_control.on_player_mined_item: last user set", event)
    end
  end
  log_on_player_mined_entity("nuke_control.on_player_mined_item: exit", event)
end

local function on_research_finished(event)
  if event.research.name == "artillery" then
    game.print("Griefers are why we can't have nice things. Artillery targeting remote disabled.")
    game.forces.player.recipes["artillery-targeting-remote"].enabled = false
  end
end

Event.register(defines.events.on_player_ammo_inventory_changed, ammo_changed)
Event.register(defines.events.on_player_deconstructed_area, on_player_deconstructed_area)
--Event.register(defines.events.on_player_mined_entity, on_player_mined_item)
Event.register(defines.events.on_research_finished, on_research_finished)
