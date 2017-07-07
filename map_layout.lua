--[[
Hey there!

With this you can customize your world generation.
Just set the map_styles of your choice to true to make it happen.

notes:

This file serves as framework for dynamicly loading the game styles.
Any enabled styled will be lazy loaded and used. Do NOT handle the on_chunk_generated event yourself.
To learn how to write a valid style refere to /locale/map_layout/sample.lua

--Author Valansch
--]]

require "locale.map_layout.perlin_noise"
perlin:load(  )





--TODO: IMPLEMENT BROKEN STYLES. DO NOT MERGE INTO MASTER BEFORE THIS IS

local map_styles = {
	--Map generation styles:
sample = true,
rail_grid = true,
up = false, --broken
right = false, --broken
square = false, --broken
circle = false, --broken
rivers = false, --broken
red_planet = false, --broken
red_planet_2 = false, --broken
red_planet_2_messy_resources = false, --broken
dagobah_swamp = false, --broken
grey_void = false, --broken
perlin_01 = false, --broken
perlin_02 = false, --broken
perlin_noise = false, --broken
gens_neko = false, --broken



--resource generation styles:
	resource_rainbow = false, --broken
	resource_cluster_truck = false --broken
}


local selected_styles = {}

for name, enabled in pairs(map_styles) do
	if enabled then
		local module = require("locale.map_layout." .. name)
		if type(module) == "boolean" then
			debug.print("Error loading module ''" .. name .."''. No table containing module elements returned")
		else
			table.insert(selected_styles, module)
		end
	end
end



local on_chunk_generated = function(event)
	for _, module in pairs(selected_styles) do
		if type(module) == "table" and type(module.on_chunk_generated) == "function" then
			module.on_chunk_generated(event)
		else
			log("Module does not contain function on_chunk_generated. Check if all enabled styles are valid modules.")
		end
	end
end

Event.register(defines.events.on_chunk_generated, on_chunk_generated)
