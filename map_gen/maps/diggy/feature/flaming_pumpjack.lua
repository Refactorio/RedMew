-- Destroy oilwells when pumpjack explodes from fire
-- created by perfectwill

local Event = require 'utils.event'

local explosions = {
	'massive-explosion',
	'big-artillery-explosion',
}

local Public = {}

Public.register = function()
    Event.add(defines.events.on_entity_died, function(event)
        local entity = event.entity
        if not (entity and entity.valid) then
            return
        end
        if entity.name == 'pumpjack' and (event.damage_type and event.damage_type.name == 'fire') then
            local oilwell = entity.surface.find_entity('crude-oil', entity.position)
            if not oilwell then
                return
            end

            oilwell.surface.create_entity({
                name = explosions[math.random(#explosions)],
                position = oilwell.position,
            })
            oilwell.destroy()
        end
    end)
end

return Public
