--
-- Created for RedMew (redmew.com) by der-dave (der-dave.com) @ 15.11.2018 15:54 via IntelliJ IDEA
--
-- Part of Racetrack scenario
-- this simply generates the map (the track) via builders.lua
-- all logic handling is done via GameScript.lua
--

local b = require 'map_gen.shared.builders'
local insert = table.insert

local GameConfig = require 'map_gen.combined.racetrack.GameConfig'
local pic_data = require ('map_gen.combined.racetrack.tracks.' .. GameConfig.track)

local checkpoints = pic_data.checkpoints

local pic = b.decompress(pic_data)
local map = b.picture(pic)

local function no_trash(x, y, world, tile)
    if not tile then
        return
    end
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'tree', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'cliff', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'resource', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end
    return tile
end

local function parse_checkpoints_by_type(checkpoint, type)
    local result = {}

    for _, data in pairs(checkpoint) do
        if data.type == type then
            insert(result, data)
        end
    end

    return result
end

local function parse_checkpoints_by_id(checkpoint, id)
    local result = {}

    for _, data in pairs(checkpoint) do
        if data.id == id then
            insert(result, data)
        end
    end

    return result
end

local function place_coins(x, y, world)
    local random = math.random(0, 100)
    local count = 100 - GameConfig.coin_chance
    if random > count then
        return {position = {world.x, world.y}, name = 'item-on-ground', stack = {name = 'coin', count = 1} }
    end
end

-- set playground (area for players not driving)
local playground = b.circle(10)
local spawn_x = pic_data.spawn.x
local spawn_y = pic_data.spawn.y
if spawn_y < 0 then
    spawn_y = (spawn_y * -1)
end
playground = b.translate(playground, pic_data.playground.x - spawn_x, pic_data.playground.y + spawn_y)
map = b.combine{playground, map}

-- CHECK: is the first checkpoint configured as finish?
if checkpoints[1].type ~= 'finish' then
    error('Configuration error in your track-data: First checkpoint is not configured as finish.')
end

-- CHECK: are the checkpoint IDs unique?            TODO: make checkpoint IDs internal unique!
local num_checkpoints = #checkpoints
for i = 1, num_checkpoints do
    local ids =  parse_checkpoints_by_id(checkpoints, i)
    local count = #ids
    if count > 1 then
        error('Configuration error in your track-data: There was a multiple checkpoint ID (ID: ' .. i .. ') found. Checkpoint IDs must be unique.')
    end
end

-- set spawnpoint
map = b.translate(map, pic_data.spawn.x, pic_data.spawn.y)



-- draw finish line
local finish_line_data = parse_checkpoints_by_type(checkpoints, 'finish')
-- CHECK: more than 1 finish configured?
if #finish_line_data ~= 1 then
    error('Configuration error in your track-data: Too many finish lines configured. Only 1 finish line is supported for now.')
end

local finish_line = b.rectangle(finish_line_data[1].width, finish_line_data[1].height)
--local finish_line = b.rectangle(finish_coordinates.width, finish_coordinates.height)
finish_line = b.translate(finish_line, finish_line_data[1].offset_x, finish_line_data[1].offset_y)
finish_line = b.change_tile(finish_line, true, finish_line_data[1].structure)


-- draw all checkpoints
local checkpoint_lines
for _, checkpoint in pairs(checkpoints) do
    local tile = b.rectangle(checkpoint.width, checkpoint.height)
    tile = b.translate(tile, checkpoint.offset_x, checkpoint.offset_y)
    tile = b.change_tile(tile, true, checkpoint.structure)

    checkpoint_lines = b.any{checkpoint_lines, tile}
end

-- combine all shapes
map = b.combine{finish_line, checkpoint_lines, map}

-- remove water from track
map = b.change_map_gen_collision_tile(map, 'water-tile', 'dirt-2')

-- remove trash from track
map = b.apply_effect(map, no_trash)

-- place coins on map
map = b.apply_entity(map, place_coins)

return map
