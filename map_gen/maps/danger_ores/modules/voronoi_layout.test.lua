-- Standalone unit tests for the pure Voronoi layout algorithm.
-- Run from the repo root:  lua map_gen/maps/danger_ores/modules/voronoi_layout.test.lua
package.path = './?.lua;' .. package.path

local Layout = require 'map_gen.maps.danger_ores.modules.voronoi_layout'

local failures = 0
local function check(cond, msg)
    if cond then
        print('ok:   ' .. msg)
    else
        failures = failures + 1
        print('FAIL: ' .. msg)
    end
end

local function rand(n) return math.random(n) end

-- partition: every cell is assigned a valid region id, and it is deterministic per seed.
math.randomseed(1)
local SIZE, SPACING = 16, 4
local seeds = Layout.place_seeds(SIZE, SPACING, rand)
local grid = Layout.partition(SIZE, SPACING, seeds)
local g = math.floor(SIZE / SPACING)
local unassigned, out_of_range = 0, 0
for x = 0, SIZE - 1 do
    for y = 0, SIZE - 1 do
        local id = grid[x][y]
        if id == nil then unassigned = unassigned + 1
        elseif id < 1 or id > g * g then out_of_range = out_of_range + 1 end
    end
end
check(unassigned == 0, 'every cell assigned a region, unassigned=' .. unassigned)
check(out_of_range == 0, 'all region ids in range, out_of_range=' .. out_of_range)

math.randomseed(42)
local s1 = Layout.place_seeds(SIZE, SPACING, rand)
local g1 = Layout.partition(SIZE, SPACING, s1)
math.randomseed(42)
local s2 = Layout.place_seeds(SIZE, SPACING, rand)
local g2 = Layout.partition(SIZE, SPACING, s2)
local identical = true
for x = 0, SIZE - 1 do for y = 0, SIZE - 1 do if g1[x][y] ~= g2[x][y] then identical = false end end end
check(identical, 'partition is deterministic for a fixed random sequence')

-- relax: keeps full coverage, is deterministic, and evens out cell sizes (lower variance).
local function cell_count_variance(grd, sz, gg)
    local counts = {}
    for id = 1, gg * gg do counts[id] = 0 end
    for x = 0, sz - 1 do for y = 0, sz - 1 do counts[grd[x][y]] = counts[grd[x][y]] + 1 end end
    local n, mean = gg * gg, (sz * sz) / (gg * gg)
    local v = 0
    for id = 1, n do local d = counts[id] - mean; v = v + d * d end
    return v / n
end

math.randomseed(7)
local rseeds = Layout.place_seeds(SIZE, SPACING, rand)
local var_before = cell_count_variance(Layout.partition(SIZE, SPACING, rseeds), SIZE, g)
Layout.relax(SIZE, SPACING, rseeds, 3)
local rgrid = Layout.partition(SIZE, SPACING, rseeds)
local var_after = cell_count_variance(rgrid, SIZE, g)

local runassigned = 0
for x = 0, SIZE - 1 do for y = 0, SIZE - 1 do if rgrid[x][y] == nil then runassigned = runassigned + 1 end end end
check(runassigned == 0, 'relaxed partition still covers every cell, unassigned=' .. runassigned)
check(var_after <= var_before, 'relaxation does not increase cell-size variance ('
    .. string.format('%.1f -> %.1f', var_before, var_after) .. ')')

math.randomseed(11)
local ra = Layout.place_seeds(SIZE, SPACING, rand); Layout.relax(SIZE, SPACING, ra, 2)
math.randomseed(11)
local rb = Layout.place_seeds(SIZE, SPACING, rand); Layout.relax(SIZE, SPACING, rb, 2)
local rdet = true
for i = 0, g - 1 do for j = 0, g - 1 do
    if ra[i][j].x ~= rb[i][j].x or ra[i][j].y ~= rb[i][j].y then rdet = false end
end end
check(rdet, 'relaxation is deterministic')

-- clean borders: adjacent cells from DIFFERENT regions must get DIFFERENT ores (incl. wrap).
math.randomseed(3)
local cseeds = Layout.place_seeds(SIZE, SPACING, rand)
Layout.relax(SIZE, SPACING, cseeds, 2)
local cgrid = Layout.partition(SIZE, SPACING, cseeds)
local remap, count = {}, 0
for x = 0, SIZE - 1 do for y = 0, SIZE - 1 do
    local id = cgrid[x][y]
    if not remap[id] then count = count + 1; remap[id] = count end
    cgrid[x][y] = remap[id]
end end
local nb = Layout.adjacency(cgrid, SIZE)
local colors = Layout.color(count, nb, 4)
check(colors ~= nil, 'color returns a valid 4-colouring')
if colors then
    local bad = 0
    for x = 0, SIZE - 1 do for y = 0, SIZE - 1 do
        local id = cgrid[x][y]
        local right, down = cgrid[(x + 1) % SIZE][y], cgrid[x][(y + 1) % SIZE]
        if right ~= id and colors[right] == colors[id] then bad = bad + 1 end
        if down ~= id and colors[down] == colors[id] then bad = bad + 1 end
    end end
    check(bad == 0, 'no two touching regions share an ore (incl. wrap), violations=' .. bad)
end

-- generate: deterministic per seed; different seeds differ.
math.randomseed(5)
local a = Layout.generate { size = 16, spacing = 4, relaxation = 2, num_ores = 4, random = rand }
math.randomseed(5)
local b = Layout.generate { size = 16, spacing = 4, relaxation = 2, num_ores = 4, random = rand }
local same = true
for x = 0, 15 do for y = 0, 15 do if a[x][y] ~= b[x][y] then same = false end end end
check(same, 'generate is deterministic for a fixed seed')
math.randomseed(6)
local c2 = Layout.generate { size = 16, spacing = 4, relaxation = 2, num_ores = 4, random = rand }
local diff = false
for x = 0, 15 do for y = 0, 15 do if a[x][y] ~= c2[x][y] then diff = true end end end
check(diff, 'different seeds produce different layouts')

-- production size guard + stone scarcity.
do
    local PROD, SP = 64, 4
    local ok_count = 0
    local totals = { 0, 0, 0, 0 }
    for seed = 1, 25 do
        math.randomseed(seed)
        local ok, grd = pcall(function()
            return Layout.generate { size = PROD, spacing = SP, relaxation = 2, num_ores = 4, random = rand }
        end)
        if ok then
            ok_count = ok_count + 1
            for x = 0, PROD - 1 do for y = 0, PROD - 1 do totals[grd[x][y]] = totals[grd[x][y]] + 1 end end
        end
    end
    check(ok_count == 25, 'generate succeeds for all 25 seeds at production size 64, got ' .. ok_count)
    local min_ore = math.min(totals[1], totals[2], totals[3], totals[4])
    check(totals[4] == min_ore, 'stone (ore 4) is the least-used ore')
end

if failures == 0 then
    print('\nALL PASSED')
else
    print('\n' .. failures .. ' FAILURE(S)')
    os.exit(1)
end
