--[[
This file is used to choose which styles you want.
You may choose up to one of each type shapes, terrain, ores and misc or one of the combined styles by removing uncommenting the line.
If you want to add your own module, just add it to the others
in this file and your run_*type*_module(event) function will be called.
--]]
local Event = require "utils.event"
local b = require "map_gen.shared.builders"

local shape = nil

--combined--
--shape = require "map_gen.combined.island_resort"
--require "map_gen.combined.red_planet_v2"
--require "map_gen.combined.borg_planet_v2"
--require "map_gen.combined.dimensions"
--require "map_gen.combined.dagobah_swamp"
--require "map_gen.combined.meteor_strike" --unfinished

--presets--
--shape = require "map_gen.presets.template"
--shape = require "map_gen.presets.web" --unfinished
--shape = require "map_gen.presets.rings_and_boxes" --unfinished
--shape = require "map_gen.presets.ring_of_balls" --unfinished
--shape = require "map_gen.presets.dna"
--shape = require "map_gen.presets.lines_and_balls"
--shape = require "map_gen.presets.mobius_strip"
--shape = require "map_gen.presets.antfarm"
--shape = require "map_gen.presets.creation_of_adam"
--shape = require "map_gen.presets.manhattan"
--shape = require "map_gen.presets.mona_lisa"
--shape = require "map_gen.presets.connected_dots"
--shape = require "map_gen.presets.maori"
--shape = require "map_gen.presets.goat"
--shape = require "map_gen.presets.GoT"
--shape = require "map_gen.presets.turkey" -- needs to be rebuilt from missing source image.
--shape = require "map_gen.presets.north_america" -- needs to be rebuilt from missing source image.
--shape = require "map_gen.presets.UK"
--shape = require "map_gen.presets.venice"
--shape = require "map_gen.presets.goats_on_goats"
--shape = require "map_gen.presets.grid_islands"
--shape = require "map_gen.presets.crosses"
--shape = require "map_gen.presets.crosses3"
--shape = require "map_gen.presets.broken_web"
--shape = require "map_gen.presets.misc_stuff"
--shape = require "map_gen.presets.lines"
--shape = require "map_gen.presets.dickbutt"
--shape = require "map_gen.presets.void_gears"
--shape = require "map_gen.presets.gears"
--shape = require "map_gen.presets.factorio_logo"
--shape = require "map_gen.presets.factorio_logo2"
--shape = require "map_gen.presets.hearts"
--shape = require "map_gen.presets.women"
--shape = require "map_gen.presets.fractal_balls"
--shape = require "map_gen.presets.fruit_loops"
--shape = require "map_gen.presets.fish_islands"
--shape = require "map_gen.presets.ContraSpiral"
--shape = require "map_gen.presets.cookies"
--shape = require "map_gen.presets.plus"
--shape = require "map_gen.presets.honeycomb"
--shape = require "map_gen.presets.line_and_trees"
--shape = require "map_gen.presets.test"

--shapes--
--shape = require "map_gen.shape.left"
--shape = require "map_gen.shape.right"
--shape = require "map_gen.shape.up"
--require "map_gen.shape.maze"
--shape = require "map_gen.shape.spiral"
--shape = require "map_gen.shape.threaded_spirals"
--shape = require "map_gen.shape.spiral_tri"
--shape = require "map_gen.shape.spiral2"
--shape = require "map_gen.shape.donut"
--shape = require "map_gen.shape.rectangular_spiral"
--shape = require "map_gen.shape.lattice"
--require "map_gen.shape.infinite_mazes"
--shape = require "map_gen.shape.x_shape"
--shape = require "map_gen.shape.pacman"

--terrain--
--require "map_gen.terrain.neko_bridged_rivers"
--require "map_gen.terrain.neko_river_overlay"

--ores--
--require "map_gen.ores.rso.rso_control"


-- modules that only return max one entity per tile
local entity_modules = {
	--require "map_gen.ores.glitter_ores",
	--require "map_gen.terrain.mines",
	--require "map_gen.terrain.worms",
	--require "map_gen.misc.wreck_items",
	--require "map_gen.ores.neko_crazy_ores",
	--require "map_gen.ores.fluffy_rainbows",
	--require "map_gen.ores.harmonic_gen",
	--require "map_gen.ores.resource_clustertruck"
}

local terrain_modules ={
	--require "map_gen.misc.tris_chunk_grid",
}

--everything else. You may use more than one of these, but beware they might not be compatible
miscs = {}
--require "map_gen.misc.rusky_pvp"
--table.insert(miscs, require("map_gen.misc.rail_grid")) -- used for map_gen.presets.UK

local regen_decoratives = false

if #entity_modules > 0 then
	shape = shape or b.full_shape

	shape = b.apply_entities(shape, entity_modules)
end

if #terrain_modules > 0 then
	shape = shape or b.full_shape

	for _, m in ipairs(terrain_modules) do
		shape = b.overlay_tile_land(shape, m)
	end
end

if shape then	
	require ("map_gen.shared.generate")({shape = shape, regen_decoratives = regen_decoratives})
	--require ("map_gen.shared.generate_not_threaded")({shape = shape, regen_decoratives = regen_decoratives})
end

--[[ local on_chunk_generated = function(event)
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

Event.add(defines.events.on_chunk_generated, on_chunk_generated) ]]
