local Event = require 'utils.event'
local Game = require 'utils.game'

global.allowed_entites = {
    ['transport-belt'] = true,
    ['fast-transport-belt'] = true,
    ['express-transport-belt'] = true,
    ['underground-belt'] = true,
    ['fast-underground-belt'] = true,
    ['express-underground-belt'] = true,
    ['small-electric-pole'] = true,
    ['medium-electric-pole'] = true,
    ['big-electric-pole'] = true,
    ['substation'] = true,
    ['electric-mining-drill'] = true,
    ['burner-mining-drill'] = true,
    ['pumpjack'] = true
}

Event.add(
    defines.events.on_built_entity,
    function(event)
        local entity = event.created_entity
        if not entity or not entity.valid then
            return
        end

        local name = entity.name

        if name == 'tile-ghost' then
            return
        end

        local ghost = false
        if name == 'entity-ghost' then
            name = entity.ghost_name
            ghost = true
        end

        if global.allowed_entites[name] then
            return
        end

        -- Some entities have a bounding_box area of zero, eg robots.
        local area = entity.bounding_box
        local left_top, right_bottom = area.left_top, area.right_bottom
        if left_top.x == right_bottom.x and left_top.y == right_bottom.y then
            return
        end

        local count = entity.surface.count_entities_filtered {area = area, type = 'resource', limit = 1}

        if count == 0 then
            return
        end

        local p = Game.get_player_by_index(event.player_index)
        if not p or not p.valid then
            return
        end

        entity.destroy()
        if not ghost then
            p.insert(event.stack)
        end
    end
)
