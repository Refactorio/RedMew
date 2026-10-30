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

-- Draws a cutscene's notes, bars and arrows in the world around the player's camera, laid out once
-- on a screen of settings.original_resolution and fitted to each player's own: positions are in
-- tiles from the middle of the screen (or with fit_to_edge, from its top left corner) as that
-- screen showed them at settings.original_zoom. Each function returns what it drew, for
-- cutscene_controller.register_rendering.
--
-- At zoom level 1 a tile is 32x32 pixels; tile size is 32 * zoom level. A high density display
-- (Retina, display_density_scale 2) draws the world that many times larger, so it shows as many
-- tiles as a display of its resolution divided by the density.

---@class CutsceneRenderSettings
---@field original_resolution { width: number, height: number } the screen the cutscene was laid out on
---@field original_zoom number the zoom it was laid out at
---@field player_zoom number the waypoint's zoom

---@class CutscenePlayerView : DisplayResolution the player's display_resolution, with:
---@field scale number display_scale, how much larger the GUI is drawn
---@field density number display_density_scale, how much larger the world is drawn

---@class CutsceneScreenFit how much of the player's screen a tile of the original screen is
---@field width number
---@field height number
---@field tile number

---@class CutsceneTextParams
---@field scale number text scale on the original screen
---@field color Color?
---@field font string?
---@field surface LuaSurface? the redmew surface when nil
---@field time_to_live number? ticks; forever when nil
---@field background table? params for the bar behind the text, falling back to these
---@field alignment TextAlign?

local Public = {}

local function text_height_in_tiles(scale, zoom)
    -- Default (count-font) at scale 10 is 125 pixels for lower letters and 109 for capital letters
    -- At scale 5 this is 64 or very close to half of the size at scale 10 (62.5)
    -- Therefore size hsa been determined to be (12.5 * scale) + 1
    local size = (12.5 * scale) + 1
    local pixel_per_tile = zoom * 32
    return size / pixel_per_tile, size
end

---@param settings CutsceneRenderSettings
---@param player_resolution CutscenePlayerView
---@return CutsceneScreenFit
local function calculate_percentages(settings, player_resolution)
    local original_resolution = settings.original_resolution
    local density = player_resolution.density or 1
    return {
        height = player_resolution.height / density / original_resolution.height,
        width = player_resolution.width / density / original_resolution.width,
        tile = (settings.original_zoom * 32) / (settings.player_zoom * 32)
    }
end

--- The player's display, and how it compares with the screen the cutscene was laid out on.
---@param settings CutsceneRenderSettings
---@param player LuaPlayer
---@return CutscenePlayerView
---@return CutsceneScreenFit
local function player_view(settings, player)
    local player_resolution = player.display_resolution --[[@as CutscenePlayerView]]
    player_resolution.scale = player.display_scale
    player_resolution.density = player.display_density_scale
    return player_resolution, calculate_percentages(settings, player_resolution)
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

-- Fitted from the screen's top left corner: the GUI is drawn display_scale times larger, the world
-- display_density_scale times.
local function fit_to_screen_edges(settings, player_resolution, coordinates)
    if not coordinates.fitted then
        local tile = settings.original_zoom * 32
        local player_tile = settings.player_zoom * 32
        local display_scale = player_resolution.scale or 1
        player_tile = player_tile * (player_resolution.density or 1)

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

--- Moves coordinates laid out on the original screen onto the player's, once: they are marked fitted.
local function fit(settings, player_resolution, percentages, coordinates, fit_to_edge)
    if fit_to_edge then
        return fit_to_screen_edges(settings, player_resolution, coordinates)
    end
    return fit_to_screen(percentages, coordinates)
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

