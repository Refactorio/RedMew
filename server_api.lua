function bot_command_players(filename)
    game.write_file(filename, string.format("Online players (%d):",#game.connected_players), false,0)
    local online_players = #game.connected_players
    for _,p in pairs(online_players) do
      game.write_file(filename, p.name, true,0)
    end
end

function bot_command_time(filename)
  game.write_file(filename, string.format("Time since server start (%d):"),#math.floor(game.tick / 60), false,0)
end
