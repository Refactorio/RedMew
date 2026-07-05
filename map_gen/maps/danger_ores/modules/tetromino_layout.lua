-- Pure-Lua layout generator for the Danger Ores "Tetrominoes" map.
-- ZERO Factorio dependencies: unit-testable with a standalone Lua interpreter.
-- All randomness is injected via `random(n) -> integer in [1, n]`, so the caller
-- owns the seed (the Factorio builder passes the map-seeded generator; tests pass
-- math.random).
--
-- Packing produces ONLY valid tetrominoes (all seven: I/O/T/S/Z/L/J) with no gaps, by
-- seeding a trivial 4x4-block tiling and then randomizing it with local 4x4 flips (a standard
-- approach for random tilings -- brute-force exact cover is intractable at this size).
local sort = table.sort
local concat = table.concat

local M = {}

-- Normalize a shape (list of {dx,dy}) so its min dx/dy are 0; return a sorted copy
-- plus a string key for de-duplication.
local function normalize(cells)
    local min_x, min_y = math.huge, math.huge
    for _, c in ipairs(cells) do
        if c[1] < min_x then min_x = c[1] end
        if c[2] < min_y then min_y = c[2] end
    end
    local out = {}
    for i, c in ipairs(cells) do
        out[i] = { c[1] - min_x, c[2] - min_y }
    end
    sort(out, function(a, b)
        if a[1] ~= b[1] then return a[1] < b[1] end
        return a[2] < b[2]
    end)
    local parts = {}
    for i, c in ipairs(out) do parts[i] = c[1] .. ',' .. c[2] end
    return out, concat(parts, ';')
end

