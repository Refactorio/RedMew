-- In-game tests for the Fault Lines overlay. These run under _DEBUG via /test-runner, and are
-- only discovered when fault_lines.lua is loaded, i.e. when DO/Fault-Lines is the active map.
-- They check the real map, whatever its seed, generating chunks terraforming hasn't unlocked yet.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'

local belts = {'underground-belt', 'fast-underground-belt', 'express-underground-belt'}

local default_tiers = {
    {radius = 512, gap = 4},
    {radius = 1280, gap = 6},
    {gap = 8}
}

-- The spawn plate's crack can come within ~61 tiles of spawn (measured over many seeds).
local SPAWN_CLEAR = 56
local WINDOW = 64

Declare.module(
    {'map_gen', 'danger ores', 'fault lines'},
    function()
        local tiers = DOC.map_config.fault_lines_tiers or default_tiers

        Declare.test(
            'spawn is clear of cracks',
            function()
                -- Act
                local surface = H.generate_around(0, 0, SPAWN_CLEAR + 32)

                -- Assert
                local cracks = surface.count_tiles_filtered {position = {0, 0}, radius = SPAWN_CLEAR, name = 'out-of-map'}
                Assert.equal(0, cracks, 'crack tiles within ' .. SPAWN_CLEAR .. ' of spawn')
            end
        )

        -- one window per tier, between its inner and outer radius, each in its own direction
        local directions = {{1, 0}, {0, 1}, {-1, 0}}
        for i, tier in pairs(tiers) do
            local inner = i > 1 and tiers[i - 1].radius or 0
            local r = tier.radius and (inner + tier.radius) / 2 or inner * 1.5
            local d = directions[(i - 1) % #directions + 1]
            local cx, cy = d[1] * r, d[2] * r

            Declare.test(
                'cracks ' .. r .. ' tiles out are ' .. tier.gap .. ' wide and an underground belt crosses them',
                function()
                    -- Arrange: the shortest underground belt that spans the tier's gap
                    local belt
                    for _, name in pairs(belts) do
                        if H.underground_gap(name) >= tier.gap then
                            belt = name
                            break
                        end
                    end
                    Assert.is_true(belt ~= nil, 'no underground belt spans ' .. tier.gap .. ' tiles')

                    -- Act
                    local surface = H.generate_around(cx, cy, WINDOW + 16)
                    local cracks = H.tile_set(surface, {{cx - WINDOW - 16, cy - WINDOW - 16}, {cx + WINDOW + 16, cy + WINDOW + 16}}, 'out-of-map')

                    -- Assert: the width of every crack tile along its better axis; where cracks meet
                    -- the width runs into the other crack, so judge the crack by its usual width
                    local widths = {}
                    local example = {}
                    for _, tile in pairs(surface.find_tiles_filtered {area = {{cx - WINDOW, cy - WINDOW}, {cx + WINDOW, cy + WINDOW}}, name = 'out-of-map'}) do
                        local p = tile.position
                        local along_x = H.crossing(cracks, p.x, p.y, 1, 0)
                        local along_y = H.crossing(cracks, p.x, p.y, 0, 1)
                        local c = along_x.width <= along_y.width and along_x or along_y
                        widths[c.width] = (widths[c.width] or 0) + 1
                        example[c.width] = example[c.width] or c
                    end
                    local usual, most = nil, 0
                    for w, n in pairs(widths) do
                        if n > most then
                            usual, most = w, n
                        end
                    end
                    Assert.is_true(usual ~= nil, 'no cracks found around ' .. cx .. ',' .. cy)
                    Assert.is_true(usual <= tier.gap, 'cracks around ' .. cx .. ',' .. cy .. ' are usually ' .. usual .. ' tiles wide, more than ' .. tier.gap)

                    local c = example[usual]
                    local a, b = H.build_underground_pair(surface, belt, c.from, c.to, c.dx, c.dy)
                    local paired = H.connected(a, b)
                    H.destroy(a, b)
                    Assert.is_true(paired, belt .. 's either side of the crack at ' .. c.from.x .. ',' .. c.from.y .. ' did not pair')
                end
            )
        end

        Declare.test(
            'every plate around spawn can be walked to',
            function()
                -- Arrange: the plates within radius of spawn, with room round them for walks that
                -- go round the end of a crack
                local half, radius = 192, 128
                local surface = H.generate_around(0, 0, half)
                local cracks = H.tile_set(surface, {{-half, -half}, {half + 1, half + 1}}, 'out-of-map')

                -- Act
                local reached = H.walk_from_spawn(cracks, half)

                -- Assert: single tiles boxed in where cracks meet are fine; a plate is thousands of tiles
                local biggest = 0
                for _, size in pairs(H.unreached_groups(cracks, reached, radius)) do
                    if size > biggest then
                        biggest = size
                    end
                end
                Assert.is_true(biggest < 16, 'a ' .. biggest .. ' tile area within ' .. radius .. ' of spawn cannot be walked to')
            end
        )
    end
)
