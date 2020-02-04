--[[-- info
    Provides the ability to collect coins.
]]

-- dependencies
local Event = require 'utils.event'
local Debug = require 'map_gen.maps.diggy.debug'
local Template = require 'map_gen.maps.diggy.template'
local Perlin = require 'map_gen.shared.perlin_noise'
local random = math.random
local ceil = math.ceil
local pairs = pairs

-- this
local CoinGathering = {}

function CoinGathering.register(config)
    local seed
    local noise_variance = config.noise_variance
    local function get_noise(surface, x, y)
        seed = seed or surface.map_gen_settings.seed + surface.index + 300
        return Perlin.noise(x * noise_variance * 0.9, y * noise_variance * 1.1, seed)
    end

    local distance_required = config.minimal_treasure_chest_distance * config.minimal_treasure_chest_distance

    local treasure_chest_noise_threshold = config.treasure_chest_noise_threshold
    Event.add(Template.events.on_void_removed, function (event)
        local position = event.position
        local x = position.x
        local y = position.y

        if (x * x + y * y <= distance_required) then
            return
        end

        local surface = event.surface

        if get_noise(surface, x, y) < treasure_chest_noise_threshold then
            return
        end

        local chest = surface.create_entity({name = 'steel-chest', position = position, force = game.forces.player})

        if not chest then
            return
        end

        local insert = chest.insert
        for name, prototype in pairs(config.treasure_chest_raffle) do
            if random() <= prototype.chance then
                insert({name = name, count = random(prototype.min, prototype.max)})
            end
        end
    end)

    local modifiers = config.alien_coin_modifiers
    local alien_coin_drop_chance = config.alien_coin_drop_chance

    Event.add(defines.events.on_entity_died, function (event)
        local entity = event.entity
        local force = entity.force
        if force.name ~= 'enemy' or random() > alien_coin_drop_chance then
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
    end)

    local mining_coin_chance = config.mining_coin_chance
    local mining_coin_amount_min = config.mining_coin_amount.min
    local mining_coin_amount_max = config.mining_coin_amount.max
    Event.add(defines.events.on_pre_player_mined_item, function (event)
        local entity = event.entity
        if entity.type ~= 'simple-entity' then
            return
        end

        if random() > mining_coin_chance then
            return
        end

        local coin = entity.surface.create_entity({
            name = 'item-on-ground',
            position = entity.position,
            stack = {name = 'coin', count = random(mining_coin_amount_min, mining_coin_amount_max)}
        })

        if coin and coin.valid then
            coin.to_be_looted = true
        end
    end)

    if config.display_chest_locations then
        Event.add(defines.events.on_chunk_generated, function (event)
            local surface = event.surface
            local area = event.area

            for x = area.left_top.x, area.left_top.x + 31 do
                local sq_x = x * x
                for y = area.left_top.y, area.left_top.y + 31 do
                    if sq_x + y * y >= distance_required and get_noise(surface, x, y) >= treasure_chest_noise_threshold then
                        Debug.print_grid_value('chest', surface, {x = x, y = y}, nil, nil, true)
                    end
                end
            end
        end)
    end
end

return CoinGathering
