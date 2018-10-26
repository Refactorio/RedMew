--[[-- info
    Provides the ability to setup a player when first joined.
]]

-- dependencies
local Event = require 'utils.event'
local Debug = require 'map_gen.Diggy.Debug'

-- this
local SetupPlayer = {}

global.SetupPlayer = {
    first_player_spawned = false,
}


--[[--
    Registers all event handlers.
]]
function SetupPlayer.register(config)
    Event.add(defines.events.on_player_created, function (event)
        local player = game.players[event.player_index]
        local position = {0, 0}
        local surface = player.surface

        for _, item in pairs(config.starting_items) do
            player.insert(item)
        end

        if (global.SetupPlayer.first_player_spawned) then
            position = surface.find_non_colliding_position('player', position, 3, 0.1)
        else
            global.SetupPlayer.first_player_spawned = true
        end

        player.force.set_spawn_position(position, surface)
        player.teleport(position)

        Debug.cheat(function()
            player.force.manual_mining_speed_modifier = config.cheats.manual_mining_speed_modifier
            player.force.character_inventory_slots_bonus = config.cheats.character_inventory_slots_bonus
            player.character_running_speed_modifier = config.cheats.character_running_speed_modifier
        end)
    end)
end

return SetupPlayer
