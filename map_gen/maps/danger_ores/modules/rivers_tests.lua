-- In-game tests for the Rivers overlay. These run under _DEBUG via /test-runner, and are only
-- discovered when rivers.lua is loaded, i.e. when DO/Rivers is the active map. They check the
-- real map, whatever its seed, generating chunks terraforming hasn't unlocked yet.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'

local floor = math.floor
local cos = math.cos
local sin = math.sin
local tau = 2 * math.pi

local water_names = {'water', 'deepwater'}

Declare.module(
    {'map_gen', 'danger ores', 'rivers'},
    function()
        local config = DOC.map_config
        local start_radius = config.rivers_start_radius or 64
        local count = config.rivers_count or 6

        Declare.test(
            'spawn stays dry apart from its pond',
            function()
                local surface = H.generate_around(0, 0, start_radius + 32)
                local wet = H.count_outside_spawn_pond(surface, start_radius - 1, water_names)
                Assert.equal(0, wet, 'water tiles between the spawn pond and ' .. start_radius .. ' from spawn')
            end
        )

        Declare.test(
            'every river springs at spawn and flows out',
            function()
                -- close to spawn, before any branch forks off, a circle crosses each river once
                local r = start_radius * 2
                local surface = H.generate_around(0, 0, r + 32)
                local water = H.tile_set(surface, {{-r - 32, -r - 32}, {r + 32, r + 32}}, water_names)
                local steps = 4096
                local hits = H.band_hits(water, r, 0, steps)
                Assert.equal(count, H.count_runs(hits, steps, true), 'rivers crossing the circle at r = ' .. r)
            end
        )

        Declare.test(
            'deep water is always banked by shallower water',
            function()
                -- grow until there is a fair amount of deep water to look at
                local function deep(surface, half)
                    return surface.count_tiles_filtered {area = {{-half, -half}, {half, half}}, name = 'deepwater', limit = 500}
                end
                local surface, half = H.generate_until(0, 0, {128, 192, 256}, function(s, h)
                    return deep(s, h) >= 500
                end)
                Assert.is_true(deep(surface, half) > 0, 'no deep water within ' .. half .. ' of spawn')
                local area = {{-half, -half}, {half, half}}
                local wet = H.tile_set(surface, area, water_names)
                local bad, first = 0, nil
                for _, tile in pairs(surface.find_tiles_filtered {area = {{-half + 1, -half + 1}, {half - 1, half - 1}}, name = 'deepwater'}) do
                    local p = tile.position
                    for _, d in pairs {{1, 0}, {-1, 0}, {0, 1}, {0, -1}} do
                        if not wet[H.key(p.x + d[1], p.y + d[2])] then
                            bad = bad + 1
                            first = first or p
                        end
                    end
                end
                Assert.equal(0, bad, 'deep water tiles next to land' .. (first and (', e.g. at ' .. first.x .. ',' .. first.y) or ''))
            end
        )

        Declare.test(
            'a stream near its spring can be crossed by an express underground belt',
            function()
                local reach = start_radius + 48
                local surface = H.generate_around(0, 0, reach + 16)
                local water = H.tile_set(surface, {{-reach - 16, -reach - 16}, {reach + 16, reach + 16}}, water_names)

                -- the narrowest axis crossing anywhere just downstream of the springs
                local best
                for r = start_radius + 2, reach, 2 do
                    local steps = floor(tau * r)
                    for i = 0, steps - 1 do
                        local a = i / steps * tau
                        local x, y = floor(r * cos(a) + 0.5), floor(r * sin(a) + 0.5)
                        if water[H.key(x, y)] then
                            for _, axis in pairs {{1, 0}, {0, 1}} do
                                local c = H.crossing(water, x, y, axis[1], axis[2])
                                if not best or c.width < best.width then
                                    best = c
                                end
                            end
                        end
                    end
                end
                Assert.is_true(best ~= nil, 'no river found near the springs')

                local name = 'express-underground-belt'
                local gap = H.underground_gap(name)
                Assert.is_true(best.width <= gap, 'narrowest crossing near the springs is ' .. best.width .. ' tiles, an express underground spans ' .. gap)

                local a, b = H.build_underground_pair(surface, name, best.from, best.to, best.dx, best.dy)
                local paired = H.connected(a, b)
                H.destroy(a, b)
                Assert.is_true(paired, 'express underground belts on either side of the stream at ' .. best.from.x .. ',' .. best.from.y .. ' did not pair')
            end
        )

        Declare.test(
            'no ore is placed under water',
            function()
                local half = 192
                local surface = H.generate_around(0, 0, half)
                local area = {{-half, -half}, {half, half}}
                local water = H.tile_set(surface, area, water_names)
                local wet = 0
                for _, e in pairs(surface.find_entities_filtered {area = area, type = 'resource'}) do
                    local p = e.position
                    if water[H.key(floor(p.x), floor(p.y))] then
                        wet = wet + 1
                    end
                end
                Assert.equal(0, wet, 'resource entities on water tiles')
            end
        )
    end
)
