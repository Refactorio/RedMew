local Thread = require "utils.Thread"
require "utils.event"

function player_print(str)
  if game.player then
    game.player.print(str)
  else
    log(str)
  end
end

function cant_run(name)
    player_print("Can't run command (" .. name .. ") - insufficient permission.")
end

local function invoke(cmd)
    if not game.player or not (game.player.admin or is_mod(game.player.name)) then
        cant_run(cmd.name)
        return
    end
    local target = cmd["parameter"]
    if target == nil or game.players[target] == nil then
        player_print("Unknown player.")
        return
    end
    local pos = game.player.surface.find_non_colliding_position("player", game.player.position, 0, 1)
    game.players[target].teleport({pos.x, pos.y}, game.player.surface)
    game.print(target .. ", get your ass over here!")
end

local function teleport_player(cmd)
    if not game.player or not (game.player.admin or is_mod(game.player.name)) then
        cant_run(cmd.name)
        return
    end
    local target = cmd["parameter"]
    if target == nil or game.players[target] == nil then
        player_print("Unknown player.")
        return
    end
    local surface = game.players[target].surface
    local pos = surface.find_non_colliding_position("player", game.players[target].position, 0, 1)
    game.player.teleport(pos, surface)
    game.print(target .. "! watcha doin'?!")
end

local function teleport_location(cmd)
    if not game.player or not (game.player.admin or is_mod(game.player.name)) then
        cant_run(cmd.name)
        return
    end
    if game.player.selected == nil then
        player_print("Nothing selected.")
        return
    end
    local pos = game.player.surface.find_non_colliding_position("player", game.player.selected.position, 0, 1)
    game.player.teleport(pos)
end

local function kill()
  if game.player and game.player.character then
    game.player.character.die()
  end
end

