local Token = require 'utils.token'
local table = require 'utils.table'

local item_pool = {
    {name = 'firearm-magazine', count = 200, weight = 1250},
    {name = 'land-mine', count = 100, weight = 250},
    {name = 'shotgun-shell', count = 200, weight = 1250},
    {name = 'piercing-rounds-magazine', count = 200, weight = 833.3333},
    {name = 'grenade', count = 100, weight = 500},
    {name = 'defender-capsule', count = 50, weight = 500},
    {name = 'railgun-dart', count = 100, weight = 500},
    {name = 'piercing-shotgun-shell', count = 200, weight = 312.5},
    {name = 'submachine-gun', count = 1, weight = 166.6667},
    {name = 'shotgun', count = 1, weight = 166.6667},
    {name = 'uranium-rounds-magazine', count = 200, weight = 166.6667},
    {name = 'cannon-shell', count = 100, weight = 166.6667},
    {name = 'rocket', count = 100, weight = 166.6667},
    {name = 'distractor-capsule', count = 25, weight = 166.6667},
    {name = 'railgun', count = 1, weight = 100},
    {name = 'flamethrower-ammo', count = 50, weight = 100},
    {name = 'explosive-rocket', count = 100, weight = 100},
    {name = 'explosive-cannon-shell', count = 100, weight = 100},
    {name = 'cluster-grenade', count = 100, weight = 100},
    {name = 'poison-capsule', count = 100, weight = 100},
    {name = 'slowdown-capsule', count = 100, weight = 100},
    {name = 'construction-robot', count = 50, weight = 100},
    {name = 'solar-panel-equipment', count = 5, weight = 833.3333},
    {name = 'artillery-targeting-remote', count = 1, weight = 50},
    {name = 'tank-flamethrower', count = 1, weight = 33.3333},
    {name = 'explosive-uranium-cannon-shell', count = 100, weight = 33.3333},
    {name = 'destroyer-capsule', count = 10, weight = 33.3333},
    {name = 'artillery-shell', count = 10, weight = 25},
    {name = 'battery-equipment', count = 5, weight = 25},
    {name = 'night-vision-equipment', count = 2, weight = 25},
    {name = 'exoskeleton-equipment', count = 2, weight = 166.6667},
    {name = 'rocket-launcher', count = 1, weight = 14.2857},
    {name = 'combat-shotgun', count = 1, weight = 10},
    {name = 'flamethrower', count = 1, weight = 10},
    {name = 'tank-cannon', count = 1, weight = 10},
    {name = 'modular-armor', count = 1, weight = 100},
    {name = 'belt-immunity-equipment', count = 1, weight = 10},
    {name = 'personal-roboport-equipment', count = 1, weight = 100},
    {name = 'energy-shield-equipment', count = 2, weight = 100},
    {name = 'personal-laser-defense-equipment', count = 2, weight = 100},
    {name = 'battery-mk2-equipment', count = 1, weight = 40},
    {name = 'tank-machine-gun', count = 1, weight = 3.3333},
    {name = 'power-armor', count = 1, weight = 33.3333},
    {name = 'fusion-reactor-equipment', count = 1, weight = 33.3333},
    {name = 'artillery-turret', count = 1, weight = 2.5},
    {name = 'artillery-wagon-cannon', count = 1, weight = 1},
    {name = 'atomic-bomb', count = 1, weight = 1}
}

local total_weights = {}
local t = 0
for _, v in ipairs(item_pool) do
    t = t + v.weight
    table.insert(total_weights, t)
end

local callback =
    Token.register(
    function(entity)
        local count = math.random(5, 11)
        for _ = 1, count do
            local i = math.random() * t

            local index = table.binary_search(total_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end

            local loot = item_pool[index]

            entity.insert(loot)
        end
    end
)

return function(x, y)
    if math.random(4096) ~= 1 then
        return nil
    end

    local d_sq = x * x + y * y
    local name
    if d_sq < 40000 then
        name = 'car'
    else
        if math.random(10) == 1 then
            name = 'tank'
        else
            name = 'car'
        end
    end

    -- neutral stops the biters attacking them.
    local entity = {name = name, force = 'neutral', callback = callback}

    return entity
end
