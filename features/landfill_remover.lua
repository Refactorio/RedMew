-- This feature allows players to remove landfill.
-- To use, create a deconstruction planner with the landfill tile filter and select tiles only mode.
-- Use the decon planner within range of the landfill to remove it

local Event = require 'utils.event'
local table = require 'utils.table'
local math = require 'utils.math'
local config = global.config.landfill_remover

local floor = math.floor
local ceil = math.ceil
local fast_remove = table.fast_remove

local collision_mask = {'floor-layer', 'object-layer'}
local whitelist = defines.deconstruction_item.tile_filter_mode.whitelist
local entity_whitelist = defines.deconstruction_item.entity_filter_mode.whitelist

local normal = defines.deconstruction_item.tile_selection_mode.normal
local never = defines.deconstruction_item.tile_selection_mode.never

local function can_select_landfill_tiles(cursor, surface, area)
    if not cursor or not cursor.valid or not cursor.valid_for_read or cursor.trees_and_rocks_only then
        return false
    end

    local tile_selection_mode = cursor.tile_selection_mode
    if tile_selection_mode == never then
        return false
    end

    local tile_filters = cursor.tile_filters
    local contains_landfill_filter = table.contains(tile_filters, 'landfill')

    local tile_filter_mode = cursor.tile_filter_mode
    if tile_filter_mode == whitelist then
        if not contains_landfill_filter then
            return false
        end
    else
        if contains_landfill_filter then
            return false
        end
    end

    if tile_selection_mode ~= normal then
        return true
    end

    local entity_filters = cursor.entity_filters
    if #entity_filters == 0 then
        if surface.count_entities_filtered({area = area, name = 'character', invert = true, limit = 1}) > 0 then
            return false
        end

        return true
    end

    local invert = cursor.entity_filter_mode ~= entity_whitelist
    if invert then
        entity_filters[#entity_filters + 1] = 'character'
    end

    return surface.count_entities_filtered({area = area, name = entity_filters, invert = invert, limit = 1}) == 0
end

local function within_reach(tile_position, player_position, radius_squared)
    local dx = tile_position.x - player_position.x
    local dy = tile_position.y - player_position.y
    return (dx * dx + dy * dy) < radius_squared
end

local function try_get_landfill_tiles(surface, area, player)
    local build_distance = player.build_distance + 0.5
    local radius_squared = build_distance * build_distance
    local player_position = player.position

    local find_tiles_filtered = surface.find_tiles_filtered
    local landfill_tiles = find_tiles_filtered({area = area, name = 'landfill'})
    local hidden_landfill_tiles = find_tiles_filtered({area = area, has_hidden_tile = true})

    for i = #landfill_tiles, 1, -1 do
        local tile = landfill_tiles[i]
        if not within_reach(tile.position, player_position, radius_squared) then
            fast_remove(landfill_tiles, i)
        end
    end

    for i = #hidden_landfill_tiles, 1, -1 do
        local tile = hidden_landfill_tiles[i]
        if tile.hidden_tile ~= 'landfill' or not within_reach(tile.position, player_position, radius_squared) then
            fast_remove(hidden_landfill_tiles, i)
        end
    end

    if #landfill_tiles == 0 and #hidden_landfill_tiles == 0 then
        return nil
    end

    local i = 0
    local first = true

    return function()
        local tile
        i = i + 1

        if first then
            tile = landfill_tiles[i]
            if tile then
                return tile
            end

            first = false
            i = 1
        end

        return hidden_landfill_tiles[i]
    end
end

Event.add(
    defines.events.on_player_deconstructed_area,
    function(event)
        if event.item ~= 'deconstruction-planner' then
            return
        end

        if event.alt then
            return
        end

        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local surface = event.surface
        if not surface or not surface.valid then
            return
        end

        local area = event.area
        local lt, rb = area.left_top, area.right_bottom
        lt.x, lt.y = floor(lt.x), floor(lt.y)
        rb.x, rb.y = ceil(rb.x), ceil(rb.y)

        local cursor = player.cursor_stack
        if not can_select_landfill_tiles(cursor, surface, area) then
            return
        end

        local tiles_iter = try_get_landfill_tiles(surface, area, player)
        if not tiles_iter then
            return
        end

        local count_entities_filtered = surface.count_entities_filtered
        local tiles_to_add = {}
        local revert_tile = config.revert_tile or 'water-mud'
        while true do
            local tile = tiles_iter()
            if not tile then
                break
            end

            local pos = tile.position
            local tile_area = {pos, {pos.x + 1, pos.y + 1}}

            if count_entities_filtered({area = tile_area, collision_mask = collision_mask}) == 0 then
                tiles_to_add[#tiles_to_add + 1] = {name = revert_tile, position = tile.position}
            end
        end

        surface.set_tiles(tiles_to_add)

        local set_hidden_tile = surface.set_hidden_tile
        for i = 1, #tiles_to_add do
            local tile = tiles_to_add[i]
            set_hidden_tile(tile.position, nil)
        end
    end
)
