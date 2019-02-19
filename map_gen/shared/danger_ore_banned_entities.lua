-- This module prevents all but the allowed items from being built on top of resources
local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
local Event = require 'utils.event'

--- Items explicitly allowed on ores
RestrictEntities.add_allowed(
    {
        'transport-belt',
        'fast-transport-belt',
        'express-transport-belt',
        'underground-belt',
        'fast-underground-belt',
        'express-underground-belt',
        'small-electric-pole',
        'medium-electric-pole',
        'big-electric-pole',
        'substation',
        'electric-mining-drill',
        'burner-mining-drill',
        'pumpjack'
    }
)

--- The logic for checking that there are resources under the entity's position
RestrictEntities.set_keep_alive_callback(
    function(entity)
        -- Some entities have a bounding_box area of zero, eg robots.
        local area = entity.bounding_box
        local left_top, right_bottom = area.left_top, area.right_bottom
        if left_top.x == right_bottom.x and left_top.y == right_bottom.y then
            return true
        end
        local count = entity.surface.count_entities_filtered {area = area, type = 'resource', limit = 1}
        if count == 0 then
            return true
        end
    end
)

--- Warning for players when their entities are destroyed
local function on_destroy(event)
    local p = event.player
    if p and p.valid then
        p.print('You cannot build that on top of ores, only belts, mining drills, and power poles are allowed.')
    end
end

Event.add(RestrictEntities.events.on_restricted_entity_destroyed, on_destroy)
