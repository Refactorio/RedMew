local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local Perlin = require 'map_gen.shared.perlin_noise'

local match = string.match
local remove = table.remove

local enemy_seed = 420420

local market_items = require 'resources.market_items'
for i = #market_items, 1, -1 do
    if match(market_items[i].name, 'flamethrower') then
        remove(market_items, i)
    end
end

Event.add(
    defines.events.on_research_finished,
    function(event)
        local p_force = game.forces.player
        local r = event.research

        if r.name == 'flamethrower' then
            p_force.recipes['flamethrower'].enabled = false
            p_force.recipes['flamethrower-turret'].enabled = false
        end
    end
)

local trees = {
    'tree-01',
    'tree-02',
    'tree-02-red',
    'tree-03',
    'tree-04',
    'tree-05',
    'tree-06',
    'tree-06-brown',
    'tree-07',
    'tree-08',
    'tree-08-brown',
    'tree-08-red',
    'tree-09',
    'tree-09-brown',
    'tree-09-red'
}

local trees_count = #trees

local function tree_shape()
    local tree = trees[math.random(trees_count)]

    return {name = tree}
    --, always_place = true}
end

local worm_names = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret'}
local spawner_names = {'biter-spawner', 'spitter-spawner'}
local factor = 10 / (768 * 32)
local max_chance = 1 / 6

local scale_factor = 32
local sf = 1 / scale_factor
local m = 1 / 850
local function enemy(x, y, world)
    local d = math.sqrt(world.x * world.x + world.y * world.y)

    if d < 2 then
        return nil
    end

    if d < 100 then
        return tree_shape()
    end

    local threshold = 1 - d * m
    threshold = math.max(threshold, 0.25) -- -0.125)

    x, y = x * sf, y * sf
    if Perlin.noise(x, y, enemy_seed) > threshold then
        if math.random(8) == 1 then
            local lvl
            if d < 400 then
                lvl = 1
            elseif d < 650 then
                lvl = 2
            else
                lvl = 3
            end

            local chance = math.min(max_chance, d * factor)

            if math.random() < chance then
                local worm_id
                if d > 1000 then
                    local power = 1000 / d
                    worm_id = math.ceil((math.random() ^ power) * lvl)
                else
                    worm_id = math.random(lvl)
                end

                return {name = worm_names[worm_id]}
            --, always_place = true}
            end
        else
            local chance = math.min(max_chance, d * factor)
            if math.random() < chance then
                local spawner_id = math.random(2)
                return {name = spawner_names[spawner_id]}
            --, always_place = true}
            end
        end
    else
        return tree_shape()
    end
end

local map = b.full_shape

map = b.change_map_gen_tile(map, 'water', 'water-green')
map = b.change_map_gen_tile(map, 'deepwater', 'deepwater-green')

map = b.apply_entity(map, enemy)

return map
