local Discord = require 'resources.discord'
local Server = require 'features.server'
local Core = require 'utils.core'
local Restart = require 'features.restart_command'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'
local ScoreTracker = require 'utils.score_tracker'
local PlayerStats = require 'features.player_stats'
return function(config)
    local map_promotion_channel = Discord.channel_names.map_promotion
    local danger_ore_role_mention = Discord.role_mentions.danger_ore
    -- Use these settings for testing
    --local map_promotion_channel = Discord.channel_names.bot_playground
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
                time_played = p.online_time
            }
        end

        local statistics = {
            scenario = config.scenario_name,
            start_epoch = Server.get_start_time(),
            end_epoch = end_epoch, -- stored as key already, useful to have it as part of same structure
            game_ticks = game.ticks_played,
            biters_killed = ScoreTracker.get_for_global(PlayerStats.aliens_killed_name),
            total_players = #game.players,
            entities_built = ScoreTracker.get_for_global(PlayerStats.built_by_players_name),
            resources_exhausted = ScoreTracker.get_for_global(PlayerStats.resources_exhausted_name),
            resources_hand_mined = ScoreTracker.get_for_global(PlayerStats.resources_hand_mined_name),
            player_data = player_data
        }

        local awards = {
            ['total_kills'] = {value = 0, player = ""},
            ['units_killed'] = {value = 0, player = ""},
            ['spawners_killed'] = {value = 0, player = ""},
            ['worms_killed'] = {value = 0, player = ""},
            ['player_deaths'] = {value = 0, player = ""},
            ['time_played'] = {value = 0, player = ""},
            ['entities_built'] = {value = 0, player = ""},
            ['entities_crafted'] = {value = 0, player = ""},
            ['distance_walked'] = {value = 0, player = ""},
            ['resources_hand_mined'] = {value = 0, player = ""}
        }

        for _, v in pairs(statistics.player_data) do
            if v.total_kills > awards.total_kills.value then
                awards.total_kills.value = v.total_kills
                awards.total_kills.player = v.name
            end
            if v.units_killed > awards.units_killed.value then
                awards.units_killed.value = v.units_killed
                awards.units_killed.player = v.name
            end
            if v.spawners_killed > awards.spawners_killed.value then
                awards.spawners_killed.value = v.spawners_killed
                awards.spawners_killed.player = v.name
            end
            if v.worms_killed > awards.worms_killed.value then
                awards.worms_killed.value = v.worms_killed
                awards.worms_killed.player = v.name
            end
            if v.player_deaths > awards.player_deaths.value then
                awards.player_deaths.value = v.player_deaths
                awards.player_deaths.player = v.name
            end
            if v.time_played > awards.time_played.value then
                awards.time_played.value = v.time_played
                awards.time_played.player = v.name
            end
            if v.entities_built > awards.entities_built.value then
                awards.entities_built.value = v.entities_built
                awards.entities_built.player = v.name
            end
            if v.entities_crafted > awards.entities_crafted.value then
                awards.entities_crafted.value = v.entities_crafted
                awards.entities_crafted.player = v.name
            end
            if v.distance_walked > awards.distance_walked.value then
                awards.distance_walked.value = v.distance_walked
                awards.distance_walked.player = v.name
            end
            if v.resources_hand_mined > awards.resources_hand_mined.value then
                awards.resources_hand_mined.value = v.resources_hand_mined
                awards.resources_hand_mined.player = v.name
            end
        end

        local time_string = Core.format_time(game.ticks_played)

        local resource_prototypes = game.get_filtered_entity_prototypes({{filter = "type", type = "resource"}})
        local total_ore = 0
        local ore_totals_message = '('
        for ore_name,ore_prototype in pairs(resource_prototypes) do
            if ore_prototype.resource_category == 'basic-solid' then
                local count = game.forces["player"].item_production_statistics.get_input_count(ore_name)
                total_ore = total_ore + count
                ore_totals_message = ore_totals_message..ore_name:gsub( "-ore", "")..": "..string.format("%.2fM, ",count/1000000)
            end
        end
        ore_totals_message = ore_totals_message:sub(1, -3)..')'
        ore_totals_message = "Total ore mined: "..string.format("%.2fM",total_ore/1000000).. "\\n"..ore_totals_message

        Server.to_discord_named_embed(map_promotion_channel, 'Danger ores map completed!\\n\\n'
        .. 'Statistics:\\n'
        .. 'Map time: '..time_string..'\\n'
        .. 'Total entities built: '..statistics.entities_built..'\\n'
        .. 'Total ore mined:'..ore_totals_message..'\\n'
        .. 'Total ore resources exhausted: '..statistics.resources_exhausted..'\\n'
        .. 'Total ore hand mined: '..statistics.resources_hand_mined..'\\n'
        .. 'Players: '..statistics.total_players..'\\n'
        .. 'Enemies killed: '..statistics.biters_killed..'\\n\\n'
        .. 'Awards:\\n'
        .. 'Most ore hand mined:'..awards.resources_hand_mined.player..' ('..awards.resources_hand_mined.value..')\\n'
        .. 'Most items crafted: '..awards.entities_crafted.player..' ('..awards.entities_crafted.value..')\\n'
        .. 'Most entities built: '..awards.entities_built.player..' ('..awards.entities_built.value..')\\n'
        .. 'Most time played: '..awards.time_played.player..' ('..Core.format_time(awards.time_played.value)..')\\n'
        .. 'Furthest walked: '..awards.distance_walked.player..' ('..math.floor(awards.distance_walked.value)..')\\n'
        .. 'Most deaths: '..awards.player_deaths.player..' ('..awards.player_deaths.value..')\\n'
        .. 'Most kills overall: '..awards.total_kills.player..' ('..awards.total_kills.value..')\\n'
        .. 'Most biters/spitters killed: '..awards.units_killed.player..' ('..awards.units_killed.value..')\\n'
        .. 'Most spawners killed: '..awards.spawners_killed.player..' ('..awards.spawners_killed.value..')\\n'
        .. 'Most worms killed: '..awards.worms_killed.player..' ('..awards.worms_killed.value..')\\n'
        )

        Server.set_data('danger_ores_data', tostring(end_epoch), statistics)

        local start_game_data = Restart.get_start_game_data()
        local new_map_name = start_game_data.name

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
