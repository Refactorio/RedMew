--[[-- info
    Provides the ability to spawn aliens.
]]

-- dependencies
local Event = require 'utils.event'
local Global = require 'utils.global'
local Token = require 'utils.global_token'
local Task = require 'utils.task'
local AlienEvolutionProgress = require 'map_gen.Diggy.AlienEvolutionProgress'
local Debug = require 'map_gen.Diggy.Debug'
local Template = require 'map_gen.Diggy.Template'
local random = math.random
local floor = math.floor
local ceil = math.ceil
local insert = table.insert
local raise_event = script.raise_event

-- this
local AlienSpawner = {}

local alien_size_chart = {}
Global.register_init({
    alien_size_chart = alien_size_chart,
}, function(tbl)
    for name, prototype in pairs(game.entity_prototypes) do
        if prototype.type == 'unit' and prototype.subgroup.name == 'enemies' then
            tbl.alien_size_chart[name] = {
                name = name,
                collision_box = prototype.collision_box
            }
        end
    end
end, function(tbl)
    alien_size_chart = tbl.alien_size_chart
end)

local do_alien_mining = Token.register(function(params)
    local surface = params.surface
    local find_entities_filtered = surface.find_entities_filtered

    for _, area in ipairs(params.positions_to_mine) do
        local rocks = find_entities_filtered({area = area, name = {'sand-rock-big', 'rock-huge'}})

        if (0 == #rocks) then
            break
        end

        for _, rock in pairs(rocks) do
            raise_event(defines.events.on_entity_died, {entity = rock})
            rock.destroy()
        end
    end
end)

local function spawn_aliens(aliens, force, surface, x, y)
    local position = {x = x, y = y}
    local create_entity = surface.create_entity
    local count_tiles_filtered = surface.count_tiles_filtered
    local areas_to_mine = {}
    local first_spawn_to_mine

    for name, amount in pairs(aliens) do
        local size_data = alien_size_chart[name]
        if not size_data then
            Debug.print_position(position, 'Unable to find prototype data for ' .. name)
            break
        end

        local locations_to_scan = {
            {x = 0, y = -1.5}, -- up
            {x = 1.5, y = 0}, -- right
            {x = 0, y = 1.5}, -- bottom
            {x = -1.5, y = 0}, -- left
        }

        local collision_box = size_data.collision_box
        local left_top_x = collision_box.left_top.x * 1.6
        local left_top_y = collision_box.left_top.y * 1.6
        local right_bottom_x = collision_box.right_bottom.x * 1.6
        local right_bottom_y = collision_box.right_bottom.y * 1.6

        for _, direction in ipairs(locations_to_scan) do
            local x_center = direction.x + x
            local y_center = direction.y + y

            -- *_center indicates the offset center relative to the location where it should spawn
            -- the area is composed of the bounding_box of the alien with a bigger size so it has space to move
            local offset_area = {
                left_top = {
                    x = floor(x_center + left_top_x),
                    y = floor(y_center + left_top_y),
                },
                right_bottom = {
                    x = ceil(x_center + right_bottom_x),
                    y = ceil(y_center + right_bottom_y),
                },
            }

            -- can't spawn properly if void is present
            if count_tiles_filtered({area = offset_area, name = 'out-of-map'}) == 0 then
                local spawned_position = {x = x_center, y = y_center}

                -- it's still in the middle of rocks, but away from void and most likely near the player
                create_entity({name = name, position = {x = x_center, y = y_center}, force = force, amount = amount})
                if not first_spawn_to_mine then
                    first_spawn_to_mine = spawned_position
                end

                insert(areas_to_mine, offset_area)
                break
            end
        end
    end

    -- can't do mining in the same tick as it would invalidate the rock just mined and there
    -- is no way to distinguish them as multiple can occupy the same position
    if #areas_to_mine > 0 then
        Task.set_timeout_in_ticks(1, do_alien_mining, {surface = surface, positions_to_mine = areas_to_mine})
    end
end

--[[--
    Registers all event handlers.
]]
function AlienSpawner.register(config)
    local alien_minimum_distance_square = config.alien_minimum_distance ^ 2

    local alien_probability = config.alien_probability

    Event.add(Template.events.on_void_removed, function (event)
        local force = game.forces.enemy
        local evolution_factor = force.evolution_factor
        force.evolution_factor = evolution_factor + 0.0000012

        local position = event.position
        local x = position.x
        local y = position.y

        if (x * x + y * y < alien_minimum_distance_square or alien_probability < random()) then
            return
        end

        local aliens = AlienEvolutionProgress.getBitersByEvolution(random(1, 2), evolution_factor)
        for name, amount in pairs(AlienEvolutionProgress.getSpittersByEvolution(random(1, 2), evolution_factor)) do
            aliens[name] = amount
        end

        spawn_aliens(aliens, force, event.surface, x, y)
    end)
end

function AlienSpawner.get_extra_map_info(config)
    return [[Alien Spawner, aliens might spawn when mining!
Spawn chance: ]] .. (config.alien_probability * 100) .. [[%
Minimum spawn distance: ]] .. config.alien_minimum_distance .. ' tiles'
end

function AlienSpawner.on_init()
	-- base factorio =                pollution_factor = 0.000015
    game.map_settings.enemy_evolution.pollution_factor = 0.000004
end

return AlienSpawner
