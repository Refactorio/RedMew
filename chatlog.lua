Event.register(-1, function()
if global.scenario.variables == nil then global.scenario.variables = {} end
global.scenario.variables.time_set_moment = 0
global.scenario.variables.current_month = 1
global.scenario.variables.current_day = 1
scenario.variables.current_h = 0
global.scenario.variables.current_m = 0
global.scenario.variables.days_passed = 0
end)

function ternary (cond, T, F)
    if cond then return T else return F end
end

function format_time(ticks)
  ticks = ticks - global.scenario.variables.time_set_moment - 5184000 * global.scenario.variables.days_passed + 3600 * (global.scenario.variables.current_m + global.scenario.variables.current_h * 60)
  if ticks > 5184000 then
    global.scenario.variables.current_day = global.scenario.variables.current_day + 1
    global.scenario.variables.days_passed = global.scenario.variables.days_passed + 1
    ticks = ticks - 5184000
    --fuck february
    if global.scenario.variables.current_day > 30 then
      if (global.scenario.variables.current_day > 31 and (global.scenario.variables.current_day % 2) == 1) or  ((global.scenario.variables.current_day % 2) == 0) then
        global.scenario.variables.current_month = global.scenario.variables.current_month + 1
        global.scenario.variables.current_day = 1
      end
    end
  end

  local s = tostring(math.floor(ticks / 60) % 60)
  local m = tostring(math.floor(ticks / 3600) % 60)
  local h = tostring(math.floor(ticks / 216000))
  local current_month_str = ternary(global.scenario.variables.current_month < 10, "0" .. tostring(global.scenario.variables.current_month), tostring(global.scenario.variables.current_month))
  local current_day_str = ternary(global.scenario.variables.current_day < 10, "0" .. tostring(global.scenario.variables.current_day), tostring(global.scenario.variables.current_day))
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
  global.scenario.variables.time_set_moment = game.tick
  global.scenario.variables.current_month = month
  global.scenario.variables.current_day = d
  global.scenario.variables.days_passed = 0
  global.scenario.variables.current_h = h
  global.scenario.variables.current_m.current_m = m
  game.print(game.player.name .. " set the clock to " .. format_time(game.tick) .. ". Type /clock to check the time.")
end


Event.register(defines.events.on_console_command, player_send_command)
Event.register(defines.events.on_console_chat, player_send)
Event.register(defines.events.on_player_joined_game, player_joined)
Event.register(defines.events.on_player_left_game, player_left)
