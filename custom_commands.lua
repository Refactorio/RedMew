function cant_run(name)
    game.player.print("Can't run command (" .. name .. ") - you are not an admin.")
end

function invoke(cmd)
    if not game.player.admin then
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
    if not game.player.admin then
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
    if not game.player.admin then
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
  if not game.player.admin then
      cant_run(cmd.name)
      return
  end
  params = {}
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


commands.add_command("kill", "Will kill you.", kill)
commands.add_command("detrain", "<player> - Kicks the player off a train.", detrain)
commands.add_command("tpplayer", "<player> - Teleports you to the player.", teleport_player)
commands.add_command("invoke", "<player> - Teleports the player to you.", invoke)
commands.add_command("tppos", "Teleports you to a selected entity.", teleport_location)
commands.add_command("walkabout", '<player> - <"close", "far", "very far", number>', walkabout)
