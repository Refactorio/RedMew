local Event = require 'utils.event'
local Generate = require 'map_gen.shared.generate'
local Global = require 'utils.global'
local Queue = require 'utils.queue'
local AlienEvolutionProgress = require 'utils.alien_evolution_progress'
local RS = require 'map_gen.shared.redmew_surface'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Server = require 'features.server'

return function(config, shared_globals)
    local recent_chunks = Queue.new() -- Keeps track of recently revealed chunks
    local recent_chunks_max = config.recent_chunks_max or 10 -- Maximum number of chunks to track
    local ticks_between_waves = config.ticks_between_waves or 60 * 30
    local enemy_factor = config.enemy_factor or 5
    local max_enemies_per_wave_per_chunk = config.max_enemies_per_wave_per_chunk or 60

    local win_data = {
        evolution_rocket_maxed = -1,
        extra_rockets = config.extra_rockets or 100
    }

    shared_globals.biters_disabled = false

    _G.rocket_launched_win_data = win_data

    Global.register(
        {recent_chunks = recent_chunks, win_data = win_data},
        function(tbl)
            recent_chunks = tbl.recent_chunks
            win_data = tbl.win_data
        end
    )

    local function give_command(group, data)
        local target = data.target

        if target and target.valid then
            local command = {
                type = defines.command.attack,
                target = target,
                distraction = defines.distraction.by_damage
            }
            group.set_command(command)
            group.start_moving()
        else
            local command = {
                type = defines.command.attack_area,
                destination = data.position,
                radius = 32,
                distraction = defines.distraction.by_damage
            }

            local members = group.members
            for i = 1, #members do
                local entitiy = members[i]
                entitiy.set_command(command)
            end
        end
    end

    local do_waves
    local do_wave

    do_waves =
        Token.register(
        function(data)
            Task.queue_task(do_wave, data, 10)
        end
    )

    do_wave =
        Token.register(
        function(data)
            if shared_globals.biters_disabled then
                return false
            end

            local wave = data.wave
            local last_wave = data.last_wave
            --game.print('wave: ' .. wave .. '/' .. last_wave)

            local chunk_index = data.chunk_index
            local chunk = data.chunks[chunk_index]

            if not chunk then
                data.wave = wave + 1
                data.chunk_index = 1
                Task.set_timeout_in_ticks(ticks_between_waves, do_waves, data)
                return false
            end

            local spawner = data.spawner

            local aliens = AlienEvolutionProgress.get_aliens(spawner, game.forces.enemy.evolution_factor)

            local left_top = chunk.area.left_top
            local center = {left_top.x + 16, left_top.y + 16}
            local surface = chunk.surface
            local find_non_colliding_position = surface.find_non_colliding_position
            local create_entity = surface.create_entity

            local group = surface.create_unit_group {position = center}
            local add_member = group.add_member

            for name, count in pairs(aliens) do
                for i = 1, count do
                    local pos = find_non_colliding_position(name, center, 32, 1)
                    if pos then
                        local e = {name = name, position = pos, force = 'enemy', center = center, radius = 16, 1}
                        local ent = create_entity(e)

                        add_member(ent)
                    end
                end
            end

            give_command(group, data)

            if chunk_index < recent_chunks_max then
                data.chunk_index = chunk_index + 1
                return true
            end

            if wave < last_wave then
                data.wave = wave + 1
                data.chunk_index = 1
                Task.set_timeout_in_ticks(ticks_between_waves, do_waves, data)
            end

            return false
        end
    )

    local function start_waves(event)
        local num_enemies = enemy_factor * game.forces.player.get_item_launched('satellite')
        local number_of_waves = math.ceil(num_enemies / max_enemies_per_wave_per_chunk)
        local num_enemies_per_wave_per_chunk = math.ceil(num_enemies / number_of_waves)

        local target = event.rocket_silo
        local position
        if target and target.valid then
            position = target.position
        else
            position = {0, 0}
        end

        local data = {
            spawner = AlienEvolutionProgress.create_spawner_request(num_enemies_per_wave_per_chunk),
            wave = 1,
            last_wave = number_of_waves,
            chunk_index = 1,
            chunks = Queue.to_array(recent_chunks),
            target = target,
            position = position
        }

        Task.set_timeout_in_ticks(1, do_waves, data)

        game.print('Warning incomming biter attack! Number of waves: ' .. number_of_waves)
    end

    local function rocket_launched(event)
        local entity = event.rocket

        if not entity or not entity.valid or not entity.force == 'player' then
            return
        end

        local inventory = entity.get_inventory(defines.inventory.rocket)
        if not inventory or not inventory.valid then
            return
        end

        local satellite_count = game.forces.player.get_item_launched('satellite')
        if satellite_count == 0 then
            return
        end

        if shared_globals.biters_disabled then
            return
        end

        -- Increase enemy_evolution
        local current_evolution = game.forces.enemy.evolution_factor

        if (satellite_count % 5) == 0 and win_data.evolution_rocket_maxed == -1 then
            local message =
                'Continued launching of satellites has angered the local biter population, evolution increasing...'
            game.print(message)
            Server.to_discord_bold(message)

            current_evolution = current_evolution + 0.05
            game.forces.enemy.evolution_factor = current_evolution
        end

        if current_evolution < 1 then
            start_waves(event)
            return
        end

        if win_data.evolution_rocket_maxed == -1 then
            win_data.evolution_rocket_maxed = satellite_count
        end

        local remaining_satellites = win_data.evolution_rocket_maxed + win_data.extra_rockets - satellite_count
        if remaining_satellites > 0 then
            local message =
                'Biters at maximum evolution! Protect the base for an additional ' ..
                remaining_satellites .. ' rockets to wipe them out forever.'
            game.print(message)
            Server.to_discord_bold(message)

            start_waves(event)
            return
        end

        local win_message = 'Congratulations! Biters have been wiped from the map!'
        game.print(win_message)
        Server.to_discord_bold(win_message)

        shared_globals.biters_disabled = true

        for key, enemy_entity in pairs(RS.get_surface().find_entities_filtered({force = 'enemy'})) do
            enemy_entity.destroy()
        end
    end

    local function chunk_unlocked(chunk)
        Queue.push(recent_chunks, chunk)

        while Queue.size(recent_chunks) > recent_chunks_max do
            Queue.pop(recent_chunks)
        end
    end

    Event.add(defines.events.on_rocket_launched, rocket_launched)
    Event.add(Generate.events.on_chunk_generated, chunk_unlocked)
end
