--[[
This file is used to choose which styles you want.
You may choose up to one of each type shapes, terrain, ores and misc by removing uncommenting the line.
If you want to add your own module, just add it to the others
in this file and your run_*type*_module(event) function will be called.
--]]


--shapes--
--require "locale.gen_shape.right"
--require "locale.gen_shape.up"
--require "locale.gen_shape.maze"
--require "locale.gen_shape.spiral"
--require "locale.gen_shape.spiral_tri"
--require "locale.gen_shape.spiral2"
--require "locale.gen_shape.donut"
--require "locale.gen_shape.rectangular_spiral"
--require "locale.gen_shape.cross"
--require "locale.gen_shape.infinite_mazes"



--terrain--
--require "locale.gen_terrain.neko_bridged_rivers"

--ores--
--require "locale.gen_ores.neko_crazy_ores"

--everything else. You may use more than one of these, but beware they might not be compatible
miscs = {}
--miscs[1] = require "locale.gen_misc.rail_grid"



local on_chunk_generated = function(event)
	if run_shape_module ~= nil then
		if run_shape_module(event) then
			if run_terrain_module ~= nil then
				run_terrain_module(event)
			elseif run_ores_module ~= nil then
				run_ores_module(event)
			end
		end
	else
		if run_terrain_module ~= nil then
			run_terrain_module(event)
		elseif run_ores_module ~= nil then
			run_ores_module(event)
		end
	end
	for _,v in pairs(miscs) do
		v.on_chunk_generated(event)
	end
end

Event.register(defines.events.on_chunk_generated, on_chunk_generated)
