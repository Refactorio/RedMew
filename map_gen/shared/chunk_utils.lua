function removeChunk(event)
    local surface = event.surface
    local tiles = {}
    for x = event.area.left_top.x, event.area.right_bottom.x do
        for y = event.area.left_top.y, event.area.right_bottom.y do
            table.insert(tiles, {name = 'out-of-map', position = {x, y}})
        end
    end
    surface.set_tiles(tiles)
end
