local worm_names = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret'}
local spawner_names = {'biter-spawner', 'spitter-spawner'}
local factor = 8 / (1024 * 32)
local max_chance = 1/8
return function(_, _, world)
    local d = math.sqrt(world.x * world.x + world.y * world.y)

    if d < 300 then
        return nil
    end

    if math.random(8) == 1 then
        local lvl
        if d < 400 then
            lvl = 1
        elseif d < 550 then
            lvl = 2
        else
            lvl = 3
        end

        local chance = math.min(max_chance, d * factor)

        if math.random() < chance then
            local worm_id = math.random(1, lvl)
            return {name = worm_names[worm_id]}
        end
    else
        local chance = math.min(max_chance, d * factor)
        if math.random() < chance then
            local spawner_id = math.random(2)
            return {name = spawner_names[spawner_id]}
        end
    end
end
