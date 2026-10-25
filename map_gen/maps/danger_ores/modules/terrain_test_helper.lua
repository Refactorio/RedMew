-- Shared helpers for the in-game tests of the Danger Ores terrain overlays (rivers, archipelago,
-- citadel, fault lines) and terraforming. The tests run on the real map, whatever its seed, so
-- everything here reads the tiles the game actually placed.
local RS = require 'map_gen.shared.redmew_surface'
local Generate = require 'map_gen.shared.generate'
local DOC = require 'map_gen.maps.danger_ores.configuration'

local floor = math.floor
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin
local tau = 2 * math.pi

local Public = {}

local CHUNK_TILES = 32 * 32
local directions_4 = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

local function chunk_area(cx, cy)
    return {left_top = {x = cx * 32, y = cy * 32}, right_bottom = {x = cx * 32 + 32, y = cy * 32 + 32}}
end
Public.chunk_area = chunk_area

--- Generates the real map over the square of tiles [x1, x2) x [y1, y2), including chunks
-- terraforming has locked: a locked chunk is solid out-of-map, which no overlay produces, so
-- it is generated again the way terraforming does when it unlocks one. Without terraforming,
-- solid out-of-map is the map's own (expanse's land not yet bought), so it is left alone.
-- @return LuaSurface
function Public.generate(x1, y1, x2, y2)
    local surface = RS.get_surface()
    local cx1, cy1 = floor(x1 / 32), floor(y1 / 32)
    local cx2, cy2 = floor((x2 - 1) / 32), floor((y2 - 1) / 32)

    for cx = cx1, cx2 do
        for cy = cy1, cy2 do
            surface.request_to_generate_chunks({cx * 32 + 16, cy * 32 + 16}, 0)
        end
    end
    surface.force_generate_chunk_requests()
    if not DOC.terraforming.enabled then
        return surface
    end

    for cx = cx1, cx2 do
        for cy = cy1, cy2 do
            local area = chunk_area(cx, cy)
            if surface.count_tiles_filtered {area = area, name = 'out-of-map'} == CHUNK_TILES then
                Generate.do_chunk({surface = surface, area = area, position = {x = cx, y = cy}})
            end
        end
    end

    return surface
end

--- Generates the square of tiles within `radius` of {cx, cy}.
function Public.generate_around(cx, cy, radius)
    return Public.generate(cx - radius, cy - radius, cx + radius, cy + radius)
end

--- Generates squares round {cx, cy} of each half-width in `halves` in turn, until
-- `found(surface, half)` is true. Generating is most of what the bigger map tests cost, and most
-- seeds show what a test looks for well inside its largest area.
-- @return the surface, and the half-width it stopped at (the last one if nothing was found)
function Public.generate_until(cx, cy, halves, found)
    local surface, half
    for _, h in ipairs(halves) do
        half = h
        surface = Public.generate_around(cx, cy, h)
        if found(surface, h) then
            break
        end
    end
    return surface, half
end

-- A tile's key in a set of tiles: a number, which is much quicker to make and look up than an
-- "x,y" string over the hundreds of thousands of tiles some tests walk. Unique for |x|, |y| < 2^19.
local function key(x, y)
    return x * 1048576 + y
end
Public.key = key

--- The x and y a key was made from.
function Public.unkey(k)
    local x = math.floor((k + 524288) / 1048576)
    return x, k - x * 1048576
end

--- Set of the tiles (by key) in an area whose tile name is in `names`.
function Public.tile_set(surface, area, names)
    local set = {}
    for _, tile in pairs(surface.find_tiles_filtered {area = area, name = names}) do
        local p = tile.position
        set[key(p.x, p.y)] = true
    end
    return set
end

--- Directions around a circle of radius r, flagged by whether any tile of the band
-- [r - half_width, r + half_width] along that direction is in `set`.
-- @return boolean[] indexed 0 .. steps - 1
function Public.band_hits(set, r, half_width, steps)
    local hits = {}
    for i = 0, steps - 1 do
        local a = i / steps * tau
        local c, s = cos(a), sin(a)
        local hit = false
        for d = r - half_width, r + half_width do
            if set[key(floor(d * c + 0.5), floor(d * s + 0.5))] then
                hit = true
                break
            end
        end
        hits[i] = hit
    end
    return hits
