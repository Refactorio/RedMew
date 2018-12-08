local Event = require 'utils.event'
local Game = require 'utils.game'

local SetupPlayer = {}

global.SetupPlayer = {
    first_player_spawned = false,
}

function SetupPlayer.register(config)
    Event.add(defines.events.on_player_created, function (event)
        local player = Game.get_player_by_index(event.player_index)
        local force = player.force
        local position = {0, 0}
        local surface = player.surface
        local redmew_player_create = global.config.player_create

        if global.SetupPlayer.first_player_spawned then
            position = surface.find_non_colliding_position('player', position, 3, 0.1)
        else
            global.SetupPlayer.first_player_spawned = true
        end

        if #config.starting_items > 0 then
            redmew_player_create.starting_items = config.starting_items
        end

        force.set_spawn_position(position, surface)
        player.teleport(position)

        local cheats = config.cheats
        local redmew_cheats = redmew_player_create.cheats
        redmew_cheats.manual_mining_speed_modifier = cheats.manual_mining_speed_modifier
        redmew_cheats.character_inventory_slots_bonus = cheats.character_inventory_slots_bonus
        redmew_cheats.character_running_speed_modifier = cheats.character_running_speed_modifier
        redmew_cheats.character_health_bonus = cheats.character_health_bonus
        redmew_cheats.unlock_all_research = cheats.unlock_all_research

        if #cheats.starting_items > 0 then
            redmew_cheats.starting_items = cheats.starting_items
        end
    end)
end

return SetupPlayer
