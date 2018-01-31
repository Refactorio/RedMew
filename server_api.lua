function get_online_players()
    game.write_file("api-output", "", false,0)   --delete 
    local online_players = game.connected_players
    for _,p in pairs(online_players) do 
      game.write_file("api-output", p.name, true,0) 
    end
end