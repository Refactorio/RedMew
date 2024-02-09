local Event = require 'utils.event'
local Game = require 'utils.game'
local Color = require 'features.player_colors'
local Item_list = require 'map_gen.maps.april_fools.modules.item_list'
local icebergs = {}

-- Inserters are sometimes randomly rotated when placed by player or bots
-- Complete
function icebergs.rotate_inserter()
    global.rotate_inserter = 0
    local rotate_base_percent = .05
    local max_rand = 100*3

    local inserter_names = {
        'burner-inserter',
        'fast-inserter',
        'filter-inserter',
        'inserter',
        'long-handed-inserter',
        'stack-filter-inserter',
        'stack-inserter'
    }

    local function on_built_inserter(event)
        local rotate_percent
        if global.rotate_inserter == 0 then
            --print('rotate_inserter not enabled')
            return
        else
            rotate_percent = global.rotate_inserter*rotate_base_percent
        end

        local entity = event.created_entity
        if not entity or not entity.valid then
            --print ('entity not valid')
            return
        end

        for i, entity_name in ipairs(inserter_names) do
            if entity.name == entity_name then
                local rand = math.random(0,max_rand)
                if rand <= max_rand*(1 - rotate_percent) then
                    --print('No rotation')
                    return
                elseif rand <= max_rand*(1-2*rotate_percent/3) then
                    --print('Single Rotation')
                    entity.rotate()
                    return
                elseif rand <= max_rand*( 1 - 1*rotate_percent/3) then
                    --print('Double Rotation')
                    entity.rotate()
                    entity.rotate()
                    return
                elseif rand <= max_rand then
                    --print('Reverse Rotation')
                    entity.rotate({reverse = true})
                    return
                end
            end
        end
    end
    Event.add(defines.events.on_robot_built_entity, on_built_inserter)
    Event.add(defines.events.on_built_entity, on_built_inserter)
end

-- when the player rotates an object it is sometimes rotated to a random direction instead.
-- Complete
function icebergs.player_rotate()
    global.player_rotate = 0
    local rotate_base_percent = .05
    local max_rand = 100*3

    Event.add(
        defines.events.on_player_rotated_entity,
        function(event)
            local rotate_percent
            if global.player_rotate == 0 then
                --print('player_rotate not enabled')
                return
            else
                rotate_percent = global.player_rotate*rotate_base_percent
            end
            local entity = event.entity
            if not entity or not entity.valid then
                --print ('entity not valid')
                return
            end
            local rand = math.random(0,max_rand)
            if rand <= max_rand*(1 - rotate_percent) then
                --print('No rotation')
                return
            elseif rand <= max_rand*(1-2*rotate_percent/3) then
                --print('Single Rotation')
                entity.rotate()
                return
            elseif rand <= max_rand*( 1 - 1*rotate_percent/3) then
                --print('Double Rotation')
                entity.rotate()
                entity.rotate()
                return
            elseif rand <= max_rand then
                --print('Reverse Rotation')
                entity.rotate({reverse = true})
                return
            end
        end
    )
end

-- crafting underground belt/pipes will no longer give an even number
-- Complete
function icebergs.craft_pair()
    global.craft_pair = 0
    local base_percent = .01
    local pair_names = {
        'underground-belt',
        'fast-underground-belt',
        'express-underground-belt',
        'pipe-to-ground'
    }

    Event.add(
        defines.events.on_player_crafted_item,
        function(event)
            local extra_percent
            if global.craft_pair == 0 then
                --print('craft_pair not enabled')
                return
            else
                extra_percent = global.craft_pair*base_percent
            end
            for i, entity_name in ipairs(pair_names) do
                if event.item_stack.name == entity_name then
                    local rand = math.random(0,100)
                    if rand >= 100*(1-extra_percent) then
                        if event.player_index == nil then
                            return
                        end
                        local player = Game.get_player_by_index(event.player_index)
                        if not player or not player.valid then
                            return
                        else
                            player.insert {name = event.item_stack.name, count = 1}
                        --print('adding 1 of the item to inventory')
                        end
                    end
                end
            end
        end
    )
end

