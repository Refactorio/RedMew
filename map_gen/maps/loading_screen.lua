local b = require "map_gen.shared.builders"
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Loading Screen')
ScenarioInfo.set_map_description(
[[
Did I, or did I not enter a server?
Why am I still seeing the menu background???
]]
)

local pic = require "map_gen.data.presets.factory"
pic = b.decompress(pic)
local map = b.picture(pic)

return map
