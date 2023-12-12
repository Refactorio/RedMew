local Event = require 'utils.event'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'

return function(config)
  ShareGlobals.data.tech_scaling = config.effects or {}

  local function on_research_finished(event)
    if not ShareGlobals.data.technology_price_multiplier then
      ShareGlobals.data.technology_price_multiplier = game.difficulty_settings.technology_price_multiplier
    end

    if event.research and ShareGlobals.data.tech_scaling[event.research.name] ~= nil then
      game.difficulty_settings.technology_price_multiplier = ShareGlobals.data.technology_price_multiplier * ShareGlobals.data.tech_scaling[event.research.name]
    end
  end

  Event.add(defines.events.on_research_finished, on_research_finished)
end
