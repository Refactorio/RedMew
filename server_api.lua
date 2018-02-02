--This file is used by the discord bot to access ingame information
--If you launch this scenario standalone, you don't need this file

function bot_command_players(filename)
  game.write_file(filename, string.format("Online players (%d):\n", #game.connected_players), false,0)
  for _,p in pairs(game.connected_players) do
    game.write_file(filename, p.name .. "\n", true,0)
  end
end

function bot_command_time(filename)
  local s = math.floor(game.tick/60)
  local m = math.floor(s/60)
  local h = math.floor(m/60)
  local d = math.floor(h/24)

  s = s % 60
  m = m % 60
  h = h % 24
  if d == 0 then
    d = ""
    if h == 0 then
      h = ""
      if m == 0 then
        m = ""
      end
    end
  else
    d = string.format("%s days ", d)
  end

  if m ~= "" then m = string.format("%s minutes ", m) end
  if h ~= "" then h = string.format("%s hours ", h) end
    game.write_file(filename,string.format("%s%s%s%s seconds", d, h, m, s), false,0)
end
