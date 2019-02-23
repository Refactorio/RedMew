-- Cut off a limb, and two more shall take its place!
local Event = require 'utils.event'
local CreateParticles = require 'features.create_particles'
local Token = require 'utils.token'
local Global = require 'utils.global'
local table = require 'utils.table'

local random = math.random
local floor = math.floor
local ceil = math.ceil
local pairs = pairs
local clear_table = table.clear_table
local compound = defines.command.compound
local logical_or = defines.compound_command.logical_or
local attack = defines.command.attack
local attack_area = defines.command.attack_area

local spawn_table = {}
for k, v in pairs(global.config.hail_hydra.hydras) do
    spawn_table[k] = v
end

local function formula(evo)
    evo = evo * 100
    local value = (0.00003 * evo ^ 3 + 0.004 * evo ^ 2 + 0.3 * evo) * 0.01
    return value <= 1 and value or 1
end

local primitives = {
    evolution_scale = formula,
    online_player_scale_enabled = global.config.hail_hydra.online_player_scale_enabled,
    online_player_scale = global.config.hail_hydra.online_player_scale,
    enabled = nil
}

Global.register(
    {
        primitives = primitives,
        spawn_table = spawn_table
    },
    function(tbl)
        primitives = tbl.primitives
        spawn_table = tbl.spawn_table
    end
)

local Public = {}

local function create_attack_command(position, target)
    local command = {type = attack_area, destination = position, radius = 10}
    if target then
        command = {
            type = compound,
            structure_type = logical_or,
            commands = {
                {type = attack, target = target},
                command
            }
        }
    end

    return command
end

local on_died =
    Token.register(
    function(event)
        local entity = event.entity
        local name = entity.name

        local hydra = spawn_table[name]
        if not hydra then
            return
        end

        local position = entity.position
        local force = entity.force

        local num_online_players = #game.connected_players
        local player_scale = 0
        if primitives.online_player_scale_enabled then
            player_scale = (num_online_players - primitives.online_player_scale) * 0.01
        end

        local evolution_factor = primitives.evolution_scale(force.evolution_factor)
        evolution_factor = evolution_factor + evolution_factor * player_scale

        local cause = event.cause
        local surface = entity.surface
        local create_entity = surface.create_entity
        local find_non_colliding_position = surface.find_non_colliding_position

        local command = create_attack_command(position, cause)

        for hydra_spawn, amount in pairs(hydra) do
            local trigger = amount.trigger
            if trigger == nil or trigger < force.evolution_factor then
                local max = amount.max
                local min = amount.min
                max = (max ~= nil and max >= min) and max or min
                if max ~= min then
                    amount = (max - min) * (evolution_factor / primitives.evolution_scale(1)) + min
                else
                    amount = min
                end
            else
                amount = 0
            end
            amount = (amount > 0) and amount or 0

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

            for _ = amount, 1, -1 do
                position = find_non_colliding_position(hydra_spawn, position, 2, 0.4) or position
                local spawned = create_entity({name = hydra_spawn, force = force, position = position})
                if spawned and spawned.type == 'unit' then
                    spawned.set_command(command)
                elseif spawned and cause and cause.valid and cause.force then
                    spawned.shooting_target = cause
                end
            end
        end
    end
)

local function register_event()
    if not primitives.enabled then
        Event.add_removable(defines.events.on_entity_died, on_died)
        primitives.enabled = true
    end
end

--- Enables hail_hydra
function Public.enable_hail_hydra()
    register_event()
end

--- Disables hail_hydra
function Public.disable_hail_hydra()
    if primitives.enabled then
        Event.remove_removable(defines.events.on_entity_died, on_died)
        primitives.enabled = nil
    end
end

--- Sets the evolution scale
-- @param scale <number>
function Public.set_evolution_scale(scale)
    primitives.evolution_scale = scale
end

--- Sets the hydra spawning table
-- @param hydras <table> see config.lua's hail_hydra section for example
function Public.set_hydras(hydras)
    clear_table(spawn_table)
    for k, v in pairs(hydras) do
        spawn_table[k] = v
    end
end

--- Adds to/overwrites parts of the hydra spawning table
-- @param hydras <table> see config.lua's hail_hydra section for example
function Public.add_hydras(hydras)
    for k, v in pairs(hydras) do
        spawn_table[k] = v
    end
end

if global.config.hail_hydra.enabled then
    register_event()
end

return Public
