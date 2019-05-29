-- This module prevents all but the allowed items from being built on top of resources
local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
local Event = require 'utils.event'

--- Items explicitly allowed on ores
RestrictEntities.add_allowed(
    {
        'basic-transport-belt',
        'transport-belt',
        'fast-transport-belt',
        'express-transport-belt',
        'turbo-transport-belt',
        'ultimate-transport-belt',
        'basic-underground-belt',
        'underground-belt',
        'fast-underground-belt',
        'express-underground-belt',
        'turbo-underground-belt',
        'ultimate-underground-belt',
        'small-electric-pole',
        'medium-electric-pole',
        'medium-electric-pole-2',
        'medium-electric-pole-3',
        'medium-electric-pole-4',
        'big-electric-pole',
        'big-electric-pole-2',
        'big-electric-pole-3',
        'big-electric-pole-4',
        'substation',
        'substation-2',
        'substation-3',
        'substation-4',
        'electric-mining-drill',
        'bob-mining-drill-1',
        'bob-mining-drill-2',
        'bob-mining-drill-3',
        'bob-mining-drill-4',
        'bob-area-mining-drill-1',
        'bob-area-mining-drill-2',
        'bob-area-mining-drill-3',
        'bob-area-mining-drill-4',
        'burner-mining-drill',
        'pumpjack',
        'bob-pumpjack-1',
        'bob-pumpjack-2',
        'bob-pumpjack-3',
        'bob-pumpjack-4',
        'water-miner-1',
        'water-miner-2',
        'water-miner-3',
        'water-miner-4',
        'water-miner-5',
        'car',
        'tank',
        'bob-tank-2',
        'bob-tank-3',
        'thermal-water-extractor'
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
