--[[-- info
    Provides the ability to collect artefacts and send them to space.
]]

-- dependencies
local Event = require 'utils.event'
local Game = require 'utils.game'
local Debug = require 'map_gen.Diggy.Debug'
local Template = require 'map_gen.Diggy.Template'
local Perlin = require 'map_gen.shared.perlin_noise'
local random = math.random
local ceil = math.ceil

-- this
local ArtefactHunting = {}

--[[--
    Registers all event handlers.
]]
function ArtefactHunting.register(config)
    local seed
    local function get_noise(surface, x, y)
        seed = seed or surface.map_gen_settings.seed + surface.index + 300
        return Perlin.noise(x * config.noise_variance * 0.9, y * config.noise_variance * 1.1, seed)
    end

    local distance_required = config.minimal_treasure_chest_distance * config.minimal_treasure_chest_distance

    Event.add(Template.events.on_void_removed, function (event)
        local position = event.position
        local x = position.x
        local y = position.y

        if (x * x + y * y <= distance_required) then
            return
        end

        local surface = event.surface

        if get_noise(surface, x, y) < config.treasure_chest_noise_threshold then
            return
        end

        local chest = surface.create_entity({name = 'steel-chest', position = position, force = game.forces.player})

        if not chest then
            return
        end

        for name, prototype in pairs(config.treasure_chest_raffle) do
            if random() <= prototype.chance then
                chest.insert({name = name, count = random(prototype.min, prototype.max)})
            end
        end
    end)

    local modifiers = {
        ['small-biter'] = 1,
        ['small-spitter'] = 1,
        ['medium-biter'] = 2,
        ['medium-spitter'] = 2,
        ['big-biter'] = 4,
        ['big-spitter'] = 4,
        ['behemoth-biter'] = 6,
        ['behemoth-spitter'] = 6,
    }

    local function picked_up_coins(player_index, count)
        local text
        if count == 1 then
            text = '+1 coin'
        else
            text = '+' .. count ..' coins'
        end

        Game.print_player_floating_text(player_index, text, {r = 255, g = 215, b = 0})
    end

    Event.add(defines.events.on_entity_died, function (event)
        local entity = event.entity
        local force = entity.force

        if force.name ~= 'enemy' then
            return
        end

        local cause = event.cause

        if not cause or cause.type ~= 'player' or not cause.valid then
            return
        end

        local modifier = modifiers[entity.name] or 1
        local evolution_multiplier = force.evolution_factor * 11
        local count = random(
            ceil(2 * evolution_multiplier * 0.1),
            ceil(5 * (evolution_multiplier * evolution_multiplier + modifier) * 0.1)
        )

        entity.surface.create_entity({
            name = 'item-on-ground',
            position = entity.position,
            stack = {name = 'coin', count = count}
        })
    end)

    Event.add(defines.events.on_picked_up_item, function (event)
        local stack = event.item_stack
        if stack.name ~= 'coin' then
            return
        end

        picked_up_coins(event.player_index, stack.count)
    end)

    Event.add(defines.events.on_pre_player_mined_item, function (event)
        if event.entity.type ~= 'simple-entity' then
            return
        end

        if random() > config.mining_artefact_chance then
            return
        end

        local count = random(config.mining_artefact_amount.min, config.mining_artefact_amount.max)
        local player_index = event.player_index

        Game.get_player_by_index(player_index).insert({name = 'coin', count = count})
        picked_up_coins(player_index, count)
    end)

    if (config.display_chest_locations) then
        Event.add(defines.events.on_chunk_generated, function (event)
            local surface = event.surface
            local area = event.area

            for x = area.left_top.x, area.left_top.x + 31 do
                local sq_x = x * x
                for y = area.left_top.y, area.left_top.y + 31 do
                    if sq_x + y * y >= distance_required and get_noise(surface, x, y) >= config.treasure_chest_noise_threshold then
                        Debug.print_grid_value('chest', surface, {x = x, y = y})
                    end
                end
            end
        end)
    end
end

function ArtefactHunting.get_extra_map_info(config)
    return 'Artefact Hunting, find precious coins while mining and launch them to the surface!'
end

return ArtefactHunting
