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

--TODO: IMPLEMENT BROKEN STYLES. DO NOT MERGE INTO MASTER BEFORE THIS

local map_shapes = {
	--Map shapes
	sample = false,
	up = true, --broken
	right = false, --broken
	square = false, --broken
	circle = false, --broken
}

local terrain_gens = {
	--Map generation styles:
	rivers = false, --broken
	red_planet = false, --broken
	red_planet_2 = false, --broken
	red_planet_2_messy_resources = false, --broken
	dagobah_swamp = false, --broken
	grey_void = false, --broken
	perlin_01 = false, --broken
	perlin_02 = false, --broken
	gens_neko = false, --broken
}

local resource_gens = {
	--resource generation styles:
		resource_rainbow = false, --broken
		resource_cluster_truck = false --broken
}

local entitiy_gens = {
	rail_grid = false
}


local shape_module
local terrain_module
local ore_module
local item_gens


local generate_shape = function(event)
	return true
end
local generate_terrain = function(event)
end
local generate_resources = function(event)
end
local generate_entities = function(event)
end

for name, enabled in pairs(map_shapes) do
	if enabled then
		local module = require("locale.map_generation.gen_shape." .. name)
		if type(module) == "boolean" then
			error("Error loading module ''" .. name .."''. No table containing module elements returned")
		else
			generate_shape = module.on_chunk_generated
		end
	end
end
for name, enabled in pairs(terrain_gens) do
	if enabled then
		local module = require("locale.map_generation.gen_terrain." .. name)
		if type(module) == "boolean" then
			error("Error loading module ''" .. name .."''. No table containing module elements returned")
		else
			generate_terrain = module.on_chunk_generated
		end
 	end
end

for name, enabled in pairs(resource_gens) do
	if enabled then
		local module = require("locale.map_generation.gen_resources." .. name)
		if type(module) == "boolean" then
			error("Error loading module ''" .. name .."''. No table containing module elements returned")
		else
			generate_resources = module.on_chunk_generated
		end
	end
end
for name, enabled in pairs(entitiy_gens) do
	if enabled then
		local module = require("locale.map_generation.gen_entities." .. name)
		if type(module) == "boolean" then
			error("Error loading module ''" .. name .."''. No table containing module elements returned")
		else
			generate_entities = module.on_chunk_generated
		end
	end
end



local on_chunk_generated = function(event)
	local continue = generate_shape(event)
	if type(continue) == "nil" or continue then
		generate_terrain(event)
		gen_resources(event)
		generate_entities(event)
	end
end

Event.register(defines.events.on_chunk_generated, on_chunk_generated)
