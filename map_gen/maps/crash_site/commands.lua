local Command = require 'utils.command'
local Rank = require 'features.rank_system'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Server = require 'features.server'
local Popup = require 'features.gui.popup'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Retailer = require 'features.retailer'
local Ranks = require 'resources.ranks'
local Core = require 'utils.core'
local Color = require 'resources.color_presets'
local Toast = require 'features.gui.toast'
local Utils = require 'utils.core'
local Discord = require 'resources.discord'
local ScoreTracker = require 'utils.score_tracker'
local PlayerStats = require 'features.player_stats'
local set_timeout_in_ticks = Task.set_timeout_in_ticks

local map_promotion_channel = Discord.channel_names.map_promotion
local crash_site_role_mention = Discord.role_mentions.crash_site

local Public = {}

function Public.control(config)

    local server_player = {name = '<server>', print = print}
    local global_data = {restarting = nil}
    local airstrike_data = {radius_level = 1, count_level = 1}

    Global.register({global_data = global_data, airstrike_data = airstrike_data}, function(tbl)
        global_data = tbl.global_data
        airstrike_data = tbl.airstrike_data
    end)

    local function double_print(str)
        game.print(str)
        print(str)
    end

    local static_entities_to_check = {
        'spitter-spawner',
        'biter-spawner',
        'small-worm-turret',
        'medium-worm-turret',
        'big-worm-turret',
        'behemoth-worm-turret',
        'gun-turret',
        'laser-turret',
        'artillery-turret',
        'flamethrower-turret'
    }

    local biter_entities_to_check = {
        'small-spitter',
        'medium-spitter',
        'big-spitter',
        'behemoth-spitter',
        'small-biter',
        'medium-biter',
        'big-biter',
        'behemoth-biter'
    }

    local function count_enemy_entities()
        local get_entity_count = game.forces["enemy"].get_entity_count
        local entity_count = 0;
        for i = 1, #static_entities_to_check do
            local name = static_entities_to_check[i]
            entity_count = entity_count + get_entity_count(name)
        end
        for i = 1, #biter_entities_to_check do
            local name = biter_entities_to_check[i]
            entity_count = entity_count + get_entity_count(name)
        end
        return entity_count
    end

    local callback
    callback = Token.register(function(data)
        if not global_data.restarting then
            return
        end

        local state = data.state
        if state == 0 then
            Server.start_scenario(data.scenario_name)
            double_print('restarting')
            global_data.restarting = nil
            return
        elseif state == 1 then

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
                    distance_walked = ScoreTracker.get_for_player(p.index,PlayerStats.player_distance_walked_name),
                    player_deaths = ScoreTracker.get_for_player(p.index, PlayerStats.player_deaths_name),
                    coins_earned = ScoreTracker.get_for_player(p.index, PlayerStats.coins_earned_name),
                    entities_built = ScoreTracker.get_for_player(p.index,PlayerStats.built_by_players_name),
                    time_played = p.online_time
                }
            end

            local statistics = {
                scenario = config.scenario_name,
                start_epoch = Server.get_start_time(),
                end_epoch = end_epoch, -- stored as key already, useful to have it as part of same structure
                game_ticks = game.ticks_played,
                enemy_entities = count_enemy_entities(),
                biters_killed = ScoreTracker.get_for_global(PlayerStats.aliens_killed_name),
                total_players = #game.players,
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
                ['distance_walked'] = {value = 0, player = ""},
                ['coins_earned'] = {value = 0, player = ""}
            }

            for k, v in pairs(statistics.player_data) do
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
                -- This stat not working
                --if v.entities_built > awards.entities_built.value then
                --    awards.entities_built.value = v.entities_built
                --    awards.entities_built.player = v.name
                --end
                if v.distance_walked > awards.distance_walked.value then
                    awards.distance_walked.value = v.distance_walked
                    awards.distance_walked.player = v.name
                end
                if v.coins_earned > awards.coins_earned.value then
                    awards.coins_earned.value = v.coins_earned
                    awards.coins_earned.player = v.name
                end
            end

            local time_string = Core.format_time(game.ticks_played)
            if statistics.enemy_entities < 1000 then
                Server.to_discord_named_embed(map_promotion_channel, 'Crash Site map won!\\n\\n'
                .. 'Statistics:\\n'
                .. 'Map time: '..time_string..'\\n'
                .. 'Total kills: '..statistics.biters_killed..'\\n'
                .. 'Biters remaining on map: '..statistics.enemy_entities..'\\n'
                .. 'Players: '..statistics.total_players..'\\n\\n'
                .. 'Awards:\\n'
                .. 'Most kills overall: '..awards.total_kills.player..' ('..awards.total_kills.value..')\\n'
                .. 'Most biters/spitters killed: '..awards.units_killed.player..' ('..awards.units_killed.value..')\\n'
                .. 'Most spawners killed: '..awards.spawners_killed.player..' ('..awards.spawners_killed.value..')\\n'
                .. 'Most worms killed: '..awards.worms_killed.player..' ('..awards.worms_killed.value..')\\n'
                .. 'Most deaths: '..awards.player_deaths.player..' ('..awards.player_deaths.value..')\\n'
                .. 'Most time played: '..awards.time_played.player..' ('..Core.format_time(awards.time_played.value)..')\\n'
                .. 'Furthest walked: '..awards.distance_walked.player..' ('..math.floor(awards.distance_walked.value)..')\\n'
                .. 'Most coins earned: '..awards.coins_earned.player..' ('..awards.coins_earned.value..')\\n'
                )
            else
                Server.to_discord_named_embed(map_promotion_channel, 'Crash Site map failed!\\n\\n'
                .. 'Statistics:\\n'
                .. 'Map time: '..time_string..'\\n'
                .. 'Total kills: '..statistics.biters_killed..'\\n'
                .. 'Biters remaining on map: '..statistics.enemy_entities..'\\n'
                .. 'Players: '..statistics.total_players..'\\n'
                )
            end
            Server.to_discord_named_raw(map_promotion_channel, crash_site_role_mention .. ' **Crash Site has just restarted!!**')

            Server.set_data('crash_site_data', tostring(end_epoch), statistics) -- Store the table, with end_epoch as the key
            Popup.all('\nServer restarting!\nInitiated by ' .. data.name .. '\n')
        end

        double_print(state)

        data.state = state - 1
        Task.set_timeout_in_ticks(60, callback, data)
    end)

    local function map_cleared(player)
        player = player or server_player
        local get_entity_count = game.forces["enemy"].get_entity_count
        -- Check how many of each turrets, worms and spawners are left and return false if there are any of each left.
        for i = 1, #static_entities_to_check do
            local name = static_entities_to_check[i]
            if get_entity_count(name) > 0 then
                player.print(
                    'All enemy spawners, worms, buildings, biters and spitters must be cleared before crashsite can be restarted.')
                return false
            end
        end

        -- Count all the remaining enemies
        local biter_total = count_enemy_entities()

        -- Return false if more than 20 left. Players have had problems finding the last few biters so set to a reasonable value.
        if biter_total > 20 then
            player.print(
                'All enemy spawners, worms, buildings are dead. Crashsite can be restarted when all biters and spitters are killed.')
            return false
        end
        return true
    end

    local function restart(args, player)
        player = player or server_player
        local sanitised_scenario = args.scenario_name

        if global_data.restarting then
            player.print('Restart already in progress')
            return
        end

        if player ~= server_player and Rank.less_than(player.name, Ranks.admin) then
            -- Check enemy count
            if not map_cleared(player) then
                return
            end

            -- Limit the ability of non-admins to call the restart function with arguments to change the scenario
            -- If not an admin, restart the same scenario always
            sanitised_scenario = config.scenario_name
        end

        global_data.restarting = true

        double_print('#################-Attention-#################')
        double_print('Server restart initiated by ' .. player.name)
        double_print('###########################################')

        for _, p in pairs(game.players) do
            if p.admin then
                p.print('Abort restart with /abort')
            end
        end
        print('Abort restart with /abort')
        Task.set_timeout_in_ticks(60, callback, {name = player.name, scenario_name = sanitised_scenario, state = 10})
    end

    local function abort(_, player)
        player = player or server_player

        if global_data.restarting then
            global_data.restarting = nil
            double_print('Restart aborted by ' .. player.name)
        else
            player.print('Cannot abort a restart that is not in progress.')
        end
    end

    local chart_area_callback = Token.register(function(data)
        local xpos = data.xpos
        local ypos = data.ypos
        local player = data.player
        local s = player.surface
        player.force.chart(s, {{xpos - 32, ypos - 32}, {xpos + 32, ypos + 32}})
    end)

    local function spy(args, player)
        local player_name = player.name
        local inv = player.get_inventory(defines.inventory.character_main)

        -- Parse the values from the location string
        -- {location = "[gps=-110,-17,redmew]"}
        local location_string = args.location
        local coords = {}
        local spy_cost = 100

        for m in string.gmatch(location_string, "%-?%d+") do -- Assuming the surface name isn't a valid number.
            table.insert(coords, tonumber(m))
        end
        -- Do some checks on the coordinates passed in the argument
        if #coords < 2 then
            player.print({'command_description.crash_site_spy_invalid'}, Color.fail)
            return
        end

        -- process each set of coordinates
        local i = 1
        local xpos = coords[i]
        local ypos = coords[i+1]
        while xpos ~= nil and ypos ~= nil do
            local coin_count = inv.get_item_count("coin")

            -- Make sure player has enough coin to cover spying cost
            if coin_count < spy_cost then
                player.print({'command_description.crash_site_spy_funds'}, Color.fail)
                return
            else
                -- reveal 3x3 chunks centred on chunk containing pinged location
                -- make sure it lasts 15 seconds
                for j = 1, 15 do
                    set_timeout_in_ticks(60 * j, chart_area_callback, {player = player, xpos = xpos, ypos = ypos})
                end
                game.print({'command_description.crash_site_spy_success', player_name, spy_cost, xpos, ypos}, Color.success)
                inv.remove({name = "coin", count = spy_cost})
            end

            -- move to the next set of coordinates
            i = i+2
            xpos = coords[i]
            ypos = coords[i+1]
        end
    end

    local spawn_poison_callback = Token.register(function(data)
        local r = data.r
        data.s.create_entity {
            name = "poison-capsule",
            position = {0, 0},
            target = {data.xpos + math.random(-r, r), data.ypos + math.random(-r, r)},
            speed = 10,
            max_range = 100000
        }
    end)

    local map_chart_tag_clear_callback = Token.register(function(tag)
        if not tag or not tag.valid then
            return -- in case a player deleted the tag manually
        end
        tag.destroy()
    end)

    -- This is needed for if players use /strike on an uncharted area. A map tag cannot be placed on void.
    local map_chart_tag_place_callback = Token.register(function(data)
        local xpos = data.xpos
        local ypos = data.ypos
        local player = data.player
        local tag = player.force.add_chart_tag(player.surface, {
            icon = {type = 'item', name = 'poison-capsule'},
            position = {xpos,ypos},
            text = player.name
        })
        set_timeout_in_ticks(60*30, map_chart_tag_clear_callback, tag) -- To clear the tag after 30 seconds
    end)

    local function render_crosshair(data)
        local red = {r = 0.5, g = 0, b = 0, a = 0.5}
        local timeout = 5*60
        local line_width = 10
        local line_length = 2
        local s = data.player.surface
        local f = data.player.force
        rendering.draw_circle{color=red, radius=1.5, width=line_width, filled=false, target=data.position, surface=s, time_to_live=timeout, forces={f}}
        rendering.draw_line{color=red, width=line_width, from={data.position.x-line_length, data.position.y}, to={data.position.x+line_length, data.position.y}, surface=s, time_to_live=timeout, forces={f}}
        rendering.draw_line{color=red, width=line_width, from={data.position.x, data.position.y-line_length}, to={data.position.x, data.position.y+line_length}, surface=s, time_to_live=timeout, forces={f}}
        s.create_entity{name="flying-text", position={data.position.x+3, data.position.y}, text = "[item=poison-capsule] "..data.player.name, color = {r = 1, g = 1, b = 1, a = 1}  }
    end

    local function render_radius(data)
        local timeout = 20*60
        local blue = {r = 0, g = 0, b = 0.1, a = 0.1}
        rendering.draw_circle{color=blue, radius=data.radius+10, filled=true, target=data.position, surface=data.player.surface, time_to_live=timeout, players={data.player}}
    end

    local function strike(args, player)
        local s = player.surface
        local location_string = args.location
        local coords = {}

        local radius_level = airstrike_data.radius_level -- max radius of the strike area
        local count_level = airstrike_data.count_level -- the number of poison capsules launched at the enemy
        if count_level == 1 then
            player.print({'command_description.crash_site_airstrike_not_researched'}, Color.fail)
            return
        end

        local radius = 5 + (radius_level * 3)
        local count = (count_level - 2) * 5 + 3
        local strikeCost = count * 4 -- the number of poison-capsules required in the chest as payment

        -- parse GPS coordinates from map ping
        for m in string.gmatch(location_string, "%-?%d+") do -- Assuming the surface name isn't a valid number.
            table.insert(coords, tonumber(m))
        end

        -- Do some checks on the coordinates passed in the argument
        if #coords < 2 then
            player.print({'command_description.crash_site_airstrike_invalid'}, Color.fail)
            return
        end

        -- Check that the chest is where it should be.
        local entities = s.find_entities_filtered {position = {-0.5, -3.5}, type = 'container', limit = 1}
        local dropbox = entities[1]

        if dropbox == nil then
            player.print("Chest not found. Replace it here: [gps=-0.5,-3.5,redmew]")
            return
        end

        -- process each set of coordinates with a 10 strike limit
        local i = 1
        local xpos = coords[i]
        local ypos = coords[i+1]
        while xpos ~= nil and ypos ~= nil and i < 20 do
            -- Check the contents of the chest by spawn for enough poison capsules to use as payment
            local inv = dropbox.get_inventory(defines.inventory.chest)
            local capCount = inv.get_item_count("poison-capsule")

            if capCount < strikeCost then
                player.print(
                    {'command_description.crash_site_airstrike_insufficient_currency_error', strikeCost - capCount},
                    Color.fail)
                return
            end

            -- Do a simple check to make sure the player isn't trying to grief the base
            -- local enemyEntities = s.find_entities_filtered {position = {xpos, ypos}, radius = radius, force = "enemy"}
            local enemyEntities = player.surface.count_entities_filtered {
                position = {xpos, ypos},
                radius = radius + 30,
                force = "enemy",
                limit = 1
            }
            if enemyEntities < 1 then
                player.print({'command_description.crash_site_airstrike_friendly_fire_error'}, Color.fail)
                Utils.print_admins(player.name .. " tried to airstrike the base here: [gps=" .. xpos .. "," .. ypos
                                       .. ",redmew]", nil)
                return
            end

            inv.remove({name = "poison-capsule", count = strikeCost})

            for j = 1, count do
                set_timeout_in_ticks(30 * j, spawn_poison_callback,
                    {s = s, xpos = xpos, ypos = ypos, count = count, r = radius})
                set_timeout_in_ticks(60 * j, chart_area_callback, {player = player, xpos = xpos, ypos = ypos})
            end
            player.force.chart(s, {{xpos - 32, ypos - 32}, {xpos + 32, ypos + 32}})
            render_crosshair({position = {x = xpos, y = ypos}, player = player})
            render_radius({position = {x = xpos, y = ypos}, player = player, radius = radius})
            set_timeout_in_ticks(60, map_chart_tag_place_callback, {player = player, xpos = xpos, ypos = ypos})

            -- move to the next set of coordinates
            i = i+2
            xpos = coords[i]
            ypos = coords[i+1]
        end
    end

    Event.add(Retailer.events.on_market_purchase, function(event)

        local market_id = event.group_name
        local group_label = Retailer.get_market_group_label(market_id)
        if group_label ~= 'Spawn' then
            return
        end

        local item = event.item
        if item.type ~= 'airstrike' then
            return
        end

        -- airstrike stuff
        local radius_level = airstrike_data.radius_level -- max radius of the strike area
        local count_level = airstrike_data.count_level -- the number of poison capsules launched at the enemy
        local radius = 5 + (radius_level * 3)
        local count = (count_level - 1) * 5 + 3
        local strikeCost = count * 4

        local name = item.name
        local player_name = event.player.name
        if name == 'airstrike_damage' then
            airstrike_data.count_level = airstrike_data.count_level + 1

            Toast.toast_all_players(15, {'command_description.crash_site_airstrike_damage_upgrade_success', player_name, count_level})
            Server.to_discord_bold('*** '..player_name..' has upgraded Airstrike Damage to level '..count_level..' ***')
            item.name_label = {'command_description.crash_site_airstrike_count_name_label', (count_level + 1)}
            item.price = math.floor(math.exp(airstrike_data.count_level ^ 0.8) / 2) * 1000
            item.description = {
                'command_description.crash_site_airstrike_count',
                (count_level + 1),
                count_level,
                count,
                tostring(strikeCost) .. ' poison capsules'
            }
            Retailer.set_item(market_id, item) -- this updates the retailer with the new item values.
        elseif name == 'airstrike_radius' then
            airstrike_data.radius_level = airstrike_data.radius_level + 1
            Toast.toast_all_players(15, {'command_description.crash_site_airstrike_radius_upgrade_success', player_name, radius_level})
            Server.to_discord_bold('*** '..player_name..' has upgraded Airstrike Radius to level '..radius_level..' ***')
            item.name_label = {'command_description.crash_site_airstrike_radius_name_label', (radius_level + 1)}
            item.description = {
                'command_description.crash_site_airstrike_radius',
                (radius_level + 1),
                radius_level,
                radius
            }
            item.price = math.floor(math.exp(airstrike_data.radius_level ^ 0.8) / 2) * 1000
            Retailer.set_item(market_id, item) -- this updates the retailer with the new item values.
        end
    end)

    Command.add('crash-site-restart-abort', {
        description = {'command_description.crash_site_restart_abort'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    }, abort)

    Command.add('abort', {
        description = {'command_description.crash_site_restart_abort'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    }, abort)

    local default_name = config.scenario_name or 'crashsite'
    Command.add('crash-site-restart', {
        description = {'command_description.crash_site_restart'},
        arguments = {'scenario_name'},
        default_values = {scenario_name = default_name},
        required_rank = Ranks.admin,
        allowed_by_server = true
    }, restart)

    Command.add('restart', {
        description = {'command_description.crash_site_restart'},
        arguments = {'scenario_name'},
        default_values = {scenario_name = default_name},
        required_rank = Ranks.guest,
        allowed_by_server = true
    }, restart)

    Command.add('spy', {
        description = {'command_description.crash_site_spy'},
        arguments = {'location'},
        capture_excess_arguments = true,
        required_rank = Ranks.guest,
        allowed_by_server = false
    }, spy)

    Command.add('strike', {
        description = {'command_description.crash_site_airstrike'},
        arguments = {'location'},
        capture_excess_arguments = true,
        required_rank = Ranks.guest,
        allowed_by_server = false
    }, strike)
end

return Public
