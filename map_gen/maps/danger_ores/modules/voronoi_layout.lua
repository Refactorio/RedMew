-- Pure-Lua layout generator for the Danger Ores "Voronoi" map.
-- ZERO Factorio dependencies: unit-testable with a standalone Lua interpreter.
-- Randomness is injected via `random(n) -> integer in [1, n]`, so the caller owns the seed.
--
-- Pipeline: jittered-grid seeds on a toroidal super-tile -> optional Lloyd relaxation ->
-- nearest-seed Voronoi partition -> region adjacency -> DSATUR 4-colouring (lowest-first, so
-- the 4th colour = stone stays rare) -> colour->ore mapping.
local floor = math.floor
local abs = math.abs
local huge = math.huge

local M = {}

-- Squared toroidal distance between (ax,ay) and (bx,by) on a size x size torus.
local function torus_d2(ax, ay, bx, by, size)
    local dx = abs(ax - bx); if dx > size - dx then dx = size - dx end
    local dy = abs(ay - by); if dy > size - dy then dy = size - dy end
    return dx * dx + dy * dy
end

-- One jittered seed per grid square. seeds[i][j] = {x,y}, i,j in 0..g-1.
function M.place_seeds(size, spacing, random)
    local g = floor(size / spacing)
    local seeds = {}
    for i = 0, g - 1 do
        seeds[i] = {}
        for j = 0, g - 1 do
            seeds[i][j] = {
                x = i * spacing + (random(spacing) - 1),
                y = j * spacing + (random(spacing) - 1),
            }
        end
    end
    return seeds
end

-- Assign each cell to its nearest seed (toroidal). Region id = si*g + sj + 1. The nearest
-- seed is always within +/-2 grid squares (seeds never drift more than ~1 square under
-- relaxation), so only a 5x5 neighbourhood is searched.
function M.partition(size, spacing, seeds)
    local g = floor(size / spacing)
    local grid = {}
    for x = 0, size - 1 do
        grid[x] = {}
        local gi = floor(x / spacing)
        for y = 0, size - 1 do
            local gj = floor(y / spacing)
            local best_id, best_d = 0, huge
            for di = -2, 2 do
                for dj = -2, 2 do
                    local si = (gi + di) % g
                    local sj = (gj + dj) % g
                    local s = seeds[si][sj]
                    local d = torus_d2(x, y, s.x, s.y, size)
                    if d < best_d then
                        best_d = d
                        best_id = si * g + sj + 1
                    end
                end
            end
            grid[x][y] = best_id
        end
    end
    return grid
end

-- Lloyd relaxation: move each seed to the toroidal centroid of the cells nearest it, `passes`
-- times. Centroids are computed from nearest-image offsets so the torus wrap is handled.
-- Seeds move less than a grid square per pass, keeping the 5x5 partition search valid.
function M.relax(size, spacing, seeds, passes)
    local g = floor(size / spacing)
    local half = size / 2
    for _ = 1, passes do
        local grid = M.partition(size, spacing, seeds)
        local sumx, sumy, cnt = {}, {}, {}
        for x = 0, size - 1 do
            for y = 0, size - 1 do
                local id = grid[x][y]
                local si = floor((id - 1) / g)
                local sj = (id - 1) % g
                local s = seeds[si][sj]
                local dx = ((x - s.x + half) % size) - half
                local dy = ((y - s.y + half) % size) - half
                sumx[id] = (sumx[id] or 0) + dx
                sumy[id] = (sumy[id] or 0) + dy
                cnt[id] = (cnt[id] or 0) + 1
            end
        end
        for i = 0, g - 1 do
            for j = 0, g - 1 do
                local id = i * g + j + 1
                local c = cnt[id]
                if c then
                    local s = seeds[i][j]
                    s.x = (s.x + sumx[id] / c) % size
                    s.y = (s.y + sumy[id] / c) % size
                end
            end
        end
    end
    return seeds
end

-- neighbors[id] = { other_id = true, ... } over the torus (4-adjacency).
function M.adjacency(grid, size)
    local neighbors = {}
    local function link(a, b)
        if a == b then return end
        neighbors[a] = neighbors[a] or {}
        neighbors[b] = neighbors[b] or {}
        neighbors[a][b] = true
        neighbors[b][a] = true
    end
    for x = 0, size - 1 do
        for y = 0, size - 1 do
            local id = grid[x][y]
            link(id, grid[(x + 1) % size][y])
            link(id, grid[x][(y + 1) % size])
        end
    end
    return neighbors
end

