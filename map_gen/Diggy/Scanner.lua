-- dependencies

-- this
local Scanner = {}

--[[--
    returns a list with all direct positions that contain tile_search.

    @param surface LuaSurface
    @param position Position
    @param tile_search string name of the tile to search for
    @return table with 0~4 directions of which have the tile searched for adjacent
]]
function Scanner.scan_around_position(surface, position, tile_search)
    local tile_found = {}

    -- north
    if (tile_search == surface.get_tile(position.x, position.y - 1).name) then
        table.insert(tile_found, { x = position.x, y = position.y - 1})
    end

    -- east
    if (tile_search == surface.get_tile(position.x + 1, position.y).name) then
        table.insert(tile_found, { x = position.x + 1, y = position.y})
    end

    -- south
    if (tile_search == surface.get_tile(position.x, position.y + 1).name) then
        table.insert(tile_found, { x = position.x, y = position.y + 1})
    end

    -- west
    if (tile_search == surface.get_tile(position.x - 1, position.y).name) then
        table.insert(tile_found, { x = position.x - 1, y = position.y})
    end

    return tile_found;
end

return Scanner
