-- In-game tests for the Danger Ores maze. These run on maps that turn the maze on (Coal Maze,
-- and the modded Scrap and Omnimatter mazes). They check the real map, whatever its seed,
-- around spawn: the whole maze is about 300 chunks across.
--
-- The maze is made of whole chunks, cell_size chunks per cell: a wall chunk is solid
-- out-of-map, a corridor chunk is ordinary map.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'

if not DOC.maze.enabled then
    return
end

local CHUNK_TILES = 32 * 32

Declare.module(
    {'map_gen', 'danger ores', 'maze'},
    function()
        local cell = DOC.maze.cell_size
        -- two chunks past the spawn cell each way: enough to walk out of it into the next
        local reach = cell + 2

        -- which chunks around spawn are open, after generating them
        local function open_chunks()
            local surface = H.generate(-reach * 32, -reach * 32, (reach + 1) * 32, (reach + 1) * 32)
            local open, walls = {}, 0
            for cx = -reach, reach do
                for cy = -reach, reach do
                    local void = surface.count_tiles_filtered {area = H.chunk_area(cx, cy), name = 'out-of-map'}
                    if void < CHUNK_TILES then
                        open[cx .. ',' .. cy] = true
                    else
                        walls = walls + 1
                    end
                end
            end
            return open, walls
        end

        Declare.test(
            'the area around spawn has both walls and corridors',
            function()
                -- Act
                local open, walls = open_chunks()

                -- Assert
                local corridors = 0
                for _ in pairs(open) do
                    corridors = corridors + 1
                end
                Assert.is_true(open['0,0'], 'the spawn chunk is walled in')
                Assert.is_true(walls > 0, 'no maze walls within ' .. reach .. ' chunks of spawn')
                Assert.is_true(corridors > cell * cell, 'only ' .. corridors .. ' open chunks within ' .. reach .. ' chunks of spawn')
            end
        )

        Declare.test(
            'walking from spawn leads out of its cell into the maze',
            function()
                -- Arrange
                local open = open_chunks()

                -- Act: walk the open chunks from spawn
                local seen = {['0,0'] = true}
                local stack = {{0, 0}}
                local farthest = 0
                while #stack > 0 do
                    local c = stack[#stack]
                    stack[#stack] = nil
                    farthest = math.max(farthest, math.abs(c[1]), math.abs(c[2]))
                    for _, d in pairs {{1, 0}, {-1, 0}, {0, 1}, {0, -1}} do
                        local x, y = c[1] + d[1], c[2] + d[2]
                        local k = x .. ',' .. y
                        if open[k] and not seen[k] then
                            seen[k] = true
                            stack[#stack + 1] = {x, y}
                        end
                    end
                end
                -- Assert: out of the spawn cell means more than a cell away from the spawn chunk
                Assert.is_true(farthest > cell, 'walking from spawn only gets ' .. farthest .. ' chunks out: the spawn cell is closed')
            end
        )
    end
)
