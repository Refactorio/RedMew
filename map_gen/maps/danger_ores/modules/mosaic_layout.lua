-- Pure-Lua layout for the Danger Ores "Mosaic" map: a monumental mural of space and industry,
-- in the flat, hard-edged style of the great mosaics on building walls.
-- ZERO Factorio dependencies. Randomness comes from the injected `random(n) -> [1, n]`, drawn
-- once for a seed; everything after that is a hash of (panel, seed), so the map is infinite,
-- never repeats and needs nothing stored.
--
-- The wall is rows of panels, framed in the line ore (coal). Each panel has a constructivist
-- background (sunburst rays, stripes, orbits, a web of rays and rings, or split fields) in three
-- inks between lines, and a big symbol on it (a rocket, sputnik, atom, gear, wheat, factory,
-- pylon...), outlined, sometimes on a great disc, with stars round it. Spawn sits in a round
-- medallion: a great faceted star of iron and copper on an iron core, ringed by a sunburst. Which inks a panel uses follows its distance from spawn: mostly
-- iron close in, more copper further out.
local Shapes = require 'map_gen.maps.danger_ores.modules.art_shapes'
local Figures = require 'map_gen.maps.danger_ores.modules.mosaic_figures'

local floor = math.floor
local abs = math.abs
local sqrt = math.sqrt
local min = math.min
local max = math.max
local cos = math.cos
local sin = math.sin
local pi = math.pi
local atan2 = math.atan2 or math.atan -- Lua 5.2 (Factorio) has atan2; later Luas take atan(y, x)

local covers = Shapes.covers
local paint_distance = Shapes.paint_distance
local pick_ink = Shapes.pick_ink

local Public = {}

