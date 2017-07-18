--[[
Neko Does stuff to key files because Im a derp
--]]


--shapes--
--require "locale.gen_shape.right"
--require "locale.gen_shape.up"
--require "locale.gen_shape.maze"
--require "locale.gen_shape.spiral"
--require "locale.gen_shape.spiral_tri"
--require "locale.gen_shape.spiral2"
--require "locale.gen_shape.donut"

--terrain--
require "locale.gen_terrain.neko_bridged_rivers"

--ores--
--require "locale.gen_ores.neko_crazy_ores"
--require "locale.gen_ores.mystery_ores"

--TODO: IMPLEMENT BROKEN STYLES. DO NOT MERGE INTO MASTER BEFORE THIS IS

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
end

Event.register(defines.events.on_chunk_generated, on_chunk_generated)
