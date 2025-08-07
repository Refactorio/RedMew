local Event = require 'utils.event'
local Server = require 'features.server'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'

return function()
    ShareGlobals.data.biters_disabled = false
    ShareGlobals.data.map_won = false
    ShareGlobals.data.goal_notice = false

    local function rocket_launched()
        if ShareGlobals.data.map_won then
            return
        end

        if ShareGlobals.data.goal_notice then
            return
        end

        ShareGlobals.data.goal_notice = true
        local message = 'Craft a legendary Mech Armor to win the map.'
        game.print(message)
        Server.to_discord_bold(message)
    end

    local function win()
        if ShareGlobals.data.map_won then
            return
        end

        ShareGlobals.data.map_won = true
        local message = 'Congratulations! The map has been won. Restart the map with /restart'
        game.print({ 'danger_ores.win' })
        Server.to_discord_bold(message)
    end

    Event.add(defines.events.on_rocket_launched, rocket_launched)
    Event.on_nth_tick(301, function()
        local player = game.forces.player
        for _, surface in pairs(game.surfaces) do
            local surface_stats = player.get_item_production_statistics(surface)
            if surface_stats then
                if surface_stats.get_input_count({ name = 'mech-armor', quality = 'legendary' }) > 0 then
                    win()
                    return
                end
            end
        end
    end)
end
