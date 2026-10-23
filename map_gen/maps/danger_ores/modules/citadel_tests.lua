-- In-game tests for the Citadel overlay. These are only discovered when citadel.lua is loaded,
-- i.e. when DO/Citadel is the active map. They check the real map, whatever its seed,
-- generating chunks terraforming hasn't unlocked yet.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'

local abs = math.abs
local floor = math.floor
local max = math.max
local cos = math.cos
local sin = math.sin
local tau = 2 * math.pi

local STEPS = 2048

Declare.module(
    {'map_gen', 'danger ores', 'citadel'},
    function()
        local config = DOC.map_config
        local first_ring = config.citadel_first_ring or 144
        local thickness = config.citadel_wall_thickness or 16
        local gate_spacing = config.citadel_gate_spacing or 900
        local wobble = config.citadel_wobble_amplitude or 12
        local reach = thickness / 2 + wobble -- how far a wall tile can sit from its ring's radius
        -- enough round the first ring for a walk from spawn to get past it
        local half = first_ring + reach + 8

        local function first_ring_walls()
            local surface = H.generate_around(0, 0, half)
            return surface, H.tile_set(surface, {{-half, -half}, {half, half}}, 'out-of-map')
        end

        Declare.test(
            'spawn is clear inside the first ring',
            function()
                -- Act
                local surface = H.generate_around(0, 0, first_ring)

                -- Assert
                local radius = first_ring - reach - 1
                local walls = surface.count_tiles_filtered {position = {0, 0}, radius = radius, name = 'out-of-map'}
                Assert.equal(0, walls, 'wall tiles within ' .. radius .. ' of spawn')
            end
        )

        Declare.test(
            'the first ring has its gates',
            function()
                -- Act
                local _, walls = first_ring_walls()

                -- Assert
                local hits = H.band_hits(walls, first_ring, reach, STEPS)
                local expected = max(2, floor(tau * first_ring / gate_spacing + 0.5))
                Assert.equal(expected, H.count_runs(hits, STEPS, false), 'gates in the first ring')
            end
        )

        Declare.test(
            'walls are too thick for pipe-to-ground to pass under',
            function()
                -- Arrange: a stretch of the first ring's wall
                local surface, walls = first_ring_walls()
                local hits = H.band_hits(walls, first_ring, reach, STEPS)

                -- a direction well inside a stretch of wall, away from any gate
                local margin = 40
                local chosen
                for i = 0, STEPS - 1 do
                    local clear = true
                    for d = -margin, margin do
                        if not hits[(i + d) % STEPS] then
                            clear = false
                            break
                        end
                    end
                    if clear then
                        chosen = i
                        break
                    end
                end
                Assert.is_true(chosen ~= nil, 'no stretch of wall away from the gates')

                -- pipes cross along x or y, whichever is closer to straight through the wall
                local a = chosen / STEPS * tau
                local c, s = cos(a), sin(a)
                local dx, dy = 0, 0
                if abs(c) >= abs(s) then
                    dx = c > 0 and 1 or -1
                else
                    dy = s > 0 and 1 or -1
                end
                local crossing
                for r = first_ring - reach, first_ring + reach do
                    local x, y = floor(r * c + 0.5), floor(r * s + 0.5)
                    if walls[H.key(x, y)] then
                        crossing = H.crossing(walls, x, y, dx, dy)
                        break
                    end
                end
                Assert.is_true(crossing ~= nil, 'no wall found along the chosen direction')

                -- Act: pipe-to-ground either side of the wall, and the same pair over open ground
                local a1, b1 = H.build_underground_pair(surface, 'pipe-to-ground', crossing.from, crossing.to, dx, dy)
                local through_wall = H.connected(a1, b1)
                H.destroy(a1, b1)

                -- the same pair over open ground in spawn connects, so the orientation is right
                local from = {x = -5, y = 20}
                local to = {x = from.x + 9 * dx, y = from.y + 9 * dy}
                local a2, b2 = H.build_underground_pair(surface, 'pipe-to-ground', from, to, dx, dy)
                local over_ground = H.connected(a2, b2)
                H.destroy(a2, b2)

                -- Assert
                Assert.is_true(over_ground, 'control: pipe-to-ground from ' .. from.x .. ',' .. from.y .. ' to ' .. to.x .. ',' .. to.y .. ' in spawn did not connect')
                Assert.is_true(not through_wall, 'pipe-to-ground connected under a ' .. crossing.width .. ' tile wall at ' .. crossing.from.x .. ',' .. crossing.from.y)
            end
        )

        Declare.test(
            'a gate leads out of the first ring',
            function()
                -- Arrange
                local _, walls = first_ring_walls()

                -- Act
                local reached = H.walk_from_spawn(walls, half)

                -- Assert
                local outside = first_ring + reach + 1
                local escaped = false
                for k in pairs(reached) do
                    if H.distance(H.unkey(k)) > outside then
                        escaped = true
                        break
                    end
                end
                Assert.is_true(escaped, 'walking from spawn never got past ' .. outside .. ' tiles out')
            end
        )
    end
)