global.walking = {}
local function walkabout(cmd)
  if not ((not game.player) or game.player.admin or is_mod(game.player.name)) then
      cant_run(cmd.name)
      return
  end
  local params = {}
  if cmd.parameter == nil then
    player_print("Walkabout failed.")
    return
  end
  for param in string.gmatch(cmd.parameter, "%S+") do table.insert(params, param) end
  local player_name = params[1]
  local duration = 60
  if #params > 2 then
    player_print("Walkabout failed, check /help walkabout.")
    return
  elseif #params == 2 and tonumber(params[2]) == nil then
    player_print(params[2] .. " is not a number.")
    return
  elseif #params == 2 and tonumber(params[2]) then
    duration = tonumber(params[2])
  end
  if duration < 15 then duration = 15 end

  local player = game.players[player_name]
  if player == nil or global.walking[player_name:lower()] then
    player_print(player_name .. " could not go on a walkabout.")
    return
  end

  local chunks = {}
  for chunk in player.surface.get_chunks() do 
    table.insert(chunks, chunk)
  end

  local chunk = chunks[math.random(#chunks)]
  if not chunk then
    return
  end
  local pos = {x=chunk.x * 32, y=chunk.y * 32}  
  local non_colliding_pos = player.surface.find_non_colliding_position("player", pos, 100, 1)
  
  if non_colliding_pos then
    game.print(player_name .. " went on a walkabout, to find himself.")
    Thread.set_timeout(duration, return_player, {player = player, force = player.force, position = {x = player.position.x, y = player.position.y}})
    player.character = nil
    player.create_character()
    player.teleport(non_colliding_pos)
    player.force = "enemy"
    global.walking[player_name:lower()] = true
  else 
    player_print("Walkabout failed: count find non colliding position")
  end
end

local function return_player(args)
  global.walking[args.player.name:lower()] = false
  args.player.character.destroy()
  local character = args.player.surface.find_entity('player', args.position)
  if character ~= nil and character.valid then
    args.player.character = character
  else
    args.player.create_character()
  end
  args.player.force = args.force
  args.player.teleport(args.position)
  game.print(args.player.name .. " came back from his walkabout.")
end

local function regular(cmd)
  if not ((not game.player) or game.player.admin or is_mod(game.player.name)) then
      cant_run(cmd.name)
      return
  end

  if cmd.parameter == nil then
    player_print("Command failed. Usage: /regular <promote, demote>, <player>")
    return
  end
  local params = {}
  for param in string.gmatch(cmd.parameter, "%S+") do table.insert(params, param) end
  if params[2] == nil then
    player_print("Command failed. Usage: /regular <promote, demote>, <player>")
    return
  elseif (params[1] == "promote") then
    add_regular(params[2])
  elseif (params[1] == "demote") then
    remove_regular(params[2])
  else
      player_print("Command failed. Usage: /regular <promote, demote>, <player>")
  end
end

local function mod(cmd)
  if game.player and not game.player.admin then
      cant_run(cmd.name)
      return
  end

  if cmd.parameter == nil then
    player_print("Command failed. Usage: /mod <promote, demote>, <player>")
    return
  end
  local params = {}
  for param in string.gmatch(cmd.parameter, "%S+") do table.insert(params, param) end
  if params[2] == nil then
    player_print("Command failed. Usage: /mod <promote, demote>, <player>")
    return
  elseif (params[1] == "promote") then
    add_mod(params[2])
  elseif (params[1] == "demote") then
    remove_mod(params[2])
  else
      player_print("Command failed. Usage: /mod <promote, demote>, <player>")
  end
end

local function afk()
  for _,v in pairs (game.players) do
    if v.afk_time > 300 then
      local time = " "
      if v.afk_time > 21600 then
        time = time .. math.floor(v.afk_time / 216000) .. " hours "
      end
      if v.afk_time > 3600 then
        time = time .. math.floor(v.afk_time / 3600) % 60 .. " minutes and "
      end
      time = time .. math.floor(v.afk_time / 60) % 60 .. " seconds."
      player_print(v.name .. " has been afk for" .. time)
    end
  end
end

local function tag(cmd)
  if game.player and not game.player.admin then
      cant_run(cmd.name)
      return
  end
  if cmd.parameter ~= nil then
    local params = {}
    for param in string.gmatch(cmd.parameter, "%S+") do table.insert(params, param) end
    if #params < 2 then
      player_print("Usage: <player> <tag> Sets a players tag.")
    elseif game.players[params[1]] == nil then
      player_print("Player does not exist.")
    else
      local tag = string.sub(cmd.parameter, params[1]:len() + 2)
      game.players[params[1]].tag = "[" .. tag .. "]"
      game.print(params[1] .. " joined [" .. tag .. "].")
    end
  else
   player_print('Usage: /tag <player> <tag> Sets a players tag.')
  end
end

local function follow(cmd)
  if not game.player then
    log("<Server can't do that.")
    return
  end
  if cmd.parameter ~= nil and game.players[cmd.parameter] ~= nil then
    global.follows[game.player.name] = cmd.parameter
    global.follows.n_entries = global.follows.n_entries + 1
  else
    player_print("Usage: /follow <player> makes you follow the player. Use /unfollow to stop following a player.")
  end
end

local function unfollow(cmd)
  if not game.player then
    log("<Server can't do that.")
    return
  end
  if global.follows[game.player.name] ~= nil then
    global.follows[game.player.name] = nil
    global.follows.n_entries = global.follows.n_entries - 1
  end
end

global.tp_players = {}
local function built_entity(event)
  local index = event.player_index

  if global.tp_players[index] then
    local entity = event.created_entity

    if entity.type ~= "entity-ghost" then return end

    game.players[index].teleport(entity.position)
    entity.destroy()
  end
end

Event.register(defines.events.on_built_entity, built_entity)

local function toggle_tp_mode(cmd)
  if not game.player or not (game.player.admin or is_mod(game.player.name)) then
    cant_run(cmd.name)
    return
  end

  local index = game.player.index
  local toggled = global.tp_players[index]

  if toggled then
    global.tp_players[index] = nil
    player_print("tp mode is now off")
  else
    global.tp_players[index] = true
    player_print("tp mode is now on - place a ghost entity to teleport there.")
  end
end

global.old_force = {}
global.force_toggle_init = true
local function forcetoggle(cmd)
   if not game.player or not (game.player.admin or is_mod(game.player.name)) then
      cant_run(cmd.name)
      return
   end

   if global.force_toggle_init then
      game.forces.enemy.research_all_technologies() --avoids losing logstics slot configuration
      global.force_toggle_init = false
   end

   -- save the logistics slots
   local slots = {}
   local slot_counts = game.player.character.request_slot_count
   if  game.player.character.request_slot_count > 0 then
      for i = 1, slot_counts do
         slot = game.player.character.get_request_slot(i)
         if slot ~= nil then
            table.insert(slots, slot)
         end
      end
   end

   if game.player.force.name == "enemy" then
      local old_force = global.old_force[game.player.name]
      if not old_force then
         game.player.force = "player"
         game.player.print("You're are now on the player force.")
      else
         if game.forces[old_force] then
            game.player.force = old_force
         else
            game.player.force = "player"
         end
      end
   else
      --Put roboports into inventory
      inv = game.player.get_inventory(defines.inventory.player_armor)
      if inv[1].valid_for_read
      then
         local name = inv[1].name
         if name:match("power") or name:match("modular") then
            local equips = inv[1].grid.equipment
            for _,equip in pairs(equips) do
               if equip.name == "personal-roboport-equipment"
               or equip.name == "personal-roboport-mk2-equipment"
               or equip.name == "personal-laser-defense-equipment" then
                  if game.player.insert{name = equip.name} == 0 then
                     game.player.surface.spill_item_stack(game.player.position, {name = equip.name})
                  end
                  inv[1].grid.take(equip)
               end
            end
         end
      end

      global.old_force[game.player.name] = game.player.force.name
      game.player.force = "enemy"
   end
   game.player.print("You are now on the " .. game.player.force.name .. " force.")

   -- Attempt to rebuild the request slots
   slot_counts = game.player.character.request_slot_count
   if game.player.character.request_slot_count > 0 then
      for _,slot in ipairs(slots) do
         game.player.character.set_request_slot(slot, _)
      end
   end
end

local function get_group()
  local group = game.permissions.get_group("Banned")
  if not group then
    game.permissions.create_group("Banned")
    group = game.permissions.get_group("Banned")
    if group then
    	for i=2,174 do
      	    group.set_allows_action(i, false)
        end
    else
      game.print("This would have nearly crashed the server, please consult the next best scenario dev (valansch or TWLtriston).")
    end
  end
  return group
end

local function tempban(cmd)
  if (not game.player) or not (game.player.admin or is_mod(game.player.name)) then
    cant_run(cmd.name)
    return
  end
  if cmd.parameter == nil then
      player_print("Tempban failed. Usage: /tempban <player> <minutes> Temporarily bans a player.")
      return
    end
  local params = {}
  for param in string.gmatch(cmd.parameter, "%S+") do table.insert(params, param) end
  if #params < 2 or not tonumber(params[2]) then
    player_print("Tempban failed. Usage: /tempban <player> <minutes> Temporarily bans a player.")
    return
  end
  if not game.players[params[1]] then
    player_print("Player doesn't exist.")
    return
  end
  local group = get_group()
  game.print(get_actor() .. " put " .. params[1] .. " in timeout for " .. params[2] .. " minutes.")
  if group then
    group.add_player(params[1])
    if not tonumber(cmd.parameter) then
      Thread.set_timeout(
        60 * tonumber(params[2]),
        function(param)
          game.print(param.name .. " is out of timeout.")
          game.permissions.get_group("Default").add_player(param.name)
        end,
        {name = params[1]}
      )
    end
  end
end


function custom_commands_replace_ghosts(param)
  for _,ghost in pairs(param.ghosts) do
    local new_ghost = game.surfaces[param.surface_index].create_entity{name = "entity-ghost", position = ghost.position, inner_name = ghost.ghost_name, expires = false, force = "enemy", direction = ghost.direction}
    new_ghost.last_user = ghost.last_user
  end
end

local function spyshot(cmd)
  if not cmd then return 0 end
  local player_name = cmd.parameter
  if player_name and game.players[player_name] then
    for _,spy in pairs(global.spys) do
      if game.players[spy] and game.players[spy].connected then
        local pos = game.players[player_name].position
        pseudo_ghosts = {}
        for _,ghost in pairs(game.players[player_name].surface.find_entities_filtered{area = {{pos.x - 60, pos.y - 35},{pos.x + 60, pos.y + 35}},name = "entity-ghost", force = enemy}) do
          local pseudo_ghost = {position = ghost.position, ghost_name = ghost.ghost_name, expires = false, force = "enemy", direction = ghost.direction, last_user = ghost.last_user}
          table.insert(pseudo_ghosts, pseudo_ghost)
          ghost.destroy()
        end
        game.take_screenshot{by_player = spy, position = pos, show_gui = false, show_entity_info = true, resolution = {1920, 1080}, anti_alias = true, zoom = 0.5, path ="spyshot.png"}
        game.players[spy].print("You just took a screenshot!")
        Thread.set_timeout(2, custom_commands_replace_ghosts, {ghosts = pseudo_ghosts, surface_index = game.players[player_name].surface.index}) --delay replacements for the screenshot to render
        return
      end
    end
    player_print("No spy online!")
  end
end

local function zoom(cmd)
  if game.player and cmd and cmd.parameter and tonumber(cmd.parameter) then
    game.player.zoom = tonumber(cmd.parameter)
  end
end

commands.add_command("kill", "Will kill you.", kill)
commands.add_command("tpplayer", "<player> - Teleports you to the player. (Admins and moderators)", teleport_player)
commands.add_command("invoke", "<player> - Teleports the player to you. (Admins and moderators)", invoke)
commands.add_command("tppos", "Teleports you to a selected entity. (Admins only)", teleport_location)
commands.add_command("walkabout", '<player> <"close", "far", "very far", number> <duration> - Send someone on a walk.  (Admins and moderators)', walkabout)
commands.add_command("market", 'Places a fish market near you.  (Admins only)', spawn_market)
commands.add_command("regulars", 'Prints a list of game regulars.', print_regulars)
commands.add_command("regular", '<promote, demote>, <player> Change regular status of a player. (Admins and moderators)', regular)
commands.add_command("mods", 'Prints a list of game mods.', print_mods)
commands.add_command("mod", '<promote, demote>, <player> Changes moderator status of a player. (Admins only)', mod)
commands.add_command("afk", 'Shows how long players have been afk.', afk)
commands.add_command("tag", '<player> <tag> Sets a players tag. (Admins only)', tag)
commands.add_command("follow", '<player> makes you follow the player. Use /unfollow to stop following a player.', follow)
commands.add_command("unfollow", 'stops following a player.', unfollow)
commands.add_command("well", '<item> <items per second> Spawns an item well. (Admins only)', well_command)
commands.add_command("tpmode", "Toggles tp mode. When on place a ghost entity to teleport there (Admins and moderators)", toggle_tp_mode)
commands.add_command("forcetoggle", "Toggles the players force between player and enemy (Admins and moderators)", forcetoggle)
commands.add_command("tempban", "<player> <minutes> Temporarily bans a player (Admins and moderators)", tempban)
commands.add_command("spyshot", "<player> Sends a screenshot of player to discord. (If a host is online. If no host is online, you can become one yourself. Ask on discord :))", spyshot)
commands.add_command("zoom", "<number> Sets your zoom.", zoom)
