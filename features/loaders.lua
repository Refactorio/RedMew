local Event = require 'utils.event'

local technology_map = {
    ['logistics'] = 'loader',
    ['logistics-2'] = 'fast-loader',
    ['logistics-3'] = 'express-loader'
}

Event.add(
    defines.events.on_research_finished,
    function(event)
        local research = event.research
        local recipe = technology_map[research.name]
        if recipe then
            research.force.recipes[recipe].enabled = true
        end
    end
)
