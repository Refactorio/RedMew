local Task = require 'utils.Task'
local Token = require 'utils.token'
local random = math.random

local CreateParticles = {}

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
    for _ = particle_count, 1, -1 do
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
    for _ = particle_count, 1, -1 do
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

    for i = 1, 2 do
        sequences[i] = {frame = i*random(1,15), prototype = create_ceiling_prototype('explosion-remnants-particle', x, y)}
    end
    for i = 3, 6 do
        sequences[i] = {frame = i*random(1,15), prototype = create_ceiling_prototype('stone-particle', x, y)}
    end

    play_particle_sequence(surface, sequences)
end

return CreateParticles
