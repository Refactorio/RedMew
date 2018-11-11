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

local function spawn_resource(config, surface, x, y, distance)
    local resource_name = get_name_by_random(config.resource_chances)

    if (config.minimum_resource_distance[resource_name] > distance) then
        return
    end

    local min_max = config.resource_richness_values[get_name_by_random(config.resource_richness_probability)]
    local amount = ceil(random(min_max[1], min_max[2]) * (1 + ((distance / config.distance_richness_modifier) * 0.01)))

    if ('crude-oil' == resource_name) then
        amount = amount * config.oil_value_modifier
    end

    if (config.cluster_mode) then
        amount = amount * config.cluster_yield_multiplier
    end

    local position = {x = x, y = y}

    Template.resources(surface, {{name = resource_name, position = position, amount = amount}})
end

--[[--
    Registers all event handlers.
]]
function ScatteredResources.register(config)
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
        return Perlin.noise(x * config.noise_variance, y * config.noise_variance, seed)
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

        if (config.cluster_mode and get_noise(surface, x, y) > config.noise_resource_threshold) then
            spawn_resource(config, surface, x, y, distance)
            return
        end

        local calculated_probability = config.resource_probability + ((distance / config.distance_probability_modifier) * 0.01)
        local probability = config.max_resource_probability

        if (calculated_probability < probability) then
            probability = calculated_probability
        end

        -- cluster mode reduces the max probability to reduce max spread
        if (config.cluster_mode) then
            probability = probability * 0.5
        end

        if (probability > random()) then
            spawn_resource(config, surface, x, y, distance)
        end
    end)

    if (config.enable_noise_grid) then
        Event.add(defines.events.on_chunk_generated, function (event)
            local surface = event.surface
            local area = event.area

            for x = area.left_top.x, area.left_top.x + 31 do
                for y = area.left_top.y, area.left_top.y + 31 do
                    Debug.print_grid_value(get_noise(surface, x, y), surface, {x = x, y = y})
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
