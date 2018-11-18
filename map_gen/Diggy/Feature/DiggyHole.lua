--[[-- info
    Provides the ability to "mine" through out-of-map tiles by destroying or
    mining rocks next to it.
]]

-- dependencies
local Event = require 'utils.event'
local Scanner = require 'map_gen.Diggy.Scanner'
local Template = require 'map_gen.Diggy.Template'
local ScoreTable = require 'map_gen.Diggy.ScoreTable'
local Debug = require 'map_gen.Diggy.Debug'
local insert = table.insert
local random = math.random

-- todo remove this dependency
local ResourceConfig = require 'map_gen.Diggy.Config'.features.ScatteredResources

local Perlin = require 'map_gen.shared.perlin_noise'
local Simplex = require 'map_gen.shared.simplex_noise'

-- this
local DiggyHole = {}

--[[--
    Triggers a diggy diggy hole for a given sand-rock-big or rock-huge.

    Will return true even if the tile behind it is immune.

    @param entity LuaEntity
]]
local function diggy_hole(entity)
    if ((entity.name ~= 'sand-rock-big') and (entity.name ~= 'rock-huge')) then
        return
    end

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
--        if (random() > 0.50) then
--        insert(rocks, {name = 'rock-huge', position = position})


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
    ScoreTable.reset('Void removed')

    Event.add(defines.events.on_entity_died, function (event)
        diggy_hole(event.entity)
    end)

    Event.add(defines.events.on_player_mined_entity, function (event)
        diggy_hole(event.entity)
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
end

return DiggyHole
