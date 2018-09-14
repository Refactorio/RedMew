--[[-- info
    Provides the ability to collapse caves when digging.
]]

-- dependencies

local Event = require 'utils.event'
local PressureMap = require 'Diggy.PressureMap'

-- this
local DiggyTilePressure = {}



--[[--
    Registers all event handlers.]

    @param config Table {@see Diggy.Config}.
]]
function DiggyTilePressure.register(config)
    Event.add(PressureMap.events.on_pressure_changed, function(event)
      
        local e = game.surfaces['nauvis'].find_entity("flying-text", event.position)
        if e then   e.destroy() end
        
        local r = event.value
        local g = 1 - event.value
        if r < 0 then r = 0 end
        if r > 1 then r = 1 end
        if g < 0 then g = 0 end
        if g > 1 then g = 1 end
        
        local e = game.surfaces['nauvis'].create_entity{
            name="flying-text",
            color={ r = g, g = g, b = 0},
            text=math.floor(100 * event.value) / 100,    
            position= event.position
        } 
        e.active = false
    end)
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function DiggyTilePressure.initialize(config)

end

return DiggyTilePressure
