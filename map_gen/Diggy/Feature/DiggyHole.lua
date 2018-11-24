--[[-- info
    Provides the ability to "mine" through out-of-map tiles by destroying or
    mining rocks next to it.
]]

-- dependencies
local Event = require 'utils.event'
local Global = require 'utils.global'
local Scanner = require 'map_gen.Diggy.Scanner'
local Template = require 'map_gen.Diggy.Template'
local ScoreTable = require 'map_gen.Diggy.ScoreTable'
local Debug = require 'map_gen.Diggy.Debug'
local CreateParticles = require 'features.create_particles'
local insert = table.insert
local random = math.random
local raise_event = script.raise_event

-- todo remove this dependency
local ResourceConfig = require 'map_gen.Diggy.Config'.features.ScatteredResources

local Perlin = require 'map_gen.shared.perlin_noise'
local Simplex = require 'map_gen.shared.simplex_noise'

-- this
local DiggyHole = {}

-- keeps track of the amount of times per player when they mined with a full inventory in a row
local full_inventory_mining_cache = {}

-- keeps track of the buffs for the bot mining mining_efficiency
local robot_mining = {
    damage = 0,
    active_modifier = 0,
    research_modifier = 0,
}

Global.register({
    full_inventory_mining_cache = full_inventory_mining_cache,
    bot_mining_damage = robot_mining,
}, function (tbl)
    full_inventory_mining_cache = tbl.full_inventory_mining_cache
    robot_mining = tbl.bot_mining_damage
end)

local function update_robot_mining_damage()
    -- remove the current buff
    local old_modifier = robot_mining.damage - robot_mining.active_modifier

    -- update the active modifier
    robot_mining.active_modifier = robot_mining.research_modifier

    -- add the new active modifier to the non-buffed modifier
    robot_mining.damage = old_modifier + robot_mining.active_modifier

    ScoreTable.set('Robot mining damage', robot_mining.damage)
end

---Triggers a diggy diggy hole for a given sand-rock-big or rock-huge.
---@param entity LuaEntity
local function diggy_hole(entity)
    local tiles = {}
    local rocks = {}
    local surface = entity.surface
    local position = entity.position
    local x = position.x
    local y = position.y

    local out_of_map_found = Scanner.scan_around_position(surface, position, 'out-of-map');
    local distance = ResourceConfig.distance(x, y)

    -- source of noise for resource generation
    -- index determines offset
    -- '-1' is reserved for cluster mode
    -- compound clusters use as many indexes as needed > 1
    local base_seed
    local function seeded_noise(surface, x, y, index, sources)
        base_seed = base_seed or surface.map_gen_settings.seed + surface.index + 4000
        local noise = 0
        for _, settings in ipairs(sources) do
            settings.type = settings.type or 'perlin'
            settings.offset = settings.offset or 0
            if settings.type == 'zero' then
                noise = noise + 0
            elseif settings.type == 'one' then
                noise = noise + settings.weight * 1
            elseif settings.type == 'perlin' then
                noise = noise + settings.weight * Perlin.noise(x/settings.variance, y/settings.variance,
                            base_seed + 2000*index + settings.offset)
            elseif settings.type == 'simplex' then
                noise = noise + settings.weight * Simplex.d2(x/settings.variance, y/settings.variance,
                            base_seed + 2000*index + settings.offset)
            else
                Debug.print('noise type \'' .. settings.type .. '\' not recognized')
            end

        end
        return noise
    end

    -- global config values
    local resource_richness_weights = ResourceConfig.resource_richness_weights
    local resource_richness_weights_sum = 0
    for _, weight in pairs(resource_richness_weights) do
        resource_richness_weights_sum = resource_richness_weights_sum + weight
    end

    local s_resource_weights = ResourceConfig.scattered_resource_weights
    local s_resource_weights_sum = 0
    for _, weight in pairs(s_resource_weights) do
        s_resource_weights_sum = s_resource_weights_sum + weight
    end

    -- compound cluster spawning
    local c_mode = ResourceConfig.cluster_mode
