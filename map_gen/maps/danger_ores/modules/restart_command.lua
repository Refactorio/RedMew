local Discord = require 'resources.discord'
local Server = require 'features.server'
local Core = require 'utils.core'
local Restart = require 'features.restart_command'
local Poll = require 'features.gui.poll'
local MapPoll = require 'map_gen.maps.danger_ores.modules.map_poll'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'
local OreMined = require 'map_gen.maps.danger_ores.modules.ore_mined'
local ScoreTracker = require 'utils.score_tracker'
local PlayerStats = require 'features.player_stats'
local RestartMessage = require 'utils.restart_message'
local RestartStatistics = require 'map_gen.maps.danger_ores.modules.restart_statistics'
local format_number = require 'util'.format_number

return function(config)
    local map_promotion_channel = Discord.channel_names.map_promotion
    local danger_ores_channel = Discord.channel_names.danger_ores
    local danger_ore_role_mention = Discord.role_mentions.danger_ore
    -- Use these settings for testing
    --local map_promotion_channel = Discord.channel_names.bot_playground
    --local danger_ores_channel = Discord.channel_names.bot_playground
    --local danger_ore_role_mention = Discord.role_mentions.test

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

    -- the name players voted for, e.g. 'Rivers (flowing out from spawn)'
    local function get_display_name(map_name)
        for _, map_data in pairs(MapPoll.get_maps()) do
            if map_data.name == map_name then
                return map_data.display_name
            end
        end
        return map_name
    end

    -- e.g. '**Danger Ores: Rivers** completed!', the map's name without its description
    local function get_title()
        local map_name = config.scenario_name
        if map_name == nil then
            return '**Danger Ores** completed!'
        end
        return '**Danger Ores: ' .. get_display_name(map_name):gsub('%s*%b()$', '') .. '** completed!'
    end

    -- {label, player_data key, format}; an award nobody earned is left out of the message
    local awards = {
        {'Most ore hand mined', 'resources_hand_mined'},
        {'Most items crafted', 'entities_crafted'},
        {'Most entities built', 'entities_built'},
        {'Most time played', 'time_played', Core.format_time},
        {'Furthest walked', 'distance_walked'},
        {'Most talkative', 'console_chats'},
        {'Biggest demolisher', 'entities_removed'},
        {'Most landfill placed', 'landfill_placed'},
        {'Most deaths', 'player_deaths'},
        {'Most kills overall', 'total_kills'},
        {'Most biters/spitters killed', 'units_killed'},
        {'Most spawners killed', 'spawners_killed'},
        {'Most worms killed', 'worms_killed'}
    }

    -- e.g. '- Ore mined: **171.5M** (iron 68.2M, copper 52.1M, coal 31.0M, stone 20.2M)', most mined
    -- first; a map with one ore only gets the total
    local function ore_mined_line(counts, total)
        local ores = {}
        for name, count in pairs(counts) do
            if count > 0 then
                ores[#ores + 1] = {name = name:gsub('%-ore$', ''), count = count}
            end
        end
        table.sort(ores, function(a, b)
            return a.count > b.count
        end)

        local line = RestartMessage.statistic('Ore mined', format_number(total, true))
        if #ores > 1 then
            for i, ore in ipairs(ores) do
                ores[i] = ore.name .. ' ' .. format_number(ore.count, true)
            end
            line = line .. ' (' .. table.concat(ores, ', ') .. ')'
        end
        return line
    end

    local function restart_callback()
        local start_game_data = Restart.get_start_game_data()
        local new_map_name = start_game_data.name

        local time_string = Core.format_time(game.ticks_played)

        local end_epoch = Server.get_current_time()
        if end_epoch == nil then
            end_epoch = -1 -- end_epoch is nil if the restart command is used locally rather than on the server
        end

        local player_data = {}
        for _, p in pairs(game.players) do
            local entities_removed, landfill_placed = RestartStatistics.get_for_player(p.index)
            player_data[p.index] = {
                name = p.name,
                total_kills = ScoreTracker.get_for_player(p.index, PlayerStats.player_total_kills_name),
                spawners_killed = ScoreTracker.get_for_player(p.index, PlayerStats.player_spawners_killed_name),
                worms_killed = ScoreTracker.get_for_player(p.index, PlayerStats.player_worms_killed_name),
                units_killed = ScoreTracker.get_for_player(p.index, PlayerStats.player_units_killed_name),
                turrets_killed = ScoreTracker.get_for_player(p.index, PlayerStats.player_turrets_killed_name),
                distance_walked = ScoreTracker.get_for_player(p.index, PlayerStats.player_distance_walked_name),
                player_deaths = ScoreTracker.get_for_player(p.index, PlayerStats.player_deaths_name),
                entities_built = ScoreTracker.get_for_player(p.index, PlayerStats.player_entities_built_name),
                entities_crafted = ScoreTracker.get_for_player(p.index, PlayerStats.player_items_crafted_name),
                resources_hand_mined = ScoreTracker.get_for_player(p.index, PlayerStats.player_resources_hand_mined_name),
                console_chats = ScoreTracker.get_for_player(p.index, PlayerStats.player_console_chats_name),
                entities_removed = entities_removed,
                landfill_placed = landfill_placed,
                time_played = p.online_time
            }
        end

        local statistics = {
            scenario = config.scenario_name or 'Danger ore',
            start_epoch = Server.get_start_time(),
            end_epoch = end_epoch, -- stored as key already, useful to have it as part of same structure
            game_ticks = game.ticks_played,
            biters_killed = ScoreTracker.get_for_global(PlayerStats.aliens_killed_name),
            total_players = #game.players,
            entities_built = ScoreTracker.get_for_global(PlayerStats.built_by_players_name),
            resources_exhausted = ScoreTracker.get_for_global(PlayerStats.resources_exhausted_name),
            resources_hand_mined = ScoreTracker.get_for_global(PlayerStats.resources_hand_mined_name),
            peak_players = RestartStatistics.get_peak_players(),
            first_satellite_ticks = ShareGlobals.data.first_satellite_ticks,
            landfill_placed = RestartStatistics.get_landfill_placed(),
            player_data = player_data
        }

        local ore_counts, total_ore = OreMined.get_ore_mined()
        statistics.ore_mined = ore_counts

        local statistics_lines = {RestartMessage.statistic('Map time', time_string)}
        local function add_line(line)
            statistics_lines[#statistics_lines + 1] = line
        end
        if statistics.first_satellite_ticks then
            add_line(RestartMessage.statistic('First satellite at', Core.format_time(statistics.first_satellite_ticks)))
        end
        add_line(ore_mined_line(ore_counts, total_ore))
        add_line(RestartMessage.statistic('Entities built', RestartMessage.format_count(statistics.entities_built)))
        add_line(RestartMessage.statistic('Ore hand mined', RestartMessage.format_count(statistics.resources_hand_mined)))
        if statistics.landfill_placed > 0 then
            add_line(RestartMessage.statistic('Landfill placed', RestartMessage.format_count(statistics.landfill_placed)))
        end
        add_line('- Players: **' .. statistics.total_players .. '** in total, **' .. statistics.peak_players .. '** online at most')
        add_line(RestartMessage.statistic('Enemies killed', RestartMessage.format_count(statistics.biters_killed)))

        local award_lines = {}
        for _, award in ipairs(awards) do
            award_lines[#award_lines + 1] = RestartMessage.award(award[1], player_data, award[2], award[3])
        end

        local statistics_message = RestartMessage.build(
            get_title(),
            {
                {name = 'Statistics', lines = statistics_lines},
                {name = 'Awards', lines = award_lines}
            },
            '**Next map:** ' .. get_display_name(new_map_name)
        )

        Server.to_discord_named_embed_raw(map_promotion_channel, statistics_message)
        Server.to_discord_named_embed_raw(danger_ores_channel, statistics_message)

        Server.set_data('danger_ores_data', tostring(end_epoch), statistics)

        local message = {
            danger_ore_role_mention,
            ' **Danger Ore has just restarted! Previous map lasted: ',
            time_string,
            '!\\n',
            'Next map: ',
            get_display_name(new_map_name),
            '**'
        }
        message = table.concat(message)

        Server.to_discord_named_raw(map_promotion_channel, message)
    end

    local function restart_requested()
        if not Restart.get_use_map_poll_result_option() then
            return
        end

        local map_data = MapPoll.get_next_map()
        if map_data == nil then
            return
        end

        local known_mod_packs = Restart.get_known_modpacks_option()
        local mod_pack = known_mod_packs[map_data.mod_pack]
        Restart.set_start_game_data({type = Restart.game_types.scenario, name = map_data.name, mod_pack = mod_pack})

        local poll_id = MapPoll.get_map_poll_id()
        Poll.send_poll_result_to_discord(poll_id)
    end

    Restart.register(can_restart, restart_callback, restart_requested)
end
