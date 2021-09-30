local Command = require 'utils.command'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Server = require 'features.server'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Retailer = require 'features.retailer'
local Ranks = require 'resources.ranks'
local Core = require 'utils.core'
local Color = require 'resources.color_presets'
local Toast = require 'features.gui.toast'
local Discord = require 'resources.discord'
local ScoreTracker = require 'utils.score_tracker'
local PlayerStats = require 'features.player_stats'
local Restart = require 'features.restart_command'
local set_timeout_in_ticks = Task.set_timeout_in_ticks

-- Use these settings for live
local map_promotion_channel = Discord.channel_names.map_promotion
local crash_site_role_mention = Discord.role_mentions.crash_site
-- Use these settings for testing
-- local map_promotion_channel = Discord.channel_names.bot_playground
-- local crash_site_role_mention = Discord.role_mentions.test

local Public = {}

function Public.control(config)
    Restart.set_start_game_data({type = Restart.game_types.scenario, name = config.scenario_name or 'crashsite'})

    local airstrike_data = {radius_level = 1, count_level = 1}
    local barrage_data = {radius_level = 1, count_level = 1}

    Global.register({airstrike_data = airstrike_data, barrage_data = barrage_data}, function(tbl)
        airstrike_data = tbl.airstrike_data
        barrage_data = tbl.barrage_data
    end)

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

    -- Scenario display name for printing new scenario to discord
    local scenario_display_name = {
        ['crashsite'] = 'Crash Site',
        ['crashsite-world'] = 'Crash Site World Map',
        ['crashsite-desert'] = 'Crash Site Desert',
        ['crashsite-arrakis'] = 'Crash Site Arrakis',
        ['crashsite-venice'] = 'Crash Site Venice',
        ['crashsite-manhattan'] = 'Crash Site Manhattan',
        ['crashsite-UK'] = 'Crash Site United Kingdom'
    }

    local function can_restart(player)
        if player.admin then
            return true
        end

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

    local function restart_callback()
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
                coins_earned = ScoreTracker.get_for_player(p.index, PlayerStats.coins_earned_name),
                entities_built = ScoreTracker.get_for_player(p.index, PlayerStats.player_entities_built_name),
                entities_crafted = ScoreTracker.get_for_player(p.index, PlayerStats.player_items_crafted_name),
                fish_eaten = ScoreTracker.get_for_player(p.index, PlayerStats.player_fish_eaten_name),
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
            entities_built = ScoreTracker.get_for_global(PlayerStats.built_by_players_name),
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
            ['coins_earned'] = {value = 0, player = ""},
            ['fish_eaten'] = {value = 0, player = ""}
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
            if v.coins_earned > awards.coins_earned.value then
                awards.coins_earned.value = v.coins_earned
                awards.coins_earned.player = v.name
            end
            if v.fish_eaten > awards.fish_eaten.value then
                awards.fish_eaten.value = v.fish_eaten
                awards.fish_eaten.player = v.name
            end
        end

        local time_string = Core.format_time(game.ticks_played)
        if statistics.enemy_entities < 1000 then
            Server.to_discord_named_embed(map_promotion_channel, 'Crash Site map won!\\n\\n'
            .. 'Statistics:\\n'
            .. 'Map time: '..time_string..'\\n'
            .. 'Total kills: '..statistics.biters_killed..'\\n'
            .. 'Biters remaining on map: '..statistics.enemy_entities..'\\n'
            .. 'Players: '..statistics.total_players..'\\n'
            .. 'Total entities built: '..statistics.entities_built..'\\n\\n'
            .. 'Awards:\\n'
            .. 'Most kills overall: '..awards.total_kills.player..' ('..awards.total_kills.value..')\\n'
            .. 'Most biters/spitters killed: '..awards.units_killed.player..' ('..awards.units_killed.value..')\\n'
            .. 'Most spawners killed: '..awards.spawners_killed.player..' ('..awards.spawners_killed.value..')\\n'
            .. 'Most worms killed: '..awards.worms_killed.player..' ('..awards.worms_killed.value..')\\n'
            .. 'Most deaths: '..awards.player_deaths.player..' ('..awards.player_deaths.value..')\\n'
            .. 'Most items crafted: '..awards.entities_crafted.player..' ('..awards.entities_crafted.value..')\\n'
            .. 'Most entities built: '..awards.entities_built.player..' ('..awards.entities_built.value..')\\n'
            .. 'Most time played: '..awards.time_played.player..' ('..Core.format_time(awards.time_played.value)..')\\n'
            .. 'Furthest walked: '..awards.distance_walked.player..' ('..math.floor(awards.distance_walked.value)..')\\n'
            .. 'Most coins earned: '..awards.coins_earned.player..' ('..awards.coins_earned.value..')\\n'
            .. 'Seafood lover: '..awards.fish_eaten.player..' ('..awards.fish_eaten.value..' fish eaten)\\n'
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

        local start_game_data = Restart.get_start_game_data()
        local new_map_name = start_game_data.name

        Server.to_discord_named_raw(map_promotion_channel,
            crash_site_role_mention .. ' **' .. (scenario_display_name[config.scenario_name] or config.scenario_name) .. ' has just restarted!!\\n'
                .. 'Next map: ' .. (scenario_display_name[new_map_name] or new_map_name) .. '**')

        Server.set_data('crash_site_data', tostring(end_epoch), statistics) -- Store the table, with end_epoch as the key
    end

    Restart.register(can_restart, restart_callback)

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
        local ypos = coords[i + 1]
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
                game.print({'command_description.crash_site_spy_success', player_name, spy_cost, xpos, ypos},
                    Color.success)
                inv.remove({name = "coin", count = spy_cost})
            end

            -- move to the next set of coordinates
            i = i + 2
            xpos = coords[i]
            ypos = coords[i + 1]
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
            icon = {type = 'item', name = data.item},
            position = {xpos, ypos},
            text = player.name
        })
        set_timeout_in_ticks(60 * 30, map_chart_tag_clear_callback, tag) -- To clear the tag after 30 seconds
    end)

    local function render_crosshair(data)
        local red = {r = 0.5, g = 0, b = 0, a = 1}
        local timeout = 20 * 60
        local line_width = 5
        local line_length = 1.8
        local s = data.player.surface
        local f = data.player.force
        rendering.draw_circle {
            color = red,
            radius = 1.2,
            width = line_width,
            filled = false,
            target = data.position,
            surface = s,
            time_to_live = timeout,
            forces = {f}
        }
        rendering.draw_line {
            color = red,
            width = line_width,
            from = {data.position.x - line_length, data.position.y},
            to = {data.position.x + line_length, data.position.y},
            surface = s,
            time_to_live = timeout,
            forces = {f}
        }
        rendering.draw_line {
            color = red,
            width = line_width,
            from = {data.position.x, data.position.y - line_length},
            to = {data.position.x, data.position.y + line_length},
            surface = s,
            time_to_live = timeout,
            forces = {f}
        }
        s.create_entity {
            name = "flying-text",
            position = {data.position.x + 3, data.position.y},
            text = "[item=" .. data.item .. "] " .. data.player.name,
            speed = 1/180,
            time_to_live = 60*5,
            color = {r = 1, g = 1, b = 1, a = 1}
        }
    end

    local function render_radius(data)
        local timeout = 20 * 60
        rendering.draw_circle {
            color = data.color,
            radius = data.radius,
            filled = true,
            target = data.position,
            surface = data.player.surface,
            time_to_live = timeout,
            players = {data.player}
        }
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
        local entities = s.find_entities_filtered {position = {2.5, -7.5}, type = 'logistic-container', limit = 1}
        local dropbox = entities[1]

        if dropbox == nil then
            player.print("Chest not found. Replace it here: [gps=2.5,-7.5,redmew]")
            return
        end

        -- process each set of coordinates with a 20 strike limit
        local i = 1
        local xpos = coords[i]
        local ypos = coords[i + 1]
        -- This while loop lets players add multiple GPS coordinates to the /strike command arguments to strike more than one place at once. Up to a maximum of 20
        while xpos ~= nil and ypos ~= nil and i < 20 do
            -- Check the contents of the chest by spawn for enough poison capsules to use as payment
            local inv = dropbox.get_inventory(defines.inventory.chest)
            local capCount = inv.get_item_count("poison-capsule")

            if capCount < strikeCost then
                player.print({
                    'command_description.crash_site_airstrike_insufficient_currency_error',
                    strikeCost - capCount
                }, Color.fail)
                return
            end

            inv.remove({name = "poison-capsule", count = strikeCost})
            player.force.chart(s, {{xpos - 32, ypos - 32}, {xpos + 32, ypos + 32}})

            for j = 1, count do
                set_timeout_in_ticks(30 * j, spawn_poison_callback,
                    {s = s, xpos = xpos, ypos = ypos, count = count, r = radius})
                set_timeout_in_ticks(60 * j, chart_area_callback, {player = player, xpos = xpos, ypos = ypos})
            end
            render_crosshair({position = {x = xpos, y = ypos}, player = player, item = "poison-capsule"})
            render_radius({position = {x = xpos, y = ypos}, player = player, radius = radius+10, color = {r = 0, g = 0, b = 0.1, a = 0.1}})
            set_timeout_in_ticks(60, map_chart_tag_place_callback, {player = player, xpos = xpos, ypos = ypos, item = 'poison-capsule'})

            -- move to the next set of coordinates
            i = i + 2
            xpos = coords[i]
            ypos = coords[i + 1]
        end
    end

    local spawn_rocket_callback = Token.register(function(data)
        data.s.create_entity {
            name = "explosive-rocket",
            position = {0, 0},
            target = {data.xpos, data.ypos},
            speed = 10,
            max_range = 100000
        }
    end)

    local function barrage(args, player)
        local s = player.surface
        local location_string = args.location
        local coords = {}

        local radius_level = barrage_data.radius_level -- max radius of the barrage area
        local count_level = barrage_data.count_level -- the number of rockets launched at the enemy

        if count_level == 1 then
            player.print({'command_description.crash_site_barrage_not_researched'}, Color.fail)
            return
        end

        local radius = 25 + (radius_level * 5)
        local count = count_level * 6

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
        local entities = s.find_entities_filtered {position = {2.5, -1.5}, type = 'logistic-container', limit = 1}
        local dropbox = entities[1]

        if dropbox == nil then
            player.print("Chest not found. Replace it here: [gps=2.5,-1.5,redmew]")
            return
        end

        -- process each set of coordinates from the arguments with a 20 strike limit
        local i = 1
        local xpos = coords[i]
        local ypos = coords[i + 1]
        -- This while loop lets players add multiple GPS coordinates to the /strike command arguments to strike more than one place at once. Up to a maximum of 20
        while xpos ~= nil and ypos ~= nil and i < 20 do
            -- Check the contents of the chest by spawn for enough rockets to use as payment
            local inv = dropbox.get_inventory(defines.inventory.chest)
            local capCount = inv.get_item_count("explosive-rocket")

            if capCount < count then
                player.print({
                    'command_description.crash_site_barrage_insufficient_currency_error',
                    count - capCount
                }, Color.fail)
                return
            end

            local nests = player.surface.find_entities_filtered {
                position = {xpos, ypos},
                radius = radius,
                force = "enemy",
                type = "unit-spawner"
            }

            local nest_count = #nests
            inv.remove({name = "explosive-rocket", count = count})
            player.force.chart(s, {{xpos - 32, ypos - 32}, {xpos + 32, ypos + 32}})
            if nest_count == 0 then
                player.print({'command_description.crash_site_barrage_no_nests',}, Color.fail)
                return
            end

            -- draw radius
            set_timeout_in_ticks(60, map_chart_tag_place_callback, {player = player, xpos = xpos, ypos = ypos, item = 'explosive-rocket'})
            render_radius({position = {x = xpos, y = ypos}, player = player, radius = radius, color = {r = 0.1, g = 0, b = 0, a = 0.1}})
            for _, nest in pairs(nests) do
                render_crosshair({position = {x = nest.position.x, y = nest.position.y}, player = player, item = "explosive-rocket"})
            end

            for j = 1, count do
                set_timeout_in_ticks(60 * j + math.random(0, 30), spawn_rocket_callback, {s = s, xpos = nests[(j%nest_count)+1].position.x, ypos = nests[(j%nest_count)+1].position.y})
                set_timeout_in_ticks(60 * j, chart_area_callback, {player = player, xpos = xpos, ypos = ypos})
            end

            -- move to the next set of coordinates
            i = i + 2
            xpos = coords[i]
            ypos = coords[i + 1]
        end
    end

    Event.add(Retailer.events.on_market_purchase, function(event)

        local market_id = event.group_name
        local group_label = Retailer.get_market_group_label(market_id)
        if group_label ~= 'Spawn' then
            return
        end

        local item = event.item
        if item.type ~= 'airstrike' and item.type~= 'barrage' then
            return
        end

        if item.type == 'airstrike' then
            local radius_level = airstrike_data.radius_level -- max radius of the strike area
            local count_level = airstrike_data.count_level -- the number of poison capsules launched at the enemy
            local radius = 5 + (radius_level * 3)
            local count = (count_level - 1) * 5 + 3
            local strikeCost = count * 4

            local name = item.name
            local player_name = event.player.name
            if name == 'airstrike_damage' then
                airstrike_data.count_level = airstrike_data.count_level + 1

                Toast.toast_all_players(15, {
                    'command_description.crash_site_airstrike_damage_upgrade_success',
                    player_name,
                    count_level
                })
                Server.to_discord_bold('*** ' .. player_name .. ' has upgraded Airstrike Damage to level ' .. count_level
                                        .. ' ***')
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
                Toast.toast_all_players(15, {
                    'command_description.crash_site_airstrike_radius_upgrade_success',
                    player_name,
                    radius_level
                })
                Server.to_discord_bold('*** ' .. player_name .. ' has upgraded Airstrike Radius to level ' .. radius_level
                                        .. ' ***')
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
        end
        if item.type == 'barrage' then
            local radius_level = barrage_data.radius_level -- max radius of the strike area
            local count_level = barrage_data.count_level -- the number of poison capsules launched at the enemy
            local radius = 5 + (radius_level * 3)
            local count = (count_level - 1) * 5 + 3
            local strikeCost = count * 4

            local name = item.name
            local player_name = event.player.name
            if name == 'barrage_damage' then
                barrage_data.count_level = barrage_data.count_level + 1

                Toast.toast_all_players(15, {
                    'command_description.crash_site_barrage_damage_upgrade_success',
                    player_name,
                    count_level
                })
                Server.to_discord_bold('*** ' .. player_name .. ' has upgraded Rocket Barrage Damage to level ' .. count_level
                                        .. ' ***')
                item.name_label = {'command_description.crash_site_barrage_count_name_label', (count_level + 1)}
                item.price = math.floor(math.exp(barrage_data.count_level ^ 0.8) / 2) * 1000
                item.description = {
                    'command_description.crash_site_barrage_count',
                    (count_level + 1),
                    count_level,
                    count,
                    tostring(strikeCost) .. ' explosive rockets'
                }
                Retailer.set_item(market_id, item) -- this updates the retailer with the new item values.
            elseif name == 'barrage_radius' then
                barrage_data.radius_level = barrage_data.radius_level + 1
                Toast.toast_all_players(15, {
                    'command_description.crash_site_barrage_radius_upgrade_success',
                    player_name,
                    radius_level
                })
                Server.to_discord_bold('*** ' .. player_name .. ' has upgraded Rocket Barrage Radius to level ' .. radius_level
                                        .. ' ***')
                item.name_label = {'command_description.crash_site_barrage_radius_name_label', (radius_level + 1)}
                item.description = {
                    'command_description.crash_site_barrage_radius',
                    (radius_level + 1),
                    radius_level,
                    radius
                }
                item.price = math.floor(math.exp(barrage_data.radius_level ^ 0.8) / 2) * 1000
                Retailer.set_item(market_id, item) -- this updates the retailer with the new item values.
            end
        end
    end)

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

    Command.add('barrage', {
        description = {'command_description.crash_site_barrage'},
        arguments = {'location'},
        capture_excess_arguments = true,
        required_rank = Ranks.guest,
        allowed_by_server = false
    }, barrage)
end

return Public
