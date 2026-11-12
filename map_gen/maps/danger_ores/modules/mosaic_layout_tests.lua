-- In-game tests for the pure Mosaic layout. These run whenever mosaic_layout.lua is loaded,
-- i.e. on the Mosaic preset. None of them touch the map: they run in game so the layout is
-- checked on Factorio's own Lua.
--
-- The layout takes its randomness the way the map gives it, from a LuaRandomGenerator. Seeds
-- start at 1000: lower seeds are raised to a minimum, so two small seeds could make the same
-- generator.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Shapes = require 'map_gen.maps.danger_ores.modules.art_shapes'
local Layout = require 'map_gen.maps.danger_ores.modules.mosaic_layout'
local Figures = require 'map_gen.maps.danger_ores.modules.mosaic_figures'
local MosaicMap = require 'map_gen.maps.danger_ores.layouts.mosaic'

local floor = math.floor

-- the vanilla map's inks
local INKS = MosaicMap.settings.main_ores_mosaic.inks

local function new_layout(seed, overrides)
    local opts = {random = game.create_random_generator(1000 + seed), inks = INKS}
    for k, v in pairs(overrides or {}) do
        opts[k] = v
    end
    return Layout.new(opts)
end

-- the shares of each ore over whole chunks in a ring from r1 to r2 tiles out
local function shares(layout, r1, r2, chunks)
    local counts, total = {}, 0
    for k = 0, chunks - 1 do
        local a = k / chunks * 2 * math.pi
        local r = r1 + (r2 - r1) * (k % 5) / 4
        local cx, cy = floor(r * math.cos(a) / 32), floor(r * math.sin(a) / 32)
        for x = cx * 32, cx * 32 + 31, 2 do
            for y = cy * 32, cy * 32 + 31, 2 do
                local ore = layout.ore_at(x, y)
                counts[ore] = (counts[ore] or 0) + 1
                total = total + 1
            end
        end
    end
    for ore, count in pairs(counts) do
        counts[ore] = count / total
    end
    return counts
end

