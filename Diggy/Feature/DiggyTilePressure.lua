--[[-- info
    Provides the ability to show pressure values on the map.
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
      

        local r = event.value
        local g = 1 - event.value
        if r < 0 then r = 0 end
        if r > 1 then r = 1 end
        if g < 0 then g = 0 end
        if g > 1 then g = 1 end

        local text = math.floor(100 * event.value) / 100   
        local color = { r = r, g = g, b = 0}
        
        local e = event.surface.find_entity("flying-text", event.position)
        
        if e then
            if text == 0 then 
                e.destroy()
            else
                e.text = text
                e.color = color
            end
        else 
            if text == 0 then return end
            local e = event.surface.create_entity{
                name ="flying-text",
                color = color,
                text = text,
                position = event.position
            }
            e.active = false
        end
    end)
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function DiggyTilePressure.initialize(config)

end

return DiggyTilePressure
