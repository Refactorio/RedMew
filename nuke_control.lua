

function allowed_to_nuke(player)
  if type(player) == "table" then
  return player.admin or is_mod(player.name) or is_regular(player.name) or ((player.online_time / 216000) > global.scenario.config.nuke_min_time_hours)
  elseif type(player) == "number" then
    return allowed_to_nuke(game.players[player])
  end
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
    player.print("Only regulars can mark things for deconstruction, if you want to deconstruct something you may ask an admin to promote you.")

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


--Never knew the debug code made it into the codebase lol
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

global.players_warned = {}
local function on_capsule_used(event)
  if event.item.name:find("capsule") then return nil end
  local player = game.players[event.player_index]
  if (not allowed_to_nuke(player)) then
    local area = {{event.position.x-5, event.position.y-5}, {event.position.x+5, event.position.y+5}}
    local count = player.surface.count_entities_filtered{force=player.force, area=area}
    if count > 4 then
      if global.players_warned[event.player_index] then
        game.ban_player(player, string.format("Damaged %i entities with %s. This action was performed automatically. If you want to contest this ban please visit redmew.com/discord.", count, event.item.name))
      else
        game.print("kick")
        global.players_warned[event.player_index] = true
        game.kick_player(player, string.format("Damaged %i entities with %s -Antigrief", count, event.item.name))
      end
    end
  end
end

Event.register(defines.events.on_player_ammo_inventory_changed, ammo_changed)
Event.register(defines.events.on_player_deconstructed_area, on_player_deconstructed_area)
--Event.register(defines.events.on_player_mined_entity, on_player_mined_item)
Event.register(defines.events.on_player_used_capsule, on_capsule_used)

