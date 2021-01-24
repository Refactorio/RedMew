local Event = require 'utils.event'
local event_repeat_seconds = 10

local prometheus = require 'features.prometheus.tarantool-prometheus'
local gauge_players_online = prometheus.gauge("players_online", "description")

local function writeMetrics()
    game.write_file("metrics/game.prom", prometheus.collect(), false)
end

local function on_nth_tick()
    writeMetrics()
end

local function on_player_joined()
    gauge_players_online:inc(1)
end

local function on_player_left()
    gauge_players_online:dec(1)
end

Event.on_nth_tick(60*event_repeat_seconds, on_nth_tick)
Event.add(defines.events.on_player_joined_game, on_player_joined)
Event.add(defines.events.on_player_left_game, on_player_left)



