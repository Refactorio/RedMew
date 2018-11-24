local random = math.random

local CreateParticles = {}

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

return CreateParticles