local SYMBOLS = {}
for name in pairs(Figures) do
    if name ~= 'disc' then
        SYMBOLS[#SYMBOLS + 1] = name
    end
end
table.sort(SYMBOLS)
Public.SYMBOLS = SYMBOLS

local PATTERNS = {'rays', 'stripes', 'rings', 'web', 'split'}
Public.PATTERNS = PATTERNS

-- the order a panel's three inks repeat in: its first ink twice as often as the others
local CYCLE = {1, 2, 1, 3}

--- Default settings; `Public.new` fills any the caller leaves out from these. Lengths in tiles.
Public.defaults = {
    -- {ore, weight near spawn, weight far out}: a panel's inks are drawn by these weights,
    -- blending from ink_near to ink_far tiles from spawn.
    inks = {{'iron-ore', 60, 30}, {'copper-ore', 32, 62}, {'coal', 8, 8}},
    line_ink = 'coal', -- frames, lines and outlines
    ink_near = 300,
    ink_far = 1500,
    row_height = 640,
    panel_width = {520, 1100},
    frame = 34,
    line = 20,
    outline = 22,
    band = {120, 200}, -- stripes and rings
    ray_counts = {8, 12, 16, 20}, -- multiples of #CYCLE, so the inks repeat evenly round
    symbol_size = 0.62, -- the main symbol's height as a share of the panel's
    disc_chance = 0.45,
    stars = {0, 3},
    -- The round medallion spawn sits in. It fits the land terraforming opens at the start (a
    -- square 384 tiles across): a great faceted star round spawn, iron and copper by turns all
    -- round for its first 100 tiles (spawn's own 64 have no ore), on an iron core showing
    -- between its points, then a ring of rays.
    medallion = 380,
    medallion_core = 240,
    medallion_core_ink = 'iron-ore',
    medallion_inks = {'iron-ore', 'copper-ore'},
    medallion_rays = 24,
    -- symbols round spawn, listed bottom first: {name, ink, x, y, unit, tilt, facets}; a faceted
    -- star has each point split down the middle in two inks, so iron and copper take turns
    -- right round spawn's edge
    spawn_symbols = {
        {'star', 'iron-ore', 0, 0, 40, 0, {'iron-ore', 'copper-ore', points = 5}}
    }
}

local function lerp(range, t)
    return range[1] + (range[2] - range[1]) * t
end

-- The inks but `name`.
local function without(inks, name)
    local left = {}
    for _, ink in ipairs(inks) do
        if ink[1] ~= name then
            left[#left + 1] = ink
        end
    end
    return left
end

-- The three inks of a panel `blend` of the way out, drawn by their weights: the second unlike
-- the first, the third unlike the second (CYCLE puts it between the first and the second).
local function draw_palette(inks, blend, next01)
    local first = pick_ink(inks, blend, next01())
    local second = pick_ink(without(inks, first), blend, next01())
    local third = pick_ink(without(inks, second), blend, next01())
    return {first, second, third}
end
Public.draw_palette = draw_palette

-- The facet of a faceted piece at (x, y): its points split down the middle, turn about. A
-- point of a star at 0 radians points up (-pi/2) and each facet spans pi / points.
local function facet_ink(piece, x, y)
    local facets = piece.facets
    local a = atan2(y - piece.y, x - piece.x) - piece.tilt + pi / 2
    local i = floor(a / (pi / facets.points)) % (2 * facets.points)
    return facets[i % 2 + 1]
end
Public.facet_ink = facet_ink

-- What the pieces (top last) put on (x, y): a piece's ink, the line ink for line work and
-- outlines, or nil.
local function draw_pieces(pieces, x, y, outline, line_ink)
    for i = #pieces, 1, -1 do
        local piece = pieces[i]
        local dx, dy = x - piece.x, y - piece.y
        local reach = piece.reach + outline
        if dx * dx + dy * dy <= reach * reach then
            local role = covers(piece, x, y)
            if role == 'paint' then
                return piece.facets and facet_ink(piece, x, y) or piece.ink
            elseif role then
                return line_ink
            elseif paint_distance(piece, x, y) < outline then
                return line_ink
            end
        end
    end
    return nil
end
Public.draw_pieces = draw_pieces

-- How far (lx, ly) is round the rays from (fx, fy): the ray it is in and how far across it
-- is from the nearest edge between rays, in tiles.
local function ray_at(lx, ly, fx, fy, n, a0)
    local dx, dy = lx - fx, ly - fy
    local r = sqrt(dx * dx + dy * dy)
    local t = ((atan2(dy, dx) - a0) / (2 * pi) * n) % n
    local i = floor(t)
    local f = t - i
    local delta = min(f, 1 - f) * 2 * pi / n
    return i, r * sin(min(delta, pi / 2)), r
end

-- The background of a panel at (lx, ly), its own coordinates: the index of one of its inks in
-- CYCLE order, or 0 for a line.
local function background(panel, lx, ly, line)
    local half = line / 2
    local pattern = panel.pattern
    if pattern == 'rays' or pattern == 'web' then
        local i, across, r = ray_at(lx, ly, panel.fx, panel.fy, panel.rays, panel.a0)
        if across < half then
            return 0
        end
        if pattern == 'rays' then
            return CYCLE[i % #CYCLE + 1]
        end
        local band = panel.band
        local j = floor(r / band)
        local f = r - j * band
        if f < half or band - f < half then
            return 0
        end
        return CYCLE[(i + j) % #CYCLE + 1]
    elseif pattern == 'rings' then
        local dx, dy = lx - panel.fx, ly - panel.fy
        local r = sqrt(dx * dx + dy * dy)
        local band = panel.band
        local j = floor(r / band)
        local f = r - j * band
        if f < half or band - f < half then
            return 0
        end
        return CYCLE[j % #CYCLE + 1]
    elseif pattern == 'stripes' then
        local s = lx * panel.ca + ly * panel.sa + panel.shift
        local band = panel.band
        local j = floor(s / band)
        local f = s - j * band
        if f < half or band - f < half then
            return 0
        end
        return CYCLE[j % #CYCLE + 1]
    end
    -- split: two lines cut the panel in up to four fields
    local region = 1
    for _, cut in ipairs(panel.cuts) do
        local side = (lx - cut[1]) * cut[4] - (ly - cut[2]) * cut[3]
        if side > -half and side < half then
            return 0
        end
        if side > 0 then
            region = region + cut[5]
        end
    end
    return CYCLE[region]
end
Public.background = background

--- A new layout. `opts` = {random = random(n), any of Public.defaults to override}.
function Public.new(opts)
    local settings = {}
    for k, v in pairs(Public.defaults) do
        settings[k] = v
    end
    for k, v in pairs(opts) do
        settings[k] = v
    end

    local seed_hash = settings.random(Shapes.PRIME - 1)
    local hash_stream = Shapes.hash_stream
    local inks, line_ink = settings.inks, settings.line_ink
    local row_height, frame, line, outline = settings.row_height, settings.frame, settings.line, settings.outline

    local function blend_at(x, y)
        local r = sqrt(x * x + y * y)
        return max(0, min(1, (r - settings.ink_near) / (settings.ink_far - settings.ink_near)))
    end

    local function make_symbol(name, ink, layer, x, y, unit, tilt, mirror)
        return Shapes.make_figure(Figures[name], ink, layer, x, y, unit, tilt, mirror)
    end

    -- the row's panel width and where its first panel starts
    local rows = {}
    local function row_at(row)
        local r = rows[row]
        if not r then
            local next01 = hash_stream(seed_hash, 1000003, row)
            local width = lerp(settings.panel_width, next01())
            r = {width = width, offset = next01() * width}
            rows[row] = r
        end
        return r
    end

    -- a panel: its background and its symbols, in map coordinates
    local function make_panel(row, col)
        local r = row_at(row)
        local next01 = hash_stream(seed_hash, col, row)
        local w, h = r.width, row_height
        local cx, cy = r.offset + (col + 0.5) * w, (row + 0.5) * h
        local panel = {x = cx, y = cy, w = w, h = h}
        panel.palette = draw_palette(inks, blend_at(cx, cy), next01)
        local pattern = PATTERNS[1 + floor(next01() * #PATTERNS)]
        panel.pattern = pattern

        -- where rays and rings come from: the middle, a corner or the middle of a side
        local spot = next01()
        local fx, fy = 0, 0
        if spot > 0.4 then
            local sx, sy = next01() < 0.5 and -1 or 1, next01() < 0.5 and -1 or 1
            if spot < 0.7 then
                fx, fy = sx * w / 2, sy * h / 2
            elseif next01() < 0.5 then
                fx = sx * w / 2
            else
                fy = sy * h / 2
            end
        end
        panel.fx, panel.fy = fx, fy
        panel.rays = settings.ray_counts[1 + floor(next01() * #settings.ray_counts)]
        panel.a0 = next01() * 2 * pi
        panel.band = lerp(settings.band, next01())
        local angle = (next01() < 0.5 and -1 or 1) * (pi / 6 + next01() * pi / 3)
        panel.ca, panel.sa = cos(angle), sin(angle)
        panel.shift = next01() * panel.band
        panel.cuts = {}
        for k = 1, 2 do
            local a = next01() * pi
            panel.cuts[k] = {(next01() - 0.5) * w * 0.5, (next01() - 0.5) * h * 0.5, cos(a), sin(a), k}
        end

        -- the symbol, on a disc sometimes, and stars
        local pieces = {}
        local ink_of = function(px, py)
            local index = background(panel, px - cx, py - cy, line)
            return index > 0 and panel.palette[index] or line_ink
        end
        -- a paint ink unlike what is under (px, py)
        local function contrast(px, py, avoid)
            local under = ink_of(px, py)
            for _, name in ipairs(panel.palette) do
                if name ~= under and name ~= line_ink and name ~= avoid then
                    return name
                end
            end
            for _, name in ipairs(panel.palette) do
                if name ~= line_ink then
                    return name
                end
            end
            return panel.palette[1]
        end
        local sx = cx + (fx == 0 and fy == 0 and 0 or (next01() - 0.5) * w * 0.3)
        local sy = cy + (next01() - 0.5) * h * 0.1
        local unit = h * settings.symbol_size / 14
        local name = SYMBOLS[1 + floor(next01() * #SYMBOLS)]
        local tilt = name == 'rocket' and (next01() - 0.5) * 1.2 or (next01() - 0.5) * 0.3
        local mirror = next01() < 0.5 and -1 or 1
        local ink = contrast(sx, sy)
        if next01() < settings.disc_chance then
            local disc_ink = contrast(sx, sy, ink)
            pieces[#pieces + 1] = make_symbol('disc', disc_ink, 1, sx, sy, unit * 1.2, 0, 1)
            if disc_ink == ink then
                ink = panel.palette[1] ~= ink and panel.palette[1] or panel.palette[2]
            end
        end
        pieces[#pieces + 1] = make_symbol(name, ink, 2, sx, sy, unit, tilt, mirror)
        panel.symbol = name
        -- stars clear of the symbol: a few tries each, then none
        local clear = pieces[#pieces].reach + h / 8
        for _ = 1, floor(lerp(settings.stars, next01()) + 0.5) do
            for _ = 1, 4 do
                local px, py = cx + (next01() - 0.5) * w * 0.8, cy + (next01() - 0.5) * h * 0.8
                if (px - sx) ^ 2 + (py - sy) ^ 2 > clear * clear then
                    pieces[#pieces + 1] = make_symbol('star', contrast(px, py), 3, px, py, h / 46, (next01() - 0.5) * 0.6, 1)
                    break
                end
            end
        end
        panel.pieces = pieces
        return panel
    end

    local panels = {}
    local function panel_at(row, col)
        local by_row = panels[row]
        if not by_row then
            by_row = {}
            panels[row] = by_row
        end
        local panel = by_row[col]
        if not panel then
            panel = make_panel(row, col)
            by_row[col] = panel
        end
        return panel
    end

    -- spawn's medallion
    local medallion = settings.medallion
    local spawn_pieces = {}
    for i, s in ipairs(settings.spawn_symbols) do
        local piece = make_symbol(s[1], s[2], 10 + i, s[3], s[4], s[5], s[6], 1)
        piece.tilt, piece.facets = s[6], s[7]
        spawn_pieces[i] = piece
    end
    local m_inks, m_rays = settings.medallion_inks, settings.medallion_rays
    local core, core_ink = settings.medallion_core, settings.medallion_core_ink
    local function medallion_at(x, y, r)
        local ink = draw_pieces(spawn_pieces, x, y, outline, line_ink)
        if ink then
            return ink
        end
        -- a solid core, then a sunburst
        if abs(r - core) < line / 2 then
            return line_ink
        end
        if r < core then
            return core_ink
        end
        local i, across = ray_at(x, y, 0, 0, m_rays, 0)
        if across < line / 2 then
            return line_ink
        end
        return m_inks[i % #m_inks + 1]
    end

    return {
        settings = settings,
        panel_at = panel_at,
        row_at = row_at,
        --- The ore at the tile (x, y).
        ore_at = function(x, y)
            local r = sqrt(x * x + y * y)
            if r < medallion + frame / 2 then
                if r > medallion - frame / 2 then
                    return line_ink
                end
                return medallion_at(x, y, r)
            end
            local row = floor(y / row_height)
            local rr = row_at(row)
            local col = floor((x - rr.offset) / rr.width)
            local left = rr.offset + col * rr.width
            local top = row * row_height
            local half = frame / 2
            if x - left < half or left + rr.width - x < half or y - top < half or top + row_height - y < half then
                return line_ink
            end
            local panel = panel_at(row, col)
            local ink = draw_pieces(panel.pieces, x, y, outline, line_ink)
            if ink then
                return ink
            end
            local index = background(panel, x - panel.x, y - panel.y, line)
            return index > 0 and panel.palette[index] or line_ink
        end
    }
end

return Public
