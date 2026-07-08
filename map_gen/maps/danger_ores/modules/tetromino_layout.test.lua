-- Standalone unit tests for the pure Tetrominoes layout algorithm.
-- Run from the repo root:  lua map_gen/maps/danger_ores/modules/tetromino_layout.test.lua
package.path = './?.lua;' .. package.path

local Layout = require 'map_gen.maps.danger_ores.modules.tetromino_layout'

local failures = 0
local function check(cond, msg)
    if cond then
        print('ok:   ' .. msg)
    else
        failures = failures + 1
        print('FAIL: ' .. msg)
    end
end

-- orientations: a square (O) collapses to 1; a chiral L expands to 8.
local o_square = Layout.orientations({ {0, 0}, {1, 0}, {0, 1}, {1, 1} })
check(#o_square == 1, 'square (O) has 1 unique orientation, got ' .. #o_square)

local l_shape = Layout.orientations({ {0, 0}, {0, 1}, {0, 2}, {1, 2} })
check(#l_shape == 8, 'L has 8 unique orientations, got ' .. #l_shape)

-- Build the flat oriented palette used by packing/generate.
local palette = require 'map_gen.maps.danger_ores.config.tetromino_shapes'
local function oriented_palette()
    local oriented = {}
    for _, s in ipairs(palette) do
        for _, v in ipairs(Layout.orientations(s)) do
            oriented[#oriented + 1] = v
        end
    end
    return oriented
end
local function rand(n) return math.random(n) end

-- pack: fully covers the torus (no empty cells) and is deterministic per seed.
math.randomseed(1)
local oriented = oriented_palette()
local PSIZE = 12
local grid = Layout.pack(PSIZE, oriented, rand)
local empty = 0
for x = 0, PSIZE - 1 do
    for y = 0, PSIZE - 1 do
        if grid[x][y] == 0 then empty = empty + 1 end
    end
end
check(empty == 0, 'pack leaves no empty cells, empty=' .. empty)

-- every piece is a valid tetromino: exactly 4 cells, at test and production sizes
local function all_tetrominoes(g, sz)
    local sizes = {}
    for x = 0, sz - 1 do
        for y = 0, sz - 1 do
            sizes[g[x][y]] = (sizes[g[x][y]] or 0) + 1
        end
    end
    local bad = 0
    for _, s in pairs(sizes) do if s ~= 4 then bad = bad + 1 end end
    return bad
end
for _, sz in ipairs({ 12, 32 }) do
    math.randomseed(sz)
    local pg = Layout.pack(sz, oriented, rand)
    check(all_tetrominoes(pg, sz) == 0, 'every piece is a 4-cell tetromino at size ' .. sz
        .. ', non-tetromino=' .. all_tetrominoes(pg, sz))
end

math.randomseed(99)
local g1 = Layout.pack(PSIZE, oriented, rand)
math.randomseed(99)
local g2 = Layout.pack(PSIZE, oriented, rand)
local identical = true
for x = 0, PSIZE - 1 do
    for y = 0, PSIZE - 1 do
        if g1[x][y] ~= g2[x][y] then identical = false end
    end
end
check(identical, 'pack is deterministic for a fixed random sequence')

-- clean borders: adjacent cells from DIFFERENT pieces must get DIFFERENT ores
-- (including across the torus wrap).
math.randomseed(42)
local cg, ccount = Layout.pack(PSIZE, oriented, rand)
local nb = Layout.adjacency(cg, PSIZE)
local colors = Layout.color(ccount, nb, 4)
check(colors ~= nil, 'color returns a valid 4-coloring')
if colors then
    local bad = 0
    for x = 0, PSIZE - 1 do
        for y = 0, PSIZE - 1 do
            local id = cg[x][y]
            local right = cg[(x + 1) % PSIZE][y]
            local down = cg[x][(y + 1) % PSIZE]
            if right ~= id and colors[right] == colors[id] then bad = bad + 1 end
            if down ~= id and colors[down] == colors[id] then bad = bad + 1 end
        end
    end
    check(bad == 0, 'no two touching pieces share an ore (incl. wrap), violations=' .. bad)
end

-- generate: deterministic per seed.
math.randomseed(7)
local a = Layout.generate { size = 16, palette = palette, num_ores = 4, random = rand }
math.randomseed(7)
local b = Layout.generate { size = 16, palette = palette, num_ores = 4, random = rand }
local same = true
for x = 0, 15 do for y = 0, 15 do if a[x][y] ~= b[x][y] then same = false end end end
check(same, 'generate is deterministic for a fixed seed')

-- generate: different seeds produce different layouts.
math.randomseed(1)
local c1 = Layout.generate { size = 16, palette = palette, num_ores = 4, random = rand }
math.randomseed(2)
local c2 = Layout.generate { size = 16, palette = palette, num_ores = 4, random = rand }
local diff = false
for x = 0, 15 do for y = 0, 15 do if c1[x][y] ~= c2[x][y] then diff = true end end end
check(diff, 'different seeds produce different layouts')

-- Production-size guard (the real map uses a 32-chunk super-tile).
do
    local PROD = 32
    local ok_count = 0
    for seed = 1, 25 do
        math.randomseed(seed)
        local ok = pcall(function()
            return Layout.generate { size = PROD, palette = palette, num_ores = 4, random = rand }
        end)
        if ok then ok_count = ok_count + 1 end
    end
    check(ok_count == 25, 'generate succeeds for all 25 seeds at production size 32, got ' .. ok_count)

    -- clean borders + all 4 ores at size 32, tested at pack+color level
    math.randomseed(3)
    local g32, c32 = Layout.pack(PROD, oriented, rand)
    local nb32 = Layout.adjacency(g32, PROD)
    local col32 = Layout.color(c32, nb32, 4)
    check(col32 ~= nil, 'color succeeds at size 32')
    if col32 then
        local bad, palette_seen = 0, {}
        for x = 0, PROD - 1 do
            for y = 0, PROD - 1 do
                local id = g32[x][y]
                palette_seen[col32[id]] = true
                local right = g32[(x + 1) % PROD][y]
                local down = g32[x][(y + 1) % PROD]
                if right ~= id and col32[right] == col32[id] then bad = bad + 1 end
                if down ~= id and col32[down] == col32[id] then bad = bad + 1 end
            end
        end
        check(bad == 0, 'no two touching pieces share an ore at size 32, violations=' .. bad)
        -- stone (the 4th colour) is intentionally rare and may be absent on some seeds,
        -- so the coloring uses at least 3 colours (all main ores) and never more than 4.
        local ore_types = 0
        for _ in pairs(palette_seen) do ore_types = ore_types + 1 end
        check(ore_types >= 3 and ore_types <= 4, 'uses 3-4 ores at size 32, got ' .. ore_types)
    end
end

-- enforcement: fewer than 4 ores must be rejected (clean borders need 4 colours)
local ok_low = pcall(function()
    return Layout.generate { size = 16, palette = palette, num_ores = 3, random = rand }
end)
check(not ok_low, 'generate rejects fewer than 4 ores')

if failures == 0 then
    print('\nALL PASSED')
else
    print('\n' .. failures .. ' FAILURE(S)')
    os.exit(1)
end
