local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local Server = require 'features.server'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'

return function(config)
    ShareGlobals.data.biters_disabled = false
    ShareGlobals.data.map_won = false

    local win_satellite_count = config.win_satellite_count or 1000

    local function disable_biters()
        if ShareGlobals.data.biters_disabled then
            return
        end

        ShareGlobals.data.biters_disabled = true
        game.forces.enemy.kill_all_units()
        for _, enemy_entity in pairs(RS.get_surface().find_entities_filtered({force = 'enemy'})) do
            enemy_entity.destroy()
        end

        local message = table.concat {
            'Launching the first satellite has killed all the biters. ',
            'Launch ',
            win_satellite_count,
            ' satellites to win the map.'
        }
        game.print({'danger_ore.biters_disabled', win_satellite_count})
        Server.to_discord_bold(message)
    end

    local function win()
        if ShareGlobals.data.map_won then
            return
        end

        ShareGlobals.data.map_won = true
        local message = 'Congratulations! The map has been won. Restart the map with /restart'
        game.print({'danger_ore.win'})
        Server.to_discord_bold(message)
    end

    local function print_satellite_message(count)
        local remaining_count = win_satellite_count - count
        if remaining_count <= 0 then
            return
        end

        local message = table.concat {'Launch another ', remaining_count, ' satellites to win the map.'}
        game.print({'danger_ore.satellite_launch', remaining_count})
        Server.to_discord_bold(message)
    end

    local function rocket_launched(event)
        if ShareGlobals.data.map_won then
            return
        end

        local entity = event.rocket
        if not entity or not entity.valid or not entity.force == 'player' then
            return
        end

        local inventory = entity.get_inventory(defines.inventory.rocket)
        if not inventory or not inventory.valid then
            return
        end

        local satellite_count = game.forces.player.get_item_launched('satellite')
        if satellite_count == 0 then
            return
        end

        if satellite_count == 1 then
            disable_biters()
        end

        if satellite_count == win_satellite_count then
            win()
            return
        end

        if (satellite_count % 50) == 0 then
            print_satellite_message(satellite_count)
        end
    end

    Event.add(defines.events.on_rocket_launched, rocket_launched)
end