Declare.module({'map_gen', 'mosaic', 'layout'}, function()
    Declare.test('a layout is the same for the same seed and differs for another', function()
        -- Arrange
        local a, again, other = new_layout(1), new_layout(1), new_layout(2)
        local same, differs = true, 0

        -- Act
        for x = -3000, 3000, 97 do
            for y = -3000, 3000, 89 do
                local ore = a.ore_at(x, y)
                if ore ~= again.ore_at(x, y) then
                    same = false
                end
                if ore ~= other.ore_at(x, y) then
                    differs = differs + 1
                end
            end
        end

        -- Assert
        Assert.is_true(same, 'the same seed laid out a different wall')
        Assert.is_true(differs > 300, 'two seeds laid out the same wall')
    end)

    Declare.test('every symbol paints a solid shape round its centre', function()
        for name, figure in pairs(Figures) do
            -- Arrange
            local piece = Shapes.make_figure(figure, 'iron-ore', 1, 0, 0, 1, 0, 1)
            local painted, total = 0, 0

            -- Act: a grid over the symbol's bounds, in grid units (unit = 1 tile)
            for u = piece.min_x, piece.max_x, 0.25 do
                for v = piece.min_y, piece.max_y, 0.25 do
                    total = total + 1
                    if Shapes.covers(piece, u, v) == 'paint' then
                        painted = painted + 1
                    end
                end
            end

            -- Assert
            Assert.is_true(painted / total > 0.15, name .. ' paints ' .. painted .. ' of ' .. total)
            Assert.is_true(piece.reach < 11, name .. ' reaches ' .. piece.reach .. ' units')
        end
    end)

    Declare.test('panels are framed in the line ore', function()
        -- Arrange
        local layout = new_layout(3)
        local h = layout.settings.row_height
        local checked = 0

        -- Act & Assert: down the left edge and along the top of panels far from spawn
        for row = 3, 8 do
            local r = layout.row_at(row)
            for col = 2, 6 do
                local left, top = floor(r.offset + col * r.width), row * h
                for k = 1, 9 do
                    Assert.equal('coal', layout.ore_at(left, top + k * h / 10), 'left edge of panel ' .. row .. ', ' .. col)
                    Assert.equal('coal', layout.ore_at(floor(left + k * r.width / 10), top), 'top edge of panel ' .. row .. ', ' .. col)
                    checked = checked + 2
                end
            end
        end
        Assert.is_true(checked > 500, 'too few tiles checked: ' .. checked)
    end)

    Declare.test('every background pattern and symbol turns up', function()
        -- Arrange
        local layout = new_layout(4)
        local patterns, symbols = {}, {}

        -- Act
        for row = -12, 12 do
            for col = -12, 12 do
                local panel = layout.panel_at(row, col)
                patterns[panel.pattern] = true
                symbols[panel.symbol] = true
            end
        end

        -- Assert
        for _, pattern in ipairs(Layout.PATTERNS) do
            Assert.is_true(patterns[pattern], 'no panel with ' .. pattern)
        end
        for _, symbol in ipairs(Layout.SYMBOLS) do
            Assert.is_true(symbols[symbol], 'no panel with a ' .. symbol)
        end
    end)

    Declare.test('a stripe pattern draws a line between stripes', function()
        -- Arrange: vertical stripes 100 tiles wide, lines 20 wide
        local panel = {pattern = 'stripes', ca = 1, sa = 0, shift = 0, band = 100}

        -- Act & Assert
        Assert.equal(0, Layout.background(panel, 5, 0, 20), 'on the line at 0')
        Assert.equal(0, Layout.background(panel, 96, 0, 20), 'on the line at 100')
        Assert.equal(1, Layout.background(panel, 50, 0, 20), 'the first stripe')
        Assert.equal(2, Layout.background(panel, 150, 0, 20), 'the second stripe')
        Assert.equal(1, Layout.background(panel, 250, 0, 20), 'the third stripe')
        Assert.equal(3, Layout.background(panel, 350, 0, 20), 'the fourth stripe')
    end)

    Declare.test('neighbouring inks of a panel differ, and coal is a rare one', function()
        -- Arrange
        local inks = INKS
        local next01 = Shapes.hash_stream(12345, 6, 7)
        local coal, total = 0, 0

        -- Act & Assert
        for k = 1, 300 do
            local palette = Layout.draw_palette(inks, (k % 3) / 2, next01)
            Assert.is_true(palette[1] ~= palette[2], 'the first and second ink are the same')
            Assert.is_true(palette[2] ~= palette[3], 'the second and third ink are the same')
            for _, name in ipairs(palette) do
                total = total + 1
                if name == 'coal' then
                    coal = coal + 1
                end
            end
        end
        Assert.is_true(coal / total < 0.2, coal .. ' of ' .. total .. ' inks are coal')
    end)

    Declare.test('iron and copper take turns right round the edge of spawn', function()
        -- Arrange
        local layout = new_layout(5)
        local settings = layout.settings
        local counts, total, runs = {}, 0, 0

        -- Act: just outside spawn's ore-free 64 tiles, all round
        local last
        for k = 0, 359 do
            local a = (k + 0.5) / 360 * 2 * math.pi
            local ore = layout.ore_at(floor(70 * math.cos(a)), floor(70 * math.sin(a)))
            counts[ore] = (counts[ore] or 0) + 1
            total = total + 1
            if ore ~= last then
                runs = runs + 1
                last = ore
            end
        end

        -- Assert: only iron and copper, half each, in the star's ten facets
        local iron, copper = counts['iron-ore'] or 0, counts['copper-ore'] or 0
        local text = ('%d iron, %d copper of %d, %d runs'):format(iron, copper, total, runs)
        Assert.equal(total, iron + copper, text)
        Assert.is_true(math.abs(iron - copper) <= total * 0.1, text)
        Assert.is_true(runs >= 10 and runs <= 11, text)
        local m = settings.medallion
        for k = 0, 35 do
            local a = k / 36 * 2 * math.pi
            Assert.equal('coal', layout.ore_at(floor(m * math.cos(a)), floor(m * math.sin(a))), 'the medallion ring')
        end
    end)

    Declare.test('far out, coal is the lines and there is more copper than iron', function()
        for seed = 6, 8 do
            -- Act
            local s = shares(new_layout(seed), 2000, 6000, 40)

            -- Assert
            local coal, iron, copper = s.coal or 0, s['iron-ore'] or 0, s['copper-ore'] or 0
            local text = ('seed %d: coal %.2f, iron %.2f, copper %.2f'):format(seed, coal, iron, copper)
            Assert.is_true(coal > 0.2 and coal < 0.5, text)
            Assert.is_true(copper > iron and iron > 0.12, text)
        end
    end)

    Declare.test('with no coal, the lightest ink draws the lines and the heaviest two the spawn', function()
        -- Arrange
        local inks = Layout.inks_of {
            {name = 'ore-a', weight = 10},
            {name = 'ore-b', weight = 15},
            {name = 'ore-c', weight = 4},
            {name = 'ore-d', weight = 10}
        }

        -- Act
        local settings = new_layout(9, {inks = inks}).settings

        -- Assert
        Assert.equal('ore-c', settings.line_ink, 'the line ink')
        Assert.equal('ore-b', settings.medallion_core_ink, 'the medallion core')
        Assert.table_equal({'ore-b', 'ore-a', 'ore-d'}, settings.medallion_inks, 'the medallion rays')
        Assert.table_equal({'ore-b', 'ore-a', points = 5}, settings.spawn_symbols[1][7], 'the star facets')
    end)

    Declare.test('coal draws the lines whatever its weight', function()
        -- Arrange
        local inks = Layout.inks_of {{name = 'coal', weight = 20}, {name = 'ore-a', weight = 5}, {name = 'ore-b', weight = 1}}

        -- Act
        local settings = new_layout(10, {inks = inks}).settings

        -- Assert
        Assert.equal('coal', settings.line_ink, 'the line ink')
        Assert.table_equal({'ore-a', 'ore-b'}, settings.medallion_inks, 'the medallion rays')
    end)

    Declare.test('a line ink that is set draws the lines, and is left out of the spawn', function()
        -- Arrange
        local inks = Layout.inks_of {{name = 'coal', weight = 1}, {name = 'ore-a', weight = 5}, {name = 'ore-b', weight = 3}}

        -- Act
        local layout = new_layout(11, {inks = inks, line_ink = 'ore-a'})
        local settings = layout.settings

        -- Assert
        Assert.equal('ore-a', settings.line_ink, 'the line ink')
        Assert.equal('ore-b', settings.medallion_core_ink, 'the medallion core')
        Assert.table_equal({'ore-b', 'coal'}, settings.medallion_inks, 'the medallion rays')
        Assert.equal('ore-a', layout.ore_at(settings.medallion, 0), 'the medallion ring')
    end)
end)
