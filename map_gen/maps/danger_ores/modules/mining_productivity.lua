-- This module replaces mining productivity research effects with robot cargo capacity effects
local Event = require 'utils.event'

local MINING_PROD = 'mining-productivity'
local function starts_with(str, pattern)
  return str:sub(1, #pattern) == pattern
end

return function(config)
  if config.replace then
    Event.add(defines.events.on_research_finished, function(event)
      local tech = event.research
      if not (tech and tech.valid) then
        return
      end

      if not starts_with(tech.name, MINING_PROD) then
        return
      end

      local force = tech.force
      force.mining_drill_productivity_bonus = 0
      force.worker_robots_storage_bonus = force.worker_robots_storage_bonus + 1

      game.print(table.concat({
        '[color=orange][Mining productivity][/color]',
        '➡',
        '[color=blue][Worker robots cargo size][/color]',
        '\nReplacing technology effects. New robots cargo capacity:',
        '[color=green][font=var]+'..force.worker_robots_storage_bonus..'[/font][/color]'
      }, '\t\t'))
    end)

    Event.add(defines.events.on_technology_effects_reset, function(event)
      local force = event.force
      if not (force and force.valid) then
        return
      end
      force.worker_robots_storage_bonus = force.worker_robots_storage_bonus + math.floor(force.mining_drill_productivity_bonus / 0.1)
      force.mining_drill_productivity_bonus = 0
    end)
  else
    Event.on_init(function()
      for _, force in pairs(game.forces) do
        for name, tech in pairs(force.technologies) do
          if starts_with(name, MINING_PROD) then
            tech.enabled = false
          end
        end
      end
    end)
  end
end
