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

---Triggers mining at the collision_box of the alien, to free it
local do_alien_mining = Token.register(function(params)
    local surface = params.surface
    local create_entity = surface.create_entity
    local find_non_colliding_position = surface.find_non_colliding_position
    local find_entities_filtered = surface.find_entities_filtered

    for _, area in ipairs(params.positions_to_mine) do
        local rocks = find_entities_filtered({area = area, name = {'sand-rock-big', 'rock-huge'}})

        if (0 == #rocks) then
            break
        end

        -- with multiple rocks opening at once, it will spawn less particles in total per rock
        local particle_count = 16 - ((#rocks - 1) * 5)
        for _, rock in pairs(rocks) do
            raise_event(defines.events.on_entity_died, {entity = rock})
            for _ = particle_count, 1, -1 do
                create_entity({
                    position = rock.position,
                    name = 'stone-particle',
                    movement = {random(-5, 5) * 0.01, random(-5, 5) * 0.01},
                    frame_speed = 1,
                    vertical_speed = random(12, 14) * 0.01,
                    height = random(9, 11) * 0.1,
                })
            end
            rock.destroy()
        end
    end

    for _, prototype in ipairs(params.locations_to_spawn) do
        -- amount is not used for aliens prototypes, it just carries along in the params
        local amount = prototype.amount
        while amount > 0 do
            prototype.position = find_non_colliding_position(prototype.name, prototype.position, 2, 0.4) or prototype.position
            create_entity(prototype)
            amount = amount - 1
        end
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
    local areas_to_mine = {}
    local locations_to_spawn = {}

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
                insert(areas_to_mine, offset_area)
                insert(locations_to_spawn, {name = name, position = {x = x_center, y = y_center}, force = force, amount = amount})
                break
            end
        end
    end

    -- can't do mining in the same tick as it would invalidate the rock just mined and there
    -- is no way to distinguish them as multiple can occupy the same position
    if #locations_to_spawn > 0 then
        Task.set_timeout_in_ticks(1, do_alien_mining, {
            surface = surface,
            positions_to_mine = areas_to_mine,
            locations_to_spawn = locations_to_spawn,
        })
    end
end

--[[--
    Registers all event handlers.
]]
function AlienSpawner.register(config)
    local alien_minimum_distance_square = config.alien_minimum_distance ^ 2
    local alien_probability = config.alien_probability
    local hail_hydra = config.hail_hydra

    if hail_hydra then
        Event.add(defines.events.on_entity_died, function (event)
            local entity = event.entity
            local name = entity.name

            local force
            local position
            local surface
            local create_entity
            local find_non_colliding_position

            for alien, hydras in pairs(hail_hydra) do
                if name == alien then
                    for hydra_spawn, amount in pairs(hydras) do
                        local extra_chance = amount % 1
                        if extra_chance > 0 then
                            if random() <= extra_chance then
                                amount = ceil(amount)
                            else
                                amount = floor(amount)
                            end
                        end

                        while amount > 0 do
                            force = force or entity.force
                            position = position or entity.position
                            surface = surface or entity.surface
                            create_entity = create_entity or surface.create_entity
                            find_non_colliding_position = find_non_colliding_position or surface.find_non_colliding_position
                            position = find_non_colliding_position(hydra_spawn, position, 2, 0.4) or position
                            create_entity({name = hydra_spawn, force = force, position = position})
                            amount = amount - 1
                        end
                    end
                    break
                end
            end
        end)
    end

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
