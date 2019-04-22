local Event = require 'utils.event'

local SetupPlayer = {}

global.SetupPlayer = {
    first_player_spawned = false
}

function SetupPlayer.register(config)
    Event.add(
        defines.events.on_player_created,
        function()
            local redmew_player_create = global.config.player_create

            if #config.starting_items > 0 then
                redmew_player_create.starting_items = config.starting_items
            end

            if not _DEBUG then
                local cheats = config.cheats
                redmew_player_create.cheats = cheats
            end
        end
    )
end

return SetupPlayer
