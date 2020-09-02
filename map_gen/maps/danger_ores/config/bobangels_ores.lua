local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

local ratio_mixed = 80 -- % purity in the ore
local main_value = value(0, 0.5)

local ores = {
    ['angels-ore1'] = {
        -- Saphirite
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['weight'] = 15,
        ['ratios'] = {}
    },
    ['angels-ore2'] = {
        -- Jivolite
        ['tiles'] = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {}
    },
    ['angels-ore3'] = {
        -- Stiratite
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {}
    },
    ['angels-ore4'] = {
        -- crotinnium
        ['tiles'] = {
            [1] = 'grass-3',
            [2] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {}
    },
    ['angels-ore5'] = {
        -- rubyte
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {}
    },
    ['angels-ore6'] = {
        -- bobmonium-ore
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {}
    },
    ['coal'] = {
        ['tiles'] = {
            [1] = 'dirt-5',
            [2] = 'dirt-6',
            [3] = 'dirt-7'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {}
    }
}

for ore_name, ore_data in pairs(ores) do
    local ratios = {
        {resource = b.resource(b.full_shape, ore_name, main_value), weight = ratio_mixed}
    }
    local sum_other_weights = 0
    for name, data in pairs(ores) do
        if name ~= ore_name then
            sum_other_weights = sum_other_weights + data.weight
        end
    end

    for name, data in pairs(ores) do
        if name ~= ore_name then
            local weight = (100 - ratio_mixed) * (data.weight / sum_other_weights)
            ratios[#ratios + 1] = {resource = b.resource(b.full_shape, name, value(0, 0.5)), weight = weight}
        end
    end

    ore_data.ratios = ratios
end

return ores