-- 0.01% chance to spawn another ore (every patch becomes a mixed ore patch)
-- OR Linaori's idea: On placement of a miner change an ore patch at a low chance
-- WIP
function icebergs.randomize_ores()
    global.randomize_ores = 0 --1 for enabled by defualt
    local base_percent = .01
    local max_rand = 1/base_percent
    local ores = {'iron-ore', 'copper-ore','stone', 'coal', 'uranium-ore'}
    local function on_built_miner(event)
        if global.randomize_ores == 0 then
            --print('randomize_ores not enabled')
            return
        else
            local entity = event.created_entity
            if not entity or not entity.valid then
                --print ('entity not valid')
                return
            end
            if entity.name == 'burner-mining-drill' or entity.name == 'electric-mining-drill' then
                local area = entity.bounding_box
                for i = area.left_top.x,area.right_bottom.x do
                    for j = area.left_top.y, area.right_bottom.y do
                        local rand = math.random(1,max_rand)
                        if rand <= global.randomize_ores then
                            local rand_ore = math.random(1,5)
                            local existing_resource = entity.surface.find_entities_filtered{area = {{i -.5,j-.5},{i+.5,j+.5}}, type = "resource"}
                            for k=1, 1, #existing_resource do
                                --print(existing_resource[k])
                                if not existing_resource[k] or not existing_resource[k].valid then
                                    --print('no resource found')
                                    return
                                else
                                    --print('replacing ore')
                                    local ore_amount = existing_resource[k].amount
                                    existing_resource[k].destroy()
                                    if entity.surface.get_tile(i, j).collides_with("ground-tile") then
                                        entity.surface.create_entity({name=ores[rand_ore], amount=ore_amount, position={i,j}})
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    Event.add(defines.events.on_robot_built_entity, on_built_miner)
    Event.add(defines.events.on_built_entity, on_built_miner)
end

--turrets have a 90% chance of being on player force when placed
-- Be sure to adjust ammo count/amount on the enemy turrets below as needed
-- Completed, beware laser turrets, as they have infinite power until destroyed
function icebergs.crazy_turrets()
    global.crazy_turrets = 0
    local base_percent = .05

    local function on_built_turret(event)
        local change_percent
        if global.crazy_turrets == 0 then
            return
        else
            change_percent = global.crazy_turrets*base_percent
        end
        local rand = math.random(0,100)
        if rand > 100*(1-change_percent) then
            local entity = event.created_entity
            if not entity or not entity.valid then
                return
            end
            local pos = entity.position
            if event.player_index == nil then
                return
            end
            local player = Game.get_player_by_index(event.player_index)
            if not player or not player.valid then
                return
            elseif entity.name == 'gun-turret' then
                entity.insert{name = 'firearm-magazine', count = 200}
                entity.clone({position = pos, force = 'enemy'})
                entity.destroy()
            elseif entity.name == 'flamethrower-turret' then
                entity.insert_fluid{name ='crude-oil', amount = 1000}
                entity.clone({position = pos, force = 'enemy'})
                entity.destroy()
            elseif entity.name == 'artillery-turret' then
                entity.insert{name = 'artillery-shell', count = 10}
                entity.clone({position = pos, force = 'enemy'})
                entity.destroy()
            elseif entity.name == 'laser-turret' then
                player.surface.create_entity{name = 'hidden-electric-energy-interface', force = 'enemy', position = pos}
                player.surface.create_entity{name = 'small-electric-pole', force = 'enemy', position = pos}
                entity.clone({position = pos, force = 'enemy'})
                entity.destroy()
            end
        end
    end
    local function remove_enemy_power_on_death(event)
        local entity = event.entity
        if entity.name == 'laser-turret' then
            --print('laser turret destroyed')
            local pos = entity.position
            local surface = entity.surface
            local enemy_power = surface.find_entities_filtered{name = 'hidden-electric-energy-interface', position = pos}
            for i=1, 1, #enemy_power do
                if not enemy_power[i] or not enemy_power[i].valid then
                    return
                else
                    enemy_power[i].destroy()
                end
            end
        end
    end

Event.add(defines.events.on_robot_built_entity, on_built_turret)
Event.add(defines.events.on_built_entity, on_built_turret)
Event.add(defines.events.on_entity_died, remove_enemy_power_on_death)
end

