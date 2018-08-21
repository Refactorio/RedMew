local b = require 'map_gen.shared.builders'

local spiral = b.circular_spiral(72, 144)
spiral = b.any {spiral, b.translate(b.circle(128), 12, -12)}

local start_ore_patch = b.scale(spiral, 0.1)

local function constant(amount)
    return function()
        return amount
    end
end
local iron = b.resource(start_ore_patch, 'iron-ore', constant(500))
local copper = b.resource(start_ore_patch, 'copper-ore', constant(500))
local stone = b.resource(start_ore_patch, 'stone', constant(500))
local coal = b.resource(start_ore_patch, 'coal', constant(500))

start_ore_patch = b.segment_pattern {iron, copper, stone, coal}

local start_ore_bounds = b.circle(32)
start_ore_patch = b.choose(start_ore_bounds, start_ore_patch, b.empty_shape)
start_ore_patch = b.translate(start_ore_patch, 0, 32)

local map = b.apply_entity(spiral, start_ore_patch)

return map
