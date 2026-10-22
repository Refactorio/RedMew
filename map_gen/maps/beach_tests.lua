-- In-game tests for the Beach map. These run under _DEBUG via /test-runner when it is the active
-- map: the world is a band 384 tiles high with void beyond it, and going north from spawn it
-- runs grass, then a sand beach where all the ore is, then the sea.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local RS = require 'map_gen.shared.redmew_surface'

-- the band is 384 high, moved 64 north: y from -256 to 128
local NORTH, SOUTH = -256, 128
local COLUMNS = {-192, -96, 0, 96, 192}

Declare.module(
    {'map_gen', 'beach'},
    function()
        local function surface()
            local s = RS.get_surface()
            for _, x in pairs(COLUMNS) do
                for y = NORTH - 32, SOUTH + 32, 32 do
                    s.request_to_generate_chunks({x, y}, 0)
                end
            end
            s.force_generate_chunk_requests()
            return s
        end

        Declare.test(
            'the world is a band 384 tiles high, void beyond it',
            function()
                local s = surface()
                for _, x in pairs(COLUMNS) do
                    Assert.equal('out-of-map', s.get_tile(x, NORTH - 2).name, 'tile north of the band at x ' .. x)
                    Assert.equal('out-of-map', s.get_tile(x, SOUTH + 2).name, 'tile south of the band at x ' .. x)
                    Assert.is_true(s.get_tile(x, NORTH + 2).name ~= 'out-of-map', 'void inside the band at ' .. x .. ',' .. (NORTH + 2))
                    Assert.is_true(s.get_tile(x, SOUTH - 2).name ~= 'out-of-map', 'void inside the band at ' .. x .. ',' .. (SOUTH - 2))
                end
            end
        )

        Declare.test(
            'going north from spawn: grass, a sand beach with the ore, then the sea',
            function()
                local s = surface()
                Assert.equal('grass-1', s.get_tile(0, 0).name, 'tile at spawn')
                for _, x in pairs(COLUMNS) do
                    local sand, sea
                    for y = SOUTH - 1, NORTH, -1 do
                        local name = s.get_tile(x, y).name
                        if not sand and name == 'sand-1' then
                            sand = y
                        elseif name == 'water' then
                            sea = y
                            break
                        end
                    end
                    Assert.is_true(sand ~= nil, 'no beach in column ' .. x)
                    Assert.is_true(sea ~= nil and sea < sand, 'no sea north of the beach in column ' .. x)
                    local beach = {{x - 16, sea}, {x + 16, sand}}
                    Assert.is_true(s.count_entities_filtered {area = beach, type = 'resource'} > 0, 'no ore on the beach at column ' .. x)
                    -- the beach edge wobbles, so the grass starts below the southernmost sand in the strip
                    local grass = sand
                    for dx = -16, 16 do
                        for y = SOUTH - 1, grass + 1, -1 do
                            if s.get_tile(x + dx, y).name == 'sand-1' then
                                grass = y
                                break
                            end
                        end
                    end
                    Assert.equal(0, s.count_entities_filtered {area = {{x - 16, grass + 8}, {x + 16, SOUTH}}, type = 'resource'}, 'ore on the grass south of the beach at column ' .. x)
                end
            end
        )
    end
)
