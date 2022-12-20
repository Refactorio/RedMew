-- This module prevents all but the allowed items from being built on top of resources
local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
local Event = require 'utils.event'
local Token = require 'utils.token'
local ScenarioInfo = require 'features.gui.info'

local DangerOre = {}

local function banned_entities(allowed_entities)
    --- Items explicitly allowed on ores
    RestrictEntities.add_allowed(allowed_entities)

    --- The logic for checking that there are resources under the entity's position
    RestrictEntities.set_keep_alive_callback(
        Token.register(
            function(entity)
                -- Some entities have a bounding_box area of zero, eg robots.
                local area = entity.bounding_box
                local left_top, right_bottom = area.left_top, area.right_bottom
                if left_top.x == right_bottom.x and left_top.y == right_bottom.y then
                    return true
                end
                local count = entity.surface.count_entities_filtered {area = area, name = {'coal', 'copper-ore', 'iron-ore', 'stone', 'uranium-ore'}, limit = 1}
                if count == 0 then
                    return true
                end
            end
        )
    )

    --- Warning for players when their entities are destroyed
    --- Note: Edit to limit warning once per minute per player produced completely automatically by ChatGPT
    local last_warning_time = {}

    local function on_destroy(event)
        local p = event.player
        if p and p.valid then
            if not last_warning_time[p.index] then
                last_warning_time[p.index] = 0
            end
            local current_time = game.tick
            if current_time > last_warning_time[p.index] + (60 * 60) then  -- 60 seconds * 60 ticks per second
                last_warning_time[p.index] = current_time
                p.print('You cannot build that on top of ores, only belts, mining drills, and power poles are allowed.')
            end
        end
    end

    Event.add(RestrictEntities.events.on_restricted_entity_destroyed, on_destroy)
end

function DangerOre.register (config)
	local allowed_entities = config.allowed_entities
	banned_entities(allowed_entities)
	ScenarioInfo.add_map_extra_info([[Danger! Ores are generally unstable to build upon.
Only the following entities have been strengthened for building upon the ores:
 [item=burner-mining-drill] [item=electric-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=car] [item=tank] [item=spidertron]
 [item=stone-wall][item=small-lamp][item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt]  [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt] [item=pipe] [item=pipe-to-ground]
]])
end

return DangerOre
