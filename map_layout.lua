--[[
Neko Does stuff to key files because Im a derp
--]]

require "locale.gen_shared.perlin_noise"
perlin:load(  )
require "locale.gen_shared.ent_functions"
require "locale.gen_shared.simplex_noise"

--shapes--
--require "locale.gen_shape.right"
--require "locale.gen_shape.up"
require "locale.gen_shape.maze"
--require "locale.gen_shape.spiral"
--require "locale.gen_shape.spiral_tri"
--require "locale.gen_shape.spiral2"

--terrain--
--require "locale.gen_terrain.neko_bridged_rivers"

--ores--
--require "locale.gen_ores.neko_crazy_ores"
--require "locale.gen_ores.mystery_ores"

--TODO: IMPLEMENT BROKEN STYLES. DO NOT MERGE INTO MASTER BEFORE THIS IS

local on_chunk_generated = function(event)
	if shape_module then
		if run_shape_module(event) then
			if terrain_module then
				run_terrain_module(event)
			elseif ores_module then
				run_ores_module(event)
			end
		end
	else
		if terrain_module then
			run_terrain_module(event)
		elseif ores_module then
			run_ores_module(event)
		end
	end
end

Event.register(defines.events.on_chunk_generated, on_chunk_generated)
