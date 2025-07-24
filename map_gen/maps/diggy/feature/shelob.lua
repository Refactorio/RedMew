-- Invincible vehicles with enough experience

local Event = require 'utils.event'
local ForceControl = require 'features.force_control'

local Public = {}

Public.register = function()
    Event.on_built(function(event)
        local entity = event.entity
        if not (entity and entity.valid) then
            return
        end
        if entity.type ~= 'spider-vehicle' then
            return
        end
        local data = ForceControl.get_force_data(entity.force)
        if not (data and data.current_level and data.current_level > 300) then
            return
        end
        entity.destructible = false
    end)
end

return Public
