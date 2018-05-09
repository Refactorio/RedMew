local b = require "map_gen.shared.builders"

local land = b.rectangle(32,16)


local circle = b.circle(4)
local patch = b.resource(b.circle(8), "iron-ore")

local tree = b.entity(circle, "tree-01")

--[[ local shape = b.apply_entity(land, patch)
shape = b.apply_entity(shape, tree) ]]

local shape = b.apply_entities(land, {patch, tree})

return shape