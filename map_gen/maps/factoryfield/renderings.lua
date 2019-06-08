local Public = {}

--At zoom level 1 a tile is 32x32 pixels
--tile size is calculated by 32 * zoom level.

function Public.draw_text(original_resolution, original_zoom, player_zoom, offset, text, scale, ttl, player, draw_background)
    local height_scalar = player.display_resolution.height / original_resolution.height
    local width_scalar = player.display_resolution.width / original_resolution.width

    --game.print('scalar: ' .. height_scalar .. ' | ' .. width_scalar)

    local tile_scalar = (original_zoom * 32) / (player_zoom * 32)
    --game.print('tile: ' .. tile_scalar)

    scale = scale * height_scalar
    local size = (0.0065 * player.display_resolution.height * scale) / (player_zoom * 32)
    --game.print('size: ' .. size .. " | scale: " .. scale)

    local offset_x = offset.x * width_scalar * tile_scalar
    local offset_y = (offset.y * height_scalar * tile_scalar) - size

    --game.print('x: ' .. offset_x .. ' | y: ' .. offset_y)

    if draw_background then
        local left_top = {x = -40, y = -size * 0.68 / tile_scalar}
        local right_bottom = {x = 40, y = size * 0.75 / tile_scalar}
        --offset.y = offset_y / height_scalar / tile_scalar
        --game.print('left_top: ' .. serpent.block(left_top) .. ' | right_bottom: ' .. serpent.block(right_bottom))
        Public.draw_rectangle(original_resolution, original_zoom, player_zoom, offset, left_top, right_bottom, nil, player)
    end

    local target = {x = player.position.x + offset_x, y = player.position.y + offset_y}
    rendering.draw_text {
        text = {'', text},
        color = {r = 255, g = 255, b = 255},
        target = target,
        scale_with_zoom = true,
        surface = game.surfaces[2],
        time_to_live = ttl,
        alignment = 'center',
        players = {player},
        scale = scale
    }
end

function Public.draw_multi_line_text(original_resolution, original_zoom, player_zoom, offset, texts, scale, ttl, player, draw_background)
    local height_scalar = player.display_resolution.height / original_resolution.height
    local size = (0.0065 * player.display_resolution.height * scale) / (player_zoom * 32)
    local tile_scalar = (original_zoom * 32) / (player_zoom * 32)

    if draw_background then
        local left_top = {x = -40, y = -size / tile_scalar / height_scalar}
        local right_bottom = {x = 40, y = ((size * 1.5) / tile_scalar / height_scalar) * #texts}
        Public.draw_rectangle(original_resolution, original_zoom, player_zoom, offset, left_top, right_bottom, ttl, nil, player)
        draw_background = false
    end

    for i = 1, #texts do
        Public.draw_text(original_resolution, original_zoom, player_zoom, offset, texts[i], scale, ttl, player, draw_background)
        offset.y = offset.y + (size * 1.5) / tile_scalar / height_scalar
    end
end

function Public.draw_rectangle(original_resolution, original_zoom, player_zoom, offset, left_top, right_bottom, ttl, color, player)
    local height_scalar = player.display_resolution.height / original_resolution.height
    local width_scalar = player.display_resolution.width / original_resolution.width
    --game.print('scalar: ' .. height_scalar .. ' | ' .. width_scalar)

    local tile_scalar = (original_zoom * 32) / (player_zoom * 32)
    --game.print('tile: ' .. tile_scalar)

    local offset_x = offset.x * width_scalar * tile_scalar
    local offset_y = offset.y * height_scalar * tile_scalar

    local left_top_x = left_top.x * tile_scalar * height_scalar
    local left_top_y = left_top.y * tile_scalar * height_scalar
    local right_bottom_x = right_bottom.x * tile_scalar * height_scalar
    local right_bottom_y = right_bottom.y * tile_scalar * height_scalar

    local target_left = {x = player.position.x + left_top_x + offset_x, y = player.position.y + left_top_y + offset_y}
    local target_right = {x = player.position.x + right_bottom_x + offset_x, y = player.position.y + right_bottom_y + offset_y}
    --game.print('target_left: ' .. serpent.block(target_left))
    --game.print('target_right: ' .. serpent.block(target_right))

    if not color then
        color = {}
    end

    rendering.draw_rectangle {
        color = color,
        filled = true,
        left_top = target_left,
        right_bottom = target_right,
        surface = game.surfaces[2],
        time_to_live = ttl,
        players = {game.player}
    }
end

function Public.blackout(player, zoom, ttl, color)
    local left_top = {x = -50, y = -25}
    local right_bottom = {x = 50, y = 25}
    Public.draw_rectangle({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 0}, left_top, right_bottom, ttl, color, player)
end

return Public
