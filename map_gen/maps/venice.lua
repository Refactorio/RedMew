local b = require "map_gen.shared.builders"
local ScenarioInfo = require 'features.gui.info'
local Event = require 'utils.event'
local pic = require "map_gen.data.presets.venice"

ScenarioInfo.set_map_name('Venice')
ScenarioInfo.set_map_description(
    [[
A terrain full of beautiful water channels and numerous bridges 
poses a nice logistical puzzle when planning a good rail network.
]]
)
ScenarioInfo.add_map_extra_info(
    [[
Pollution spreads faster over water and slows down considerably in forests. 
Will you take advantage of the effect of the forests when it comes to expanding, 
or do you prefer to go hunting for the most mineral-rich mines, devastating 
any enemy you find in your path?
Will you use the larger bridges to get your trains into the central area 
or do you prefer to leave the train stations on the outskirts and use 
conveyor belts and/or robots for the journey inside?
]]
)

ScenarioInfo.set_new_info(
    [[
2020-08-25 - Abarel
- Added map descriptions
- Disabled landfill to prevent cheating
]]
)

pic = b.decompress(pic)
local map = b.picture(pic)

map = b.translate(map, 90, 190)

map = b.scale(map, 2, 2)

map = b.change_tile(map, false, "deepwater")

local function on_init()
    local player_force = game.forces.player
    player_force.technologies['landfill'].enabled = false           -- disable landfill
end
Event.on_init(on_init)

return map
