-- The symbols of Mosaic's panels (see mosaic_layout.lua): space and industry, in the flat,
-- hard-edged style of monumental mosaics. Figures as art_shapes.lua draws them: shapes in grid
-- units around the centre, x right and y down, drawn in order; `detail = true` shows the line
-- ore (coal). Keep lines at least 0.6 units wide: ~20 tiles at the smallest symbols.
local cos = math.cos
local sin = math.sin
local pi = math.pi

local function star(outer, inner, points, cx, cy)
    local poly = {'poly'}
    for k = 0, 2 * points - 1 do
        local r = k % 2 == 0 and outer or inner
        local a = -pi / 2 + k * pi / points
        poly[#poly + 1] = {(cx or 0) + r * cos(a), (cy or 0) + r * sin(a)}
    end
    return poly
end

-- an ellipse as a closed line, turned by `angle`
local function orbit(rx, ry, angle, width, cx, cy)
    local line = {'line', width}
    local ca, sa = cos(angle), sin(angle)
    for k = 0, 32 do
        local t = k / 32 * 2 * pi
        local x, y = rx * cos(t), ry * sin(t)
        line[#line + 1] = {(cx or 0) + x * ca - y * sa, (cy or 0) + x * sa + y * ca}
    end
    return line
end

local function rays(count, r1, r2, width, offset)
    local shapes = {}
    for k = 0, count - 1 do
        local a = (offset or 0) + k * 2 * pi / count
        shapes[#shapes + 1] = {'line', width, {r1 * cos(a), r1 * sin(a)}, {r2 * cos(a), r2 * sin(a)}}
    end
    return shapes
end

local function concat(...)
    local all = {}
    for _, list in ipairs({...}) do
        for _, shape in ipairs(list) do
            all[#all + 1] = shape
        end
    end
    return all
end

-- an ear of wheat: a stalk from (x1, y1) to its tip (x2, y2) with grains in pairs along the top
local function ear(x1, y1, x2, y2)
    local shapes = {{'line', 0.7, {x1, y1}, {x2, y2}}}
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    local ux, uy = dx / len, dy / len
    for k = 0, 3 do
        local t = len - 0.5 - k * 1.4
        local px, py = x1 + ux * t, y1 + uy * t
        -- grains lean up and out from the stalk
        shapes[#shapes + 1] = {'line', 0.8, {px, py}, {px - uy * 0.9 + ux * 0.6, py + ux * 0.9 + uy * 0.6}}
        shapes[#shapes + 1] = {'line', 0.8, {px, py}, {px + uy * 0.9 + ux * 0.6, py - ux * 0.9 + uy * 0.6}}
    end
    shapes[#shapes + 1] = {'line', 0.7, {x2, y2}, {x2 + ux * 0.9, y2 + uy * 0.9}}
    return shapes
end

return {
    star = {star(6, 2.5, 5)},
    rocket = {
        {'poly', {0, -7.5}, {1.3, -5}, {1.6, 3.2}, {-1.6, 3.2}, {-1.3, -5}},
        {'poly', {-1.6, -0.5}, {-3.4, 3.8}, {-1.6, 3.8}},
        {'poly', {1.6, -0.5}, {3.4, 3.8}, {1.6, 3.8}},
        {'poly', {-1.2, 3.1}, {-0.8, 7}, {0, 5.4}, {0.8, 7}, {1.2, 3.1}},
        {'disc', 0.75, 0, -3, detail = true},
        {'line', 0.6, {-1.5, 0.6}, {1.5, 0.6}, detail = true}
    },
    sputnik = {
        {'disc', 2.7, 0, 0},
        {'line', 0.7, {-1.6, 1.4}, {-6.6, 4.6}},
        {'line', 0.7, {-0.9, 2.1}, {-4.6, 6.6}},
        {'line', 0.7, {1.6, 1.4}, {6.6, 4.6}},
        {'line', 0.7, {0.9, 2.1}, {4.6, 6.6}},
        {'line', 0.6, {-2.7, -0.2}, {2.7, -0.2}, detail = true}
    },
    atom = {
        orbit(6.2, 2.2, 0, 0.9),
        orbit(6.2, 2.2, pi / 3, 0.9),
        orbit(6.2, 2.2, 2 * pi / 3, 0.9),
        {'disc', 1.5, 0, 0}
    },
    gear = concat({{'disc', 4, 0, 0}}, rays(10, 3.6, 5.6, 2.0), {{'disc', 1.8, 0, 0, detail = true}}),
    wheat = concat(ear(0, 6.5, 0, -5.5), ear(-0.4, 6.5, -4.4, -3.4), ear(0.4, 6.5, 4.4, -3.4)),
    factory = {
        {'poly', {-6.5, 8}, {-6.5, 2}, {-4.5, 0.2}, {-4.5, 2}, {-2.5, 0.2}, {-2.5, 2}, {-0.5, 0.2}, {-0.5, 2}, {6.5, 2}, {6.5, 8}},
        {'poly', {1.5, 2.2}, {1.5, -4.5}, {2.9, -4.5}, {2.9, 2.2}},
        {'poly', {4.1, 2.2}, {4.1, -2.8}, {5.5, -2.8}, {5.5, 2.2}},
        {'disc', 1.0, 2.6, -5.8},
        {'disc', 1.3, 3.8, -7},
        {'line', 0.9, {-5.2, 5}, {-3.6, 5}, detail = true},
        {'line', 0.9, {-2.4, 5}, {-0.8, 5}, detail = true},
        {'line', 0.9, {0.6, 5}, {2.2, 5}, detail = true},
        {'line', 0.9, {3.4, 5}, {5, 5}, detail = true}
    },
    pylon = {
        {'line', 0.8, {-3.4, 7}, {-0.7, -6.5}},
        {'line', 0.8, {3.4, 7}, {0.7, -6.5}},
        {'line', 0.8, {-5, -3.8}, {5, -3.8}},
        {'line', 0.8, {-3.8, -0.6}, {3.8, -0.6}},
        {'line', 0.7, {-2.6, 4.6}, {2, 1.6}},
        {'line', 0.7, {2.6, 4.6}, {-2, 1.6}},
        {'line', 0.7, {-1.8, 1.4}, {1.2, -2.6}},
        {'line', 0.7, {1.8, 1.4}, {-1.2, -2.6}},
        {'disc', 0.7, -5, -3.0},
        {'disc', 0.7, 5, -3.0},
        {'disc', 0.7, -3.8, 0.2},
        {'disc', 0.7, 3.8, 0.2}
    },
    planet = {
        {'disc', 3.8, 0, 0},
        orbit(6.8, 1.9, -0.35, 1.0)
    },
    helmet = {
        {'disc', 5.2, 0, -0.5},
        {'poly', {-3.5, 4}, {3.5, 4}, {4.2, 6.2}, {-4.2, 6.2}},
        {'poly', {-3.4, -2.2}, {3.4, -2.2}, {3.9, 0.4}, {2.6, 2.4}, {-2.6, 2.4}, {-3.9, 0.4}, detail = true},
        {'disc', 0.6, 1.8, -1.2}
    },
    flag = {
        {'line', 0.8, {-5.5, -6.5}, {-5.5, 7}},
        {'poly', {-5.5, -6.5}, {-2.5, -7.2}, {0.5, -6}, {3.5, -6.8}, {6.5, -5.8}, {6.5, -1.2}, {3.5, -2.2}, {0.5, -1.4}, {-2.5, -2.6}, {-5.5, -1.8}},
        star(1.4, 0.6, 5, -3, -4.2)
    },
    sun = concat({{'disc', 3.2, 0, 0}}, rays(12, 3.6, 6.4, 1.1, pi / 12)),
    bolt = {{'poly', {1.5, -7}, {-3.5, 0.8}, {-0.4, 0.8}, {-2, 7}, {3.8, -1.2}, {0.7, -1.2}, {3, -7}}},
    disc = {{'disc', 6, 0, 0}}
}
