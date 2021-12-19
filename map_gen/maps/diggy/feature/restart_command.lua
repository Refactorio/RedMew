local Discord = require 'resources.discord'
local Server = require 'features.server'
local Core = require 'utils.core'
local Restart = require 'features.restart_command'
local Global = require 'utils.global'
local Color = require 'resources.color_presets'

local restart_difficulty

Global.register_init({},
function(tbl)
    tbl.restart_difficulty = math.random(5, 15) -- mining productivity 5 costs 5k of each science (1x tech multiplier), mining productivity 15 costs 30k of each science.
end,
function(tbl)
    restart_difficulty = tbl.restart_difficulty
end)

return function(config)
    -- Use these on live to ping @diggy role in #map-promotion channel
    local map_promotion_channel = Discord.channel_names.map_promotion
    local diggy_role_mention = Discord.role_mentions.diggy

    -- Use these instead if testing new restart features so as to not ping @diggy role:
    --local map_promotion_channel = Discord.channel_names.bot_playground
    --local diggy_role_mention = Discord.role_mentions.test

    Restart.set_start_game_data({type = Restart.game_types.scenario, name = config.scenario_name or 'diggy-next'})

    local function can_restart(player)
        local adjusted_difficulty = restart_difficulty - 1 --because the labels in game are different from the technologies[].level. This adjusts the printed messages so it's correct for player.
        if player.admin then
            if game.forces.player.technologies["mining-productivity-4"].level < restart_difficulty  then
                player.print("Victory condition overriden. Did not reach Mining Productivity "..adjusted_difficulty,Color.fail)
            else
                player.print("Victory condition reached: Mining Productivity: "..adjusted_difficulty,Color.success)
            end
            return true
        end
        if game.forces.player.technologies["mining-productivity-4"].level < restart_difficulty  then
            player.print({'command_description.diggy_restart_condition_not_met', adjusted_difficulty},Color.fail)
            return false
        end
        return true
    end

    local function restart_callback()
        local start_game_data = Restart.get_start_game_data()
        local new_map_name = start_game_data.name

        local time_string = Core.format_time(game.ticks_played)

        local message = {
            diggy_role_mention,
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
