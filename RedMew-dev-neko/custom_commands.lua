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





commands.add_command("detrain", "<player> - Kicks the player off a train.", detrain)
commands.add_command("tpplayer", "<player> - Teleports you to the player.", teleport_player)
commands.add_command("invoke", "<player> - Teleports the player to you.", invoke)
commands.add_command("tppos", "Teleports you to a selected entity.", teleport_location)
