local Task = require 'utils.Task'
local Global = require 'utils.global'
local Token = require 'utils.token'
local Command = require 'utils.command'
local Event = require 'utils.event'
local random = math.random
local ceil = math.ceil
local floor = math.floor
local format = string.format

local CreateParticles = {}

local settings = {
    scale = 1.0,
    particles_spawned_buffer = 0,
    max_particles_in_three_seconds = 12000,
}

Global.register({
    settings = settings,
}, function (tbl)
    settings = tbl.settings
end)

---sets the scale of particles. 1.0 means 100%, 0.5 would mean spawn only 50% of the particles.
---@param scale number
function CreateParticles.set_scale(scale)
    if scale < 0 or scale > 1 then
        error(format('Scale must range from 0 to 1'))
    end

    settings.scale = scale
end

---Returns the current scale
function CreateParticles.get_scale()
    return settings.scale
end

local function get_particle_cap()
    return settings.max_particles_in_three_seconds * (settings.scale + 0.1)
end

---Returns whether or not more particles may be spawned, scale minimum is 0.1
local function may_spawn_particles()
    return settings.particles_spawned_buffer < get_particle_cap()
end

--- resets the amount of particles in the past 3 seconds so new ones may spawn
Event.on_nth_tick(191, function ()
    settings.particles_spawned_buffer = 0
end)

Command.add('set-particle-scale', {
    description = 'Sets the particle scale between 0 and 1. Lower means less particles per function and a lower buffer size per 3 seconds.',
    arguments = {'scale'},
    admin_only = true,
    allowed_by_server = true,
}, function (arguments, player)
    local scale = tonumber(arguments.scale)
    if scale == nil or scale < 0 or scale > 1 then
        player.print('Scale must be a valid number ranging from 0 to 1')
        return
    end

    CreateParticles.set_scale(scale)
    local p = player.print
    p(format('Particle scale changed to: %.2f', scale))
    p(format('Particles per 3 seconds: %d', get_particle_cap()))
end)

Command.add('get-particle-scale', {
    description = 'Shows the current particle scale.',
    admin_only = true,
    allowed_by_server = true,
}, function (_, player)
    local p = player.print
    p(format('Particle scale: %.2f', CreateParticles.get_scale()))
    p(format('Particles per 3 seconds: %d', get_particle_cap()))
end)

---Scales the count to round the fraction up. Always returns at least 1 unless the particle limit is reached.
---Useful for particle spawning that influences gameplay for visual indications.
---@param count number
local function scale_ceil(count)
    if not may_spawn_particles() then
        return 0
    end

    local scale = settings.scale
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
    local scale = settings.scale
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
    params.surface.create_entity(params.prototype)
end)

local function play_particle_sequence(surface, sequences)
    local create_entity = surface.create_entity
    for i = 1, #sequences do
        local sequence = sequences[i]
        local frame = sequence.frame
        if frame == 1 then
            create_entity(sequence.prototype)
        else
            Task.set_timeout_in_ticks(frame, on_play_particle, {surface = surface, prototype = sequence.prototype})
        end
    end
end

---@param create_entity function a reference to a surface.create_entity
---@param particle_count number particle count to spawn
---@param position Position
function CreateParticles.destroy_rock(create_entity, particle_count, position)
    for _ = scale_floor(particle_count), 1, -1 do
        settings.particles_spawned_buffer = settings.particles_spawned_buffer + 1
        create_entity({
            position = position,
            name = 'stone-particle',
            movement = {random(-5, 5) * 0.01, random(-5, 5) * 0.01},
            frame_speed = 1,
            vertical_speed = random(12, 14) * 0.01,
            height = random(9, 11) * 0.1,
        })
    end
end

---@param create_entity function a reference to a surface.create_entity
---@param particle_count number particle count to spawn
---@param position Position
function CreateParticles.blood_explosion(create_entity, particle_count, position)
    for _ = particle_count, 1, -1 do
        create_entity({
            position = position,
            name = 'blood-particle',
            movement = {random(-5, 5) * 0.01, random(-5, 5) * 0.01},
            frame_speed = 1,
            vertical_speed = random(10, 12) * 0.01,
            height = random(5, 15) * 0.1,
        })
    end
end

---@param create_entity function a reference to a surface.create_entity
---@param particle_count number particle count to spawn
---@param position Position
function CreateParticles.mine_rock(create_entity, particle_count, position)
    for _ = scale_floor(particle_count), 1, -1 do
        settings.particles_spawned_buffer = settings.particles_spawned_buffer + 1
        create_entity({
            position = position,
            name = 'stone-particle',
            movement = {random(-5, 5) * 0.01, random(-5, 5) * 0.01},
            frame_speed = 1,
            vertical_speed = random(8, 10) * 0.01,
            height = random(5, 8) * 0.1,
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
