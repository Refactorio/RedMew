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

--BT's additions
local Config = require 'map_gen.Diggy.Config'

local Perlin = require 'map_gen.shared.perlin_noise'
local Simplex = require 'map_gen.shared.simplex_noise'

local sqrt = math.sqrt
local ceil = math.ceil
local floor = math.floor

-- this
local DiggyHole = {}

--[[--
    Triggers a diggy diggy hole for a given sand-rock-big or rock-huge.

    Will return true even if the tile behind it is immune.

    @param entity LuaEntity
]]
local function diggy_hole(entity)
--[BT's additions, copied from ScatteredResources.lua
local function get_name_by_weight(collection, sum)
    local pre_calculated = random()
    local current = 0
    local target = pre_calculated * sum
    
    for name, weight in pairs(collection) do
        current = current + weight
        if (current >= target) then
            return name
        end
    end

    Debug.print('Current \'' .. current .. '\' should be higher or equal to random \'' .. target .. '\'')
end
--]

    if ((entity.name ~= 'sand-rock-big') and (entity.name ~= 'rock-huge')) then
        return
    end

    local tiles = {}
    local rocks = {}
    local surface = entity.surface

    local out_of_map_found = Scanner.scan_around_position(surface, entity.position, 'out-of-map');

        local position = entity.position
        local x = position.x
        local y = position.y
        local surface = entity.surface


        local distance = Config.features.ScatteredResources.distance(x, y)

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

--        local c_clusters = Config.features.ScatteredResources.clusters
--        local c_mode = Config.features.ScatteredResources.cluster_mode
    
    -- global config values
    
    local resource_richness_weights = Config.features.ScatteredResources.resource_richness_weights
    local resource_richness_weights_sum = 0
    for _, weight in pairs(resource_richness_weights) do
        resource_richness_weights_sum = resource_richness_weights_sum + weight
    end
    local resource_richness_values = Config.features.ScatteredResources.resource_richness_values
    local resource_type_scalar = Config.features.ScatteredResources.resource_type_scalar
    
    -- scattered config values
    local s_mode = Config.features.ScatteredResources.scattered_mode
    local s_dist_mod = Config.features.ScatteredResources.scattered_distance_probability_modifier
    local s_min_prob = Config.features.ScatteredResources.scattered_min_probability
    local s_max_prob = Config.features.ScatteredResources.scattered_max_probability
    local s_dist_richness = Config.features.ScatteredResources.scattered_distance_richness_modifier
    local s_cluster_prob = Config.features.ScatteredResources.scattered_cluster_probability_multiplier
    local s_cluster_mult = Config.features.ScatteredResources.scattered_cluster_yield_multiplier
    
    local s_resource_weights = Config.features.ScatteredResources.scattered_resource_weights
    local s_resource_weights_sum = 0
    for _, weight in pairs(s_resource_weights) do
        s_resource_weights_sum = s_resource_weights_sum + weight
    end
    local s_min_dist = Config.features.ScatteredResources.scattered_minimum_resource_distance

    -- cluster config values
    local cluster_mode = Config.features.ScatteredResources.cluster_mode
    
    -- compound cluster spawning
    local c_mode = Config.features.ScatteredResources.cluster_mode
--    local c_clusters = Config.features.ScatteredResources.clusters
    local c_clusters = require(Config.features.ScatteredResources.cluster_file_location)
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
        local distance = sqrt(x * x + y * y)
        local resource_name = get_name_by_weight(cluster.weights, cluster.weights_sum)
        if resource_name == 'skip' then
            return false
        end
        if cluster.distances[resource_name] then
            if distance < cluster.distances[resource_name] then
                return false
            end
        end
    
        local range = resource_richness_values[get_name_by_weight(resource_richness_weights, resource_richness_weights_sum)]
        local amount = random(range[1], range[2])
        amount = amount * (1 + ((distance / cluster.distance_richness) * 0.01))
        amount = amount * cluster.yield
        
        if resource_type_scalar[resource_name] then 
            amount = amount * resource_type_scalar[resource_name]
        end

        Template.resources(surface, {{name = resource_name, position = {x = x, y = y}, amount = ceil(amount)}})
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
        local entity = event.entity
        diggy_hole(entity)

        local position = entity.position
        local surface = entity.surface

        -- fixes massive frame drops when too much stone is spilled
        local stones = surface.find_entities_filtered({
            area = {{position.x - 2, position.y - 2}, {position.x + 2, position.y + 2}},
            limit = 60,
            type = 'item-entity',
            name = 'item-on-ground',
        })
        for _, stone in ipairs(stones) do
            if (stone.stack.name == 'stone') then
                stone.destroy()
            end
        end
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
