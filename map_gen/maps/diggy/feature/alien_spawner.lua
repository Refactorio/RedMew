--[[-- info
    Provides the ability to spawn aliens.
]]

-- dependencies
require 'utils.table'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Token = require 'utils.token'
local Task = require 'utils.task'
local AlienEvolutionProgress = require 'utils.alien_evolution_progress'
local Debug = require 'map_gen.maps.diggy.debug'
local Template = require 'map_gen.maps.diggy.template'
local CreateParticles = require 'features.create_particles'
local random = math.random
local floor = math.floor
local ceil = math.ceil
local size = table.size
local pairs = pairs
local raise_event = script.raise_event
local get_aliens = AlienEvolutionProgress.get_aliens
local create_spawner_request = AlienEvolutionProgress.create_spawner_request
local set_timeout_in_ticks = Task.set_timeout_in_ticks
local destroy_rock = CreateParticles.destroy_rock

-- this
local AlienSpawner = {}

local memory = {
    alien_collision_boxes = {},
}
local locations_to_scan = {
    {x = 0, y = -1.5}, -- up
    {x = 1.5, y = 0}, -- right
    {x = 0, y = 1.5}, -- bottom
    {x = -1.5, y = 0}, -- left
}

Global.register_init({
    memory = memory,
}, function(tbl)
    for name, prototype in pairs(game.entity_prototypes) do
        if prototype.type == 'unit' and prototype.subgroup.name == 'enemies' then
            tbl.memory.alien_collision_boxes[name] = prototype.collision_box
        end
    end
end, function(tbl)
    memory = tbl.memory
end)

local rocks_to_find = Template.diggy_rocks

---Triggers mining at the collision_box of the alien, to free it
local do_alien_mining = Token.register(function(params)
    local surface = params.surface
    local create_entity = surface.create_entity
    local find_non_colliding_position = surface.find_non_colliding_position

    local rocks = surface.find_entities_filtered({area = params.clear_area, name = rocks_to_find})

    local rock_count = #rocks
    if rock_count > 0 then
        -- with multiple rocks opening at once, it will spawn less particles in total per rock
        local particle_count
        if rock_count == 1 then
            particle_count = 15
        elseif rock_count == 2 then
            particle_count = 10
        else
            particle_count = 5
        end

        for rock_index = rock_count, 1, -1 do
            local rock = rocks[rock_index]
            raise_event(defines.events.on_entity_died, {entity = rock})
            destroy_rock(create_entity, particle_count, rock.position)
            rock.destroy()
        end
    end

    local spawn_location = params.spawn_location
    -- amount is not used for aliens prototypes, it just carries along in the params
    local amount = spawn_location.amount
    while amount > 0 do
        spawn_location.position = find_non_colliding_position(spawn_location.name, spawn_location.position, 2, 0.4) or spawn_location.position
        create_entity(spawn_location)
        amount = amount - 1
    end
end)

---Spawns aliens given the parameters.
---@param aliens table index is the name, value is the amount of biters to spawn
---@param force LuaForce of the biters
---@param surface LuaSurface to spawn on
---@param x number
---@param y number
local function spawn_aliens(aliens, force, surface, x, y)
    local position = {x = x, y = y}
    local count_tiles_filtered = surface.count_tiles_filtered

    local spawn_count = 0
    local alien_collision_boxes = memory.alien_collision_boxes

    for name, amount in pairs(aliens) do
        local collision_box = alien_collision_boxes[name]
        if not collision_box then
            Debug.print_position(position, 'Unable to find prototype data for ' .. name)
            break
        end

        local left_top = collision_box.left_top
        local right_bottom = collision_box.right_bottom
        local left_top_x = left_top.x * 1.6
        local left_top_y = left_top.y * 1.6
        local right_bottom_x = right_bottom.x * 1.6
        local right_bottom_y = right_bottom.y * 1.6

        for i = #locations_to_scan, 1, -1 do
            local direction = locations_to_scan[i]
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
                spawn_count = spawn_count + 1
                set_timeout_in_ticks(spawn_count, do_alien_mining, {
                    surface = surface,
                    clear_area = offset_area,
                    spawn_location = {
                        name = name,
                        position = {x = x_center, y = y_center},
                        force = force,
                        amount = amount
                    },
                })
                break
            end
        end
    end
end

--[[--
    Registers all event handlers.
]]
function AlienSpawner.register(config)
    local alien_minimum_distance_square = config.alien_minimum_distance ^ 2
    local alien_probability = config.alien_probability
    local hail_hydra = config.hail_hydra

    if size(hail_hydra) > 0 then
        global.config.hail_hydra.enabled = true
        global.config.hail_hydra.hydras = hail_hydra
    end

    Event.add(Template.events.on_void_removed, function (event)
        local force = game.forces.enemy
        local evolution_factor = force.evolution_factor
        force.evolution_factor = evolution_factor + 0.0000024

        local position = event.position
        local x = position.x
        local y = position.y

        if (x * x + y * y < alien_minimum_distance_square or alien_probability < random()) then
            return
        end

        spawn_aliens(get_aliens(create_spawner_request(3), force.evolution_factor), force, event.surface, x, y)
    end)
end

function AlienSpawner.get_extra_map_info(config)
    return [[Alien Spawner, aliens might spawn when mining!
Spawn chance: ]] .. (config.alien_probability * 100) .. [[%
Minimum spawn distance: ]] .. config.alien_minimum_distance .. ' tiles'
end

function AlienSpawner.on_init()
    -- base factorio =                time_factor = 0.000004
    game.map_settings.enemy_evolution.time_factor = 0.000008
    game.forces.enemy.evolution_factor = 0.1
    game.map_settings.pollution.enabled = false
end

return AlienSpawner
