-- Pure-Lua shape drawing for the Danger Ores maps painted in ore (Mosaic): figures made of
-- round-capped strokes, discs and polygons, turned, flipped and scaled onto the map, read back
-- per tile; plus the hash and weighted picks those maps draw their randomness from.
-- ZERO Factorio dependencies.
--
-- A figure is a list of shapes in grid units around its centre, x right and y down like the
-- map, drawn in order, each over the ones before it:
--   {'line', width, {x, y}, {x, y}, ...}   a round-capped stroke through the points
--   {'disc', radius, x, y}
--   {'poly', {x, y}, {x, y}, ...}          a filled polygon
-- A shape with `detail = true` is line work: it shows the line ore instead of the figure's ink.
local floor = math.floor
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin
local max = math.max
local min = math.min

local Public = {}

local PRIME = 2147483647
Public.PRIME = PRIME

-- (a * b) % PRIME without leaving the 2^53 a double holds exactly: a, b < 2^31.
local function mulmod(a, b)
    local high = floor(b / 65536)
    return ((a * high) % PRIME * 65536 + a * (b - high * 65536)) % PRIME
end

-- A hash of (a, b): squaring mixes it, so neighbouring a and b look nothing alike (a linear
-- hash lines them up in visible rows).
local function hash(seed_hash, a, b)
    local h = (seed_hash + a * 7919) % PRIME
    h = (mulmod(h, h) + b * 104729 + 1) % PRIME
    h = (mulmod(h, h) + 2654435) % PRIME
    h = mulmod(h, h)
    return h == 0 and 1 or h
end

--- A stream of numbers in [0, 1) for (a, b): `next01()` returns the next one.
function Public.hash_stream(seed_hash, a, b)
    local h = hash(seed_hash, a, b)
    return function()
        h = (h * 48271) % PRIME
        return h / PRIME
    end
end

-- The weight of an ink `blend` of the way from near spawn (0) to far out (1).
local function ink_weight(ink, blend)
    local far = ink[3] or ink[2]
    return ink[2] + (far - ink[2]) * blend
end

