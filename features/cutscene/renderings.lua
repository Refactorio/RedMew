local RS = require 'map_gen.shared.redmew_surface'

local Public = {}

--At zoom level 1 a tile is 32x32 pixels
--tile size is calculated by 32 * zoom level.

function Public.draw_text(original_resolution, original_zoom, player_zoom, offset, text, scale, player, params, draw_background)
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
        local background_params = params.background
        background_params = background_params or params
        Public.draw_rectangle(original_resolution, original_zoom, player_zoom, offset, left_top, right_bottom, player, background_params)
    end

    local target = {x = player.position.x + offset_x, y = player.position.y + offset_y}

    local color = params.color
    color = color and color or {r = 255, g = 255, b = 255}

    local font = params.font

    local surface = params.surface
    surface = surface or RS.get_surface()

    local ttl = params.time_to_live
    ttl = ttl and ttl or -1

    local forces = params.forces

    local players = params.players
    players = players or {}

    table.insert(players, player)

    local visible = params.visible
    visible = visible or true

    local dog = params.draw_on_ground
    dog = dog or false

    local orientation = params.orientation
    orientation = orientation or 0

    local alignment = params.alignment
    alignment = alignment or 'center'

    local swz = params.scale_with_zoom
    swz = swz or true

    local oiam = params.only_in_alt_mode
    oiam = oiam or false

    return rendering.draw_text {
        text = {'', text},
        color = color,
        target = target,
        scale_with_zoom = swz,
        surface = surface,
        time_to_live = ttl,
        alignment = alignment,
        players = players,
        scale = scale,
        forces = forces,
        visible = visible,
        draw_on_ground = dog,
        only_in_alt_mode = oiam,
        orientation = orientation,
        font = font
    }
end

function Public.draw_multi_line_text(original_resolution, original_zoom, player_zoom, offset, texts, scale, player, params, draw_background)
    local ids = {}
    local height_scalar = player.display_resolution.height / original_resolution.height
    local size = (0.0065 * player.display_resolution.height * scale) / (player_zoom * 32)
    local tile_scalar = (original_zoom * 32) / (player_zoom * 32)

    if draw_background then
        local left_top = {x = -40, y = -size / tile_scalar / height_scalar}
        local right_bottom = {x = 40, y = ((size * 1.5) / tile_scalar / height_scalar) * #texts}
        local background_params = params.background
        background_params = background_params or params
        table.insert(ids, Public.draw_rectangle(original_resolution, original_zoom, player_zoom, offset, left_top, right_bottom, player, background_params))
        draw_background = false
    end

    for i = 1, #texts do
        table.insert(ids, Public.draw_text(original_resolution, original_zoom, player_zoom, offset, texts[i], scale, player, params, draw_background))
        offset.y = offset.y + (size * 1.5) / tile_scalar / height_scalar
    end
    return ids
end

function Public.draw_rectangle(original_resolution, original_zoom, player_zoom, offset, left_top, right_bottom, player, params)
    local height_scalar = player.display_resolution.height / original_resolution.height
    local width_scalar = player.display_resolution.width / original_resolution.width
    --game.print('scalar: ' .. height_scalar .. ' | ' .. width_scalar)

    local tile_scalar = (original_zoom * 32) / (player_zoom * 32)
    --game.print('tile: ' .. tile_scalar)

    local offset_x = offset.x * width_scalar * tile_scalar
    local offset_y = offset.y * height_scalar * tile_scalar

    local left_top_x = left_top.x * tile_scalar * width_scalar
    local left_top_y = left_top.y * tile_scalar * height_scalar
    local right_bottom_x = right_bottom.x * tile_scalar * width_scalar
    local right_bottom_y = right_bottom.y * tile_scalar * height_scalar

    local target_left = {x = player.position.x + left_top_x + offset_x, y = player.position.y + left_top_y + offset_y}
    local target_right = {x = player.position.x + right_bottom_x + offset_x, y = player.position.y + right_bottom_y + offset_y}
    --game.print('target_left: ' .. serpent.block(target_left))
    --game.print('target_right: ' .. serpent.block(target_right))


    local color = params.color
    color = color and color or {}

    local width = params.width
    width = width and width or 0

    local filled = params.filled
    filled = filled and filled or true

    local surface = params.surface
    surface = surface or RS.get_surface()

    local ttl = params.time_to_live
    ttl = ttl and ttl or -1

    local forces = params.forces

    local players = params.players
    players = players or {}

    table.insert(players, player)

    local visible = params.visible
    visible = visible or true

    local dog = params.draw_on_ground
    dog = dog or false

    local oiam = params.only_in_alt_mode
    oiam = oiam or false

    return rendering.draw_rectangle {
        color = color,
        width = width,
        filled = filled,
        left_top = target_left,
        right_bottom = target_right,
        surface = surface,
        time_to_live = ttl,
        forces = forces,
        players = players,
        visible = visible,
        draw_on_ground = dog,
        only_in_alt_mode = oiam
    }
end

function Public.blackout(player, zoom, ttl, color)
    local left_top = {x = -40, y = -22.5}
    local right_bottom = {x = 40, y = 22.5}
    return Public.draw_rectangle({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 0}, left_top, right_bottom, player, {color = color, time_to_live = ttl})
end

return Public
