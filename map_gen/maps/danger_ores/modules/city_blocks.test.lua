-- Standalone tests for City Blocks chunk stamping.
-- Run from the repo root:  lua map_gen/maps/danger_ores/modules/city_blocks.test.lua
--
-- Stubs out the Factorio side of the module and runs generate_chunk against a fake surface
-- that just records set_tiles and create_entity calls. That is enough to pin the stamping
-- arithmetic -- how many rails, where, and that a chunk never writes outside itself -- which
-- is where the bugs of this kind actually live. Whether the game accepts those placements is
-- what the in-game suite in city_blocks_tests.lua checks.
package.path = './?.lua;' .. package.path

_G.defines = {direction = {north = 0, east = 4}}

package.loaded['utils.event'] = {on_init = function() end, add = function() end}
package.loaded['utils.global'] = {register = function() end}
package.loaded['utils.token'] = {register = function(f) return f end}
package.loaded['utils.table'] = {shuffle_table = function(t) return t end}
package.loaded['map_gen.shared.builders'] = setmetatable({}, {__index = function() return function() end end})
package.loaded['map_gen.shared.generate'] = {events = {on_chunk_generated = 1}}
package.loaded['map_gen.shared.redmew_surface'] = {get_surface = function() return nil end}
package.loaded['map_gen.shared.entity_placement_restriction'] = {
    events = {on_restricted_entity_destroyed = 2},
    set_keep_alive_callback = function() end,
    enable_refund = function() end
}

local CityBlocks = require 'map_gen.maps.danger_ores.modules.city_blocks'
local Layout = require 'map_gen.maps.danger_ores.modules.city_blocks_layout'

local failures = 0
local function check(cond, msg)
    if cond then print('ok:   ' .. msg) else failures = failures + 1 print('FAIL: ' .. msg) end
end

local function fake_surface()
    local s = {tiles = {}, entities = {}}
    function s.set_tiles(tiles)
        for _, t in ipairs(tiles) do
            s.tiles[t.position[1] .. '/' .. t.position[2]] = t.name
        end
    end
    function s.create_entity(spec)
        s.entities[#s.entities + 1] = {name = spec.name, x = spec.position[1], y = spec.position[2]}
        return s.entities[#s.entities]
    end
    function s.find_entities_filtered() return {} end
    return s
end

local function chunk_area(cx, cy)
    return {
        left_top = {x = cx * 32, y = cy * 32},
        right_bottom = {x = cx * 32 + 32, y = cy * 32 + 32}
    }
end

local function count(s, name)
    local n = 0
    for _, e in ipairs(s.entities) do if e.name == name then n = n + 1 end end
    return n
end

-- 1) vertical corridor chunk
local s = fake_surface()
local area = chunk_area(7, 0)
CityBlocks.generate_chunk(s, area)

local from, to = Layout.trunk_range(area.left_top.y, area.right_bottom.y, false, false)
local slots = math.floor((to - from) / 2) + 1
check(count(s, 'straight-rail') == slots * 2,
    'corridor chunk lays slots*2 rails: expected ' .. slots * 2 .. ' got ' .. count(s, 'straight-rail'))

local on_a, on_b, elsewhere = 0, 0, 0
for _, e in ipairs(s.entities) do
    if e.x == area.left_top.x + Layout.RAIL_A then on_a = on_a + 1
    elseif e.x == area.left_top.x + Layout.RAIL_B then on_b = on_b + 1
    else elsewhere = elsewhere + 1 end
end
check(on_a == slots and on_b == slots, 'rails split evenly over both tracks: ' .. on_a .. '/' .. on_b)
check(elsewhere == 0, 'no rails off the two track offsets, got ' .. elsewhere)

local out_of_chunk = 0
for _, e in ipairs(s.entities) do
    if e.x < area.left_top.x or e.x >= area.right_bottom.x or e.y < area.left_top.y or e.y >= area.right_bottom.y then
        out_of_chunk = out_of_chunk + 1
    end
end
check(out_of_chunk == 0, 'a chunk only ever writes inside itself, got ' .. out_of_chunk)

local mismatches = 0
for xo = 0, 31 do
    for yo = 0, 31 do
        local want = Layout.corridor_tile(xo, yo, true, false)
        if s.tiles[(area.left_top.x + xo) .. '/' .. (area.left_top.y + yo)] ~= want then
            mismatches = mismatches + 1
        end
    end
end
check(mismatches == 0, 'paving matches the pure pattern, mismatches=' .. mismatches)

-- 2) corner chunk
local corner = fake_surface()
local carea = chunk_area(2, 2)
CityBlocks.generate_chunk(corner, carea)
check(count(corner, 'straight-rail') == 0, 'no trunk rails on the corner')

local expected_pieces = 0
for _, e in pairs(Layout.ROUNDABOUT) do
    local x, y = carea.left_top.x + 16 + e.x, carea.left_top.y + 16 + e.y
    if x >= carea.left_top.x and x < carea.right_bottom.x and y >= carea.left_top.y and y < carea.right_bottom.y then
        expected_pieces = expected_pieces + 1
    end
end
check(expected_pieces > 0 and #corner.entities == expected_pieces,
    'corner stamps exactly the clipped ring pieces: expected ' .. expected_pieces .. ' got ' .. #corner.entities)

-- 3) room interior is untouched
local room = fake_surface()
CityBlocks.generate_chunk(room, chunk_area(0, 0))
check(#room.entities == 0 and next(room.tiles) == nil, 'room interior is left alone')

-- 4) out of bounds is voided
local void = fake_surface()
local varea = chunk_area((Layout.ROOMS_RADIUS + 1) * Layout.PITCH, 0)
CityBlocks.generate_chunk(void, varea)
check(void.tiles[(varea.left_top.x + 5) .. '/5'] == 'out-of-map', 'out of bounds chunk is voided')

-- 5) chunk next to a corner shortens its trunk and stamps the overhang
local near = fake_surface()
local narea = chunk_area(2, 1) -- ly == PITCH-2, so a corner sits to the south
CityBlocks.generate_chunk(near, narea)
check(count(near, 'straight-rail') < slots * 2,
    'trunk is shortened next to a corner: ' .. count(near, 'straight-rail') .. ' < ' .. slots * 2)
check(count(near, 'curved-rail-a') + count(near, 'curved-rail-b') > 0, 'ring overhang is stamped')

local near_out = 0
for _, e in ipairs(near.entities) do
    if e.x < narea.left_top.x or e.x >= narea.right_bottom.x or e.y < narea.left_top.y or e.y >= narea.right_bottom.y then
        near_out = near_out + 1
    end
end
check(near_out == 0, 'overhang stamping stays inside the chunk, got ' .. near_out)

if failures == 0 then
    print('\nALL PASSED')
else
    print('\n' .. failures .. ' FAILURE(S)')
    os.exit(1)
end


