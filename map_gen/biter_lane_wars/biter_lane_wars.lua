--[[
    TO DO:
    - Implement game state logic. Lobby, when all players are spectator team. Playing, players split into two teams.
    - Update market_items.lua to implement a table of items which we can iterate through when creating the markets for each team
    - Small GUI element for wave number and time remaining to next wave
    - Decide on GUI requirements for scoring. What do we want to show? Just income per team?
    - Code for creating the teams when leaving lobby game state and starting playing game state
    - Table structure to store creeps bought for each team. Used to calculate waves and income
    - Fix on_tick event function as per comments from Valansch on previous commit
    - Implement Hydra for forces other than enemy force since for this map we have 2 enemy forces. Turn it on based on retailer event.
    - Implement biters dropping coins upon death based on values in alien_coin_modifiers() in config.lua. Values must be modifiable per team
]]--

--- This is the main file to regulate the gameplay loop.

-- dependencies
require 'utils.table'
local BLW = global.map.blw
local teams = BLW.teams
local Event = require 'utils.event'

-- localised functions
local format = 'string.format'
local random = math.random

Event.add(Retailer.events.on_market_purchase, function (event)
    -- Below is lin's working example
    --event.player.print(format('You\'ve bought %d of %s, costing a total of %d', event.count, event.item.name, event.item.price * event.count))

    -- Below are Jay's added examples of actions we need to perform. Not currently working/tested.
    -- CREEP EVENTS
        if event.item.name == "small-biter" then
            -- incrememnt team X small biter wave count
            --event.player.force.print(format('One small biter purchased, your team\'s income increased %d coins per wave', table_of_something.variable_containing_income_per_biter))
        elseif  event.item.name == "medium-biter" then
            -- incrememnt team X medium biter wave count
        elseif event.item.name == "big-biter" then
        elseif event.item.name == "behemoth-biter" then
        elseif event.item.name == "small-spitter" then
        elseif event.item.name == "medium-spitter" then
        elseif event.item.name == "big-spitter" then
        elseif event.item.name == "behemoth-spitter" then
        elseif event.item.name == "big-biter" then

    -- TOME EVENTS
        elseif event.item.name == "hydra" then
            -- check the team of player who purchased
            -- enable low chance hydra mode for opposing team
            -- disable item in market for purchasing team
        elseif event.item.name == "hydra-chance" then
            -- check the team of player who purchased
            -- modify opposing team's hydra spawn chances
            -- increase price in market by 50%
        elseif event.item.name == "movement-speed" then
            event.player.force.character_running_speed_modifier=event.player.force.character_running_speed_modifier + 0.1
        elseif event.item.name == "kill-all" then
            event.player.force.print(format('%s purchased %s, you can relax for the rest of this wave', event.player.name, event.item.name_label))
            if event.player.force == "team_1_players" then
                game.forces["team_1_creeps"].kill_all_units()
            elseif event.player.force == "team_2_players" then
                game.forces["team_2_creeps"].kill_all_units()
            end
        elseif event.item.name == "loot-increase" then
            -- increase the amount of coins that biters drop when you kill them
        elseif event.item.name == "reveal" then
            -- reveal enemy teams so the buyer can get an idea of what tactics they're using
            event.player.force.print(format('%s purchased launched a spy satellite! Enemies revealed for 30 seconds.', event.player.name))
            -- Need a less goofy message
        end
end)


local modifiers = config.alien_coin_modifiers
local alien_coin_drop_chance = config.alien_coin_drop_chance

Event.add(defines.events.on_entity_died, function (event)
    -- OVERVIEW: Manages:
        -- Creep deaths (for coin drops)
        -- Player deaths (for respawn delay increase)
        -- Team furnace deaths (for scenario victory condition)

    local entity = event.entity
    local force = entity.force
    if force.name ~= 'team_1_creeps' or force.name ~= 'team_2_creeps' then
        -- This is the random coin drop code from Diggy
        if random() > alien_coin_drop_chance then
            return
        end

        local modifier = modifiers[entity.name] or 1
        local evolution_multiplier = force.evolution_factor
        local count = random(
            ceil(2 * evolution_multiplier * modifier),
            ceil(5 * evolution_multiplier * modifier)
        )

        local coin = entity.surface.create_entity({
            name = 'item-on-ground',
            position = entity.position,
            stack = {name = 'coin', count = count}
        })

        if coin and coin.valid then
            coin.to_be_looted = true
        end
    end

    -- Update the player respawn timer upon death
    if force.name ~= 'team_1_players' or force.name ~= 'team_2_players' then
        -- Look up player respawn timer
        -- Increment
        -- Make sure they respawn with all of their items
        -- Print a message about the death to all teams, to give an indication that the other force is struggling?
    end

    if entity.name ~= 'electric-furnace' then
        -- game over
        -- change game state, teleport players to lobby island and start over
    end
end)

local function on_tick(Event)
    local game_tick = game.tick
    local wave_duration_secs = 60 --in seconds
    local wave_duration_ticks = wave_duration_secs * 60
    local surface = game.surfaces.nauvis

    --if game_tick % 60 == 49 then -- I don't know why I chose these tick multiples. Do I have to do different stuff on different ticks to avoid messing stuff up?
        -- Update the clock gui once per second
    --end

    -- WAVE EVENTS
    if game_tick % wave_duration_ticks == 50 then
        -- OVERVIEW
        -- Update the GUI with the wavenumber
        -- Print a warning that the wave has started
        -- Spawn a group of biters for each team and send the biters towards the players
        -- Give each player on each team their income in coins


        wave_number = wave_number + 1
        game.print('Wave ' .. wave_number .. ' is starting. Prepare yourselves!')
        -- Update the GUI with the wave number

        -- For each team
        for _, team in pairs(table_of_teams) do
            -- For each biter type
            --for _, biter in pairs(table_of_biters_purchased) do
                -- For each biter, find a non-colliding position
                -- the 'small-biter' needs changing to the field in table_of_biters_purchased once the table has been set up
                -- the spawn position will need to be updated per team
                for _ = 1, 20 do
                    local p = surface.find_non_colliding_position('small-biter', {-60,0}, 30, 1)
                    if p then
                        surface.create_entity {name = 'small-biter', position={-220,0}}
                    end
                end
            --end

            -- Find the new biters in an area around the spawn area
            -- Set them into an attack force and send them towards the player spawn
            -- Give each team member their gold income
        end
    end
end

local function on_player_joined_game(Event)
    -- if in list of registered players, set force
    -- else set to spectator so they can wait until the next round or join a team mid-round if a player drops out?
    -- We haven't yet decided the logic that decides how to handle game leavers or people that join in mid-game.
end
