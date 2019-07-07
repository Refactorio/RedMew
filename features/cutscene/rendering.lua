local RS = require 'map_gen.shared.redmew_surface'
local Debug = require 'utils.debug'
local Rendering = require 'utils.rendering'
local Vertices = require 'resources.vertices'
local insert = table.insert

local toggle_debug = false --Set to true if you wish to get spammed with debug messages from the rendering module (Requires _DEBUG = true)

local function debug_print(message, trace_levels)
    if toggle_debug then
        Debug.print(message, trace_levels)
    end
end

local Public = {}

--At zoom level 1 a tile is 32x32 pixels
--tile size is calculated by 32 * zoom level.

local function text_height_in_tiles(scale, zoom)
    -- Default (count-font) at scale 10 is 125 pixels for lower letters and 109 for capital letters
    -- At scale 5 this is 64 or very close to half of the size at scale 10 (62.5)
    -- Therefore size hsa been determined to be (12.5 * scale) + 1
    local size = (12.5 * scale) + 1
    local pixel_per_tile = zoom * 32
    return size / pixel_per_tile, size
end

local function calculate_percentages(settings, player_resolution)
    local original_resolution = settings.original_resolution
    return {
        height = player_resolution.height / original_resolution.height,
        width = player_resolution.width / original_resolution.width,
        tile = (settings.original_zoom * 32) / (settings.player_zoom * 32)
    }
end

local function text_scale(percentage, scale)
    return scale * (percentage.height + percentage.width) * 0.5
end

local function fit_to_screen(percentage, coordinates)
    if not coordinates.fitted then
        local height = percentage.height
        local width = percentage.width
        local tile = percentage.tile
        for _, pos in pairs(coordinates) do
            if type(pos) == 'number' then
                coordinates.x = coordinates.x * width
                coordinates.y = coordinates.y * height
                break
            else
                pos.x = pos.x * width
                pos.y = pos.y * height
            end
        end
        for _, pos in pairs(coordinates) do
            if type(pos) == 'number' then
                coordinates.x = coordinates.x * tile
                coordinates.y = coordinates.y * tile
                break
            else
                pos.x = pos.x * tile
                pos.y = pos.y * tile
            end
        end
        coordinates.fitted = true
    end
    return coordinates
end

local function fit_to_screen_edges(settings, player_resolution, coordinates)
    if not coordinates.fitted then
        local tile = settings.original_zoom * 32
        local player_tile = settings.player_zoom * 32
        local display_scale = player_resolution.scale or 1

        local player_height = (player_resolution.height / player_tile) * 0.5
        local player_width = (player_resolution.width / player_tile) * 0.5

        for _, pos in pairs(coordinates) do
            if type(pos) == 'number' then
                coordinates.y = -player_height + (((coordinates.y * tile) / player_tile) * display_scale)
                coordinates.x = -player_width + (((coordinates.x * tile) / player_tile) * display_scale)
                break
            else
                pos.y = -player_height + (((pos.y * tile) / player_tile) * display_scale)
                pos.x = -player_width + (((pos.x * tile) / player_tile) * display_scale)
            end
        end
        coordinates.fitted = true
    end
    return coordinates
end

local function create_background_params(params)
    local background_params = params.background
    if background_params then
        for k, v in pairs(params) do
            if k ~= 'background' then
                if not background_params[k] then
                    background_params[k] = v
                end
            end
        end
    else
        background_params = params
    end
    return background_params
end

local function text_background(settings, offset, player, percentages, size, number_text, params)
    local margin = 0.01 / params.scale
    local left_top = fit_to_screen(percentages, {x = -40, y = 0})
    local right_bottom = fit_to_screen(percentages, {x = 40, y = 0})
    left_top.y = -size * margin * 0.875
    right_bottom.y = size * (1.5 + (margin * 1.125)) * number_text
    local background_params = create_background_params(params)
    return Public.draw_rectangle(settings, offset, left_top, right_bottom, player, background_params)
end

