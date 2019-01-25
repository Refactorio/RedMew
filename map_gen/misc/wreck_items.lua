-- adds some wrecked items around the map, good for MP, reduces total resources pulled from factory, and adds incentive to push out
local Token = require 'utils.token'

local random = math.random

local wreck_item_pool = {
    {name = 'iron-gear-wheel', count = 32},
    {name = 'iron-plate', count = 64},
    {name = 'rocket-control-unit', count = 1},
    {name = 'atomic-bomb', count = 1},
    {name = 'rocket-fuel', count = 7},
    {name = 'coal', count = 8},
    {name = 'rocket-launcher', count = 1},
    {name = 'rocket', count = 32},
    {name = 'copper-cable', count = 128},
    {name = 'land-mine', count = 64},
    {name = 'railgun', count = 1},
    {name = 'railgun-dart', count = 128},
    {name = 'fast-inserter', count = 8},
    {name = 'stack-filter-inserter', count = 2},
    {name = 'belt-immunity-equipment', count = 1},
    {name = 'fusion-reactor-equipment', count = 1},
    {name = 'electric-engine-unit', count = 8},
    {name = 'exoskeleton-equipment', count = 1},
    {name = 'rocket-fuel', count = 10},
    {name = 'used-up-uranium-fuel-cell', count = 3},
    {name = 'uranium-fuel-cell', count = 2},
    {name = 'power-armor', count = 1},
    {name = 'modular-armor', count = 1},
    {name = 'water-barrel', count = 4},
    {name = 'sulfuric-acid-barrel', count = 6},
    {name = 'crude-oil-barrel', count = 8},
    {name = 'energy-shield-equipment', count = 1},
    {name = 'explosive-rocket', count = 32},
}

local entity_list = {
    {name = 'big-ship-wreck-1', chance = 35000, force = 'player'},
    {name = 'big-ship-wreck-2', chance = 45000, force = 'player'},
    {name = 'big-ship-wreck-3', chance = 55000, force = 'player'},
}

local callback =
    Token.register(
    function(entity)
        entity.health = math.random(entity.health)

        entity.insert(wreck_item_pool[random(#wreck_item_pool)])
        entity.insert(wreck_item_pool[random(#wreck_item_pool)])
        entity.insert(wreck_item_pool[random(#wreck_item_pool)])
    end
)

return function()
    local ship = entity_list[random(#entity_list)]

    if math.random(ship.chance) ~= 1 then
        return nil
    end

    ship.callback = callback

    return ship
end
