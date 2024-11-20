-- This module prevents all but the allowed items from being built on top of resources
local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
local Event = require 'utils.event'
local Token = require 'utils.token'

return function(allowed_entities, message)
    --- Items explicitly allowed on ores
    RestrictEntities.add_allowed(allowed_entities or {})

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
                local count = entity.surface.count_entities_filtered {area = area, type = 'resource', limit = 1}
                if count == 0 then
                    return true
                end
            end
        )
    )

    --- Warning for players when their entities are destroyed
    local function on_destroy(event)
        local p = event.player
        if p and p.valid then
            if message then
                p.print(message)
                return
            end
            local items = {}
            local len = 0
            local entities = RestrictEntities.get_allowed()
            for k, _ in pairs(entities) do
                local entity = prototypes.entity[k]
                if entity then
                    for _, v in pairs(entity.items_to_place_this or {}) do
                        if not items[v.name] then --- Avoid duplication for straight-rail and curved-rail, which both use rail
                            items[v.name] = v
                            len = len + 1
                        end
                    end
                end
            end
            local str = "You cannot build that on top of ores, only "
            local strs = {};
            for k in pairs(items) do
                table.insert(strs, "[img=item." .. k .."]")
            end
            p.print(str..table.concat(strs, " "))
        end
    end

    Event.add(RestrictEntities.events.on_restricted_entity_destroyed, on_destroy)
end
