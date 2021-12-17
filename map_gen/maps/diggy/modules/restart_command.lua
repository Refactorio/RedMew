local Discord = require 'resources.discord'
local Server = require 'features.server'
local Core = require 'utils.core'
local Restart = require 'features.restart_command'

local restart_difficulty = 5
-- local restart_difficulty = math.random(5,15)

return function(config)
    local map_promotion_channel = Discord.channel_names.map_promotion
    local danger_ore_role_mention = Discord.role_mentions.diggy

    -- Use these instead if testing live:
    --local map_promotion_channel = Discord.channel_names.bot_playground
    --local danger_ore_role_mention = Discord.role_mentions.test

    Restart.set_start_game_data({type = Restart.game_types.scenario, name = config.scenario_name or 'diggy-next'})

    local function can_restart(player)
        --if player.admin then
        --    return true
        --end
        if game.player.force.technologies["mining-productivity-4"].level < restart_difficulty  then
            player.print("Mine harder dwarf! You must reach Mining Productivity "..restart_difficulty.." to start a new mining venture!")
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
            ' **Diggy has just restarted! Previous map lasted: ',
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
