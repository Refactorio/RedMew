-- In-game tests for the pure Tetrominoes layout algorithm. These run whenever
-- tetromino_layout.lua is loaded, i.e. on the Tetrominoes preset. None of them touch the map:
-- they run in game so the layout is checked on Factorio's own Lua.
--
-- The layout takes its randomness the way the map gives it, from a LuaRandomGenerator
-- (math.randomseed does nothing in Factorio). Seeds start at 1000: lower seeds are raised to a
-- minimum, so two small seeds could make the same generator.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Layout = require 'map_gen.maps.danger_ores.modules.tetromino_layout'
local palette = require 'map_gen.maps.danger_ores.config.tetromino_shapes'

local PSIZE = 12
local PROD = 32 -- the size the map uses

local function random(seed)
    return game.create_random_generator(1000 + seed)
end

-- the flat oriented palette packing uses
local function oriented_palette()
    local oriented = {}
    for _, s in ipairs(palette) do
        for _, v in ipairs(Layout.orientations(s)) do
            oriented[#oriented + 1] = v
        end
    end
    return oriented
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

-- Asserts no two touching pieces share an ore, across the wrap too, and returns the ores used.
local function assert_clean_borders(grid, colors, size)
    local seen = {}
    for x = 0, size - 1 do
        for y = 0, size - 1 do
            local id = grid[x][y]
            seen[colors[id]] = true
            for _, other in pairs({grid[(x + 1) % size][y], grid[x][(y + 1) % size]}) do
                Assert.is_true(other == id or colors[other] ~= colors[id],
                    'pieces ' .. id .. ' and ' .. other .. ' touch at ' .. x .. ',' .. y .. ' at size ' .. size .. ' and share ore ' .. colors[id])
            end
        end
    end
    return seen
end

Declare.module(
    {'map_gen', 'tetrominoes', 'layout'},
    function()
        Declare.test(
            'pieces have their unique orientations',
            function()
                -- Act
                local square = Layout.orientations({{0, 0}, {1, 0}, {0, 1}, {1, 1}})
                local l = Layout.orientations({{0, 0}, {0, 1}, {0, 2}, {1, 2}})

                -- Assert: a square (O) collapses to 1; a chiral L expands to 8
                Assert.equal(1, #square, 'orientations of the square (O)')
                Assert.equal(8, #l, 'orientations of the L')
            end
        )

        Declare.test(
            'packing leaves no cell empty',
            function()
                -- Act
                local grid = Layout.pack(PSIZE, oriented_palette(), random(1))

                -- Assert
                for x = 0, PSIZE - 1 do
                    for y = 0, PSIZE - 1 do
                        Assert.is_true(grid[x][y] ~= 0, 'cell ' .. x .. ',' .. y .. ' is empty after packing')
                    end
                end
            end
        )

        Declare.test(
            'every packed piece has 4 cells, at test and production sizes',
            function()
                -- Act
                local oriented = oriented_palette()
                local packed = {}
                for _, size in ipairs({12, 32}) do
                    packed[size] = Layout.pack(size, oriented, random(size))
                end

                -- Assert
                for size, grid in pairs(packed) do
                    local cells = {}
                    for x = 0, size - 1 do
                        for y = 0, size - 1 do
                            cells[grid[x][y]] = (cells[grid[x][y]] or 0) + 1
                        end
                    end
                    for id, n in pairs(cells) do
                        Assert.equal(4, n, 'cells in piece ' .. id .. ' at size ' .. size)
                    end
                end
            end
        )

        Declare.test(
            'packing is the same for the same seed',
            function()
                -- Act
                local oriented = oriented_palette()
                local a = Layout.pack(PSIZE, oriented, random(99))
                local b = Layout.pack(PSIZE, oriented, random(99))

                -- Assert
                Assert.is_true(same_grid(a, b, PSIZE), 'packing differs for the same seed')
            end
        )

        -- over several seeds, as one can come out clean by chance
        Declare.test(
            'no two touching pieces share an ore, across the wrap too',
            function()
                local oriented = oriented_palette()
                for seed = 1, 10 do
                    -- Arrange
                    local grid, count = Layout.pack(PSIZE, oriented, random(seed))

                    -- Act
                    local colors = Layout.color(count, Layout.adjacency(grid, PSIZE), 4)

                    -- Assert
                    Assert.is_true(colors ~= nil, 'no 4-colouring was found for seed ' .. seed)
                    assert_clean_borders(grid, colors, PSIZE)
                end
            end
        )

        Declare.test(
            'a layout is the same for the same seed and differs for another',
            function()
                -- Act
                local function generate(seed)
                    return Layout.generate {size = 16, palette = palette, num_ores = 4, random = random(seed)}
                end
                local a, again = generate(7), generate(7)
                local one, two = generate(1), generate(2)

                -- Assert
                Assert.is_true(same_grid(a, again, 16), 'the layout differs for the same seed')
                Assert.is_true(not same_grid(one, two, 16), 'two seeds gave the same layout')
            end
        )

        -- the real map uses a 32-chunk super-tile
        Declare.test(
            'layouts at the size the map uses always generate',
            function()
                -- Act
                local results = {}
                for seed = 1, 25 do
                    results[seed] = {pcall(Layout.generate, {size = PROD, palette = palette, num_ores = 4, random = random(seed)})}
                end

                -- Assert
                for seed, result in ipairs(results) do
                    Assert.is_true(result[1], 'seed ' .. seed .. ' failed to generate at size ' .. PROD .. ': ' .. tostring(result[2]))
                end
            end
        )

        Declare.test(
            'at the size the map uses, no two touching pieces share an ore and the main ores are all used',
            function()
                -- Arrange
                local grid, count = Layout.pack(PROD, oriented_palette(), random(3))

                -- Act
                local colors = Layout.color(count, Layout.adjacency(grid, PROD), 4)

                -- Assert
                Assert.is_true(colors ~= nil, 'no 4-colouring was found at size ' .. PROD)
                local seen = assert_clean_borders(grid, colors, PROD)
                -- stone (the 4th colour) is meant to be rare and may be absent on some seeds, so
                -- at least the 3 main ores, and never more than 4
                local ores = 0
                for _ in pairs(seen) do
                    ores = ores + 1
                end
                Assert.is_true(ores >= 3 and ores <= 4, 'the layout uses ' .. ores .. ' ores at size ' .. PROD)
            end
        )

        Declare.test(
            'fewer than 4 ores are rejected, as clean borders need 4',
            function()
                -- Act
                local ok = pcall(Layout.generate, {size = 16, palette = palette, num_ores = 3, random = random(1)})

                -- Assert
                Assert.is_true(not ok, 'a layout with 3 ores was generated')
            end
        )
    end
)
