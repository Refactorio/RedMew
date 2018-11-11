--[[-- info
    Provides the ability to spawn random ores all over the place.
]]

-- dependencies
local Event = require 'utils.event'
local Debug = require 'map_gen.Diggy.Debug'
local Template = require 'map_gen.Diggy.Template'
local Perlin = require 'map_gen.shared.perlin_noise'
local random = math.random
local sqrt = math.sqrt
local ceil = math.ceil
local floor = math.floor

-- this
local ScatteredResources = {}

local function get_name_by_random(collection)
    local pre_calculated = random()
    local current = 0

    for name, probability in pairs(collection) do
        current = current + probability
        if (current >= pre_calculated) then
            return name
        end
    end

    Debug.print('Current \'' .. current .. '\' should be higher or equal to random \'' .. pre_calculated .. '\'')
end

--[[--
    Registers all event handlers.
]]
function ScatteredResources.register(config)
    local noise_resource_threshold = config.noise_resource_threshold
    local noise_variance = config.noise_variance
    local cluster_mode = config.cluster_mode
    local distance_probability_modifier = config.distance_probability_modifier
    local resource_probability = config.resource_probability
    local max_resource_probability = config.max_resource_probability
    local resource_chances = config.resource_chances
    local resource_richness_probability = config.resource_richness_probability
    local distance_richness_modifier = config.distance_richness_modifier
    local liquid_value_modifiers = config.liquid_value_modifiers
    local resource_richness_values = config.resource_richness_values
    local minimum_resource_distance = config.minimum_resource_distance
    local cluster_yield_multiplier = config.cluster_yield_multiplier

    local function spawn_resource(surface, x, y, distance)
        local resource_name = get_name_by_random(resource_chances)

        if (minimum_resource_distance[resource_name] > distance) then
            return
        end

        local min_max = resource_richness_values[get_name_by_random(resource_richness_probability)]
        local amount = ceil(random(min_max[1], min_max[2]) * (1 + ((distance / distance_richness_modifier) * 0.01)))

        if liquid_value_modifiers[name] then
            amount = amount * modifier
        end

        if (cluster_mode) then
            amount = amount * cluster_yield_multiplier
        end

        local position = {x = x, y = y}

        Template.resources(surface, {{name = resource_name, position = position, amount = amount}})
    end

    function sum(t)
        local sum = 0
        for _, v in pairs(t) do
            sum = sum + v
        end

        return sum
    end

    local seed
    local function get_noise(surface, x, y)
        seed = seed or surface.map_gen_settings.seed + surface.index + 200
        return Perlin.noise(x * noise_variance, y * noise_variance, seed)
    end

    local resource_sum = sum(config.resource_chances)
    if (1 ~= resource_sum) then
        error('Expected a sum of 1.00, got \'' .. resource_sum .. '\' for config.feature.ScatteredResources.resource_chances.')
    end

    local richness_sum = sum(config.resource_richness_probability)
    if (1 ~= richness_sum) then
        error('Expected a sum of 1.00, got \'' .. richness_sum .. '\' for config.feature.ScatteredResources.resource_richness_probability.')
    end

    Event.add(Template.events.on_void_removed, function (event)
        local position = event.position
        local x = position.x
        local y = position.y
        local surface = event.surface

        local distance = floor(sqrt(x * x + y * y))

        if (cluster_mode and get_noise(surface, x, y) > noise_resource_threshold) then
            spawn_resource(surface, x, y, distance)
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
                    if get_noise(surface, x, y) >= noise_resource_threshold then
                        Debug.print_grid_value('ore', surface, {x = x, y = y}, nil, nil, true)
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
