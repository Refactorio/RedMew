local b = require 'map_gen.shared.builders'
local start_value = b.euclidean_value(0, 0.35)
local value = b.exponential_value(0, 0.06, 1.55)

local function resource(primary_ore, secondary_ore)
    return function(_, _, world)
        local v = value(world.x, world.y)
        local ore
        if v > 1500 then
            ore = primary_ore
        else
            ore = secondary_ore
        end

        return {
            name = ore,
            amount = v
        }
    end
end

return {
    {
        name = 'copper-ore',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {
                resource = resource('copper-ore', 'iron-ore'),
                weight = 15
            },
            {
                resource = resource('copper-ore', 'copper-ore'),
                weight = 70
            },
            {
                resource = resource('copper-ore', 'stone'),
                weight = 10
            },
            {
                resource = resource('copper-ore', 'coal'),
                weight = 5
            }
        }
    },
    {
        name = 'coal',
        ['tiles'] = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3',
            [4] = 'dirt-4',
            [5] = 'dirt-5',
            [6] = 'dirt-6',
            [7] = 'dirt-7'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {
                resource = resource('coal', 'iron-ore'),
                weight = 14
            },
            {
                resource = resource('coal', 'copper-ore'),
                weight = 6
            },
            {
                resource = resource('coal', 'stone'),
                weight = 10
            },
            {
                resource = resource('coal', 'coal'),
                weight = 70
            }
        }
    },
    {
        name = 'iron-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {
                resource = resource('iron-ore', 'iron-ore'),
                weight = 75
            },
            {
                resource = resource('iron-ore', 'copper-ore'),
                weight = 13
            },
            {
                resource = resource('iron-ore', 'stone'),
                weight = 7
            },
            {
                resource = resource('iron-ore', 'coal'),
                weight = 5
            }
        }
    },
    {
        name = 'stone',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {
                resource = resource('stone', 'iron-ore'),
                weight = 25
            },
            {
                resource = resource('stone', 'copper-ore'),
                weight = 10
            },
            {
                resource = resource('stone', 'stone'),
                weight = 60
            },
            {
                resource = resource('stone', 'coal'),
                weight = 5
            }
        }
    }
}
