-- Shared checks for the in-game tests of maps laid out as a maze of whole chunks, land corridors
-- with void walls: the Maze map and Inception.
local Assert = require 'utils.test.assert'
local RS = require 'map_gen.shared.redmew_surface'

local Public = {}

--- Generates the chunks within `radius` of spawn.
-- @return table "cx,cy" -> true for a land chunk, false for void, and the chunks that are part
-- land, part void
function Public.chunk_map(radius)
    local surface = RS.get_surface()
    surface.request_to_generate_chunks({0, 0}, radius)
    surface.force_generate_chunk_requests()
    local land, mixed = {}, {}
    for cx = -radius, radius - 1 do
        for cy = -radius, radius - 1 do
            local void = surface.count_tiles_filtered {area = {{cx * 32, cy * 32}, {cx * 32 + 32, cy * 32 + 32}}, name = 'out-of-map'}
            land[cx .. ',' .. cy] = void == 0
            if void ~= 0 and void ~= 1024 then
                mixed[#mixed + 1] = cx .. ',' .. cy
            end
        end
    end
    return land, mixed
end

-- The checks take what chunk_map returned for `radius`.

function Public.assert_whole_chunks(land, mixed, radius)
    Assert.equal(0, #mixed, 'chunks part land, part void: ' .. table.concat(mixed, ' '))
    local count = 0
    for _, is_land in pairs(land) do
        count = count + (is_land and 1 or 0)
    end
    local total = (2 * radius) ^ 2
    Assert.is_true(count > 0 and count < total, count .. ' of ' .. total .. ' chunks round spawn are land')
end

function Public.assert_thin_walls(land, radius)
    for cx = -radius, radius - 2 do
        for cy = -radius, radius - 2 do
            local block = not land[cx .. ',' .. cy] and not land[(cx + 1) .. ',' .. cy]
                and not land[cx .. ',' .. (cy + 1)] and not land[(cx + 1) .. ',' .. (cy + 1)]
            Assert.is_true(not block, 'a 2x2 block of void chunks at chunk ' .. cx .. ',' .. cy)
        end
    end
end

function Public.assert_corridors_lead_out(land, radius)
    Assert.is_true(land['0,0'], 'spawn is not on land')
    local seen, queue = {['0,0'] = true}, {{0, 0}}
    while #queue > 0 do
        local c = table.remove(queue)
        if math.abs(c[1]) >= radius - 1 or math.abs(c[2]) >= radius - 1 then
            return
        end
        for _, d in pairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
            local key = (c[1] + d[1]) .. ',' .. (c[2] + d[2])
            if land[key] and not seen[key] then
                seen[key] = true
                queue[#queue + 1] = {c[1] + d[1], c[2] + d[2]}
            end
        end
    end
    Assert.is_true(false, 'the corridors from spawn end within ' .. radius .. ' chunks of it')
end

return Public
