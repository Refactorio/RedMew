local Discord = require 'resources.discord'
local Server = require 'features.server'
local Core = require 'utils.core'
local Restart = require 'features.restart_command'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'

return function(config)
    local map_promotion_channel = Discord.channel_names.map_promotion
    local danger_ore_role_mention = Discord.role_mentions.danger_ore

    Restart.set_start_game_data({type = Restart.game_types.scenario, name = config.scenario_name or 'danger-ore-next'})

    local function can_restart(player)
        if player.admin then
            return true
        end

        if not ShareGlobals.data.map_won then
            player.print({'command_description.danger_ore_restart_condition_not_met'})
            return false
        end

        return true
    end

    local function restart_callback()
        local start_game_data = Restart.get_start_game_data()
        local new_map_name = start_game_data.name

        local time_string = Core.format_time(game.ticks_played)

        local message = {
            danger_ore_role_mention,
            ' **Danger Ore has just restarted! Previous map lasted: ',
            time_string,
            '!\\n',
            'Next map: ',
            new_map_name,
            '**'
        }
        message = table.concat(message)

        Server.to_discord_named_raw(map_promotion_channel, message)
    end

    Restart.register(can_restart, restart_callback)
end
