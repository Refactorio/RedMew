local Event = require 'utils.event'
local Game = require 'utils.game'
local Metatable = require 'utils.metatable'

local mt = {__index = function(self, name) local real_name =  global.anonymous.real_names[game.players[name].index] if real_name then return rawget(self, real_name) end return nil end }


Metatable.set(global.donators, mt)
Metatable.set(global.regulars, mt)

local colors ={{r=0,g=0,b=0},{r=65,g=65,b=65},{r=130,g=130,b=130},{r=190,g=190,b=190},{r=255,g=255,b=255},{r=0,g=130,b=0},{r=25,g=255,b=51},{r=130,g=255,b=130},{r=20,g=220,b=190},{r=30,g=30,b=180},{r=0,g=100,b=255},{r=20,g=180,b=235},{r=160,g=50,b=255},{r=179,g=102,b=255},{r=130,g=130,b=255},{r=255,g=0,b=255},{r=160,g=0,b=0},{r=255,g=0,b=25},{r=255,g=130,b=130},{r=242,g=70,b=13},{r=255,g=140,b=25},{r=255,g=255,b=0},{r=0.6,g=0.4,b=0.1}}
local colors_n = #colors

global.anonymous = global.anonymous or {["real_names"] = {}}

local function set_name(player, name, set_real_name)
  if set_real_name then
    global.anonymous.real_names[player.index] = player.name
  end
  player.name = name

  local color = colors[math.random(1, colors_n)]
  player.chat_color = color
  player.color = color
end

Event.add(defines.events.on_player_created, function(event)
  local new_name
  repeat
    new_name = tostring(math.random(10000000, 100000000))
  until not game.players[new_name]
    if not global.anonymous.real_names[event.player_index] then
      local player = Game.get_player_by_index(event.player_index)
      set_name(player, new_name, true)
    end
end)

Event.add(defines.events.on_player_joined_game, function(event)
  local previous_player
  local first_player_name
  for index, player in pairs(game.players) do
      if player.connected then
          if first_player_name then
              --Sets prev_player_name <= current_player_name
              set_name(previous_player, player.name)
          else
              first_player_name = player.name
          end
          previous_player = player
      end
  end

  --Sets first_player_name <= last_player_name
  set_name(previous_player, first_player_name)
end)

Event.add(defines.events.on_console_command, function(event)
  if event.command == "ban" and event.parameters then
    local name = ""
    local reason = ""
    local i = 1
    for param in event.parameters:gmatch("%w+") do
      if i == 1 then
        name = param
      else
        reason = reason .. " " .. param
      end
      i = i + 1
    end
    local player = game.players[name]
    if player and global.anonymous.real_names[player.index] then
      game.print("Banned: " .. global.anonymous.real_names[player.index])
      game.ban(global.anonymous.real_names[player.index], reason)
    end
  end
end)

commands.add_command('whois', '<playername> Reveals the true identy of a player (admin only)', function(cmd)
  if game.player and not game.player.admin then
    game.player.print("You are not an admin. Nice try.")
    return
  end
  if not cmd.parameter then
    player_print("Usage: /whois <playername>.")
    return
  end
  local player = game.players[cmd.parameter]
  if not player then
    player_print("Player does not exist.")
    return
  end
  local true_name = global.anonymous.real_names[player.index]
  if true_name then
    player_print("pssst... " .. cmd.parameter .. " is really " .. true_name)
  else
    player_print("Could not find " .. cmd.parameter)
  end
end)
