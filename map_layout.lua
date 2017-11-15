--[[
This file is used to choose which styles you want.
You may choose up to one of each type shapes, terrain, ores and misc or one of the combined styles by removing uncommenting the line.
If you want to add your own module, just add it to the others
in this file and your run_*type*_module(event) function will be called.
--]]


--combined--
--require "locale.gen_combined.island_resort"
--require "locale.gen_combined.red_planet_v2"
--require "locale.gen_combined.borg_planet_v2"
--require "locale.gen_combined.dimentions"
--require "locale.gen_combined.dagobah_swamp"
--require "locale.gen_combined.UK"

--grilledham's map gen
--MAP_GEN = require "locale.gen_combined.grilledham_map_gen.presets.mobius_strip"
--MAP_GEN = require "locale.gen_combined.grilledham_map_gen.presets.antfarm"
--MAP_GEN = require "locale.gen_combined.grilledham_map_gen.presets.creation_of_adam"
--MAP_GEN = require "locale.gen_combined.grilledham_map_gen.presets.manhattan"
--MAP_GEN = require "locale.gen_combined.grilledham_map_gen.presets.mona_lisa"
--MAP_GEN = require "locale.gen_combined.grilledham_map_gen.presets.connected_dots"
--MAP_GEN = require "locale.gen_combined.grilledham_map_gen.presets.cage"
--MAP_GEN = require "locale.gen_combined.grilledham_map_gen.presets.maori"
--MAP_GEN = require "locale.gen_combined.grilledham_map_gen.presets.goat"
--MAP_GEN = require "locale.gen_combined.grilledham_map_gen.presets.biome_test"
MAP_GEN = require "locale.gen_combined.grilledham_map_gen.presets.GoT"

--shapes--
--require "locale.gen_shape.left"
--require "locale.gen_shape.right"
--require "locale.gen_shape.up"
--require "locale.gen_shape.maze"
--require "locale.gen_shape.spiral"
--require "locale.gen_shape.threaded_spirals"
--require "locale.gen_shape.spiral_tri"
--require "locale.gen_shape.spiral2"
--require "locale.gen_shape.donut"
--require "locale.gen_shape.rectangular_spiral"
--require "locale.gen_shape.lattice"
--require "locale.gen_shape.infinite_mazes"
--require "locale.gen_shape.x_shape"
--require "locale.gen_shape.pacman"

--terrain--
--require "locale.gen_terrain.neko_bridged_rivers"
--require "locale.gen_terrain.neko_river_overlay"
--require "locale.gen_terrain.worms"
--require "locale.gen_terrain.mines"

--ores--
--require "locale.gen_ores.neko_crazy_ores"
--require "locale.gen_ores.fluffy_rainbows"
require "locale.gen_ores.rso.rso_control"
--require "locale.gen_ores.harmonic_gen"

--everything else. You may use more than one of these, but beware they might not be compatible
miscs = {}
--miscs[1] = require "locale.gen_misc.rail_grid"
--require "locale.gen_misc.rusky_pvp"
--miscs[1] = require "locale.gen_misc.wreck_items"
--miscs[2] = require "locale.gen_misc.tris_chunk_grid"
miscs[1] = require "locale.gen_ores.glitter_ores"

local on_chunk_generated = function(event)
	if run_combined_module == nil then
		if run_shape_module ~= nil then
			if run_shape_module(event) then
				if run_terrain_module ~= nil then
					run_terrain_module(event)
				end
				if run_ores_module ~= nil then
					run_ores_module(event)
				end
			end
		else
			if run_terrain_module ~= nil then
				run_terrain_module(event)
			end
			if run_ores_module ~= nil then
				run_ores_module(event)
			end
		end
		for _,v in pairs(miscs) do
			v.on_chunk_generated(event)
		end
	else
		run_combined_module(event)
		if run_ores_module ~= nil then
			run_ores_module(event)
		end
		for _,v in pairs(miscs) do
			v.on_chunk_generated(event)
		end
	end
end

Event.register(defines.events.on_chunk_generated, on_chunk_generated)
