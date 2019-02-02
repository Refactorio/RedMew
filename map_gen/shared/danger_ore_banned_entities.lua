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
RestrictEntities.set_logic(
    function(surface, area)
        local count = surface.count_entities_filtered {area = area, type = 'resource', limit = 1}
        if count == 0 then
            return true
        end
    end
)

--- Warning for players when their entities are destroyed
local function on_destroy(event)
    local p = event.player
    if p and p.valid then
        p.print('You cannot build on top of ores')
    end
end

Event.add(RestrictEntities.events.on_restricted_entity_destroyed, on_destroy)
