-- In-game tests for the pure shape drawing of the maps painted in ore. These run whenever
-- art_shapes.lua is loaded, i.e. on the Mosaic preset. None of them touch the map: they run in
-- game so the shapes are checked on Factorio's own Lua.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Shapes = require 'map_gen.maps.danger_ores.modules.art_shapes'

local floor = math.floor

-- A face: a disc of radius 5 with an eye (line work) and a highlight in the eye (paint again).
local FACE = {
    {'disc', 5, 0, 0},
    {'disc', 1.5, 2, -1, detail = true},
    {'disc', 0.5, 2, -1}
}

-- An arrow pointing right and up, so flipping it shows.
local ARROW = {
    {'line', 1, {-4, 2}, {2, -1}},
    {'poly', {1, -3}, {4, -2}, {2, 1}}
}

Declare.module({'map_gen', 'art shapes'}, function()
    Declare.test('a polygon holds what is inside it, whichever way round it is drawn', function()
        -- Arrange
        local square = {0, 0, 10, 0, 10, 10, 0, 10}
        local backwards = {0, 10, 10, 10, 10, 0, 0, 0}

        -- Act & Assert
        Assert.is_true(Shapes.in_poly(square, 5, 5))
        Assert.is_true(Shapes.in_poly(backwards, 5, 5))
        Assert.is_true(not Shapes.in_poly(square, 15, 5))
        Assert.is_true(not Shapes.in_poly(square, 5, -1))
    end)

    Declare.test('shapes later in a figure paint over earlier ones', function()
        -- Arrange: 10 tiles a unit, at the centre of the map
        local face = Shapes.make_figure(FACE, 'iron-ore', 1, 0, 0, 10, 0, 1)

        -- Act & Assert
        Assert.equal('paint', Shapes.covers(face, -30, 10), 'the face')
        Assert.equal('detail', Shapes.covers(face, 32, -10), 'the eye')
        Assert.equal('paint', Shapes.covers(face, 20, -10), 'the highlight in the eye')
        Assert.equal(false, Shapes.covers(face, 60, 0), 'beside the face')
    end)

    Declare.test('a figure is placed, scaled and turned on the map', function()
        -- Arrange: the face at (100, 50), 10 tiles a unit, turned a quarter right
        local face = Shapes.make_figure(FACE, 'iron-ore', 1, 100, 50, 10, math.pi / 2, 1)

        -- Act & Assert: a unit above the highlight, (2, -2) in the face, is in the eye; turned a
        -- quarter right it lies 2 units right and 2 down of the centre
        Assert.equal('detail', Shapes.covers(face, 120, 70))
        Assert.equal('paint', Shapes.covers(face, 80, 30))
        Assert.equal(false, Shapes.covers(face, 100, -5))
        -- the corner of the face's bounds, 5 units out each way
        Assert.is_true(math.abs(face.reach - 50 * math.sqrt(2)) < 1e-6, 'reach ' .. face.reach)
    end)

    Declare.test('a mirrored figure is the same figure flipped left to right', function()
        -- Arrange
        local arrow = Shapes.make_figure(ARROW, 'iron-ore', 1, 0, 0, 1, 0, 1)
        local mirrored = Shapes.make_figure(ARROW, 'iron-ore', 1, 0, 0, 1, 0, -1)
        local differs = false

        -- Act & Assert: off the round numbers the shapes are drawn on, so no point is on an edge
        for u = -5.07, 5, 0.25 do
            for v = -4.03, 4, 0.25 do
                Assert.equal(Shapes.covers(arrow, u, v), Shapes.covers(mirrored, -u, v))
                if Shapes.covers(arrow, u, v) ~= Shapes.covers(mirrored, u, v) then
                    differs = true
                end
            end
        end
        Assert.is_true(differs, 'the mirrored arrow is the same as the arrow')
    end)

    Declare.test("a figure's paint distance is in tiles, negative inside, line work left out", function()
        -- Arrange
        local face = Shapes.make_figure(FACE, 'iron-ore', 1, 0, 0, 10, 0, 1)

        -- Act & Assert
        Assert.is_true(math.abs(Shapes.paint_distance(face, 80, 0) - 30) < 1e-6, 'outside')
        Assert.is_true(math.abs(Shapes.paint_distance(face, 0, 0) + 50) < 1e-6, 'at the centre')
        Assert.is_true(Shapes.paint_distance(face, 20, -10) < 0, 'in the eye, inside the face')
    end)

    Declare.test('a hash stream is the same for the same seed and place', function()
        -- Arrange
        local a, again = Shapes.hash_stream(42, 3, -7), Shapes.hash_stream(42, 3, -7)
        local other = Shapes.hash_stream(43, 3, -7)
        local differs = false

        -- Act & Assert
        for _ = 1, 20 do
            local value = a()
            Assert.equal(value, again())
            Assert.is_true(value >= 0 and value < 1, 'out of [0, 1): ' .. value)
            if value ~= other() then
                differs = true
            end
        end
        Assert.is_true(differs, 'two seeds gave the same stream')
    end)

    Declare.test('neighbouring places draw independently', function()
        -- Arrange
        local bins, distinct = {}, 0

        -- Act: the step from each place's first draw to its neighbour's
        for a = -10, 10 do
            for b = -10, 10 do
                local step = (Shapes.hash_stream(99, a + 1, b)() - Shapes.hash_stream(99, a, b)()) % 1
                local bin = floor(step * 50)
                if not bins[bin] then
                    bins[bin] = true
                    distinct = distinct + 1
                end
            end
        end

        -- Assert: a hash linear in the place shifts every draw by the same step from its
        -- neighbour's, which lines up whatever is drawn from it in rows
        Assert.is_true(distinct >= 40, distinct .. ' of 50 bins')
    end)

    Declare.test('inks are picked by their weights, blending from near spawn to far out', function()
        -- Arrange
        local inks = {{'iron-ore', 3, 1}, {'copper-ore', 1, 3}}
        local near, far = {}, {}

        -- Act: evenly spread draws at either end of the blend
        for k = 0, 999 do
            local t = (k + 0.5) / 1000
            local a, b = Shapes.pick_ink(inks, 0, t), Shapes.pick_ink(inks, 1, t)
            near[a] = (near[a] or 0) + 1
            far[b] = (far[b] or 0) + 1
        end

        -- Assert
        Assert.equal(750, near['iron-ore'])
        Assert.equal(750, far['copper-ore'])
    end)
end)