function Public.draw_text(settings, offset, text, player, params, draw_background, fit_to_edge)
    local ids = {}
    local player_resolution = player.display_resolution
    player_resolution.scale = player.display_scale
    local percentages = calculate_percentages(settings, player_resolution)
    local scale = params.scale

    if draw_background ~= -1 then
        scale = text_scale(percentages, scale)
        local size = text_height_in_tiles(scale, settings.player_zoom)
        if fit_to_edge then
            offset = fit_to_screen_edges(settings, player_resolution, offset)
        else
            offset = fit_to_screen(percentages, offset)
        end
        offset.y = offset.y - size * 0.5
    end
    local size = text_height_in_tiles(scale, settings.player_zoom)

    if draw_background == true then
        insert(ids, text_background(settings, offset, player, percentages, size, 1, params, fit_to_edge))
    end

    local target = {x = player.position.x + offset.x, y = player.position.y + offset.y}

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

    --local swz = params.scale_with_zoom
    local swz = true

    local oiam = params.only_in_alt_mode
    oiam = oiam or false

    local rendering_params = {
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

    debug_print(rendering_params)

    insert(ids, rendering.draw_text(rendering_params))
    return ids
end

function Public.draw_multi_line_text(settings, offset, texts, player, params, draw_background, fit_to_edge)
    local ids = {}
    local player_resolution = player.display_resolution
    player_resolution.scale = player.display_scale
    local percentages = calculate_percentages(settings, player_resolution)
    local scale = params.scale

    scale = text_scale(percentages, scale)
    local size = text_height_in_tiles(scale, settings.player_zoom)

    if fit_to_edge then
        offset = fit_to_screen_edges(settings, player_resolution, offset)
    else
        offset = fit_to_screen(percentages, offset)
    end

    offset.y = offset.y - size * 0.5

    if draw_background then
        insert(ids, text_background(settings, offset, player, percentages, size, #texts, params, fit_to_edge))
        draw_background = -1
    end

    for i = 1, #texts do
        insert(ids, Public.draw_text(settings, offset, texts[i], player, params, draw_background, fit_to_edge)[1])
        offset.y = offset.y + (size * 1.5)
    end
    return ids
end

function Public.draw_rectangle(settings, offset, left_top, right_bottom, player, params, fit_to_edge)
    local player_resolution = player.display_resolution
    player_resolution.scale = player.display_scale
    local percentages = calculate_percentages(settings, player_resolution)
    if fit_to_edge then
        offset = fit_to_screen_edges(settings, player_resolution, offset)
        left_top = fit_to_screen_edges(settings, player_resolution, left_top)
        right_bottom = fit_to_screen_edges(settings, player_resolution, right_bottom)
    else
        offset = fit_to_screen(percentages, offset)
        left_top = fit_to_screen(percentages, left_top)
        right_bottom = fit_to_screen(percentages, right_bottom)
    end

    local target_left = {x = player.position.x + left_top.x + offset.x, y = player.position.y + left_top.y + offset.y}
    local target_right = {x = player.position.x + right_bottom.x + offset.x, y = player.position.y + right_bottom.y + offset.y}

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

    local rendering_params = {
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

    debug_print(rendering_params)

    return rendering.draw_rectangle(rendering_params)
end

local blackout_settings = {original_resolution = {height = 1440, width = 2560}, original_zoom = 1, player_zoom = 1}
function Public.blackout(player, zoom, ttl, color)
    local left_top = {x = -40, y = -22.5}
    local right_bottom = {x = 40, y = 22.5}
    blackout_settings.player_zoom = zoom
    return Public.draw_rectangle(blackout_settings, {x = 0, y = 0}, left_top, right_bottom, player, {color = color, time_to_live = ttl})
end

function Public.draw_arrow(settings, offset, player, params, fit_to_edge)
    local player_resolution = player.display_resolution
    player_resolution.scale = player.display_scale
    local percentages = calculate_percentages(settings, player_resolution)
    if fit_to_edge then
        offset = fit_to_screen_edges(settings, player_resolution, offset)
    else
        offset = fit_to_screen(percentages, offset)
    end

    local vertices = Rendering.scale(Vertices.arrow, percentages.tile, percentages.tile)
    vertices = Rendering.rotate(vertices, params.rotation)
    vertices = Rendering.translate(vertices, offset.x, offset.y)

    local color = params.color or {1, 1, 1, 1}
    params.color = color

    local players = params.players
    players = players or {}

    table.insert(players, player)
    params.players = players

    params.surface = RS.get_surface()
    --Debug.print(vertices)
    return Rendering.draw_polygon(vertices, params)
end

return Public
