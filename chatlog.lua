local time_set_moment = 0
local current_month = 1
local current_day = 1
local current_h = 0
local current_m = 0
local days_passed = 0
function ternary (cond, T, F)
    if cond then return T else return F end
end

function format_time(ticks)


  ticks = ticks - time_set_moment - 5184000 * days_passed + 3600 * (current_m + current_h * 60)

  if ticks > 5184000 then
    current_day = current_day + 1
    days_passed = days_passed + 1
    ticks = ticks - 5184000
    --fuck february
    if current_day > 30 then
      if (current_day > 31 and (current_day % 2) == 1) or  ((current_day % 2) == 0) then
        current_month = current_month + 1
        current_day = 1
      end
    end
  end

  local s = tostring(math.floor(ticks / 60) % 60)
  local m = tostring(math.floor(ticks / 3600) % 60)
  local h = tostring(math.floor(ticks / 216000))
  local current_month_str = ternary(current_month < 10, "0" .. tostring(current_month), tostring(current_month))
  local current_day_str = ternary(current_day < 10, "0" .. tostring(current_day), tostring(current_day))
  h = ternary(h:len() == 1, "0" .. h, h)
  m = ternary(m:len() == 1, "0" .. m, m)
  s = ternary(s:len() == 1, "0" .. s, s)
  return current_day_str .. "-" .. current_month_str .. "-" .. h .. ":" .. m .. ":" ..s
end

function log_chat_message(event, message)
    game.write_file("chatlog.txt", "[" .. format_time(event.tick) .. "] " .. message .. "\n", true)
end

function player_send_command(event)
    local silent = event.command == "silent-command"
    if not silent then
        local player = game.players[event.player_index]
        log_chat_message(event, player.name .. " used command: " .. event.command .. " " .. event.parameters)
    end
end

function player_send(event)
    local player = game.players[event.player_index]
    log_chat_message(event, player.name .. ": " .. event.message)
end


function player_joined(event)
    local player = game.players[event.player_index]
    log_chat_message(event, "### " .. player.name .. " joined the game. ###")
end

function player_left(event)
    local player = game.players[event.player_index]
    log_chat_message(event, "### " .. player.name .. " left the game. ###")
end

function set_time(d, month, h, m)
  time_set_moment = game.tick
  current_month = month
  current_day = d
  current_h = h
  current_m = m
  game.print(game.player.name .. " set the clock to " .. format_time(game.tick) .. ". Type /clock to check the time.")
end

Event.register(defines.events.on_console_command, player_send_command)
Event.register(defines.events.on_console_chat, player_send)
Event.register(defines.events.on_player_joined_game, player_joined)
Event.register(defines.events.on_player_left_game, player_left)