end

--- Number of runs of `value` in a circular boolean array.
function Public.count_runs(hits, steps, value)
    local runs = 0
    for i = 0, steps - 1 do
        if hits[i] == value and hits[(i - 1) % steps] ~= value then
            runs = runs + 1
        end
    end
    return runs
end

--- The crossing of a run of `blocked` tiles through (x, y) along the axis (dx, dy): the last
-- open tile before it, the first open tile after it, and how many tiles it is across.
function Public.crossing(blocked, x, y, dx, dy)
    local back = 0
    while blocked[key(x - dx * (back + 1), y - dy * (back + 1))] do
        back = back + 1
    end
    local forward = 0
    while blocked[key(x + dx * (forward + 1), y + dy * (forward + 1))] do
        forward = forward + 1
    end
    return {
        from = {x = x - dx * (back + 1), y = y - dy * (back + 1)},
        to = {x = x + dx * (forward + 1), y = y + dy * (forward + 1)},
        width = back + forward + 1,
        dx = dx,
        dy = dy
    }
end

local function direction_of(dx, dy)
    if dx > 0 then
        return defines.direction.east
    elseif dx < 0 then
        return defines.direction.west
    elseif dy > 0 then
        return defines.direction.south
    end
    return defines.direction.north
end

local function opposite(dx, dy)
    return direction_of(-dx, -dy)
end

local function clear_for_building(surface, x, y)
    for _, e in pairs(surface.find_entities_filtered {area = {{x, y}, {x + 1, y + 1}}}) do
        if e.type ~= 'resource' then
            e.destroy()
        end
    end
end

--- Builds an underground pair of `name` from tile `from` to tile `to` (an axis crossing).
-- Underground belts and pipe-to-ground are both handled. Returns the two entities; the caller
-- destroys them.
function Public.build_underground_pair(surface, name, from, to, dx, dy)
    clear_for_building(surface, from.x, from.y)
    clear_for_building(surface, to.x, to.y)

    local a, b
    if prototypes.entity[name].type == 'underground-belt' then
        local dir = direction_of(dx, dy)
        a = surface.create_entity {name = name, position = {from.x + 0.5, from.y + 0.5}, direction = dir, type = 'input', force = 'player'}
        b = surface.create_entity {name = name, position = {to.x + 0.5, to.y + 0.5}, direction = dir, type = 'output', force = 'player'}
    else
        -- a pipe-to-ground faces its above-ground connection; the underground one points back
        a = surface.create_entity {name = name, position = {from.x + 0.5, from.y + 0.5}, direction = opposite(dx, dy), force = 'player'}
        b = surface.create_entity {name = name, position = {to.x + 0.5, to.y + 0.5}, direction = direction_of(dx, dy), force = 'player'}
    end
    return a, b
end

local function contains(list, entity)
    if list == entity then
        return true
    end
    if type(list) ~= 'table' then
        return false
    end
    for _, v in pairs(list) do
        if contains(v, entity) then
            return true
        end
    end
    return false
end

--- Whether two built underground entities are paired with each other.
function Public.connected(a, b)
    if a == nil or b == nil then
        return false
    end
    if a.type == 'underground-belt' then
        return a.underground_belt_neighbour == b
    end
    return contains(a.fluidbox_neighbours, b)
end

function Public.destroy(...)
    for _, e in pairs {...} do
        if e and e.valid then
            e.destroy()
        end
    end
end

--- The widest gap an underground of `name` spans: tiles between the two ends.
function Public.underground_gap(name)
    return prototypes.entity[name].max_underground_distance - 1
end

