-- In-game tests for the pure Voronoi layout algorithm. These run under _DEBUG via /test-runner,
-- and in CI, whenever voronoi_layout.lua is loaded, i.e. on the Voronoi preset. None of them
-- touch the map: they run in game so the layout is checked on Factorio's own Lua.
--
-- The layout takes its randomness the way the map gives it, from a LuaRandomGenerator
-- (math.randomseed does nothing in Factorio). Seeds start at 1000: lower seeds are raised to a
-- minimum, so two small seeds could make the same generator.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Layout = require 'map_gen.maps.danger_ores.modules.voronoi_layout'

local SIZE, SPACING = 16, 4
local G = math.floor(SIZE / SPACING)

local function random(seed)
    return game.create_random_generator(1000 + seed)
end

local function same_grid(a, b, size)
    for x = 0, size - 1 do
        for y = 0, size - 1 do
            if a[x][y] ~= b[x][y] then
                return false
            end
        end
    end
    return true
end

local function cell_count_variance(grid, size, g)
    local counts = {}
    for id = 1, g * g do
        counts[id] = 0
    end
    for x = 0, size - 1 do
        for y = 0, size - 1 do
            counts[grid[x][y]] = counts[grid[x][y]] + 1
        end
    end
    local n, mean = g * g, (size * size) / (g * g)
    local v = 0
    for id = 1, n do
        local d = counts[id] - mean
        v = v + d * d
    end
    return v / n
end

Declare.module(
    {'map_gen', 'voronoi', 'layout'},
    function()
        Declare.test(
            'every cell is assigned a region, the same for the same seed',
            function()
                local grid = Layout.partition(SIZE, SPACING, Layout.place_seeds(SIZE, SPACING, random(1)))
                for x = 0, SIZE - 1 do
                    for y = 0, SIZE - 1 do
                        local id = grid[x][y]
                        Assert.is_true(id ~= nil, 'cell ' .. x .. ',' .. y .. ' has no region')
                        Assert.is_true(id >= 1 and id <= G * G, 'cell ' .. x .. ',' .. y .. ' has region ' .. id .. ', out of range')
                    end
                end

                local g1 = Layout.partition(SIZE, SPACING, Layout.place_seeds(SIZE, SPACING, random(42)))
                local g2 = Layout.partition(SIZE, SPACING, Layout.place_seeds(SIZE, SPACING, random(42)))
                Assert.is_true(same_grid(g1, g2, SIZE), 'the partition differs for the same seed')
            end
        )

        Declare.test(
            'relaxing keeps every cell covered, evens out the cells and is repeatable',
            function()
                local seeds = Layout.place_seeds(SIZE, SPACING, random(7))
                local var_before = cell_count_variance(Layout.partition(SIZE, SPACING, seeds), SIZE, G)
                Layout.relax(SIZE, SPACING, seeds, 3)
                local grid = Layout.partition(SIZE, SPACING, seeds)
                for x = 0, SIZE - 1 do
                    for y = 0, SIZE - 1 do
                        Assert.is_true(grid[x][y] ~= nil, 'cell ' .. x .. ',' .. y .. ' has no region after relaxing')
                    end
                end
                local var_after = cell_count_variance(grid, SIZE, G)
                Assert.is_true(var_after <= var_before,
                    'relaxing raised the cell-size variance (' .. string.format('%.1f -> %.1f', var_before, var_after) .. ')')

                local a = Layout.place_seeds(SIZE, SPACING, random(11))
                Layout.relax(SIZE, SPACING, a, 2)
                local b = Layout.place_seeds(SIZE, SPACING, random(11))
                Layout.relax(SIZE, SPACING, b, 2)
                for i = 0, G - 1 do
                    for j = 0, G - 1 do
                        Assert.is_true(a[i][j].x == b[i][j].x and a[i][j].y == b[i][j].y,
                            'relaxed seed ' .. i .. ',' .. j .. ' differs for the same seed')
                    end
                end
            end
        )

        -- over several seeds, as one can come out clean by chance
        Declare.test(
            'no two touching regions share an ore, across the wrap too',
            function()
                for seed = 1, 10 do
                    local seeds = Layout.place_seeds(SIZE, SPACING, random(seed))
                    Layout.relax(SIZE, SPACING, seeds, 2)
                    local grid = Layout.partition(SIZE, SPACING, seeds)
                    local remap, count = {}, 0
                    for x = 0, SIZE - 1 do
                        for y = 0, SIZE - 1 do
                            local id = grid[x][y]
                            if not remap[id] then
                                count = count + 1
                                remap[id] = count
                            end
                            grid[x][y] = remap[id]
                        end
                    end
                    local colors = Layout.color(count, Layout.adjacency(grid, SIZE), 4)
                    Assert.is_true(colors ~= nil, 'no 4-colouring was found for seed ' .. seed)

                    for x = 0, SIZE - 1 do
                        for y = 0, SIZE - 1 do
                            local id = grid[x][y]
                            for _, other in pairs({grid[(x + 1) % SIZE][y], grid[x][(y + 1) % SIZE]}) do
                                Assert.is_true(other == id or colors[other] ~= colors[id],
                                    'regions ' .. id .. ' and ' .. other .. ' touch at ' .. x .. ',' .. y .. ' and share ore ' .. colors[id] .. ' (seed ' .. seed .. ')')
                            end
                        end
                    end
                end
            end
        )

        Declare.test(
            'a layout is the same for the same seed and differs for another',
            function()
                local function generate(seed)
                    return Layout.generate {size = 16, spacing = 4, relaxation = 2, num_ores = 4, random = random(seed)}
                end
                local a = generate(5)
                Assert.is_true(same_grid(a, generate(5), 16), 'the layout differs for the same seed')
                Assert.is_true(not same_grid(a, generate(6), 16), 'two seeds gave the same layout')
            end
        )

        Declare.test(
            'layouts at the size the map uses always generate, with stone the rarest ore',
            function()
                local PROD = 64
                local totals = {0, 0, 0, 0}
                for seed = 1, 25 do
                    local ok, grid = pcall(Layout.generate, {size = PROD, spacing = SPACING, relaxation = 2, num_ores = 4, random = random(seed)})
                    Assert.is_true(ok, 'seed ' .. seed .. ' failed to generate at size ' .. PROD .. ': ' .. tostring(grid))
                    for x = 0, PROD - 1 do
                        for y = 0, PROD - 1 do
                            totals[grid[x][y]] = totals[grid[x][y]] + 1
                        end
                    end
                end
                Assert.equal(math.min(totals[1], totals[2], totals[3], totals[4]), totals[4],
                    'stone (ore 4) is not the least-used ore, cells per ore: ' .. table.concat(totals, ', '))
            end
        )

        Declare.test(
            'fewer than 4 ores are rejected, as clean borders need 4',
            function()
                local ok = pcall(Layout.generate, {size = 16, spacing = 4, relaxation = 0, num_ores = 3, random = random(1)})
                Assert.is_true(not ok, 'a layout with 3 ores was generated')
            end
        )
    end
)