--- Picks from `inks` = {{name, weight near spawn, weight far out (optional)}, ...} by their
-- weights `blend` of the way out, with `t` in [0, 1).
function Public.pick_ink(inks, blend, t)
    local total = 0
    for _, ink in ipairs(inks) do
        total = total + ink_weight(ink, blend)
    end
    local r = t * total
    for _, ink in ipairs(inks) do
        r = r - ink_weight(ink, blend)
        if r < 0 then
            return ink[1]
        end
    end
    return inks[#inks][1]
end

-- Squared distance from (px, py) to the segment (ax, ay)-(bx, by).
local function segment_d2(px, py, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local wx, wy = px - ax, py - ay
    local len2 = dx * dx + dy * dy
    local t = 0
    if len2 > 0 then
        t = (wx * dx + wy * dy) / len2
        if t < 0 then
            t = 0
        elseif t > 1 then
            t = 1
        end
    end
    local ex, ey = wx - t * dx, wy - t * dy
    return ex * ex + ey * ey
end

-- A part is a set of strokes {ax, ay, bx, by, radius} or a flat polygon {x1, y1, x2, y2, ...},
-- with its bounds.
local function strokes_part(strokes, detail)
    local min_x, max_x, min_y, max_y = math.huge, -math.huge, math.huge, -math.huge
    for _, s in ipairs(strokes) do
        local r = s[5]
        min_x = min(min_x, s[1] - r, s[3] - r)
        max_x = max(max_x, s[1] + r, s[3] + r)
        min_y = min(min_y, s[2] - r, s[4] - r)
        max_y = max(max_y, s[2] + r, s[4] + r)
    end
    return {strokes = strokes, detail = detail, min_x = min_x, max_x = max_x, min_y = min_y, max_y = max_y}
end

local function poly_part(points, detail)
    local flat = {}
    local min_x, max_x, min_y, max_y = math.huge, -math.huge, math.huge, -math.huge
    for _, p in ipairs(points) do
        flat[#flat + 1] = p[1]
        flat[#flat + 1] = p[2]
        min_x, max_x = min(min_x, p[1]), max(max_x, p[1])
        min_y, max_y = min(min_y, p[2]), max(max_y, p[2])
    end
    return {poly = flat, detail = detail, min_x = min_x, max_x = max_x, min_y = min_y, max_y = max_y}
end

-- Whether (u, v) is inside the flat polygon (even-odd rule).
local function in_poly(poly, u, v)
    local inside = false
    local n = #poly
    local jx, jy = poly[n - 1], poly[n]
    for i = 1, n, 2 do
        local ix, iy = poly[i], poly[i + 1]
        if (iy > v) ~= (jy > v) and u < (jx - ix) * (v - iy) / (jy - iy) + ix then
            inside = not inside
        end
        jx, jy = ix, iy
    end
    return inside
end
Public.in_poly = in_poly

local function part_covers(part, u, v)
    if u < part.min_x or u > part.max_x or v < part.min_y or v > part.max_y then
        return false
    end
    local poly = part.poly
    if poly then
        return in_poly(poly, u, v)
    end
    for _, s in ipairs(part.strokes) do
        local r = s[5]
        if segment_d2(u, v, s[1], s[2], s[3], s[4]) <= r * r then
            return true
        end
    end
    return false
end

-- Signed distance from (u, v) to the part: negative inside.
local function part_distance(part, u, v)
    local poly = part.poly
    if poly then
        local best = math.huge
        local n = #poly
        local jx, jy = poly[n - 1], poly[n]
        for i = 1, n, 2 do
            local ix, iy = poly[i], poly[i + 1]
            best = min(best, segment_d2(u, v, jx, jy, ix, iy))
            jx, jy = ix, iy
        end
        local d = sqrt(best)
        return in_poly(poly, u, v) and -d or d
    end
    local best = math.huge
    for _, s in ipairs(part.strokes) do
        best = min(best, sqrt(segment_d2(u, v, s[1], s[2], s[3], s[4])) - s[5])
    end
    return best
end

-- How far (u, v) is from the part's bounds, never more than from the part itself.
local function box_distance(part, u, v)
    local dx = max(part.min_x - u, 0, u - part.max_x)
    local dy = max(part.min_y - v, 0, v - part.max_y)
    return sqrt(dx * dx + dy * dy)
end

--- Builds a piece from a figure: in `ink`, centred on (x, y) tiles, `unit` tiles to a grid
-- unit, turned by `tilt` radians and flipped left to right when `mirror` is -1.
function Public.make_figure(figure, ink, layer, x, y, unit, tilt, mirror)
    local parts = {}
    for _, shape in ipairs(figure) do
        local kind, detail = shape[1], shape.detail and true or false
        if kind == 'poly' then
            local points = {}
            for i = 2, #shape do
                points[#points + 1] = {shape[i][1] * mirror, shape[i][2]}
            end
            parts[#parts + 1] = poly_part(points, detail)
        elseif kind == 'disc' then
            local px, py = shape[3] * mirror, shape[4]
            parts[#parts + 1] = strokes_part({{px, py, px, py, shape[2]}}, detail)
        else -- line
            local r = shape[2] / 2
            local strokes = {}
            local ax, ay = shape[3][1] * mirror, shape[3][2]
            for i = 4, #shape do
                local bx, by = shape[i][1] * mirror, shape[i][2]
                strokes[#strokes + 1] = {ax, ay, bx, by, r}
                ax, ay = bx, by
            end
            if #strokes == 0 then
                strokes[1] = {ax, ay, ax, ay, r}
            end
            parts[#parts + 1] = strokes_part(strokes, detail)
        end
    end

    local min_x, max_x, min_y, max_y = math.huge, -math.huge, math.huge, -math.huge
    for _, part in ipairs(parts) do
        min_x, max_x = min(min_x, part.min_x), max(max_x, part.max_x)
        min_y, max_y = min(min_y, part.min_y), max(max_y, part.max_y)
    end
    return {
        ink = ink,
        layer = layer,
        x = x,
        y = y,
        unit = unit,
        cos = cos(tilt),
        sin = sin(tilt),
        parts = parts,
        min_x = min_x,
        max_x = max_x,
        min_y = min_y,
        max_y = max_y,
        -- the farthest the paint reaches from the centre, in tiles
        reach = sqrt(max(min_x * min_x, max_x * max_x) + max(min_y * min_y, max_y * max_y)) * unit
    }
end

-- (x, y) tiles in the piece's own grid units
local function to_piece(piece, x, y)
    local dx, dy = x - piece.x, y - piece.y
    local inv = 1 / piece.unit
    return (dx * piece.cos + dy * piece.sin) * inv, (dy * piece.cos - dx * piece.sin) * inv
end

--- What the piece puts on the tile at (x, y): 'paint' (its ink), 'detail' (its line work) or
-- false (nothing).
function Public.covers(piece, x, y)
    local u, v = to_piece(piece, x, y)
    if u < piece.min_x or u > piece.max_x or v < piece.min_y or v > piece.max_y then
        return false
    end
    local parts = piece.parts
    for i = #parts, 1, -1 do
        local part = parts[i]
        if part_covers(part, u, v) then
            return part.detail and 'detail' or 'paint'
        end
    end
    return false
end

--- The distance in tiles from the tile at (x, y) to the piece's paint, its line work left out:
-- negative inside. What outlines are drawn from.
function Public.paint_distance(piece, x, y)
    local u, v = to_piece(piece, x, y)
    local d = math.huge
    for _, part in ipairs(piece.parts) do
        if not part.detail and box_distance(part, u, v) < d then
            d = min(d, part_distance(part, u, v))
        end
    end
    return d * piece.unit
end

return Public
