local Event = require 'utils.event'

return function(config)
  local unlocks = config.unlocks or {}
  if table_size(unlocks) == 0 then
    return
  end

  Event.add(defines.events.on_research_finished, function(event)
    local research = event.research
    local techs = research.force.technologies

    for _, name in pairs(unlocks[research.name] or {}) do
      local tech = techs[name]
      if tech then
        tech.researched = true
      end
    end
  end)
end
