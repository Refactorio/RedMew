local b = require 'map_gen.shared.builders'
local MGSP = require 'resources.map_gen_settings'

local type = type
local water_tiles = b.water_tiles
local path_tiles = b.path_tiles

local pic = require 'map_gen.data.presets.manhattan'
local world_map = b.picture(pic)
local degrees = require "utils.math".degrees

local x_offset, y_offset = 200, 1337
world_map = b.translate(world_map, x_offset, y_offset)
world_map = b.rotate(world_map, degrees(-270))

local scale = 2
local height = 8000 * scale
local width = 8000 * scale

world_map = b.scale(world_map, scale)


local bounds = b.rectangle(width, height)
bounds = b.translate(bounds, x_offset * scale, y_offset * scale)

local config = {
    scenario_name = 'crashsite-manhattan',
    map_gen_settings = {
        MGSP.starting_area_very_low,
        MGSP.ore_oil_none,
        MGSP.enemy_none,
        MGSP.cliff_none
    },
    grid_number_of_blocks = 15,
    mini_grid_number_of_blocks = 29,
    bounds_shape = bounds
}

local Scenario = require 'map_gen.maps.crash_site.scenario'
local crashsite = Scenario.init(config)

local function get_tile_name(tile)
    if type(tile) == 'table' then
        return tile.tile
    else
        return tile
    end
end

local function map(x, y, world)
    local tile = world_map(x, y, world)
    if not tile then
        return tile
    end

    local world_tile_name = get_tile_name(tile)
    if not world_tile_name or water_tiles[world_tile_name] then
        return tile
    end

    local crashsite_tile = crashsite(x, y, world)
    local crashsite_tile_name = get_tile_name(crashsite_tile)
    if path_tiles[crashsite_tile_name] then
        return crashsite_tile
    end

    if type(crashsite_tile) == 'table' then
        crashsite_tile.tile = world_tile_name
        return crashsite_tile
    end

    return tile
end

return map
