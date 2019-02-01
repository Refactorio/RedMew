--[[-- info
    Provides the ability to spawn random ores all over the place.
]]

-- dependencies
local Event = require 'utils.event'
local Debug = require 'map_gen.maps.diggy.debug'
local Template = require 'map_gen.maps.diggy.template'
local Perlin = require 'map_gen.shared.perlin_noise'
local Simplex = require 'map_gen.shared.simplex_noise'
local Utils = require 'utils.core'
local random = math.random
local sqrt = math.sqrt
local ceil = math.ceil
local min = math.min
local pairs = pairs
local template_resources = Template.resources

-- this
local ScatteredResources = {}

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

--[[--
    Registers all event handlers.
]]
function ScatteredResources.register(config)

    -- source of noise for resource generation
    -- index determines offset
    -- '-1' is reserved for cluster mode
    -- compound clusters use as many indexes as needed > 1
    local base_seed
    local function seeded_noise(surface, x, y, index, sources)
        base_seed = base_seed or surface.map_gen_settings.seed + surface.index + 4000
        local noise = 0
        for _, settings in pairs(sources) do
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

    local resource_richness_weights = config.resource_richness_weights
    local resource_richness_weights_sum = 0
    for _, weight in pairs(resource_richness_weights) do
        resource_richness_weights_sum = resource_richness_weights_sum + weight
    end
    local resource_richness_values = config.resource_richness_values
    local resource_type_scalar = config.resource_type_scalar

    -- scattered config values
    local s_mode = config.scattered_mode
    local s_dist_mod = config.scattered_distance_probability_modifier
    local s_min_prob = config.scattered_min_probability
    local s_max_prob = config.scattered_max_probability
    local s_dist_richness = config.scattered_distance_richness_modifier
    local s_cluster_prob = config.scattered_cluster_probability_multiplier
    local s_cluster_mult = config.scattered_cluster_yield_multiplier

    local s_resource_weights = config.scattered_resource_weights
    local s_resource_weights_sum = 0
    for _, weight in pairs(s_resource_weights) do
        s_resource_weights_sum = s_resource_weights_sum + weight
    end
    local s_min_dist = config.scattered_minimum_resource_distance

    -- cluster config values
    local cluster_mode = config.cluster_mode

    -- compound cluster spawning
    local c_mode = config.cluster_mode
    local c_clusters = config.ore_pattern
    if 'table' ~= type(c_clusters) then
        error('ore_pattern invalid')
    end
    local c_count = 0
    for _, cluster in pairs(c_clusters) do
        c_count = c_count + 1
        cluster.weights_sum = 0
        -- ensure the cluster colors are valid otherwise it fails silently
        -- and breaks things elsewhere
        if cluster.color then
            local c = cluster.color
            if (not c.r) or (not c.g) or (not c.b) then
                cluster.color = nil
            elseif c.r < 0 or c.r > 1 or c.g < 0 or c.g > 1 or c.b < 0 or c.b > 1 then
                cluster.color = nil
            end
        end
        for _, weight in pairs(cluster.weights) do
            cluster.weights_sum = cluster.weights_sum + weight
        end
    end

    local function spawn_cluster_resource(surface, x, y, cluster)
        local distance = sqrt(x * x + y * y)
        local resource_name = get_name_by_weight(cluster.weights, cluster.weights_sum)
        if resource_name == 'skip' then
            return false
        end

        local cluster_distance = cluster.distances[resource_name]
        if cluster_distance and distance < cluster_distance then
            return false
        end

        local range = resource_richness_values[get_name_by_weight(resource_richness_weights, resource_richness_weights_sum)]
        local amount = random(range[1], range[2]) * (1 + ((distance / cluster.distance_richness) * 0.01)) * cluster.yield

        if resource_type_scalar[resource_name] then
            amount = amount * resource_type_scalar[resource_name]
        end

        template_resources(surface, {{name = resource_name, position = {x = x, y = y}, amount = ceil(amount)}})
        return true
    end

    -- event registration
    Event.add(Template.events.on_void_removed, function (event)
        local position = event.position
        local x = position.x
        local y = position.y
        local surface = event.surface

        local distance = config.distance(x, y)

        if c_mode then
            for index,cluster in pairs(c_clusters) do
                if distance >= cluster.min_distance and cluster.noise_settings.type ~= 'skip' then
                    if cluster.noise_settings.type == "connected_tendril" then
                        local noise = seeded_noise(surface, x, y, index, cluster.noise_settings.sources)
                        if -1 * cluster.noise_settings.threshold < noise and noise < cluster.noise_settings.threshold then
                            if spawn_cluster_resource(surface, x, y, cluster) then
                                return -- resource spawned
                            end
                        end
                    elseif cluster.noise_settings.type == "fragmented_tendril" then
                        local noise1 = seeded_noise(surface, x, y, index, cluster.noise_settings.sources)
                        local noise2 = seeded_noise(surface, x, y, index, cluster.noise_settings.discriminator)
                        if -1 * cluster.noise_settings.threshold < noise1 and noise1 < cluster.noise_settings.threshold
                                and -1 * cluster.noise_settings.discriminator_threshold < noise2
                                and noise2 < cluster.noise_settings.discriminator_threshold then
                            if spawn_cluster_resource(surface, x, y, cluster) then
                                return -- resource spawned
                            end
                        end
                    else
                        local noise = seeded_noise(surface, x, y, index, cluster.noise_settings.sources)
                        if noise >= cluster.noise_settings.threshold then
                            if spawn_cluster_resource(surface, x, y, cluster) then
                                return -- resource spawned
                            end
                        end
                    end
                end
            end
        end

        if s_mode then
            local probability = min(s_max_prob, s_min_prob + 0.01 * (distance / s_dist_mod))

            if (cluster_mode) then
                probability = probability * s_cluster_prob
            end

            if (probability > random()) then
                -- spawn single resource point for scatter mode
                local resource_name = get_name_by_weight(s_resource_weights, s_resource_weights_sum)
                if resource_name == 'skip' or s_min_dist[resource_name] > distance then
                    return
                end

                local range = resource_richness_values[get_name_by_weight(resource_richness_weights, resource_richness_weights_sum)]
                local amount = random(range[1], range[2])
                amount = amount * (1 + ((distance / s_dist_richness) * 0.01))

                if resource_type_scalar[resource_name] then
                    amount = amount * resource_type_scalar[resource_name]
                end

                if (cluster_mode) then
                    amount = amount * s_cluster_mult
                end

                Template.resources(surface, {{name = resource_name, position={x=x,y=y}, amount = ceil(amount)}})
            end
        end
    end)

    if (config.display_ore_clusters) then
        local color = {}
        Event.add(defines.events.on_chunk_generated, function (event)
            local surface = event.surface
            local area = event.area

            for x = area.left_top.x, area.left_top.x + 31 do
                for y = area.left_top.y, area.left_top.y + 31 do
                    for index,cluster in pairs(c_clusters) do
                        if cluster.noise_settings.type == "connected_tendril" then
                            local noise = seeded_noise(surface, x, y, index, cluster.noise_settings.sources)
                            if -1 * cluster.noise_settings.threshold < noise and noise < cluster.noise_settings.threshold then
                                color[index] = color[index] or cluster.color or Utils.random_RGB
                                Debug.print_colored_grid_value('o' .. index, surface, {x = x, y = y}, nil, true, 0, color[index])
                            end
                        elseif cluster.noise_settings.type == "fragmented_tendril" then
                            local noise1 = seeded_noise(surface, x, y, index, cluster.noise_settings.sources)
                            local noise2 = seeded_noise(surface, x, y, index, cluster.noise_settings.discriminator)
                            if -1 * cluster.noise_settings.threshold < noise1 and noise1 < cluster.noise_settings.threshold
                                    and -1 * cluster.noise_settings.discriminator_threshold < noise2
                                    and noise2 < cluster.noise_settings.discriminator_threshold then
                                color[index] = color[index] or cluster.color or Utils.random_RGB
                                Debug.print_colored_grid_value('o' .. index, surface, {x = x, y = y}, nil, true, 0, color[index])
                            end
                        elseif cluster.noise_settings.type ~= 'skip' then
                            local noise = seeded_noise(surface, x, y, index, cluster.noise_settings.sources)
                            if noise >= cluster.noise_settings.threshold then
                                color[index] = color[index] or cluster.color or Utils.random_RGB
                                Debug.print_colored_grid_value('o' .. index, surface, {x = x, y = y}, nil, true, 0, color[index])
                            end
                        end
                    end
                end
            end
        end)
    end
end

function ScatteredResources.get_extra_map_info()
    return [[Scattered Resources, resources are everywhere!
Scans of the mine have shown greater amounts of resources to be deeper in the mine]]
end

return ScatteredResources
