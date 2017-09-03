local Thread = require "locale.utils.Thread"
require "locale/utils/event"

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

function invoke(cmd)
    if not game.player or not (game.player.admin or is_mod(game.player.name)) then
        cant_run(cmd.name)
        return
    end
    local target = cmd["parameter"]
    if target == nil or game.players[target] == nil then
        player_print("Unknown player.")
        return
    end
    local pos = game.surfaces[1].find_non_colliding_position("player", game.player.position, 0, 1)
    game.players[target].teleport({pos.x, pos.y})
    game.print(target .. ", get your ass over here!")
end

function teleport_player(cmd)
    if not game.player or not (game.player.admin or is_mod(game.player.name)) then
        cant_run(cmd.name)
        return
    end
    local target = cmd["parameter"]
    if target == nil or game.players[target] == nil then
        player_print("Unknown player.")
        return
    end
    local pos = game.surfaces[1].find_non_colliding_position("player", game.players[target].position, 0, 1)
    game.player.teleport({pos.x, pos.y})
    game.print(target .. "! watcha doin'?!")
end

function teleport_location(cmd)
    if not game.player or not (game.player.admin or is_mod(game.player.name)) then
        cant_run(cmd.name)
        return
    end
    if game.player.selected == nil then
        player_print("Nothing selected.")
        return
    end
    local pos = game.surfaces[1].find_non_colliding_position("player", game.player.selected.position, 0, 1)
    game.player.teleport({pos.x, pos.y})
end

local function detrain(param)
    if game.player and not (game.player.admin or is_mod(game.player.name)) then
        cant_run(param.name)
        return
    end
    local player_name = param["parameter"]
    if player_name == nil or game.players[player_name] == nil then player_print("Unknown player.") return end
    if game.players[player_name].vehicle == nil then player_print("Player not in vehicle.") return end
    game.players[player_name].vehicle.passenger = game.player
		local player = game.player or {name = "<server>"}
    game.print(string.format("%s kicked %s off the train. God damn!", player.name, player_name))
end


function kill()
  if game.player then
    game.player.character.die()
  end
end

global.walking = {}
function walkabout(cmd)
  if not ((not game.player) or game.player.admin or is_mod(game.player.name)) then
      cant_run(cmd.name)
      return
  end
  local params = {}
  if cmd.parameter == nil then
      game.print("Walkabout failed.")
      return
    end
  for param in string.gmatch(cmd.parameter, "%w+") do table.insert(params, param) end
  local player_name = params[1]
  local distance = ""
  local duration = 60
  if #params == 2  then
    distance = params[2]
  elseif #params == 3 then
    distance = params[2] .. " " .. params[3]
    if distance ~= "very far" then
      distance = params[2]
      if tonumber(params[3]) == nil then
        player_print(params[3] .. " is not a number.")
        return
      else
        duration = tonumber(params[3])
      end
    end
  elseif #params == 4 then
    distance = params[2] .. " " .. params[3]
    if tonumber(params[4]) == nil then
      player_print(params[4] .. " is not a number.")
      return
    else
      duration = tonumber(params[4])
    end
  end
  if duration < 15 then duration = 15 end
  if distance == nil or distance == "" then
    distance = math.random(5000, 10000)
  end

  if tonumber(distance) ~= nil then
  elseif distance == "close" then
    distance = math.random(3000, 7000)
  elseif distance == "far" then
    distance = math.random(7000, 11000)
  elseif distance == "very far" then
    distance = math.random(11000, 15000)
  else
    game.print("Walkabout failed.")
    return
  end

  local x = 1
  local y = 1
  local player = game.players[player_name]
  if player == nil or global.walking[player_name:lower()] then
    player_print(player_name .. " could not go on a walkabout.")
    return
  end
  global.walking[player_name:lower()] = true
  local surface = game.surfaces[1]
  local distance_max = distance * 1.05
  local distance_min = distance * 0.95
  distance_max = round(distance_max, 0)
  distance_min = round(distance_min, 0)

  x = math.random(distance_min, distance_max)
  if 1 == math.random(1, 2) then
    x = x * -1
  end
  y = math.random(distance_min, distance_max)
  if 1 == math.random(1, 2) then
    y = y * -1
  end
  if 1 == math.random(1, 2) then
    z = distance_max * -1
    x = math.random(z, distance_max)
  else
    z = distance_max * -1
    y = math.random(z, distance_max)
  end

  local pos = {x, y}
  game.print(player_name .. " went on a walkabout, to find himself.")
  Thread.set_timeout(duration, return_player, {player = player, force = player.force, position = {x = player.position.x, y = player.position.y}})
  player.character = nil
  player.create_character()
  player.teleport(player.surface.find_non_colliding_position("player", pos, 100, 1))
  player.force = "enemy"
end

function return_player(args)
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

function on_set_time(cmd)
  if not ((not game.player) or game.player.admin or is_regular(game.player.name) or is_mod(game.player.name)) then
      cant_run(cmd.name)
      return
  end

  local params = {}
  local params_numeric = {}

  if cmd.parameter == nil then
    player_print("Setting clock failed. Usage: /settime <day> <month> <hour> <minute>")
    return
  end

  for param in string.gmatch(cmd.parameter, "%w+") do table.insert(params, param) end

  if params[4] == nil then
    player_print("Setting clock failed. Usage: /settime <day> <month> <hour> <minute>")
    return
  end

  for _, param in pairs(params) do
    if tonumber(param) == nil then
      player_print("Don't be stupid.")
      return
    end
    table.insert(params_numeric, tonumber(param))
  end
  if (params_numeric[2] > 12)  or (params_numeric[2] < 1)  or (params_numeric[1] > 31)  or (params_numeric[1] < 1) or (params_numeric[2] % 2 == 0 and params_numeric[1] > 30) or (params_numeric[3] > 24) or (params_numeric[3] < 0) or (params_numeric[4] > 60) or (params_numeric[4] < 0)  then
    player_print("Don't be stupid.")
    return
  end
  set_time(params_numeric[1], params_numeric[2], params_numeric[3], params_numeric[4])
end

local function clock()
  player_print(format_time(game.tick))
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
  for param in string.gmatch(cmd.parameter, "%w+") do table.insert(params, param) end
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
  for param in string.gmatch(cmd.parameter, "%w+") do table.insert(params, param) end
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
    for param in string.gmatch(cmd.parameter, "%w+") do table.insert(params, param) end
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

Event.register(defines.events.on_built_entity, built_entity )

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

commands.add_command("kill", "Will kill you.", kill)
commands.add_command("detrain", "<player> - Kicks the player off a train. (Admins and moderators)", detrain)
commands.add_command("tpplayer", "<player> - Teleports you to the player. (Admins and moderators)", teleport_player)
commands.add_command("invoke", "<player> - Teleports the player to you. (Admins and moderators)", invoke)
commands.add_command("tppos", "Teleports you to a selected entity. (Admins only)", teleport_location)
commands.add_command("walkabout", '<player> <"close", "far", "very far", number> <duration> - Send someone on a walk.  (Admins and moderators)', walkabout)
commands.add_command("market", 'Places a fish market near you.  (Admins only)', spawn_market)
commands.add_command("settime", '<day> <month> <hour> <minute> - Sets the clock (Admins, moderators and regulars)', on_set_time)
commands.add_command("clock", 'Look at the clock.', clock)
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