-- A bar across the screen behind the line of text at `offset`, as far above it as below. Text
-- drawn in the world is always one line (a line break in it isn't drawn), so one line is all it fits.
local function text_background(settings, offset, player, percentages, size, params)
    local left_top = fit_to_screen(percentages, {x = -40, y = 0})
    local right_bottom = fit_to_screen(percentages, {x = 40, y = 0})
    left_top.y = size * 0.5 - size * 0.85
    right_bottom.y = size * 0.5 + size * 0.85
    local background_params = create_background_params(params)
    return Public.draw_rectangle(settings, offset, left_top, right_bottom, player, background_params)
end

--- Draws a line of text centred on offset, on a bar across the screen with draw_background. The
--- text is drawn display_density_scale times larger: a high density display draws text at its scale
--- in its own pixels, which are that many times smaller, where it draws the world that many times
--- larger, so drawn as many times larger it fills as much of the screen as on any other display.
--- offset is fitted to the player's screen in place, and moved up by half the text's height.
---@param settings CutsceneRenderSettings
---@param offset MapPosition tiles from the player's camera
---@param text LocalisedString
---@param player LuaPlayer
---@param params CutsceneTextParams
---@param draw_background boolean?
---@param fit_to_edge boolean?
---@return LuaRenderObject[]
function Public.draw_text(settings, offset, text, player, params, draw_background, fit_to_edge)
    local list = {}
    local player_resolution, percentages = player_view(settings, player)

    local scale = text_scale(percentages, params.scale)
    local size = text_height_in_tiles(scale, settings.player_zoom)
    offset = fit(settings, player_resolution, percentages, offset, fit_to_edge)
    offset.y = offset.y - size * 0.5

    -- on a background the text is centred in the bar
    local vertical_alignment
    if draw_background == true then
        insert(list, text_background(settings, offset, player, percentages, size, params))
        vertical_alignment = 'middle'
        offset = {x = offset.x, y = offset.y + size * 0.5}
    end

    local target = {x = player.physical_position.x + offset.x, y = player.physical_position.y + offset.y}

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
        scale = scale * (player_resolution.density or 1),
        forces = forces,
        visible = visible,
        draw_on_ground = dog,
        only_in_alt_mode = oiam,
        orientation = orientation,
        font = font,
        vertical_alignment = vertical_alignment
    }

    debug_print(rendering_params)

    insert(list, rendering.draw_text(rendering_params))
    return list
end

--- Draws lines of text one under another from offset, each on its own bar with draw_background
--- (see draw_text). draw_text moves offset up by half a line each time, so the lines are a line and
--- a half apart.
---@param settings CutsceneRenderSettings
---@param offset MapPosition tiles from the player's camera
---@param texts LocalisedString[]
---@param player LuaPlayer
---@param params CutsceneTextParams
---@param draw_background boolean?
---@param fit_to_edge boolean?
---@return LuaRenderObject[]
function Public.draw_multi_line_text(settings, offset, texts, player, params, draw_background, fit_to_edge)
    local list = {}
    local player_resolution, percentages = player_view(settings, player)
    local size = text_height_in_tiles(text_scale(percentages, params.scale), settings.player_zoom)

    offset = fit(settings, player_resolution, percentages, offset, fit_to_edge)
    offset.y = offset.y - size * 0.5

    for i = 1, #texts do
        for _, drawn in pairs(Public.draw_text(settings, offset, texts[i], player, params, draw_background, fit_to_edge)) do
            insert(list, drawn)
        end
        offset.y = offset.y + (size * 2)
    end
    return list
end

--- Draws a rectangle from left_top to right_bottom around offset, filled unless params.filled is false.
---@param settings CutsceneRenderSettings
---@param offset MapPosition tiles from the player's camera
---@param left_top MapPosition from offset
---@param right_bottom MapPosition from offset
---@param player LuaPlayer
---@param params table color, width, filled, surface, time_to_live, ... as for rendering.draw_rectangle
---@param fit_to_edge boolean?
---@return LuaRenderObject
function Public.draw_rectangle(settings, offset, left_top, right_bottom, player, params, fit_to_edge)
    local player_resolution, percentages = player_view(settings, player)
    offset = fit(settings, player_resolution, percentages, offset, fit_to_edge)
    left_top = fit(settings, player_resolution, percentages, left_top, fit_to_edge)
    right_bottom = fit(settings, player_resolution, percentages, right_bottom, fit_to_edge)

    local target_left = {x = player.physical_position.x + left_top.x + offset.x, y = player.physical_position.y + left_top.y + offset.y}
    local target_right = {x = player.physical_position.x + right_bottom.x + offset.x, y = player.physical_position.y + right_bottom.y + offset.y}

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
--- Covers the player's screen, in black unless color is given.
---@param player LuaPlayer
---@param zoom number
---@param ttl number? ticks
---@param color Color?
---@return LuaRenderObject
function Public.blackout(player, zoom, ttl, color)
    local left_top = {x = -40, y = -22.5}
    local right_bottom = {x = 40, y = 22.5}
    blackout_settings.player_zoom = zoom
    return Public.draw_rectangle(blackout_settings, {x = 0, y = 0}, left_top, right_bottom, player, {color = color, time_to_live = ttl})
end

--- Draws an arrow at offset, turned by params.rotation.
---@param settings CutsceneRenderSettings
---@param offset MapPosition tiles from the player's camera
---@param player LuaPlayer
---@param params table rotation, color, ... as for utils.rendering's draw_polygon
---@param fit_to_edge boolean?
---@return LuaRenderObject
function Public.draw_arrow(settings, offset, player, params, fit_to_edge)
    local player_resolution, percentages = player_view(settings, player)
    offset = fit(settings, player_resolution, percentages, offset, fit_to_edge)

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
