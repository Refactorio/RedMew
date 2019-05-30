local Event = require 'utils.event'

local SetupPlayer = {}
local config

function SetupPlayer.register(cfg)
    config = cfg
    Event.add(
        defines.events.on_player_created,
        function()
            local redmew_player_create = global.config.player_create

            if #cfg.starting_items > 0 then
                redmew_player_create.starting_items = cfg.starting_items
            end

            if not _DEBUG then
                redmew_player_create.cheats = cfg.cheats
            end
        end
    )
end

function SetupPlayer.on_init()
    game.forces.player.manual_mining_speed_modifier = config.initial_mining_speed_bonus
end

return SetupPlayer
