local Event = require 'utils.event'
local Global = require 'utils.global'

local biter_utils_conf = global.config.biter_corpse_util

local biter_corpses = {}

Global.register(
    biter_corpses,
    function(tbl)
        biter_corpses = tbl
    end
)

-- currently no on_corpse_spawned event, using on_entity_died instead

local function biter_died(event)
    local entity = event.entity
    if entity.valid then
        local dying_force = entity.force
        -- ignore player owned entities
        if dying_force == 'player' then
            return
        end

        local corpse_names = entity.prototype.corpses

        -- put corpse name in global list of biter/enemies
        for corpse_name, _ in pairs(corpse_names) do
            if not biter_corpses[corpse_name] then
                table.insert(biter_corpses, corpse_name)
            end
        end

        local position = entity.position
        local radius = biter_utils_conf.radius
        local area_to_search = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}}
        local surface = entity.surface

        -- count corpses on the ground around dead entity
        -- if above threshold, remove them
        -- all corpses are neutral

        if
            surface.count_entities_filtered {
                area = area_to_search,
                type = 'corpse',
                name = biter_corpses
            } > biter_utils_conf.corpse_threshold
         then
            -- remove the corpses
            for k, corpse in pairs(
                surface.find_entities_filtered {
                    area = area_to_search,
                    type = 'corpse',
                    name = biter_corpses
                }
            ) do
                if k % 2 == 1 then
                    corpse.destroy()
                end
            end
        end
    end
end

Event.add(defines.events.on_entity_died, biter_died)