-- golden goose
-- spawn_interval and change_geese_interval should be set to the number of ticks between the event triggering
function icebergs.golden_goose()
    global.golden_goose = 0 -- 1 for enabled by defualt
    local base_geese = 1
    local spawn_interval = 60
    local change_geese_interval = 6000

    Event.add(
        defines.events.on_tick,
        function()
            local rand_goose = {}
            local num_geese = 1

            if #game.connected_players>= 1 then
                if game.tick % change_geese_interval == 0 then
                    if global.golden_goose == 0 then
                        return
                    else
                        num_geese = global.golden_goose * base_geese
                        for j = 1, num_geese do
                            rand_goose[j] = math.random(1,#game.connected_players)
                        end
                    end
                end

                if game.tick % spawn_interval == 0 then
                    if global.golden_goose == 0 then
                        return
                    else
                        for i, goose in ipairs(game.connected_players) do
                            for j = 1, num_geese do
                                if not goose or not goose.valid then
                                    print('golden goose not valid')
                                    return
                                elseif i == rand_goose[j] then
                                    goose.surface.create_entity{name = 'item-on-ground', position = goose.position, stack = {name = 'coin', count = 1}}
                                end
                            end
                        end
                    end
                end
            end
        end
    )
end

--rotten egg, produces pollution. Similar to golden goose
function icebergs.rotten_egg()
    global.rotten_egg = 0 -- 1 for enabled by defualt
    local base_geese = 1
    local spawn_interval = 600
    local change_geese_interval = 6000
    local pollute_amount = 10

    Event.add(
        defines.events.on_tick,
        function()
            local num_geese = 1
            local rand_goose = {}
            if #game.connected_players >= 1 then
                if game.tick % change_geese_interval == 0 then
                    if global.rotten_egg == 0 then
                        return
                    else
                        num_geese = global.rotten_egg * base_geese
                        for j = 1, num_geese do
                            rand_goose[j] = math.random(1,#game.connected_players)
                        end
                    end
                end

                if game.tick % spawn_interval == 0 then
                    if global.rotten_egg == 0 then
                        return
                    else
                        for i, goose in ipairs(game.connected_players) do
                            for j = 1, num_geese do
                                if not goose or not goose.valid then
                                    return
                                elseif i == rand_goose[j] then
                                    goose.surface.pollute(goose.position, pollute_amount*global.rotten_egg)
                                end
                            end
                        end
                    end
                end
            end
        end
    )
end
--Floor is lava, a player that is AFK for allowed_afk_time ticks will be damaged every damage_interval ticks
function icebergs.floor_is_lava()
    global.floor_is_lava = 0 -- 1 for enabled by defualt
    local damage_interval = 60
    local base_damage = 1
    local allowed_afk_time = 120

    Event.add(
        defines.events.on_tick,
        function()
            if #game.connected_players >= 1 then
                if game.tick % damage_interval == 0 then
                    if global.floor_is_lava == 0 then
                        return
                    else
                        for i, player in ipairs(game.connected_players) do
                            if not player or not player.valid then
                                return
                            elseif player.afk_time > allowed_afk_time then
                                if not player.character or not player.character.valid then
                                    return
                                else
                                    player.character.damage(base_damage * global.floor_is_lava, "enemy")
                                end
                            end
                        end
                    end
                end
            end
        end
    )
end

-- Spawns biters of a level scaling with global.alternative_biters on every player that has alt_mode toggles ON
function icebergs.alternative_biters()
    global.alternative_biters = 0 --1 for enabled by defualt
    global.alt_biters_players = {}
    local spawn_interval = 600

    Event.add(
        defines.events.on_tick,
        function()
            local biters ={}
            if #game.connected_players >= 1 then
                if game.tick % spawn_interval == 0 then
                    if global.alternative_biters == 0 then
                        return
                    elseif global.alternative_biters == 1 then
                        biters = {
                            'small-biter'
                        }
                    elseif global.alternative_biters == 2 then
                        biters = {
                            'small-biter',
                            'small-spitter'
                        }
                    elseif global.alternative_biters == 3 then
                        biters = {
                            'small-biter',
                            'small-spitter',
                            'medium-biter',
                        }
                    elseif global.alternative_biters == 4 then
                        biters = {
                            'small-biter',
                            'small-spitter',
                            'medium-biter',
                            'medium-spitter'
                        }
                    elseif global.alternative_biters == 5 then
                        biters = {
                            'small-biter',
                            'small-spitter',
                            'medium-biter',
                            'medium-spitter',
                            'big-biter'
                        }
                    elseif global.alternative_biters == 6 then
                        biters = {
                            'small-biter',
                            'small-spitter',
                            'medium-biter',
                            'medium-spitter',
                            'big-biter',
                            'big-spitter'
                        }
                    elseif global.alternative_biters == 7 then
                        biters = {
                            'small-biter',
                            'small-spitter',
                            'medium-biter',
                            'medium-spitter',
                            'big-biter',
                            'big-spitter',
                            'behemoth-biter'
                        }
                    elseif global.alternative_biters >= 8 then
                        biters = {
                            'small-biter',
                            'small-spitter',
                            'medium-biter',
                            'medium-spitter',
                            'big-biter',
                            'big-spitter',
                            'behemoth-biter',
                            'behemoth-spitter'
                        }
                    end

                    for i, player in ipairs(game.connected_players) do
                        if not player or not player.valid then
                            return
                        elseif global.alt_biters_players[player.index] == 1 then
                            local rand_biter = math.random(1,#biters)
                            local pos = {player.position.x + 1, player.position.y + 1}
                            player.surface.create_entity{name = biters[rand_biter], position = pos, force = "enemy"}
                        end
                    end
                end
            end
        end
    )
-- toggle alt-biters for the player when alt-mode is toggled
    Event.add(
        defines.events.on_player_toggled_alt_mode,
        function(event)
            local player_index = event.player_index
            if player_index == nil then
                return
            elseif global.alt_biters_players[player_index] == 1 then
                global.alt_biters_players[player_index] = 0
            else
                global.alt_biters_players[player_index]  = 1
            end
        end
    )
-- turn off alt-mode on game join, and set alt-biters to off
    Event.add(
        defines.events.on_player_joined_game,
        function(event)
            local player_index = event.player_index
            if player_index == nil then
                return
            else
                game.players[player_index].game_view_settings.show_entity_info = false
                global.alt_biters_players[player_index] = 0
            end
        end
    )
end

-- Increases research costs and enables marathon mode
function icebergs.marathon()
    global.marathon = 0
    global.enabled_marathon = 0
    Event.add(
        defines.events.on_research_started,
        function()
            if global.marathon == global.enabled_marathon then
                return
            end
            if global.marathon == 1 then
                game.difficulty_settings.technology_difficulty = 1
            end
            if global.marathon == 2 then
                game.difficulty_settings.recipe_difficulty = 1
            end
            if global.marathon > global.enabled_marathon then
                game.difficulty_settings.technology_price_multiplier= global.marathon
                global.enabled_marathon = global.marathon
            end
        end
    )
end

function icebergs.crazy_toolbar()
    global.crazy_toolbar = 0
    local change_interval = 120
    local base_chance = .05

    Event.add(
        defines.events.on_tick,
        function()
            local crazy_chance
            if #game.connected_players >= 1 then
                if game.tick % change_interval == 0 then
                    if global.crazy_toolbar == 0 then
                    --print('rotten_egg not enabled')
                        return
                    else
                        crazy_chance = base_chance * global.crazy_toolbar
                        for i, player in ipairs(game.connected_players) do
                            local rand = math.random(1,100)
                            if not player or not player.valid then
                                return
                            elseif rand >100 * (1-crazy_chance) then
                                for j=1, global.crazy_toolbar do
                                    local rand_item = Item_list[math.random(1,#Item_list)]
                                    local rand_position = math.random(1,100)
                                    player.set_quick_bar_slot(rand_position, rand_item)
                                end
                            end
                        end
                    end
                end
            end
        end
    )
end
-- Changes player color with every message
function icebergs.crazy_colors()
    Event.add(
        defines.events.on_console_chat,
        function(event)
            if event.player_index == nil then
                return
            else
                Color.set_random_color(game.players[event.player_index])
            end
        end
    )
end

return icebergs
