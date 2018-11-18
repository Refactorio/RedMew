--[[-- info
    Provides the ability to setup a player when first joined.
]]

-- dependencies
local Event = require 'utils.event'
local Global = require 'utils.global'
local CaveCollapse = require 'map_gen.Diggy.Feature.DiggyCaveCollapse'
local Game = require 'utils.game'
local Report = require 'features.report'

-- this
local Antigrief = {}

global.Antigrief = {
    autojail = false,
    jailed_players = {},
    last_collapse = 0
}

local allowed_collapses_first_hour = 0

local player_collapses = {}

Global.register({
    cave_collapse_disabled = cave_collapse_disabled
}, function(tbl)
    cave_collapse_disabled = tbl.cave_collapse_disabled
end)


--[[--
    Registers all event handlers.
]]
function Antigrief.register(config)
    global.Antigrief.autojail = config.autojail
    allowed_collapses_first_hour = config.allowed_collapses_first_hour
end


Event.add(CaveCollapse.events.on_collapse, function(event)
    local player_index = event.player_index
    if player_index and global.Antigrief.last_collapse ~= game.tick then
        global.Antigrief.last_collapse = game.tick
        local count = player_collapses[player_index] or 0
        count = count + 1
        player_collapses[player_index] = count
        local player = Game.get_player_by_index(player_index)
        if global.Antigrief.autojail and count > allowed_collapses_first_hour and player.online_time < 216000 and not global.Antigrief.jailed_players[player_index] then
            Report.jail(player)
            Report.report(nil, player, string.format("Caused %d collapses in the first hour", count))
            global.Antigrief.jailed_players[player_index] = true
        end
    end
end)

return Antigrief
