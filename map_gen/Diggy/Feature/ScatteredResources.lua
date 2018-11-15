--[[-- info
    Provides the ability to spawn random ores all over the place.
]]

-- dependencies
local Event = require 'utils.event'
local Debug = require 'map_gen.Diggy.Debug'
local Template = require 'map_gen.Diggy.Template'
local Perlin = require 'map_gen.shared.perlin_noise'
local Simplex = require 'map_gen.shared.simplex_noise'
local random = math.random
local sqrt = math.sqrt
local ceil = math.ceil
local floor = math.floor

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
    local function seeded_noise(surface, x, y, index, cluster_variance, noise_type)
        base_seed = base_seed or surface.map_gen_settings.seed + surface.index + 400
        noise_type = noise_type or "perlin"
        if noise_type == "perlin" then
            return Perlin.noise(x * cluster_variance, y * cluster_variance, base_seed + 200 * index)
        elseif noise_type == "simplex" then
            return Simplex.d2(x * cluster_variance, y * cluster_variance, base_seed + 200 * index)
        end
    end
    
    -- cluster and scattered spawning

    local noise_resource_threshold = config.noise_resource_threshold
    local noise_variance = config.noise_variance
    local cluster_mode = config.cluster_mode
    local distance_probability_modifier = config.distance_probability_modifier
    local resource_probability = config.resource_probability
    local max_resource_probability = config.max_resource_probability
    local resource_weights = config.resource_weights
    local resource_richness_weights = config.resource_richness_weights
    local distance_richness_modifier = config.distance_richness_modifier
    local liquid_value_modifiers = config.liquid_value_modifiers
    local resource_richness_values = config.resource_richness_values
    local minimum_resource_distance = config.minimum_resource_distance
    local cluster_yield_multiplier = config.cluster_yield_multiplier
    
    local resource_weights_sum = 0
    for _, weight in pairs(resource_weights) do
        resource_weights_sum = resource_weights_sum + weight
    end
    local resource_richness_weights_sum = 0
    for _, weight in pairs(resource_richness_weights) do
        resource_richness_weights_sum = resource_richness_weights_sum + weight
    end

    local function spawn_resource(surface, x, y, distance)
        local resource_name = get_name_by_weight(resource_weights, resource_weights_sum)

        if (minimum_resource_distance[resource_name] > distance) then
            return
        end

        local min_max = resource_richness_values[get_name_by_weight(resource_richness_weights, resource_richness_weights_sum)]
        local amount = ceil(random(min_max[1], min_max[2]) * (1 + ((distance / distance_richness_modifier) * 0.01)))

        if liquid_value_modifiers[resource_name] then
            amount = amount * liquid_value_modifiers[resource_name]
        end

        if (cluster_mode) then
            amount = amount * cluster_yield_multiplier
        end

        local position = {x = x, y = y}

        Template.resources(surface, {{name = resource_name, position = position, amount = amount}})
    end

    -- compound cluster spawning
    
    local cc_mode = config.compound_cluster_mode
    local cc_richness_weights = config.compound_cluster_richness_weights
    local cc_richness_values = config.compound_cluster_richness_values
    local cc_type_scalar = config.compound_cluster_type_scalar
    local cc_clusters = config.compound_clusters
    
    local cc_richness_weights_sum = 0
    for _, weight in pairs(cc_richness_weights) do
        cc_richness_weights_sum = cc_richness_weights_sum + weight
    end
    local cc_cluster_count = 0
    for _, cluster in ipairs(cc_clusters) do
        cc_cluster_count = cc_cluster_count + 1
        cluster.weights_sum = 0
        for _, weight in pairs(cluster.weights) do
            cluster.weights_sum = cluster.weights_sum + weight
        end
    end
    
    local function spawn_compound_cluser_resource(surface, x, y, cluster_index, cluster)
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
    
        local range = cc_richness_values[get_name_by_weight(cc_richness_weights, cc_richness_weights_sum)]
        local amount = random(range[1], range[2])
        amount = amount * (1 + ((distance / cluster.distance_richness) * 0.01))
        
        if cc_type_scalar[resource_name] then 
            amount = amount * cc_type_scalar[resource_name]
        end

        Template.resources(surface, {{name = resource_name, position = {x = x, y = y}, amount = floor(amount)}})
        return true
    end
    
    local function spawn_compound_clusters(surface, x, y, distance)
        for index,cluster in ipairs(cc_clusters) do
            if distance >= cluster.min_distance then
                if seeded_noise(surface, x, y, index, cluster.variance,
                        cluster.noise or 'perlin') >= cluster.threshold then
                    if spawn_compound_cluser_resource(surface, x, y, index, cluster) then
                        return true -- resource spawned
                    end
                end
            end
        end
        return false -- nothing spawned
    end
    
    -- event registration
    Event.add(Template.events.on_void_removed, function (event)
        local position = event.position
        local x = position.x
        local y = position.y
        local surface = event.surface

        local distance = sqrt(x * x + y * y)
        
        if cc_mode then
            if (spawn_compound_clusters(surface, x, y, distance)) then
                return
            end
        end
        distance = floor(distance)

        if (cluster_mode and seeded_noise(surface, x, y, -1, noise_variance) > noise_resource_threshold) then
            spawn_resource(surface, x, y, distance)
            return
        end
        
        if not scattered_mode then
            return
        end

        local calculated_probability = resource_probability + ((distance / distance_probability_modifier) * 0.01)
        local probability = max_resource_probability

        if (calculated_probability < probability) then
            probability = calculated_probability
        end

        -- cluster mode reduces the max probability to reduce max spread
        if (cluster_mode) then
            probability = probability * 0.5
        end

        if (probability > random()) then
            spawn_resource(surface, x, y, distance)
        end
    end)

    if (config.display_resource_fields) then
        Event.add(defines.events.on_chunk_generated, function (event)
            local surface = event.surface
            local area = event.area

            for x = area.left_top.x, area.left_top.x + 31 do
                for y = area.left_top.y, area.left_top.y + 31 do
                    if seeded_noise(surface, x, y, -1, noise_variance) >= noise_resource_threshold then
                        Debug.print_grid_value('ore', surface, {x = x, y = y}, nil, nil, true)
                    end
                end
            end
        end)
    end
    
    if (config.display_compound_ore_locations) then
        Event.add(defines.events.on_chunk_generated, function (event)
            local surface = event.surface
            local area = event.area

            for x = area.left_top.x, area.left_top.x + 31 do
                for y = area.left_top.y, area.left_top.y + 31 do
                    for index,cluster in ipairs(cc_clusters) do
                        if seeded_noise(surface, x, y, index, cluster.variance,
                        cluster.noise or 'perlin') >= cluster.threshold then
                            Debug.print_grid_value('o' .. index, surface, {x = x, y = y}, nil, nil, true)
                        end
                    end
                end
            end
        end)
    end
end

function ScatteredResources.get_extra_map_info(config)
    return [[Scattered Resources, resources are everywhere!
Scans of the mine have shown greater amounts of resources to be deeper in the mine]]
end

return ScatteredResources
