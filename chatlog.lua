function ternary (cond, T, F)
    if cond then return T else return F end
end

function format_time(ticks)
    local s = tostring(math.floor(ticks / 60) % 60)
    local m = tostring(math.floor(ticks / 3600) % 60)
    local h = tostring(math.floor(ticks / 216000))
    h = ternary(h:len() == 1, "0" .. h, h)
    m = ternary(m:len() == 1, "0" .. m, m)
    s = ternary(s:len() == 1, "0" .. s, s)
  print(tostring(h:len()))
    return (h .. ":" .. m .. ":" ..s)
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
    log_chat_message(event, "##" .. player.name .. " joined the game.")
end

function player_left(event)
    local player = game.players[event.player_index]
    log_chat_message(event, "##" .. player.name .. " left the game.")
end
Event.register(defines.events.on_console_command, player_send_command)
Event.register(defines.events.on_console_chat, player_send)
Event.register(defines.events.on_player_joined_game, player_joined)
Event.register(defines.events.on_player_left_game, player_left)
