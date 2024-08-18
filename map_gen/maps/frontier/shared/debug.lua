
local Debug = {}

function Debug.print_admins(msg, color)
  for _, p in pairs(game.connected_players) do
    if p.admin then
      p.print(msg, color)
    end
  end
end

function Debug.print(msg, color)
  for _, p in pairs(game.connected_players) do
    p.print(msg, color)
  end
end

function Debug.log(data)
  log(serpent.block(data))
end

return Debug
