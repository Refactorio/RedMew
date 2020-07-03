local Task = require 'utils.task'
local Global = require 'utils.global'
local Token = require 'utils.token'
local Command = require 'utils.command'
local Event = require 'utils.event'
local Ranks = require 'resources.ranks'
local random = math.random
local ceil = math.ceil
local floor = math.floor
local format = string.format

local CreateParticles = {}

local settings = {
    faction = 1.0,
    particles_spawned_buffer = 0,
    max_particles_per_second = 4000,
}

Global.register({
    settings = settings,
}, function (tbl)
    settings = tbl.settings
end)

---sets the scale of particles. 1.0 means 100%, 0.5 would mean spawn only 50% of the particles.
---@param fraction number
function CreateParticles.set_fraction(fraction)
    if fraction < 0 or fraction > 1 then
        error(format('Fraction must range from 0 to 1'))
    end

    settings.faction = fraction
end

---Returns the current scale
function CreateParticles.get_fraction()
    return settings.faction
end

local function get_particle_cap()
    return settings.max_particles_per_second * (settings.faction + 0.1)
end

---Returns whether or not more particles may be spawned, scale minimum is 0.1
local function may_spawn_particles()
    return settings.particles_spawned_buffer < get_particle_cap()
end

--- resets the amount of particles in the past second so new ones may spawn
Event.on_nth_tick(63, function ()
    settings.particles_spawned_buffer = 0
end)

Command.add('particle-scale', {
    description = {'command_description.particle_scale'},
    arguments = {'fraction'},
    default_values = {fraction = false},
    required_rank = Ranks.admin,
    allowed_by_server = true,
}, function (arguments, player)
    local p = player and player.print or print

    local fraction = arguments.fraction

    if fraction ~= false then
        local scale = tonumber(fraction)
        if scale == nil or scale < 0 or scale > 1 then
            p('Scale must be a valid number ranging from 0 to 1')
            return
        end
        CreateParticles.set_fraction(scale)
    end

    p(format('Particle fraction: %.2f', CreateParticles.get_fraction()))
    p(format('Particles per second: %d', get_particle_cap()))
end)

---Scales the count to round the fraction up. Always returns at least 1 unless the particle limit is reached.
---Useful for particle spawning that influences gameplay for visual indications.
---@param count number
local function scale_ceil(count)
    if not may_spawn_particles() then
        return 0
    end

    local scale = settings.faction
    if scale == 0 then
        return 1
    end
    if scale < 1 and count > 1 then
        count = ceil(count * scale)
    end

    return count
end

---Scales the count to round the fraction down.
---Useful for particle spawning that doesn't influence gameplay.
---@param count number
local function scale_floor(count)
    local scale = settings.faction
    if scale == 0 then
        return 0
    end
    if not may_spawn_particles() then
        return 0
    end
    if scale < 1 then
        count = floor(count * scale)
    end

    return count
end

local on_play_particle = Token.register(function (params)
    params.surface.create_particle(params.prototype)
end)

local function play_particle_sequence(surface, sequences)
    local create_particle = surface.create_particle
    for i = 1, #sequences do
        local sequence = sequences[i]
        local frame = sequence.frame
        if frame == 1 then
            create_particle(sequence.prototype)
        else
            Task.set_timeout_in_ticks(frame, on_play_particle, {surface = surface, prototype = sequence.prototype})
        end
    end
end

---@param create_particle function a reference to a surface.create_particle
---@param particle_count number particle count to spawn
---@param position Position
function CreateParticles.destroy_rock(create_particle, particle_count, position)
    for _ = scale_floor(particle_count), 1, -1 do
        settings.particles_spawned_buffer = settings.particles_spawned_buffer + 1
        create_particle({
            name = 'stone-particle',
            position = position,
            movement = {random(-5, 5) * 0.01, random(-5, 5) * 0.01},
            height = random(9, 11) * 0.1,
            vertical_speed = random(12, 14) * 0.01,
            frame_speed = 1,
        })
    end
end

---@param create_particle function a reference to a surface.create_particle
---@param particle_count number particle count to spawn
---@param position Position
function CreateParticles.blood_explosion(create_particle, particle_count, position)
    for _ = particle_count, 1, -1 do
        create_particle({
            name = 'blood-particle',
            position = position,
            movement = {random(-5, 5) * 0.01, random(-5, 5) * 0.01},
            height = random(5, 15) * 0.1,
            vertical_speed = random(10, 12) * 0.01,
            frame_speed = 1,
        })
    end
end

---@param create_particle function a refrence to a surface.create_particle
---@param particle_count number particle count to spawn
---@param position Position
function CreateParticles.mine_rock(create_particle, particle_count, position)
    for _ = scale_floor(particle_count), 1, -1 do
        settings.particles_spawned_buffer = settings.particles_spawned_buffer + 1
        create_particle({
            name = 'stone-particle',
            position = position,
            movement = {random(-5, 5) * 0.01, random(-5, 5) * 0.01},
            height = random(5, 8) * 0.1,
            vertical_speed = random(8, 10) * 0.01,
            frame_speed = 1,
        })
    end
end


---Creates a prototype for LuaSurface.create_entity
---@param particle string name of the particle
---@param x number
---@param y number
local function create_ceiling_prototype(particle, x, y)
    return {
        name = particle,
        position = {x = x + random(0, 1), y = y + random(0, 1)},
        movement = {random(-5, 5) * 0.002, random(-5, 5) * 0.002},
        frame_speed = 1,
        vertical_speed = 0,
        height = 3
    }
end

---Creates a crumbling effect from the ceiling
---@param surface LuaSurface
---@param position table
function CreateParticles.ceiling_crumble(surface, position)
    local sequences = {}
    local x = position.x
    local y = position.y
    local smoke_scale = scale_ceil(2)
    local stone_scale = scale_floor(4)

    -- pre-calculate how many particles will be spawned. Prevents spawning too many particles over ticks.
    local particles = settings.particles_spawned_buffer

    for i = 1, smoke_scale do
        particles = particles + 1
        sequences[i] = {frame = i*random(1,15), prototype = create_ceiling_prototype('explosion-remnants-particle', x, y)}
    end
    for i = smoke_scale + 1, smoke_scale + stone_scale do
        particles = particles + 1
        sequences[i] = {frame = i*random(1,15), prototype = create_ceiling_prototype('stone-particle', x, y)}
    end

    settings.particles_spawned_buffer = particles

    play_particle_sequence(surface, sequences)
end

return CreateParticles
