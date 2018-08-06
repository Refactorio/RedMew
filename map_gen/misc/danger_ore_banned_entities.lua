local Event = require 'utils.event'

local allowed_entites = {
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
    ['pumpjack'] = true,
}

Event.add(
    defines.events.on_built_entity,
    function(event)
        local entity = event.created_entity
        if not entity or not entity.valid then
            return
        end

        local name = entity.name
        local ghost = false
        if name == 'entity-ghost' then
            name = entity.ghost_name
            ghost = true
        end

        if allowed_entites[name] then
            return
        end

        local surface = entity.surface
        local count = surface.count_entities_filtered {area = entity.bounding_box, type = 'resource', limit = 1}

        if count == 0 then
            return
        end

        local p = game.players[event.player_index]
        if not p or not p.valid then
            return
        end

        entity.destroy()
        if not ghost then
            p.insert {name = name}
        end
    end
)
