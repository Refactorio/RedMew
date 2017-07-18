function cant_run(name)
    game.player.print("Can't run command (" .. name .. ") - insufficient permission.")
end

function invoke(cmd)
    if not (game.player.admin or is_mod(game.player.name)) then
        cant_run(cmd.name)
        return
    end
    local target = cmd["parameter"]
    if target == nil or game.players[target] == nil then
        game.player.print("Unknown player.")
        return
    end
    local pos = game.surfaces[1].find_non_colliding_position("player", game.player.position, 0, 1)
    game.players[target].teleport({pos.x, pos.y})
    game.print(target .. ", get your ass over here!")
end

function teleport_player(cmd)
    if not (game.player.admin or is_mod(game.player.name)) then
        cant_run(cmd.name)
        return
    end
    local target = cmd["parameter"]
    if target == nil or game.players[target] == nil then
        game.player.print("Unknown player.")
        return
    end
    local pos = game.surfaces[1].find_non_colliding_position("player", game.players[target].position, 0, 1)
    game.player.teleport({pos.x, pos.y})
    game.print(target .. "! watcha doin'?!")
end

function teleport_location(cmd)
    if not game.player.admin then
        cant_run(cmd.name)
        return
    end
    if game.player.selected == nil then
        game.player.print("Nothing selected.")
        return
    end
    local pos = game.surfaces[1].find_non_colliding_position("player", game.player.selected.position, 0, 1)
    game.player.teleport({pos.x, pos.y})
end

local function detrain(param)
    if not (game.player.admin or is_mod(game.player.name)) then
        cant_run(param.name)
        return
    end
    local player_name = param["parameter"]
    if player_name == nil or game.players[player_name] == nil then game.player.print("Unknown player.") return end
    if game.players[player_name].vehicle == nil then game.player.print("Player not in vehicle.") return end
    game.players[player_name].vehicle.passenger = game.player
    game.print(string.format("%s kicked %s off the train. God damn!", game.player.name, player_name))
end


function kill()
  game.player.character.die()
end

function walkabout(cmd)
  if not (game.player.admin or is_mod(game.player.name)) then
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
  if params[3] == nil then
    distance = params[2]
  else
    distance = params[2] .. " " .. params[3]
  end

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
  while game.players[x] ~= nil do
    local player = game.players[x]
    if player_name == player.name then
      local repeat_attempts = 5
      local r = 1
      local surface = game.surfaces[1]
      local distance_max = distance * 1.05
      local distance_min = distance * 0.95
      distance_max = round(distance_max, 0)
      distance_min = round(distance_min, 0)

      --while r <= repeat_attempts do
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
          player.teleport(pos)
          game.print(player_name .. " went on a walkabout, to find himself.")
          return
    end
    x = x + 1
  end
  game.print(player_name .. " could not go on a walkabout.")
end

function on_set_time(cmd)
  if not (game.player.admin or is_regular(game.player.name) or is_mod(game.player.name)) then
      cant_run(cmd.name)
      return
  end

  local params = {}
  local params_numeric = {}


  if cmd.parameter == nil then
    game.player.print("Setting clock failed. Usage: /settime <day> <month> <hour> <minute>")
    return
  end

  for param in string.gmatch(cmd.parameter, "%w+") do table.insert(params, param) end

  if params[4] == nil then
    game.player.print("Setting clock failed. Usage: /settime <day> <month> <hour> <minute>")
    return
  end

  for _, param in pairs(params) do
    if tonumber(param) == nil then
      game.player.print("Don't be stupid.")
      return
    end
    table.insert(params_numeric, tonumber(param))
  end
  if (params_numeric[2] > 12)  or (params_numeric[2] < 1)  or (params_numeric[1] > 31)  or (params_numeric[1] < 1) or (params_numeric[2] % 2 == 0 and params_numeric[1] > 30) or (params_numeric[3] > 24) or (params_numeric[3] < 0) or (params_numeric[4] > 60) or (params_numeric[4] < 0)  then
    game.player.print("Don't be stupid.")
    return
  end
  set_time(params_numeric[1], params_numeric[2], params_numeric[3], params_numeric[4])
end

local function clock()
  game.player.print(format_time(game.tick))
end

local function regular(cmd)
  if not (game.player.admin or is_mod(game.player.name)) then
      cant_run(cmd.name)
      return
  end

  if cmd.parameter == nil then
    game.player.print("Command failed. Usage: /regular <promote, demote>, <player>")
    return
  end
  local params = {}
  for param in string.gmatch(cmd.parameter, "%w+") do table.insert(params, param) end
  if params[2] == nil then
    game.player.print("Command failed. Usage: /regular <promote, demote>, <player>")
    return
  elseif (params[1] == "promote") then
    add_regular(params[2])
  elseif (params[1] == "demote") then
    remove_regular(params[2])
  else
      game.player.print("Command failed. Usage: /regular <promote, demote>, <player>")
  end
end

local function mod(cmd)
  if not game.player.admin then
      cant_run(cmd.name)
      return
  end

  if cmd.parameter == nil then
    game.player.print("Command failed. Usage: /mod <promote, demote>, <player>")
    return
  end
  local params = {}
  for param in string.gmatch(cmd.parameter, "%w+") do table.insert(params, param) end
  if params[2] == nil then
    game.player.print("Command failed. Usage: /mod <promote, demote>, <player>")
    return
  elseif (params[1] == "promote") then
    add_mod(params[2])
  elseif (params[1] == "demote") then
    remove_mod(params[2])
  else
      game.player.print("Command failed. Usage: /mod <promote, demote>, <player>")
  end
end

local function afk()
  for _,v in pairs (game.players) do
    if v.afk_time > 300 then
      local time = " "
      if v.afk_time > 21600 then
        time = time .. math.floor(v.afk_time / 21600) .. " hours "
      end
      if v.afk_time > 3600 then
        time = time .. math.floor(v.afk_time / 3600) % 60 .. " minutes and "
      end
      time = time .. math.floor(v.afk_time / 60) % 60 .. " seconds."
      game.player.print(v.name .. " has been afk for" .. time)
    end
  end
end

commands.add_command("kill", "Will kill you.", kill)
commands.add_command("detrain", "<player> - Kicks the player off a train. (Admins and moderators)", detrain)
commands.add_command("tpplayer", "<player> - Teleports you to the player. (Admins and moderators)", teleport_player)
commands.add_command("invoke", "<player> - Teleports the player to you. (Admins and moderators)", invoke)
commands.add_command("tppos", "Teleports you to a selected entity. (Admins only)", teleport_location)
commands.add_command("walkabout", '<player> <"close", "far", "very far", number> - Send someone on a walk.  (Admins and moderators)', walkabout)
commands.add_command("settime", '<day> <month> <hour> <minute> - Sets the clock (Admins, moderators and regulars)', on_set_time)
commands.add_command("clock", 'Look at the clock.', clock)
commands.add_command("regulars", 'Prints a list of game regulars.', print_regulars)
commands.add_command("regular", '<promote, demote>, <player> Change regular status of a player. (Admins and moderators)', regular)
commands.add_command("mods", 'Prints a list of game mods.', print_mods)
commands.add_command("mod", '<promote, demote>, <player> Changes moderator status of a player. (Admins only)', mod)
commands.add_command("afktime", 'Shows how long players have been afk.', afk)
