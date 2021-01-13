local b = require 'map_gen.shared.builders'

local value = b.euclidean_value
return {
    ['iron-ore'] = {
        tiles = {'grass-1', 'grass-2', 'grass-3', 'grass-4'},
        start = value(40, 0),
        shape = b.resource(b.full_shape, 'iron-ore', value(0, 0.6)),
        weight = function(v)
            return 4 * (v ^ 4) + 0.25
        end
    },
    ['copper-ore'] = {
        tiles = {'red-desert-0', 'red-desert-1', 'red-desert-2', 'red-desert-3'},
        start = value(40, 0),
        shape = b.resource(b.full_shape, 'copper-ore', value(0, 0.6)),
        weight = function(v)
            return 3 * (v ^ 4) + 0.2
        end
    },
    ['coal'] = {
        tiles = {'dirt-1', 'dirt-2', 'dirt-3', 'dirt-4', 'dirt-5', 'dirt-6', 'dirt-7'},
        start = value(40, 0),
        shape = b.resource(b.full_shape, 'coal', value(0, 0.6)),
        weight = function(v)
            return 2.5 * (v ^ 6) + 0.2
        end
    },
    ['stone'] = {
        tiles = {'sand-1', 'sand-2', 'sand-3'},
        start = value(40, 0),
        shape = b.resource(b.full_shape, 'stone', value(0, 0.6)),
        weight = function(v)
            return 1 * (v ^ 6) + 0.15
        end
    }
}