-- Complete graph colouring via dynamic DSATUR (incremental saturation) + backtracking.
-- Colours are tried lowest-first, so the highest colour is used only when forced; generate()
-- maps that rarest colour to stone. Returns colors[id] = 1..num_colors, or nil if impossible.
function M.color(count, neighbors, num_colors)
    local adj = {}
    local deg = {}
    for id = 1, count do
        local a = {}
        local nb = neighbors[id]
        if nb then for o in pairs(nb) do a[#a + 1] = o end end
        adj[id] = a
        deg[id] = #a
    end

    local colors = {}
    local sat = {}
    local ncolor = {}
    for id = 1, count do
        sat[id] = 0
        local t = {}
        for c = 1, num_colors do t[c] = 0 end
        ncolor[id] = t
    end

    local uncolored = count
    local SAFETY = 200000
    local nodes = 0

    local function assign(id, c)
        colors[id] = c
        uncolored = uncolored - 1
        for _, o in ipairs(adj[id]) do
            if colors[o] == nil then
                local nc = ncolor[o]
                if nc[c] == 0 then sat[o] = sat[o] + 1 end
                nc[c] = nc[c] + 1
            end
        end
    end

    local function unassign(id, c)
        for _, o in ipairs(adj[id]) do
            if colors[o] == nil then
                local nc = ncolor[o]
                nc[c] = nc[c] - 1
                if nc[c] == 0 then sat[o] = sat[o] - 1 end
            end
        end
        colors[id] = nil
        uncolored = uncolored + 1
    end

    local function pick()
        local best, best_sat, best_deg = nil, -1, -1
        for id = 1, count do
            if colors[id] == nil then
                local s = sat[id]
                local d = deg[id]
                if s > best_sat or (s == best_sat and d > best_deg) then
                    best, best_sat, best_deg = id, s, d
                end
            end
        end
        return best
    end

    local function solve()
        if uncolored == 0 then return true end
        nodes = nodes + 1
        if nodes > SAFETY then return false end
        local id = pick()
        local nc = ncolor[id]
        for c = 1, num_colors do
            if nc[c] == 0 then
                assign(id, c)
                if solve() then return true end
                unassign(id, c)
            end
        end
        return false
    end

    if solve() then return colors end
    return nil
end

-- Place seeds -> relax -> partition -> 4-colour -> map colours to ores, retrying with fresh
-- seeds until a clean colouring exists. Returns a layout: { size, spacing, g, seeds, seed_ore }
-- where seed_ore[region_id] is the ore index for the seed at region_id = si*g + sj + 1.
-- Adjacency/colouring use the cell raster (which captures every edge-adjacency of the diagram),
-- so the guarantee holds for the smooth per-tile boundaries drawn by ore_at().
function M.build(opts)
    local size = opts.size
    local spacing = opts.spacing
    local relaxation = opts.relaxation or 0
    local num_ores = opts.num_ores
    -- the clean-border guarantee is a graph colouring: 4 colours is the mathematical minimum
    assert(num_ores >= 4, 'voronoi_layout: at least 4 ore types are required for guaranteed clean borders')
    local random = opts.random
    local max_attempts = opts.max_attempts or 8
    local g = floor(size / spacing)

    for _ = 1, max_attempts do
        local seeds = M.place_seeds(size, spacing, random)
        if relaxation > 0 then M.relax(size, spacing, seeds, relaxation) end
        local grid = M.partition(size, spacing, seeds)
        local neighbors = M.adjacency(grid, size)
        local colors = M.color(g * g, neighbors, num_ores)
        if colors then
            -- rarest colour (highest, from lowest-first colouring) -> last ore (stone);
            -- permute the rest among the remaining ores for per-seed variety.
            local ore_of = {}
            local perm = {}
            for i = 1, num_ores - 1 do perm[i] = i end
            for i = num_ores - 1, 2, -1 do
                local j = random(i)
                perm[i], perm[j] = perm[j], perm[i]
            end
            for c = 1, num_ores - 1 do ore_of[c] = perm[c] end
            ore_of[num_ores] = num_ores

            local seed_ore = {}
            for id = 1, g * g do seed_ore[id] = ore_of[colors[id]] end
            return { size = size, spacing = spacing, g = g, seeds = seeds, seed_ore = seed_ore }
        end
    end
    error('voronoi_layout: could not ' .. num_ores .. '-colour after ' .. max_attempts .. ' attempts')
end

-- Smooth per-point ore lookup: ore of the seed nearest to continuous cell-space (fx,fy),
-- both already reduced into [0,size). Gives tile-resolution (non-blocky) Voronoi boundaries.
function M.ore_at(layout, fx, fy)
    local size, spacing, g, seeds = layout.size, layout.spacing, layout.g, layout.seeds
    local gi = floor(fx / spacing)
    local gj = floor(fy / spacing)
    local best_id, best_d = 1, huge
    for di = -2, 2 do
        for dj = -2, 2 do
            local si = (gi + di) % g
            local sj = (gj + dj) % g
            local s = seeds[si][sj]
            local d = torus_d2(fx, fy, s.x, s.y, size)
            if d < best_d then best_d = d; best_id = si * g + sj + 1 end
        end
    end
    return layout.seed_ore[best_id]
end

-- Convenience: rasterise the smooth layout to an ore_grid[x][y] (used by tests).
function M.generate(opts)
    local layout = M.build(opts)
    local size = layout.size
    local ore_grid = {}
    for x = 0, size - 1 do
        ore_grid[x] = {}
        for y = 0, size - 1 do
            ore_grid[x][y] = M.ore_at(layout, x, y)
        end
    end
    return ore_grid
end

return M
