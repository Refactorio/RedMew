-- Helpers for Diggy's in-game tests: opening the void the way digging does.
local Event = require 'utils.event'
local Template = require 'map_gen.maps.diggy.template'

local Public = {}

-- void tiles opened so far, counted from the event digging raises for each
local opened = 0
Event.add(Template.events.on_void_removed, function()
    opened = opened + 1
end)

--- Opens the void in `area` ({{x1, y1}, {x2, y2}}, x2 and y2 left out) into dirt through
-- Template.insert, as digging does, after generating it. Calls `after(count)` once the insert has
-- finished, with how many void tiles were opened.
function Public.open(context, surface, area, after)
    local x1, y1, x2, y2 = area[1][1], area[1][2], area[2][1], area[2][2]
    surface.request_to_generate_chunks({(x1 + x2) / 2, (y1 + y2) / 2}, math.ceil(math.max(x2 - x1, y2 - y1) / 64) + 1)
    surface.force_generate_chunk_requests()
    local tiles = {}
    for x = x1, x2 - 1 do
        for y = y1, y2 - 1 do
            -- Template reads position.x and position.y
            tiles[#tiles + 1] = {name = 'dirt-1', position = {x = x, y = y}}
        end
    end
    local before = opened
    Template.insert(surface, tiles, {})
    -- 8 tiles an insert: the first four inserts happen at once, the rest are queued, one a tick
    context:timeout(math.ceil(#tiles / 8) + 60, function()
        after(opened - before)
    end)
end

--- Destroys what the enemy force has in `area`, so a test's aliens don't wander into the next.
function Public.clear_enemies(surface, area)
    for _, entity in pairs(surface.find_entities_filtered {area = area, force = 'enemy'}) do
        entity.destroy()
    end
end

return Public
