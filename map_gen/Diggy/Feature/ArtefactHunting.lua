--[[-- info
    Provides the ability to collect artefacts and send them to space.
]]

-- dependencies
local Event = require 'utils.event'
local Debug = require 'map_gen.Diggy.Debug'
local Template = require 'map_gen.Diggy.Template'
local Perlin = require 'map_gen.shared.perlin_noise'
local insert = table.insert
local random = math.random

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

    Event.add(Template.events.on_void_removed, function(event)
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