-- All unique orientations (4 rotations x reflection) of a shape.
function M.orientations(shape)
    local variants = {}
    local seen = {}
    local cur = shape
    for _ = 1, 4 do
        local rotated = {}      -- rotate 90deg: (x,y) -> (y, -x)
        for i, c in ipairs(cur) do rotated[i] = { c[2], -c[1] } end
        local reflected = {}    -- reflect the rotated variant: (x,y) -> (-x, y)
        for i, c in ipairs(rotated) do reflected[i] = { -c[1], c[2] } end
        for _, variant in ipairs({ rotated, reflected }) do
            local norm, key = normalize(variant)
            if not seen[key] then
                seen[key] = true
                variants[#variants + 1] = norm
            end
        end
        cur = rotated
    end
    return variants
end

-- Enumerate every way to tile a w x h rectangle with tetrominoes. `tetros_rel` is a list of
-- tetromino orientations, each as offsets relative to its scan-leading cell (offset {0,0}).
-- w*h is tiny (8), so this exhaustive DFS is instant. Returns a list of tilings; each tiling
-- is a list of pieces; each piece a list of {x,y} cells within the rectangle.
local function enumerate(w, h, tetros_rel)
    local g = {}
    for x = 0, w - 1 do g[x] = {}; for y = 0, h - 1 do g[x][y] = 0 end end
    local sols, cur = {}, {}
    local function first_empty()
        for x = 0, w - 1 do for y = 0, h - 1 do if g[x][y] == 0 then return x, y end end end
    end
    local function rec()
        local x, y = first_empty()
        if not x then
            local snap = {}
            for _, piece in ipairs(cur) do
                local cc = {}
                for _, c in ipairs(piece) do cc[#cc + 1] = { c[1], c[2] } end
                snap[#snap + 1] = cc
            end
            sols[#sols + 1] = snap
            return
        end
        for _, rel in ipairs(tetros_rel) do
            local placed, ok = {}, true
            for _, c in ipairs(rel) do
                local px, py = x + c[1], y + c[2]
                if px < 0 or px >= w or py < 0 or py >= h or g[px][py] ~= 0 then
                    ok = false
                    break
                end
                placed[#placed + 1] = { px, py }
            end
            if ok then
                for _, p in ipairs(placed) do g[p[1]][p[2]] = 1 end
                cur[#cur + 1] = placed
                rec()
                cur[#cur] = nil
                for _, p in ipairs(placed) do g[p[1]][p[2]] = 0 end
            end
        end
    end
    rec()
    return sols
end

-- Pack a size x size torus entirely with tetrominoes (size must be a multiple of 4).
-- Returns grid[x][y] = piece id (1..count) and the piece count.
function M.pack(size, oriented, random)
    -- tetromino orientations only, as offsets relative to the scan-leading cell
    local tetros_rel = {}
    for _, cells in ipairs(oriented) do
        if #cells == 4 then
            local bx, by = cells[1][1], cells[1][2]
            local rel = {}
            for _, c in ipairs(cells) do rel[#rel + 1] = { c[1] - bx, c[2] - by } end
            tetros_rel[#tetros_rel + 1] = rel
        end
    end
    -- All tilings of a 4x4 block by four tetrominoes. Using a 4x4 base (rather than 2x4) is
    -- what lets all seven tetrominoes appear -- T, S and Z cannot pair-tile a 2x4 rectangle.
    local decomp = enumerate(4, 4, tetros_rel)

    local grid = {}
    for x = 0, size - 1 do grid[x] = {}; for y = 0, size - 1 do grid[x][y] = 0 end end
    local nid = 0

    -- Base tiling: fill 4x4 blocks, each with a random valid 4-tetromino decomposition.
    for bx = 0, size - 1, 4 do
        for by = 0, size - 1, 4 do
            local d = decomp[random(#decomp)]
            for _, piece in ipairs(d) do
                nid = nid + 1
                for _, c in ipairs(piece) do grid[(bx + c[1]) % size][(by + c[2]) % size] = nid end
            end
        end
    end

    -- Local flip shuffling: repeatedly pick a 4x4 window; if it currently holds exactly four
    -- whole tetrominoes, re-tile it with a random decomposition. This mixes the rigid base
    -- grid into an organic layout while staying a valid tetromino tiling.
    local function try_flip()
        local x, y = random(size) - 1, random(size) - 1
        local counts, order = {}, {}
        for i = 0, 3 do
            for j = 0, 3 do
                local id = grid[(x + i) % size][(y + j) % size]
                if not counts[id] then counts[id] = 0; order[#order + 1] = id end
                counts[id] = counts[id] + 1
            end
        end
        if #order ~= 4 then return end
        for _, id in ipairs(order) do if counts[id] ~= 4 then return end end
        local d = decomp[random(#decomp)]
        for _, piece in ipairs(d) do
            nid = nid + 1
            for _, c in ipairs(piece) do grid[(x + c[1]) % size][(y + c[2]) % size] = nid end
        end
    end

    local passes = size * size * 80
    for _ = 1, passes do try_flip() end

    -- Renumber surviving piece ids to a contiguous 1..count range.
    local remap, count = {}, 0
    for x = 0, size - 1 do
        for y = 0, size - 1 do
            local id = grid[x][y]
            if not remap[id] then count = count + 1; remap[id] = count end
            grid[x][y] = remap[id]
        end
    end
    return grid, count
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

-- Complete graph coloring via dynamic DSATUR (incremental saturation) + backtracking.
-- Returns colors[id] = 1..num_colors (no two adjacent pieces equal) or nil if impossible.
-- Colors are tried lowest-first, so the highest color index is used only when forced --
-- generate() maps that rarest color to the last ore (stone), keeping sand scarce. A static
-- (non-adaptive) trial order also keeps the backtracking near-linear.
function M.color(count, neighbors, num_colors)
    local adj = {}
    local deg = {}
    for id = 1, count do
        local a = {}
        local nb = neighbors[id]
        if nb then
            for o in pairs(nb) do a[#a + 1] = o end
        end
        adj[id] = a
        deg[id] = #a
    end

    local colors = {}   -- id -> color, or nil
    local sat = {}      -- id -> number of distinct colors among its coloured neighbours
    local ncolor = {}   -- id -> { [c] = number of neighbours currently coloured c }
    for id = 1, count do
        sat[id] = 0
        local t = {}
        for c = 1, num_colors do t[c] = 0 end
        ncolor[id] = t
    end

    local uncolored = count
    -- Backtracking node ceiling. With the static DSATUR order the solve is near-linear, so
    -- this is a generous safety net; it fails closed to nil, letting generate() re-pack.
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

-- Pack + color, retrying with fresh randomness until a clean coloring exists. Returns
-- ore_grid[x][y] = ore index in 1..num_ores (0-based x,y in [0,size-1]).
function M.generate(opts)
    local size = opts.size
    local num_ores = opts.num_ores
    local random = opts.random
    local max_attempts = opts.max_attempts or 8

    local oriented = {}
    for _, shape in ipairs(opts.palette) do
        for _, variant in ipairs(M.orientations(shape)) do
            oriented[#oriented + 1] = variant
        end
    end

    for _ = 1, max_attempts do
        local grid, count = M.pack(size, oriented, random)
        local neighbors = M.adjacency(grid, size)
        local colors = M.color(count, neighbors, num_ores)
        if colors then
            -- Map colors -> ores. Lowest-first coloring makes the highest color the rarest,
            -- so pin it to the last ore (stone) to keep sand scarce; permute the remaining
            -- colors among the remaining ores for per-seed variety in which ore dominates.
            local ore_of = {}
            local perm = {}
            for i = 1, num_ores - 1 do perm[i] = i end
            for i = num_ores - 1, 2, -1 do
                local j = random(i)
                perm[i], perm[j] = perm[j], perm[i]
            end
            for c = 1, num_ores - 1 do ore_of[c] = perm[c] end
            ore_of[num_ores] = num_ores

            local ore_grid = {}
            for x = 0, size - 1 do
                ore_grid[x] = {}
                for y = 0, size - 1 do
                    ore_grid[x][y] = ore_of[colors[grid[x][y]]]
                end
            end
            return ore_grid
        end
    end
    error('tetromino_layout: could not ' .. num_ores .. '-color the packing after '
        .. max_attempts .. ' attempts')
end

return M
