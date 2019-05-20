local b = require 'map_gen.shared.builders'
local map_entities = {
          require 'map_gen.shared.loot_items',
          require 'map_gen.shared.car_body'
}

local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

RS.set_map_gen_settings(
    {
        MGSP.water_none
    }
)

local map = true

b.apply_entities(map, map_entities)

return map
