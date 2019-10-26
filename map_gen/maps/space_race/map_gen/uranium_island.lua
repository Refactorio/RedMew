local b = require 'map_gen.shared.builders'

local inf = function()
    return 100000000
end

local uranium_island = b.circle(10)
uranium_island = b.remove_map_gen_resources(uranium_island)
local uranium_ore = b.resource(b.rectangle(2, 2), 'uranium-ore', inf, true)
uranium_island = b.apply_entity(uranium_island, uranium_ore)

local uranium_island_water = b.change_tile(b.circle(20), true, 'water')
local uranium_island_bridge = b.all({b.any({b.line_x(2), b.line_y(2)}), b.circle(20)})
uranium_island_bridge = b.change_tile(uranium_island_bridge, true, 'water-shallow')
uranium_island_water = b.if_else(uranium_island_bridge, uranium_island_water)

uranium_island = b.if_else(uranium_island, uranium_island_water)

return uranium_island
