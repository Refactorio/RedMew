local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local Event = require 'utils.event'
local global = require 'utils.global'

-- Dragon Fractal Map by R. Nukem
local block = 64
local h = 4*block
local w = block

-- Level 0
local map1 = b.translate(b.rectangle(w, h), w/2, -h/2)
local map2
local a1 = w
local b1 = h
local a2

-- How many iterations of "unfolding" the fractal?
--Note each iteration on the order of doubles the map size each iteration
local FractalOrder = 10

-- Loop to unfold the fractal
for n = 1, FractalOrder, 1
do
	map1 = b.translate(map1,-a1,b1)
	map2 = b.rotate(map1,math.pi/2)
	map1 = b.add(map1,map2)
	map1 = b.translate(map1,a1,-b1)
	a2 = a1
	a1 = a1 + b1
	b1 = b1 - a2
end

map1 = b.translate(map1, -block/2, block/2)

-- make starting area
local start_region = b.rectangle(block, block)
map1 = b.subtract(map1, start_region)
start_region = b.change_tile(start_region, true, 'grass-1')
start_region = b.remove_map_gen_resources(start_region)
local start_water = b.change_tile(b.circle(5), true, 'water')
map1 = b.any {start_water, start_region, map1}
--make starting ores
local value = b.manhattan_value
local ore_shape = b.scale(b.circle(30), 0.15)
local start_ore = b.circle(30)
local start_iron = b.resource(start_ore, 'iron-ore', value(1000, 0))
local start_copper = b.resource(start_ore, 'copper-ore', value(750, 0))
local start_coal = b.resource(start_ore, 'coal', value(500, 0))
local start_stone = b.resource(start_ore, 'stone', value(500, 0))
start_ore = b.segment_pattern({start_coal, start_stone, start_copper, start_iron})
ore_shape = b.choose(b.circle(30), start_ore, ore_shape)

--apply starting ores to map
map1 = b.apply_entity(map1, ore_shape)
--shift spawn so player doesn't die to start water
map1 = b.translate(map1, 0, block/2)

return map1
