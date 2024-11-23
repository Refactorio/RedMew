local Event = require 'utils.event'

local trigger_names = {
  uranium = {
    'uranium-mining',
    'uranium-processing',
  },
  liquefaction = {
    'oil-processing',
  },
}

return function(config)
  Event.on_init(function()
    for _, force in pairs(game.forces) do
      for key, enabled in pairs(config) do

        local names = enabled and trigger_names[key] or {}

        for _, name in pairs(names) do
          local tech = force.technologies[name]
          if tech and tech.prototype.research_trigger then
            tech.researched = true
          end
        end

      end
    end
  end)
end
