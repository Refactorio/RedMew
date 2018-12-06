-- Cut off a limb, and two more shall take its place!
local Event = require 'utils.event'
local CreateParticles = require 'features.create_particles'
local random = math.random
local floor = math.floor
local ceil = math.ceil
local pairs = pairs
local compound = defines.command.compound
local logical_or = defines.compound_command.logical_or
local attack = defines.command.attack
local attack_area = defines.command.attack_area
local config = global.config.hail_hydra
local hydras = config.hydras

local function create_attack_command(position, target)
    local command = {type = attack_area, destination = position, radius = 10}
    if target then
        command = {type = compound, structure_type = logical_or, commands = {
            {type = attack, target = target},
            command,
        }}
    end

    return command
end


Event.add(defines.events.on_entity_died, function (event)
    local entity = event.entity
    local name = entity.name

    local hydra = hydras[name]
    if not hydra then
        return
    end

    local position = entity.position
    local force = entity.force
    local evolution_factor = force.evolution_factor
    local cause = event.cause

    local surface = entity.surface
    local create_entity = surface.create_entity
    local find_non_colliding_position = surface.find_non_colliding_position

    local command = create_attack_command(position, cause)

    for hydra_spawn, amount in pairs(hydra) do
        amount = amount + evolution_factor
        local extra_chance = amount % 1
        if extra_chance > 0 then
            if random() <= extra_chance then
                amount = ceil(amount)
            else
                amount = floor(amount)
            end
        end
        local particle_count

        if amount > 4 then
            particle_count = 60
        else
            particle_count = amount * 15
        end

        CreateParticles.blood_explosion(create_entity, particle_count, position)

        for _ = amount, 1, -1  do
            position = find_non_colliding_position(hydra_spawn, position, 2, 0.4) or position
            local spawned = create_entity({name = hydra_spawn, force = force, position = position})
            if spawned and spawned.type == 'unit' then
                spawned.set_command(command)
            elseif spawned and cause then
                spawned.shooting_target = cause
            end
        end
    end
end)
