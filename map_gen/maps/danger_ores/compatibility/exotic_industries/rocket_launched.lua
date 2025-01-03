local Event = require 'utils.event'
local Rocket = require 'utils.rocket'
local RS = require 'map_gen.shared.redmew_surface'
local Server = require 'features.server'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'

return function()
    ShareGlobals.data.biters_disabled = false
    ShareGlobals.data.map_won = false

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
            'Launch more Exploration Satellites to the asteroids to unlock the final age'
        }
        game.print({'danger_ores.biters_disabled_ei'})
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

        if 0 == Rocket.count_rocket_contents(entity.cargo_pod, { name = 'satellite' }) then
            return
        end

        local satellite_count = Rocket.get_item_launched({ name = 'satellite' })
        if satellite_count == 0 then
            return
        end
        if satellite_count == 1 then
            disable_biters()
        end
    end

    local function win()
        if ShareGlobals.data.map_won then
            return
        end

        if not game.finished_but_continuing then
            return
        end

        ShareGlobals.data.map_won = true
        local message = 'Congratulations! The map has been won. Restart the map with /restart'
        game.print({'danger_ores.win'})
        Server.to_discord_bold(message)
    end

    Event.on_nth_tick(60 * 17, win)
    Event.add(defines.events.on_rocket_launched, rocket_launched)
end