--    local c_clusters = Config.features.ScatteredResources.clusters
    local c_clusters = require(ResourceConfig.cluster_file_location)
    if ('table' ~= type(c_clusters)) then
        error('cluster_file_location invalid')
    end

    local c_count = 0
    for _, cluster in ipairs(c_clusters) do
        c_count = c_count + 1
        cluster.weights_sum = 0
        for _, weight in pairs(cluster.weights) do
            cluster.weights_sum = cluster.weights_sum + weight
        end
    end

    local function spawn_cluster_resource(surface, x, y, cluster_index, cluster)
        for name, weight in pairs(cluster.weights) do
            if name == 'skip' then return false end
        end
        return true
    end

        local huge_rock_inserted = false
    for _, position in pairs(out_of_map_found) do
        insert(tiles, {name = 'dirt-' .. random(1, 7), position = position})


        if c_mode then
            for index,cluster in ipairs(c_clusters) do
                if distance >= cluster.min_distance and cluster.noise_settings.type ~= 'skip' then
                    if cluster.noise_settings.type == "connected_tendril" then
                        local noise = seeded_noise(surface, x, y, index, cluster.noise_settings.sources)
                        if -1 * cluster.noise_settings.threshold < noise and noise < cluster.noise_settings.threshold then
                            if spawn_cluster_resource(surface, x, y, index, cluster) then
                                insert(rocks, {name = 'rock-huge', position = position})
                                huge_rock_inserted = true
                            end
                        end
                    elseif cluster.noise_settings.type == "fragmented_tendril" then
                        local noise1 = seeded_noise(surface, x, y, index, cluster.noise_settings.sources)
                        local noise2 = seeded_noise(surface, x, y, index, cluster.noise_settings.discriminator)
                        if -1 * cluster.noise_settings.threshold < noise1 and noise1 < cluster.noise_settings.threshold
                                and -1 * cluster.noise_settings.discriminator_threshold < noise2
                                and noise2 < cluster.noise_settings.discriminator_threshold then
                            if spawn_cluster_resource(surface, x, y, index, cluster) then
                                insert(rocks, {name = 'rock-huge', position = position})
                                huge_rock_inserted = true
                            end
                        end
                    else
                        local noise = seeded_noise(surface, x, y, index, cluster.noise_settings.sources)
                        if noise >= cluster.noise_settings.threshold then
                            if spawn_cluster_resource(surface, x, y, index, cluster) then
                                insert(rocks, {name = 'rock-huge', position = position})
                                huge_rock_inserted = true
                            end
                        end
                    end
                end
            end
        end

    if (huge_rock_inserted == false) then
        insert(rocks, {name = 'sand-rock-big', position = position})
        end
    end

    Template.insert(surface, tiles, rocks)
end

local artificial_tiles = {
    ['stone-brick'] = true,
    ['stone-path'] = true,
    ['concrete'] = true,
    ['hazard-concrete-left'] = true,
    ['hazard-concrete-right'] = true,
    ['refined-concrete'] = true,
    ['refined-hazard-concrete-left'] = true,
    ['refined-hazard-concrete-right'] = true,
}

local function on_mined_tile(surface, tiles)
    local new_tiles = {}

    for _, tile in pairs(tiles) do
        if (artificial_tiles[tile.old_tile.name]) then
            insert(new_tiles, { name = 'dirt-' .. random(1, 7), position = tile.position})
        end
    end

    Template.insert(surface, new_tiles, {})
end

