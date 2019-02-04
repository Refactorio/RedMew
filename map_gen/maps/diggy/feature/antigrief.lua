-- dependencies
local Event = require 'utils.event'
local Global = require 'utils.global'
local CaveCollapse = require 'map_gen.maps.diggy.feature.diggy_cave_collapse'
local Game = require 'utils.game'
local Report = require 'features.report'
local format = string.format

-- this
local Antigrief = {}

local global_primitives = {}

local allowed_collapses_first_hour = 0

local player_collapses = {}
local jailed_players = {}

Global.register({
    player_collapses = player_collapses,
    jailed_players = jailed_players,
    global_primitives = global_primitives,
}, function(tbl)
    player_collapses = tbl.player_collapses
    jailed_players = tbl.jailed_players
    global_primitives = tbl.global_primitives
end)

global_primitives.autojail = false
global_primitives.last_collapse = 0

--[[--
    Registers all event handlers.
]]
function Antigrief.register(config)
    global_primitives.autojail = config.autojail
    allowed_collapses_first_hour = config.allowed_collapses_first_hour
end


Event.add(CaveCollapse.events.on_collapse, function(event)
    local player_index = event.player_index
    if player_index and global_primitives.last_collapse ~= game.tick then
        global_primitives.last_collapse = game.tick
        local count = player_collapses[player_index] or 0
        count = count + 1
        player_collapses[player_index] = count
        local player = Game.get_player_by_index(player_index)
        if global_primitives.autojail and count > allowed_collapses_first_hour and player.online_time < 216000 and not jailed_players[player_index] then
            Report.jail(player)
            Report.report(nil, player, format('Caused %d collapses in the first hour', count))
            jailed_players[player_index] = true
        end
    end
end)

return Antigrief
