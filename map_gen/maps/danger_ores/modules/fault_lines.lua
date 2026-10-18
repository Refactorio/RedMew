-- Fault Lines: the map is broken into plates by thin cracks of out-of-map. A crack is never
-- wider than an underground belt can span, but the tier it takes grows with distance from
-- spawn: near spawn yellow undergrounds cross, further out red, then blue. Pipe-to-ground
-- crosses every crack. Players and trains cross at bridges.
--
-- Plates are the cells of a jittered grid of points. Spawn's point sits on spawn and is
-- weighted (a power diagram), so its plate is larger while every border stays straight. Each
-- crack is the border between two plates; its width is set by how far the crack's centre is
-- from spawn, so it is the same along the whole crack. Only cracks between relative
-- neighbours (no third point closer to both) get a bridge, at their centre. That graph is
-- sparse but always connected, so every plate can be walked to. Plates are found in warped
-- coordinates, so the cracks bend while the junctions where they meet stay closed.
--
-- The width is measured along the x or y axis, whichever is closer to straight across the
-- crack, since that is how a belt crosses it. Everything is derived from the seed per tile:
-- nothing is stored.
local Perlin = require 'map_gen.shared.perlin_noise'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'

local perlin_noise = Perlin.noise
local abs = math.abs
local floor = math.floor
local max = math.max
local sqrt = math.sqrt

local PRIME = 2147483647

local default_tiers = {
    {radius = 512, gap = 4}, -- yellow
    {radius = 1280, gap = 6}, -- red
    {gap = 8} -- blue
}

return function(config)
    local plate_size = config.fault_lines_plate_size or 128
    local jitter = config.fault_lines_jitter or 0.45
    local spawn_plate_radius = config.fault_lines_spawn_plate_radius or 64
    local tiers = config.fault_lines_tiers or default_tiers
    local bridge_width = config.fault_lines_bridge_width or 24
    local wobble_amplitude = config.fault_lines_wobble_amplitude or 8
    local wobble_scale = config.fault_lines_wobble_scale or 1 / 48
    local seed = config.fault_lines_seed or seed_provider()

    local seed_hash = floor(seed) % PRIME
    local function hash01(a, c, k)
        local h = (seed_hash + a * 7919 + c * 104729 + k * 1299709) % PRIME
        h = (h * 48271) % PRIME
        h = (h * 48271) % PRIME
        return h / PRIME
    end

    -- the plate point of grid cell (i, j), cached since every tile nearby asks
    local points = {}
    local function point_of(i, j)
        local column = points[i]
        if not column then
            column = {}
            points[i] = column
        end
        local p = column[j]
        if p then
            return p
        end
        if i == 0 and j == 0 then
            p = {0, 0, 0, 0, spawn_plate_radius * spawn_plate_radius}
        else
            p = {
                (i + (hash01(i, j, 1) * 2 - 1) * jitter) * plate_size,
                (j + (hash01(i, j, 2) * 2 - 1) * jitter) * plate_size,
                i,
                j,
                0
            }
        end
        column[j] = p
        return p
    end

    local function gap_at(r)
        for _, tier in pairs(tiers) do
            if not tier.radius or r < tier.radius then
                return tier.gap
            end
        end
        return tiers[#tiers].gap
    end

    -- whether no third point is closer to both a and b than they are to each other, cached
    -- per pair
    local bridged = {}
    local function has_bridge(a, b)
        if a[3] > b[3] or (a[3] == b[3] and a[4] > b[4]) then
            a, b = b, a
        end
        local key = a[3] .. ',' .. a[4] .. ',' .. b[3] .. ',' .. b[4]
        local result = bridged[key]
        if result ~= nil then
            return result
        end

        local dx, dy = b[1] - a[1], b[2] - a[2]
        local d_ab = dx * dx + dy * dy
        local reach_cells = floor(sqrt(d_ab) / plate_size) + 2
        local ci = floor((a[1] + b[1]) / 2 / plate_size + 0.5)
        local cj = floor((a[2] + b[2]) / 2 / plate_size + 0.5)
        result = true
        for i = ci - reach_cells, ci + reach_cells do
            for j = cj - reach_cells, cj + reach_cells do
                local c = point_of(i, j)
                if c ~= a and c ~= b then
                    local ax, ay = c[1] - a[1], c[2] - a[2]
                    local bx, by = c[1] - b[1], c[2] - b[2]
                    if ax * ax + ay * ay < d_ab and bx * bx + by * by < d_ab then
                        result = false
                        break
                    end
                end
            end
            if not result then
                break
            end
        end
        bridged[key] = result
        return result
    end

    local half_bridge = bridge_width / 2
    local reach = 0
    for _, tier in pairs(tiers) do
        reach = max(reach, tier.gap)
    end

    local warp_seed_x = seed
    local warp_seed_y = seed + 7919
    local function warp(x, y, warp_seed)
        return wobble_amplitude * perlin_noise(x * wobble_scale, y * wobble_scale, warp_seed)
    end

    return function(x, y)
        -- plates are found in warped space, so cracks and their junctions bend together
        local u = x + warp(x, y, warp_seed_x)
        local v = y + warp(x, y, warp_seed_y)
        local ci = floor(u / plate_size + 0.5)
        local cj = floor(v / plate_size + 0.5)

        -- nearest and second nearest plate points, by power distance
        local d1, d2 = math.huge, math.huge
        local p1, p2
        for i = ci - 2, ci + 2 do
            for j = cj - 2, cj + 2 do
                local p = point_of(i, j)
                local dx, dy = u - p[1], v - p[2]
                local d = dx * dx + dy * dy - p[5]
                if d < d1 then
                    d2, p2 = d1, p1
                    d1, p1 = d, p
                elseif d < d2 then
                    d2, p2 = d, p
                end
            end
        end

        -- distance to the border of p1 and p2, in warped space
        local nx, ny = p2[1] - p1[1], p2[2] - p1[2]
        local length = sqrt(nx * nx + ny * ny)
        local s = (d2 - d1) / (2 * length)
        if s > reach then
            return false
        end
        nx, ny = nx / length, ny / length

        -- the crack's centre: where it crosses the line between the two points
        local along = (length * length + p1[5] - p2[5]) / (2 * length)
        local mx, my = p1[1] + nx * along, p1[2] + ny * along
        local gap = gap_at(sqrt(mx * mx + my * my))

        -- how fast the distance changes per tile stepped along x and along y: the warp
        -- stretches it, so measure the gap a belt sees along the better axis
        local sx = nx * (2 + warp(x + 1, y, warp_seed_x) - warp(x - 1, y, warp_seed_x)) / 2
            + ny * (warp(x + 1, y, warp_seed_y) - warp(x - 1, y, warp_seed_y)) / 2
        local sy = nx * (warp(x, y + 1, warp_seed_x) - warp(x, y - 1, warp_seed_x)) / 2
            + ny * (2 + warp(x, y + 1, warp_seed_y) - warp(x, y - 1, warp_seed_y)) / 2
        if s >= gap / 2 * max(abs(sx), abs(sy)) then
            return false
        end

        if abs((u - mx) * -ny + (v - my) * nx) < half_bridge and has_bridge(p1, p2) then
            return false
        end

        return 'out-of-map'
    end
end