--[[--
    Registers all event handlers.
]]
function DiggyHole.register(config)
    robot_mining.damage = config.robot_initial_mining_damage
    ScoreTable.set('Robot mining damage', robot_mining.damage)
    ScoreTable.reset('Void removed')

    Event.add(defines.events.on_entity_died, function (event)
        local entity = event.entity
        local name = entity.name
        if name ~= 'sand-rock-big' and name ~= 'rock-huge' then
            return
        end
        diggy_hole(entity)
        if event.cause then
            CreateParticles.destroy_rock(entity.surface.create_entity, 10, entity.position)
        end
    end)

    Event.add(defines.events.on_entity_damaged, function (event)
        local entity = event.entity
        local name = entity.name

        if entity.health ~= 0 then
            return
        end

        if name ~= 'sand-rock-big' and name ~= 'rock-huge' then
            return
        end

        raise_event(defines.events.on_entity_died, {entity = entity, cause = event.cause, force = event.force})
        entity.destroy()
    end)

    Event.add(defines.events.on_robot_mined_entity, function (event)
        local entity = event.entity
        local name = entity.name

        if name ~= 'sand-rock-big' and name ~= 'rock-huge' then
            return
        end

        local health = entity.health
        health = health - robot_mining.damage
        event.buffer.clear()

        local graphics_variation = entity.graphics_variation
        local create_entity = entity.surface.create_entity
        local position = entity.position
        local force = event.robot.force

        if health < 1 then
            raise_event(defines.events.on_entity_died, {entity = entity, force = force})
            CreateParticles.mine_rock(create_entity, 6, position)
            entity.destroy()
            return
        end
        entity.destroy()

        local rock = create_entity({name = name, position = position})
        CreateParticles.mine_rock(create_entity, 1, position)
        rock.graphics_variation = graphics_variation
        rock.order_deconstruction(force)
        rock.health = health
    end)

    Event.add(defines.events.on_player_mined_entity, function (event)
        local entity = event.entity
        local name = entity.name
        if name ~= 'sand-rock-big' and name ~= 'rock-huge' then
            return
        end

        event.buffer.clear()

        diggy_hole(entity)
        CreateParticles.mine_rock(entity.surface.create_entity, 6, entity.position)
    end)

    Event.add(defines.events.on_robot_mined_tile, function (event)
        on_mined_tile(event.robot.surface, event.tiles)
    end)

    Event.add(defines.events.on_player_mined_tile, function (event)
        on_mined_tile(game.surfaces[event.surface_index], event.tiles)
    end)

    Event.add(Template.events.on_void_removed, function ()
        ScoreTable.increment('Void removed')
    end)

    Event.add(defines.events.on_research_finished, function (event)
        local new_modifier = event.research.force.mining_drill_productivity_bonus * 50 * config.robot_damage_per_mining_prod_level

        if (robot_mining.research_modifier == new_modifier) then
            -- something else was researched
            return
        end

        robot_mining.research_modifier = new_modifier
        update_robot_mining_damage()
    end)

    if config.enable_debug_commands then
        commands.add_command('clear-void', '<left top x> <left top y> <width> <height> <surface index> triggers Template.insert for the given area.', function(cmd)
            local params = {}
            local args = cmd.parameter or ''
            for param in string.gmatch(args, '%S+') do
                table.insert(params, param)
            end

            if (#params ~= 5) then
                game.player.print('/clear-void requires exactly 5 arguments: <left top x> <left top y> <width> <height> <surface index>')
                return
            end

            local left_top_x = tonumber(params[1])
            local left_top_y = tonumber(params[2])
            local width = tonumber(params[3])
            local height = tonumber(params[4])
            local surface_index = params[5]
            local tiles = {}
            local entities = {}

            for x = 0, width do
                for y = 0, height do
                    insert(tiles, {name = 'dirt-' .. random(1, 7), position = {x = x + left_top_x, y = y + left_top_y}})
                end
            end

            Template.insert(game.surfaces[surface_index], tiles, entities)
        end
        )
    end
end

function DiggyHole.on_init()
    game.forces.player.technologies['landfill'].enabled = false
    game.forces.player.technologies['atomic-bomb'].enabled = false
end

return DiggyHole