--- Flood fills the open tiles of the square [-half, half]^2 from spawn, where `blocked` marks
-- tiles that can't be walked on.
-- @return set of reached tile keys
function Public.walk_from_spawn(blocked, half)
    local seen = {[key(0, 0)] = true}
    local stack = {{0, 0}}
    while #stack > 0 do
        local p = stack[#stack]
        stack[#stack] = nil
        for _, d in pairs(directions_4) do
            local x, y = p[1] + d[1], p[2] + d[2]
            if x >= -half and x <= half and y >= -half and y <= half then
                local k = key(x, y)
                if not seen[k] and not blocked[k] then
                    seen[k] = true
                    stack[#stack + 1] = {x, y}
                end
            end
        end
    end
    return seen
end

--- Sizes of the groups of open tiles within `radius` of spawn that `reached` doesn't contain.
function Public.unreached_groups(blocked, reached, radius)
    local done = {}
    local sizes = {}
    local r_sq = radius * radius
    for x = -radius, radius do
        for y = -radius, radius do
            local k = key(x, y)
            if x * x + y * y < r_sq and not blocked[k] and not reached[k] and not done[k] then
                local size = 0
                local stack = {{x, y}}
                done[k] = true
                while #stack > 0 do
                    local p = stack[#stack]
                    stack[#stack] = nil
                    size = size + 1
                    for _, d in pairs(directions_4) do
                        local nx, ny = p[1] + d[1], p[2] + d[2]
                        local nk = key(nx, ny)
                        if nx * nx + ny * ny < r_sq and not blocked[nk] and not reached[nk] and not done[nk] then
                            done[nk] = true
                            stack[#stack + 1] = {nx, ny}
                        end
                    end
                end
                sizes[#sizes + 1] = size
            end
        end
    end
    return sizes
end

-- Danger Ores puts a pond of this radius at spawn for an offshore pump (modules/map.lua).
Public.SPAWN_POND_RADIUS = 14

--- Tiles named `names` between the spawn pond and `radius` from spawn.
function Public.count_outside_spawn_pond(surface, radius, names)
    local all = surface.count_tiles_filtered {position = {0, 0}, radius = radius, name = names}
    local pond = surface.count_tiles_filtered {position = {0, 0}, radius = Public.SPAWN_POND_RADIUS + 1, name = names}
    return all - pond
end

function Public.distance(x, y)
    return sqrt(x * x + y * y)
end

local function footprint(name, position)
    local box = prototypes.entity[name].collision_box
    return {
        {position.x + box.left_top.x, position.y + box.left_top.y},
        {position.x + box.right_bottom.x, position.y + box.right_bottom.y}
    }
end
Public.footprint = footprint

--- A place near spawn where `name` can be built with ore under it. Where there is none to
-- build on (Diggy's ore is in the rock), ore is put under a place where it can be built.
-- @return position or nil
function Public.ore_spot(surface, name)
    Public.generate_around(0, 0, 128)
    for _, ore in pairs(surface.find_entities_filtered {position = {0, 0}, radius = 128, type = 'resource', name = {'iron-ore', 'copper-ore', 'coal', 'stone'}, limit = 4000}) do
        local p = ore.position
        if surface.can_place_entity {name = name, position = p, force = 'player'} then
            return p
        end
    end
    local p = Public.dry_spot(surface, name)
    if p then
        surface.create_entity {name = 'iron-ore', position = p, amount = 1000}
    end
    return p
end

--- A place near spawn where `name` can be built with no ore under it. Some maps have ore right up
-- to spawn; there the ore is cleared off a place where it can be built.
-- @return position or nil
function Public.dry_spot(surface, name)
    Public.generate_around(0, 0, 64)
    for r = 0, 60 do
        for _, d in pairs({{r, 0}, {-r, 0}, {0, r}, {0, -r}, {r, r}, {-r, -r}, {r, -r}, {-r, r}}) do
            local p = {x = d[1] + 0.5, y = d[2] + 0.5}
            if surface.can_place_entity {name = name, position = p, force = 'player'}
                and surface.count_entities_filtered {area = footprint(name, p), type = 'resource'} == 0 then
                return p
            end
        end
    end
    local p = surface.find_non_colliding_position(name, {0, 0}, 32, 1)
    if p then
        -- a tile further out, as the building snaps to the tile grid when it is placed
        local area = footprint(name, p)
        area = {{area[1][1] - 1, area[1][2] - 1}, {area[2][1] + 1, area[2][2] + 1}}
        for _, ore in pairs(surface.find_entities_filtered {area = area, type = 'resource'}) do
            ore.destroy()
        end
    end
    return p
end

return Public
