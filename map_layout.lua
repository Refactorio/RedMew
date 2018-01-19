--[[
This file is used to choose which styles you want.
You may choose up to one of each type shapes, terrain, ores and misc or one of the combined styles by removing uncommenting the line.
If you want to add your own module, just add it to the others
in this file and your run_*type*_module(event) function will be called.
--]]


--combined--
--require "map_gen.combined.island_resort"
--require "map_gen.combined.red_planet_v2"
--require "map_gen.combined.borg_planet_v2"
--require "map_gen.combined.dimensions"
--require "map_gen.combined.dagobah_swamp"
--require "map_gen.combined.UK"

--grilledham's map gen
-- Need to copy the file you want from the _locale folder to this one for it to be included
-- only get what you need, otherwise the save file is too big!

--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.template"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.mobius_strip"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.antfarm"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.creation_of_adam"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.manhattan"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.mona_lisa"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.connected_dots"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.cage"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.maori"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.goat"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.biome_test"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.GoT"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.turkey"
--require "locale.grilledham_map_gen.presets.UK"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.north_america"
--MAP_GEN = require "map_gen.combined.grilledham_map_gen.presets.lines_and_balls"

--shapes--
--require "map_gen.shape.left"
--require "map_gen.shape.right"
--require "map_gen.shape.up"
--require "map_gen.shape.maze"
--require "map_gen.shape.spiral"
--require "map_gen.shape.threaded_spirals"
--require "map_gen.shape.spiral_tri"
--require "map_gen.shape.spiral2"
--require "map_gen.shape.donut"
--require "map_gen.shape.rectangular_spiral"
--require "map_gen.shape.lattice"
--require "map_gen.shape.infinite_mazes"
--require "map_gen.shape.x_shape"
--require "map_gen.shape.pacman"

--terrain--
--require "map_gen.terrain.neko_bridged_rivers"
--require "map_gen.terrain.neko_river_overlay"
--require "map_gen.terrain.worms"
--require "map_gen.terrain.mines"

--ores--
--require "map_gen.ores.neko_crazy_ores"
--require "map_gen.ores.fluffy_rainbows"
--require "map_gen.ores.rso.rso_control"
--require "map_gen.ores.harmonic_gen"

--everything else. You may use more than one of these, but beware they might not be compatible
miscs = {}
--miscs[1] = require "map_gen.misc.rail_grid"
--require "map_gen.misc.rusky_pvp"
--table.insert(miscs, require("map_gen.misc.wreck_items"))
--table.insert(miscs, require("map_gen.misc.tris_chunk_grid"))
--table.insert(miscs, require("map_gen.ores.glitter_ores"))

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
