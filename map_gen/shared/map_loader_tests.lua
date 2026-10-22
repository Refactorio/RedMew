-- In-game smoke test for whichever map is loaded. map_loader loads every map, so this runs
-- under _DEBUG via /test-runner on all of them, and in CI on every map in the list there.
--
-- Map generation errors stop the game under _DEBUG, so generating the spawn area at all
-- already catches a map whose shape fails (a require inside a builder function, say, which
-- only fails once the map is built). On top of that, players have to spawn somewhere they
-- can stand.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local RS = require 'map_gen.shared.redmew_surface'

local SPAWN_CHUNK_RADIUS = 3

Declare.module(
    {'map_gen', 'map loads'},
    function()
        Declare.test(
            'the spawn area generates',
            function()
                local surface = RS.get_surface()
                Assert.valid(surface, 'no map surface')

                local spawn = game.forces.player.get_spawn_position(surface)
                surface.request_to_generate_chunks(spawn, SPAWN_CHUNK_RADIUS)
                surface.force_generate_chunk_requests()

                -- a finite world (One Direction's ribbon, say) has no chunks past its edge
                local settings = surface.map_gen_settings
                local function in_world(c, size)
                    if not size or size == 0 then
                        return true
                    end
                    return c * 32 + 32 > -size / 2 and c * 32 < size / 2
                end

                local cx, cy = math.floor(spawn.x / 32), math.floor(spawn.y / 32)
                for x = cx - SPAWN_CHUNK_RADIUS, cx + SPAWN_CHUNK_RADIUS do
                    for y = cy - SPAWN_CHUNK_RADIUS, cy + SPAWN_CHUNK_RADIUS do
                        if in_world(x, settings.width) and in_world(y, settings.height) then
                            Assert.is_true(surface.is_chunk_generated({x, y}), 'chunk ' .. x .. ',' .. y .. ' near spawn was not generated')
                        end
                    end
                end
            end
        )

        Declare.test(
            'players spawn somewhere they can stand',
            function()
                local surface = RS.get_surface()
                local spawn = game.forces.player.get_spawn_position(surface)
                surface.request_to_generate_chunks(spawn, 2)
                surface.force_generate_chunk_requests()

                -- a new player is put at the nearest free spot within 50 tiles (redmew_surface), and
                -- only without one on a 3x3 island at the spawn point, so there has to be one
                local free = surface.find_non_colliding_position('character', spawn, 50, 1)
                Assert.is_true(free ~= nil, 'no room for a character within 50 tiles of the spawn point ' .. spawn.x .. ',' .. spawn.y)
            end
        )
    end
)
