local worms_per_chunk = 50
local small_worm_spawn_distance = 100
local medium_worm_spawn_distance = 150
local big_worm_spawn_distance = 200

local worm_names = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret'}

local chance = worms_per_chunk / (32 * 32)

return function(_, _, world)
    local distance = math.sqrt(world.x * world.x + world.y * world.y)

    if distance > small_worm_spawn_distance - 32 then
        local lvl = 1
        if distance > medium_worm_spawn_distance then
            lvl = 2
        end
        if distance > big_worm_spawn_distance then
            lvl = 3
        end
        if math.random() < chance then
            local worm_id = math.random(1, lvl)
            return {name = worm_names[worm_id]}
        end
    end
end
