require "map_gen.shared.generate"

local land = rectangle_builder(32,16)


local circle = circle_builder(4)
local patch = resource_module_builder(circle, "iron-ore")

local tree = spawn_entity(circle, "tree-01")

local shape = builder_with_resource(land, patch)

return shape