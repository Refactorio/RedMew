local Event = require 'utils.event'

local SetupPlayer = {}

global.SetupPlayer = {
    first_player_spawned = false,
}

function SetupPlayer.register(config)
    Event.add(defines.events.on_player_created, function ()
        local redmew_player_create = global.config.player_create

        if #config.starting_items > 0 then
            redmew_player_create.starting_items = config.starting_items
        end

        local cheats = config.cheats
        local redmew_cheats = redmew_player_create.cheats
        redmew_cheats.manual_mining_speed_modifier = cheats.manual_mining_speed_modifier
        redmew_cheats.character_inventory_slots_bonus = cheats.character_inventory_slots_bonus
        redmew_cheats.character_running_speed_modifier = cheats.character_running_speed_modifier
        redmew_cheats.character_health_bonus = cheats.character_health_bonus

        if #cheats.starting_items > 0 then
            redmew_cheats.starting_items = cheats.starting_items
        end
    end)
end

return SetupPlayer
