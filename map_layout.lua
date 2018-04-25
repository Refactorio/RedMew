--[[
This file is used to choose which styles you want.
You may choose up to one of each type shapes, terrain, ores and misc or one of the combined styles by removing uncommenting the line.
If you want to add your own module, just add it to the others
in this file and your run_*type*_module(event) function will be called.
--]]

local Event = require "utils.event"

--combined--
--require "map_gen.combined.island_resort"
--require "map_gen.combined.red_planet_v2"
--require "map_gen.combined.borg_planet_v2"
--require "map_gen.combined.dimensions"
--require "map_gen.combined.dagobah_swamp"
--require "map_gen.combined.meteor_strike" --unfinished

--presets--
--MAP_GEN = require "map_gen.presets.template"
--MAP_GEN = require "map_gen.presets.web" --unfinished
--MAP_GEN = require "map_gen.presets.rings_and_boxes" --unfinished
--MAP_GEN = require "map_gen.presets.ring_of_balls" --unfinished
--MAP_GEN = require "map_gen.presets.dna"
--MAP_GEN = require "map_gen.presets.lines_and_balls"
--MAP_GEN = require "map_gen.presets.mobius_strip"
--MAP_GEN = require "map_gen.presets.antfarm"
--MAP_GEN = require "map_gen.presets.creation_of_adam"
--MAP_GEN = require "map_gen.presets.manhattan"
--MAP_GEN = require "map_gen.presets.mona_lisa"
--MAP_GEN = require "map_gen.presets.connected_dots"
--MAP_GEN = require "map_gen.presets.maori"
--MAP_GEN = require "map_gen.presets.goat"
--MAP_GEN = require "map_gen.presets.GoT"
--MAP_GEN = require "map_gen.presets.turkey" -- needs to be rebuilt from missing source image.
--MAP_GEN = require "map_gen.presets.north_america" -- needs to be rebuilt from missing source image.
--MAP_GEN = require "map_gen.presets.UK"
--MAP_GEN = require "map_gen.presets.venice"
--MAP_GEN = require "map_gen.presets.goats_on_goats"
--MAP_GEN = require "map_gen.presets.grid_islands"
--MAP_GEN = require "map_gen.presets.crosses"
--MAP_GEN = require "map_gen.presets.crosses3"
--MAP_GEN = require "map_gen.presets.broken_web"
--MAP_GEN = require "map_gen.presets.misc_stuff"
--MAP_GEN = require "map_gen.presets.lines"
--MAP_GEN = require "map_gen.presets.dickbutt"
--MAP_GEN = require "map_gen.presets.void_gears"
--MAP_GEN = require "map_gen.presets.gears"
--MAP_GEN = require "map_gen.presets.factorio_logo"
--MAP_GEN = require "map_gen.presets.factorio_logo2"
--MAP_GEN = require "map_gen.presets.hearts"
--MAP_GEN = require "map_gen.presets.women"
--MAP_GEN = require "map_gen.presets.fractal_balls"
--MAP_GEN = require "map_gen.presets.fruit_loops"
--MAP_GEN = require "map_gen.presets.fish_islands"
--MAP_GEN = require "map_gen.presets.ContraSpiral"
--MAP_GEN = require "map_gen.presets.cookies"
--MAP_GEN = require "map_gen.presets.plus"
MAP_GEN = require "map_gen.presets.honeycomb"



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
--require "map_gen.misc.rusky_pvp"
--table.insert(miscs, require("map_gen.misc.rail_grid")) -- used for map_gen.presets.UK
--table.insert(miscs, require("map_gen.misc.wreck_items"))
--table.insert(miscs, require("map_gen.misc.tris_chunk_grid"))
--table.insert(miscs, require("map_gen.ores.glitter_ores"))

local on_chunk_generated = function(event)
	if run_combined_module ~= nil then
		run_combined_module(event)
	end
	if run_shape_module ~= nil then
		run_shape_module(event)
	end
	if run_terrain_module ~= nil then
		run_terrain_module(event)
	end
	if run_ores_module ~= nil then
		run_ores_module(event)
	end
	for _,v in pairs(miscs) do
		v.on_chunk_generated(event)
	end
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)
